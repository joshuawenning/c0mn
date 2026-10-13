require_relative "method_override_helper"
require "vips"

module ImageImportTestHelper
  include MethodOverrideHelper

  def with_image_download(&block)
    Tempfile.create([ "test-image", ".png" ]) do |file|
      Vips::Image.black(800, 400).pngsave(file.path)
      replacement = ->(_url, &consumer) { consumer.call(file) }
      with_method(ImageDownload, :open, replacement, &block)
    end
  end

  def import_image(entry)
    with_image_download { ImportEntryImageJob.perform_now(entry.id, entry.image_import_token) }
    entry.reload
  end
end
