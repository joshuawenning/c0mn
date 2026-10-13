require "digest"

class Tag < ApplicationRecord
  has_many :taggings, dependent: :delete_all
  has_many :entries, through: :taggings

  validates :color, presence: true, uniqueness: true, format: { with: /\A#[0-9a-f]{6}\z/i }
  validates :name, :slug, presence: true, uniqueness: true

  before_validation :normalize_fields

  scope :popular, -> {
    joins(:taggings)
      .select("tags.*, COUNT(taggings.id) AS taggings_count")
      .group("tags.id")
      .order("taggings_count DESC, tags.name ASC")
  }

  def self.normalize_name(name)
    name.to_s.strip.downcase.gsub(/\s+/, " ").presence
  end

  def self.find_or_create_named!(name)
    name = normalize_name(name)
    attempts = 0

    begin
      attempts += 1
      find_by(name: name) || transaction(requires_new: true) { create!(name: name) }
    rescue ActiveRecord::RecordInvalid => error
      existing = find_by(name: name) if error.record.errors.of_kind?(:name, :taken)
      return existing if existing

      retry if error.record.errors.attribute_names == [ :color ] && error.record.errors.of_kind?(:color, :taken) && attempts < 3
      raise
    rescue ActiveRecord::RecordNotUnique
      existing = find_by(name: name)
      return existing if existing

      retry if attempts < 3
      raise
    end
  end

  private

  def normalize_fields
    self.name = self.class.normalize_name(name)
    self.slug = name&.parameterize
    self.color ||= next_available_color
  end

  def next_available_color
    salt = 0

    loop do
      bytes = Digest::SHA256.digest("#{name}:#{salt}").bytes
      candidate = format("#%02x%02x%02x", *bytes.first(3).map { |byte| 64 + (byte % 144) })
      return candidate unless self.class.where.not(id: id).exists?(color: candidate)

      salt += 1
    end
  end
end
