class AddTimestampFieldToDatasetCells < ActiveRecord::Migration
  def change
    add_column :dataset_cells, :scraped_timestamp, :timestamp
  end
end
