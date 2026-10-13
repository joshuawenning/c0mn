require "test_helper"

class EntryImageBackfillTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "queues legacy and failed images and skips pending ready and non-image entries" do
    legacy = Entry.create!(title: "Legacy", url: "https://example.com/legacy.png")
    legacy.update_columns(image_import_status: "none", image_import_token: nil)
    failed = Entry.create!(title: "Failed", url: "https://example.com/failed.png")
    failed.update_column(:image_import_status, "failed")
    pending = Entry.create!(title: "Pending", url: "https://example.com/pending.png")
    ready = Entry.create!(title: "Ready", url: "https://example.com/ready.png")
    ready.update_column(:image_import_status, "ready")
    Entry.create!(title: "Link", url: "https://example.com/link")
    tokens = [ pending.image_import_token, ready.image_import_token ]

    assert_enqueued_jobs 2, only: ImportEntryImageJob do
      assert_equal({ queued: 2, skipped: 1 }, EntryImageBackfill.call)
    end
    assert_equal "pending", legacy.reload.image_import_status
    assert_equal "pending", failed.reload.image_import_status
    assert_equal tokens, [ pending.reload.image_import_token, ready.reload.image_import_token ]
    assert_no_enqueued_jobs(only: ImportEntryImageJob) { EntryImageBackfill.call }
  end
end
