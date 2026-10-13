class IndexRecentEntries < ActiveRecord::Migration[8.1]
  def change
    add_index :entries, [ :collected_at, :created_at, :id ], name: "index_entries_on_recent_order"
    remove_index :entries, :collected_at
    remove_index :taggings, :entry_id
  end
end
