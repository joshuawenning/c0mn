class EntryUrl
  IMAGE_EXTENSION = /\.(avif|gif|jpe?g|png|webp)\z/i
  AUDIO_EXTENSION = /\.(mp3|wav|m4a|ogg)\z/i
  YOUTUBE_PATH_PREFIXES = %w[embed live shorts].freeze
  YOUTUBE_ID = /\A[A-Za-z0-9_-]{6,}\z/

  attr_reader :uri

  def initialize(value)
    @uri = URI.parse(value.to_s)
    @uri = nil unless @uri.is_a?(URI::HTTP) && @uri.host.present?
  rescue URI::InvalidURIError
    @uri = nil
  end

  def valid?
    uri.present?
  end

  def https?
    uri.is_a?(URI::HTTPS)
  end

  def source_name
    host&.delete_prefix("www.")
  end

  def media_kind
    if uri&.path.to_s.match?(IMAGE_EXTENSION)
      "image"
    elsif youtube? || domain?("vimeo.com")
      "video"
    elsif domain?("spotify.com") || uri&.path.to_s.match?(AUDIO_EXTENSION)
      "audio"
    else
      "link"
    end
  end

  def youtube_embed_url
    return unless youtube?

    id = youtube_id
    "https://www.youtube.com/embed/#{id}" if id&.match?(YOUTUBE_ID)
  end

  private

  def host
    uri&.host&.downcase
  end

  def domain?(domain)
    host == domain || host&.end_with?(".#{domain}")
  end

  def youtube?
    domain?("youtube.com") || domain?("youtu.be")
  end

  def youtube_id
    if domain?("youtu.be")
      uri.path.split("/").second
    elsif YOUTUBE_PATH_PREFIXES.include?(uri.path.split("/").second)
      uri.path.split("/").third
    else
      Rack::Utils.parse_query(uri.query)["v"]
    end
  end
end
