class AddImageUrlToEntriesAndRemoveFeatured < ActiveRecord::Migration[8.1]
  def change
    add_column :entries, :image_url, :string
    remove_index :entries, :featured
    remove_column :entries, :featured, :boolean
  end
end
