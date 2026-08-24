class Entry < ApplicationRecord
  MEDIA_KINDS = %w[link image video audio article].freeze

  has_many :taggings, dependent: :destroy
  has_many :tags, -> { order(:name) }, through: :taggings

  validates :title, :url, :media_kind, :collected_at, presence: true
  validates :url, uniqueness: true
  validates :media_kind, inclusion: { in: MEDIA_KINDS }
  validate :url_must_be_absolute_http_url
  validate :embeddable_urls_must_use_https
  validate :pending_tags_must_be_valid

  before_validation :set_collected_at, on: :create
  before_validation :infer_source_name
  before_validation :infer_media_kind
  after_save :synchronize_pending_tags
  before_destroy :remember_tag_ids, prepend: true
  after_destroy :destroy_orphaned_tags

  scope :recent, -> { order(collected_at: :desc, created_at: :desc) }

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
    return @pending_tag_names.join(", ") if defined?(@pending_tag_names)

    tags.map(&:name).join(", ")
  end

  def tag_list=(names)
    @pending_tag_names = names.to_s.split(",").filter_map { |name| Tag.normalize_name(name) }.uniq
  end

  def source_name=(value)
    self.source_name_overridden = value.present? if has_attribute?(:source_name_overridden)
    super
  end

  def media_kind=(value)
    self.media_kind_overridden = value.present? if has_attribute?(:media_kind_overridden)
    super
  end

  def save_with_tags
    save
  rescue ActiveRecord::RecordInvalid => error
    errors.add(:tag_list, error.record.errors.full_messages.to_sentence) unless error.record == self
    false
  rescue ActiveRecord::RecordNotUnique
    errors.add(:tag_list, "contains a tag that was created concurrently; please try again")
    false
  end

  def embeddable_image_url
    candidate = media_kind == "image" ? url : image_url
    parsed_candidate = EntryUrl.new(candidate)

    candidate if parsed_candidate.https?
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

  def url_must_be_absolute_http_url
    return if entry_url.valid?

    errors.add(:url, "must be an absolute http or https URL")
  end

  def embeddable_urls_must_use_https
    if image_url.present? && !image_entry_url.https?
      errors.add(:image_url, "must be an absolute https URL")
    end

    if media_kind == "image" && entry_url.valid? && !entry_url.https?
      errors.add(:url, "must use https for image entries")
    end
  end

  def resolve_pending_tags
    @pending_tag_names.filter_map do |name|
      tag = Tag.find_or_initialize_by(name: name)

      if tag.valid?
        tag
      else
        errors.add(:tag_list, "#{name}: #{tag.errors.full_messages.to_sentence}")
        nil
      end
    end
  end

  def pending_tags_must_be_valid
    @resolved_tags = resolve_pending_tags if defined?(@pending_tag_names)
  end

  def synchronize_pending_tags
    synchronize_tags(@resolved_tags) if defined?(@pending_tag_names)
  end

  def synchronize_tags(resolved_tags)
    previous_tag_ids = tag_ids

    self.tags = resolved_tags
    remove_instance_variable(:@pending_tag_names)
    Tag.where(id: previous_tag_ids).where.missing(:taggings).destroy_all
  end

  def remember_tag_ids
    @tag_ids_to_clean_up = tag_ids
  end

  def destroy_orphaned_tags
    Tag.where(id: @tag_ids_to_clean_up).where.missing(:taggings).destroy_all
  end
end
