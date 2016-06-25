class AddDatasetValuesTextIndex < ActiveRecord::Migration
  def change
    add_index :dataset_values, [:text], :unique => true
  end
end
