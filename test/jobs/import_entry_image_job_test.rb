require "test_helper"
require_relative "../test_helpers/image_import_test_helper"

class ImportEntryImageJobTest < ActiveSupport::TestCase
  include ImageImportTestHelper
  include ActiveJob::TestHelper

  test "queues URL changes but not title changes and publishes all capped images" do
    entry = nil
    assert_enqueued_with(job: ImportEntryImageJob) do
      entry = Entry.create!(title: "Image", url: "https://example.com/image.png")
    end
    assert_no_enqueued_jobs(only: ImportEntryImageJob) { entry.update!(title: "Edited") }
    import_image(entry)
    assert_equal "ready", entry.image_import_status
    ImageOptimizer::SIZES.each do |kind, (_dimension, cap)|
      blob = entry.local_image(kind).blob
      assert_equal "image/webp", blob.content_type
      assert_operator blob.byte_size, :<=, cap
      assert blob.metadata["analyzed"]
    end
    original = entry.image_master.blob_id
    assert_no_difference "ActiveStorage::Blob.count" do
      import_image(entry)
    end
    assert_equal original, entry.image_master.blob_id
  end

  test "failed replacements retain previous images and can be retried" do
    entry = Entry.create!(title: "Image", url: "https://example.com/old.png")
    import_image(entry)
    previous = entry.image_master.blob_id
    entry.update!(url: "https://example.com/new.png")
    with_method(ImageDownload, :open, ->(*) { raise ImageDownload::Error, "Missing image" }) do
      ImportEntryImageJob.perform_now(entry.id, entry.image_import_token)
    end
    entry.reload
    assert_equal "failed", entry.image_import_status
    assert_equal "Missing image", entry.image_import_error
    assert_equal previous, entry.image_master.blob_id
    old_token = entry.image_import_token
    assert entry.retry_image_import!
    assert_not_equal old_token, entry.image_import_token
    import_image(entry)
    assert_equal "ready", entry.image_import_status
    assert_nil entry.image_import_error
    assert_not_equal previous, entry.image_master.blob_id
  end

  test "a URL change during processing prevents stale publication and removes unused blobs" do
    entry = Entry.create!(title: "Image", url: "https://example.com/old.png")
    token = entry.image_import_token
    optimizer = ImageOptimizer.method(:call)
    with_image_download do
      with_method(ImageOptimizer, :call, ->(path) {
        images = optimizer.call(path)
        Entry.find(entry.id).update!(url: "https://example.com/new.png")
        images
      }) do
        assert_no_difference "ActiveStorage::Blob.count" do
          ImportEntryImageJob.perform_now(entry.id, token)
        end
      end
    end
    assert_not entry.reload.image_master.attached?
    assert_equal "pending", entry.image_import_status
  end

  test "removing the source and deleting entries purge local files" do
    entry = Entry.create!(title: "Article", url: "https://example.com/article", image_url: "https://example.com/photo.png")
    import_image(entry)
    blobs = ImageOptimizer::SIZES.keys.map { |kind| entry.local_image(kind).blob }
    entry.update!(image_url: nil)
    perform_enqueued_jobs(only: ActiveStorage::PurgeJob) do
      ImportEntryImageJob.perform_now(entry.id, entry.image_import_token)
    end
    blobs.each { |blob| assert_not blob.service.exist?(blob.key) }
    assert_not entry.reload.image_master.attached?
    entry.update!(image_url: "https://example.com/photo.png")
    import_image(entry)
    blob = entry.image_master.blob
    perform_enqueued_jobs(only: ActiveStorage::PurgeJob) { entry.destroy! }
    assert_not blob.service.exist?(blob.key)
  end
end
