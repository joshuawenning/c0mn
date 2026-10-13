require "stringio"

class ImportEntryImageJob < ApplicationJob
  NETWORK_ERRORS = [ ImageDownload::TransientError, Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError, EOFError ].freeze
  retry_on(*NETWORK_ERRORS, wait: :polynomially_longer, attempts: 3)
  discard_on ActiveRecord::RecordNotFound

  def perform(entry_id, token)
    entry = Entry.find(entry_id)
    return unless entry.image_import_token == token
    return if entry.image_import_status == "ready"
    source = entry.embeddable_image_url
    blobs = {}
    published = false

    if source
      images = ImageDownload.open(source) { |file| ImageOptimizer.call(file.path) }
      images.each do |kind, image|
        blobs[kind] = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new(image[:bytes]), filename: "entry-#{entry.id}-#{kind}.webp",
          content_type: "image/webp", identify: false,
          metadata: { width: image[:width], height: image[:height], analyzed: true }
        )
      end
    end

    entry.with_lock do
      return unless entry.image_import_token == token
      # Another execution of the same job may already have published these images.
      return if source && entry.image_import_status == "ready"

      if source
        blobs.each { |kind, blob| entry.local_image(kind).attach(blob) }
      else
        ImageOptimizer::SIZES.each_key { |kind| entry.local_image(kind).purge_later }
      end
      entry.update!(image_import_status: source ? "ready" : "none", image_import_error: nil)
    end
    published = true
  rescue *NETWORK_ERRORS => error
    record_failure(entry_id, token, error)
    raise
  rescue ImageDownload::Error, ImageOptimizer::Error => error
    record_failure(entry_id, token, error)
  ensure
    blobs&.each_value { |blob| blob.purge unless published }
  end

  private

  def record_failure(entry_id, token, error)
    Entry.where(id: entry_id, image_import_token: token).where.not(image_import_status: "ready")
      .update_all(image_import_status: "failed", image_import_error: error.message.to_s.truncate(250))
  end
end
