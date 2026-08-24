class MigrateEntryDescriptionsToNotes < ActiveRecord::Migration[8.1]
  class MigrationEntry < ActiveRecord::Base
    self.table_name = "entries"
  end

  def up
    MigrationEntry.reset_column_information

    MigrationEntry.where.not(description: [ nil, "" ]).find_each do |entry|
      notes = [ entry.description, entry.notes ].select(&:present?).join("\n\n")
      entry.update_columns(notes: notes)
    end

    remove_column :entries, :description, :text
  end

  def down
    add_column :entries, :description, :text
  end
end
