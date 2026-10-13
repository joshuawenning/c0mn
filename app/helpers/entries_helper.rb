module EntriesHelper
  def local_entry_image_tag(entry, kind:, alt:, lazy:)
    attachment = entry.local_image(kind)
    return unless attachment.attached?

    metadata = attachment.blob.metadata
    options = { alt: alt, width: metadata["width"], height: metadata["height"], loading: lazy ? "lazy" : nil, decoding: "async" }
    if kind == :master && entry.image_card.attached? && entry.image_card.blob.metadata["width"] != metadata["width"]
      options[:srcset] = [ [ url_for(entry.image_card), "#{entry.image_card.blob.metadata.fetch('width')}w" ], [ url_for(attachment), "#{metadata.fetch('width')}w" ] ]
      options[:sizes] = "(max-width: 700px) 100vw, 75vw"
    end
    image_tag attachment, **options
  end
end
