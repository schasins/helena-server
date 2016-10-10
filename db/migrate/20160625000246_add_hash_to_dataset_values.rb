class AddHashToDatasetValues < ActiveRecord::Migration
  def change
  	remove_index :dataset_values, :column => [:text]
    add_column :dataset_values, :hash, :string
    add_index :dataset_values, [:hash]
  end
end
