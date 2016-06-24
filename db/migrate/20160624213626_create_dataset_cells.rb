class CreateDatasetCells < ActiveRecord::Migration
  def change
    create_table :dataset_cells do |t|
      t.references :dataset, index: true, foreign_key: true
      t.integer :row
      t.integer :col
      t.references :dataset_value, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
