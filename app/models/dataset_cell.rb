class DatasetCell < ActiveRecord::Base
  belongs_to :dataset
  belongs_to :dataset_value
  belongs_to :dataset_link
  belongs_to :source_url, class_name: "Url"
  belongs_to :top_frame_source_url, class_name: "Url"
end
