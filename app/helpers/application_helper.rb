module ApplicationHelper
  MARKDOWN_TAGS = %w[p br strong em a ul ol li blockquote code pre h2 h3 h4 hr].freeze
  MARKDOWN_ATTRIBUTES = %w[href title].freeze

  def render_markdown(text)
    return if text.blank?

    html = Commonmarker.to_html(text, options: {
      render: { unsafe: false, ignore_empty_links: true },
      extension: { header_ids: nil }
    })

    sanitize html, tags: MARKDOWN_TAGS, attributes: MARKDOWN_ATTRIBUTES
  end

  def tag_color_dot(tag_record)
    tag.svg class: "tag-dot", viewBox: "0 0 10 10", aria: { hidden: true } do
      tag.circle cx: 5, cy: 5, fill: tag_record.color, r: 5
    end
  end
end
