class CreateEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :entries do |t|
      t.string :title, null: false
      t.string :url, null: false
      t.string :source_name
      t.string :media_kind, null: false, default: "link"
      t.text :description
      t.text :notes
      t.boolean :featured, null: false, default: false
      t.datetime :collected_at, null: false

      t.timestamps
    end

    add_index :entries, :url, unique: true
    add_index :entries, :media_kind
    add_index :entries, :collected_at
    add_index :entries, :featured
  end
end
