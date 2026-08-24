class TrackEntryMetadataOverrides < ActiveRecord::Migration[8.1]
  def up
    add_column :entries, :source_name_overridden, :boolean, null: false, default: false
    add_column :entries, :media_kind_overridden, :boolean, null: false, default: false

    execute <<~SQL
      UPDATE entries
      SET source_name_overridden = CASE WHEN source_name IS NULL OR source_name = '' THEN 0 ELSE 1 END,
          media_kind_overridden = 1
    SQL
  end

  def down
    remove_column :entries, :source_name_overridden
    remove_column :entries, :media_kind_overridden
  end
end
