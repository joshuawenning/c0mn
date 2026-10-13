class EnsureActiveStorageTables < ActiveRecord::Migration[8.1]
  def up
    unless table_exists?(:active_storage_blobs)
      create_table :active_storage_blobs do |t|
        t.string :key, null: false
        t.string :filename, null: false
        t.string :content_type
        t.text :metadata
        t.string :service_name, null: false
        t.bigint :byte_size, null: false
        t.string :checksum
        t.datetime :created_at, null: false
        t.index :key, unique: true
      end
    end

    unless table_exists?(:active_storage_attachments)
      create_table :active_storage_attachments do |t|
        t.string :name, null: false
        t.references :record, null: false, polymorphic: true, index: false
        t.references :blob, null: false, foreign_key: { to_table: :active_storage_blobs }
        t.datetime :created_at, null: false
        t.index [ :record_type, :record_id, :name, :blob_id ], name: :index_active_storage_attachments_uniqueness, unique: true
      end
    end

    unless table_exists?(:active_storage_variant_records)
      create_table :active_storage_variant_records do |t|
        t.references :blob, null: false, foreign_key: { to_table: :active_storage_blobs }, index: false
        t.string :variation_digest, null: false
        t.index [ :blob_id, :variation_digest ], name: :index_active_storage_variant_records_uniqueness, unique: true
      end
    end
  end

  def down
    # Tables may predate this repair migration and contain existing attachments.
    raise ActiveRecord::IrreversibleMigration
  end
end
