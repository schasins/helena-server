class CreateDatasetLinks < ActiveRecord::Migration
  def change
    create_table :dataset_links do |t|
      t.text :link

      t.timestamps null: false
    end

    add_index :dataset_links, [:link], :unique => true

    add_column :dataset_cells, :scraped_attribute, :integer

	add_reference :dataset_cells, :source_url, references: :urls, index: true
	add_foreign_key :dataset_cells, :urls, column: :source_url_id

	add_reference :dataset_cells, :top_frame_source_url, references: :urls, index: true
	add_foreign_key :dataset_cells, :urls, column: :top_frame_source_url_id
  end
end