class Entry < ApplicationRecord
  MEDIA_KINDS = %w[link image video audio article].freeze

  has_many :taggings, dependent: :delete_all
  has_many :tags, -> { order(:name) }, through: :taggings

  validates :title, :url, :media_kind, :collected_at, presence: true
  validates :url, uniqueness: true
  validates :media_kind, inclusion: { in: MEDIA_KINDS }
  validate :url_must_be_regular_http_url
  validate :image_urls_must_be_safe

  before_validation :set_collected_at, on: :create
  before_validation :infer_source_name
  before_validation :infer_media_kind

  scope :recent, -> { order(collected_at: :desc, created_at: :desc, id: :desc) }

  def self.search(query)
    return all if query.blank?

    pattern = "%#{sanitize_sql_like(query.to_s.strip)}%"
    where(<<~SQL.squish, query: pattern)
      entries.title LIKE :query ESCAPE '\\'
      OR entries.notes LIKE :query ESCAPE '\\'
      OR entries.source_name LIKE :query ESCAPE '\\'
      OR EXISTS (
        SELECT 1 FROM taggings
        INNER JOIN tags ON tags.id = taggings.tag_id
        WHERE taggings.entry_id = entries.id
          AND tags.name LIKE :query ESCAPE '\\'
      )
    SQL
  end

  def self.tagged_with(slug)
    return all if slug.blank?

    where(<<~SQL.squish, slug: slug)
      EXISTS (
        SELECT 1 FROM taggings
        INNER JOIN tags ON tags.id = taggings.tag_id
        WHERE taggings.entry_id = entries.id AND tags.slug = :slug
      )
    SQL
  end

  def tag_list
    return @tag_list if defined?(@tag_list)

    tags.map(&:name).sort.join(", ")
  end

  def tag_list=(names)
    @tag_list = names.to_s
  end

  def save_with_tags
    transaction do
      save!
      if defined?(@tag_list)
        names = @tag_list.split(",").filter_map { |name| Tag.normalize_name(name) }.uniq
        self.tags = names.map { |name| Tag.find_or_create_named!(name) }
      end
    end

    remove_instance_variable(:@tag_list) if defined?(@tag_list)
    true
  rescue ActiveRecord::RecordInvalid => error
    errors.add(:tag_list, "#{error.record.name}: #{error.record.errors.full_messages.to_sentence}") unless error.record == self
    false
  rescue ActiveRecord::RecordNotUnique
    if self.class.where(url: url).where.not(id: id).exists?
      errors.add(:url, :taken)
    else
      errors.add(:base, "could not be saved because another change was made; please try again")
    end
    false
  end

  def source_name=(value)
    self.source_name_overridden = value.present?
    super
  end

  def media_kind=(value)
    self.media_kind_overridden = value.present?
    super
  end

  def embeddable_image_url
    candidate = media_kind == "image" ? url : image_url
    parsed_candidate = EntryUrl.new(candidate)

    candidate if parsed_candidate.image?
  end

  def youtube_embed_url
    return unless media_kind == "video"

    entry_url.youtube_embed_url
  end

  private

  def set_collected_at
    self.collected_at ||= Time.current
  end

  def infer_source_name
    return if source_name_overridden?

    self[:source_name] = entry_url.source_name
  end

  def infer_media_kind
    return if media_kind_overridden?

    self[:media_kind] = entry_url.media_kind
  end

  def entry_url
    EntryUrl.new(url)
  end

  def image_entry_url
    EntryUrl.new(image_url)
  end

  def url_must_be_regular_http_url
    return if entry_url.valid?

    errors.add(:url, "must be a regular http or https link")
  end

  def image_urls_must_be_safe
    if image_url.present? && !image_entry_url.image?
      errors.add(:image_url, "must be an HTTPS URL ending in avif, gif, jpg, jpeg, png, or webp")
    end

    if media_kind == "image" && entry_url.valid? && !entry_url.image?
      errors.add(:url, "must be an HTTPS image ending in avif, gif, jpg, jpeg, png, or webp")
    end
  end
end
