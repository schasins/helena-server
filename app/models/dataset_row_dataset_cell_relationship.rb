class DatasetRowDatasetCellRelationship < ActiveRecord::Base
  belongs_to :dataset_row
  belongs_to :dataset_cell
end
