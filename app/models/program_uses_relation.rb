class ProgramUsesRelation < ActiveRecord::Base
  belongs_to :program
  belongs_to :relation
end
