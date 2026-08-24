require "digest"

class Tag < ApplicationRecord
  has_many :taggings, dependent: :destroy
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

  private

  def normalize_fields
    self.name = self.class.normalize_name(name)
    self.slug = name&.parameterize
    self.color ||= next_available_color
  end

  def next_available_color
    used_colors = self.class.where.not(id: id).pluck(:color)
    salt = 0

    loop do
      bytes = Digest::SHA256.digest("#{name}:#{salt}").bytes
      candidate = format("#%02x%02x%02x", *bytes.first(3).map { |byte| 64 + (byte % 144) })
      return candidate unless used_colors.include?(candidate)

      salt += 1
    end
  end
end
