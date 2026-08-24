class EnsureEntriesHaveNotes < ActiveRecord::Migration[8.1]
  def up
    add_column :entries, :notes, :text unless column_exists?(:entries, :notes)
  end

  def down
    # The original entries migration also defines this column.
  end
end
