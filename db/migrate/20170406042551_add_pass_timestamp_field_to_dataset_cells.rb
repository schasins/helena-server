class AddPassTimestampFieldToDatasetCells < ActiveRecord::Migration
  def change
    add_column :dataset_cells, :pass_timestamp, :timestamp
  end
end
