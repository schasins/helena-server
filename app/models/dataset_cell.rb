class DatasetCell < ActiveRecord::Base
  belongs_to :dataset
  belongs_to :dataset_value
end
