class DatasetCell < ActiveRecord::Base
  belongs_to :dataset
  belongs_to :dataset_value
  belongs_to :dataset_link
  has_many :dataset_row_dataset_cell_relationships
  has_many :dataset_rows, through: :dataset_row_dataset_cell_relationships
  belongs_to :source_url, class_name: "Url"
  belongs_to :top_frame_source_url, class_name: "Url"
end
