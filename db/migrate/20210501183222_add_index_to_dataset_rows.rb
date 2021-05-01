class AddIndexToDatasetRows < ActiveRecord::Migration[6.1]
  def change
  	    add_index :dataset_rows, [:program_id, :created_at]
  end
end
