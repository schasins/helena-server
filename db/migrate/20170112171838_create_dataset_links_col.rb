class CreateDatasetLinksCol < ActiveRecord::Migration
  def change

	add_reference :dataset_cells, :dataset_link, index: true
	add_foreign_key :dataset_cells, :dataset_links
  end
end
