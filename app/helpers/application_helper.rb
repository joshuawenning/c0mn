module ApplicationHelper
  EXTERNAL_LINK_TAGS = %w[a].freeze
  EXTERNAL_LINK_ATTRIBUTES = %w[class href rel target].freeze
  MARKDOWN_TAGS = %w[p br strong em a ul ol li blockquote code pre h2 h3 h4 h5 h6 hr].freeze
  MARKDOWN_ATTRIBUTES = %w[href title].freeze

  def external_link_to(label, url, class_name: nil, https_only: false)
    parsed_url = EntryUrl.new(url)
    valid_url = parsed_url.uri.to_s if parsed_url.valid? && (!https_only || parsed_url.https?)
    return ERB::Util.html_escape(label) unless valid_url

    sanitize(
      link_to(label, valid_url, target: "_blank", rel: "noopener", class: class_name),
      tags: EXTERNAL_LINK_TAGS,
      attributes: EXTERNAL_LINK_ATTRIBUTES
    )
  end

  def render_markdown(text)
    return if text.blank?

    html = Commonmarker.to_html(text, options: {
      render: { unsafe: false, ignore_empty_links: true },
      extension: { header_ids: nil }
    })
    html.gsub!(/<(\/?)h([1-6])>/) do
      closing, level = Regexp.last_match.captures
      "<#{closing}h#{[ level.to_i + 1, 6 ].min}>"
    end

    sanitize html, tags: MARKDOWN_TAGS, attributes: MARKDOWN_ATTRIBUTES
  end

  def tag_color_dot(tag_record)
    tag.svg class: "tag-dot", viewBox: "0 0 10 10", aria: { hidden: true } do
      tag.circle cx: 5, cy: 5, fill: tag_record.color, r: 5
    end
  end
end
