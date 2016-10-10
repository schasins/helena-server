class RenameHash < ActiveRecord::Migration
  def change
    remove_column :dataset_values, :hash, :string
    add_column :dataset_values, :text_hash, :string
    add_index :dataset_values, [:text_hash]
  end
end
