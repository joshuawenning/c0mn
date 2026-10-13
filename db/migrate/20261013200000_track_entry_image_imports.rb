class TrackEntryImageImports < ActiveRecord::Migration[8.1]
  def change
    add_column :entries, :image_import_token, :string
    add_column :entries, :image_import_status, :string, default: "none", null: false
    add_column :entries, :image_import_error, :string
  end
end
