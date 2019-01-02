class AddHiddenToPrograms < ActiveRecord::Migration
  def change
    add_column :programs, :hidden, :boolean
  end
end
