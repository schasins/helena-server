class AddProgramToDatasets < ActiveRecord::Migration
  def change
    add_reference :datasets, :program, index: true, foreign_key: true
  end
end
