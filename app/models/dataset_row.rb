class DatasetRow < ActiveRecord::Base
  belongs_to :program
  belongs_to :program_run
  belongs_to :program_sub_run
  has_many :dataset_row_dataset_cell_relationships
  has_many :dataset_cells, through: :dataset_row_dataset_cell_relationships
end
