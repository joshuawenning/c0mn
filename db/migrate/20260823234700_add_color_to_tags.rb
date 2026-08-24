require "digest"

class AddColorToTags < ActiveRecord::Migration[8.1]
  COLORS = %w[
    #e84a5f #f28e2b #edc948 #59a14f #00a878 #76b7b2 #4e79a7 #6f63bb
    #9c6ade #b07aa1 #d45087 #ff9da7 #9c755f #8f6b4f #79706e #bab0ab
  ].freeze

  class MigrationTag < ActiveRecord::Base
    self.table_name = "tags"
  end

  def up
    add_column :tags, :color, :string
    MigrationTag.reset_column_information

    used_colors = []

    MigrationTag.order(:id).find_each.with_index do |tag, index|
      color = COLORS[index] || generated_color(tag.name, used_colors)
      tag.update_columns(color: color)
      used_colors << color
    end

    change_column_null :tags, :color, false
    add_index :tags, :color, unique: true
  end

  def down
    remove_column :tags, :color, :string
  end

  private

  def generated_color(name, used_colors)
    salt = 0

    loop do
      bytes = Digest::SHA256.digest("#{name}:#{salt}").bytes
      candidate = format("#%02x%02x%02x", *bytes.first(3).map { |byte| 64 + (byte % 144) })
      return candidate unless used_colors.include?(candidate)

      salt += 1
    end
  end
end
