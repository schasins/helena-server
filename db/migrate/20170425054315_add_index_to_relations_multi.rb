class AddIndexToRelationsMulti < ActiveRecord::Migration
  def change
    add_index :relations, [:id, :selector, :selector_version], unique: true
  end
end
