class Relation < ActiveRecord::Base
  belongs_to :url
  has_many :columns
end
