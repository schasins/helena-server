class CreateDatasetValues < ActiveRecord::Migration
  def change
    create_table :dataset_values do |t|
      t.text :text

      t.timestamps null: false
    end
  end
end
