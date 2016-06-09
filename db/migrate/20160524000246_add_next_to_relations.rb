class AddNextToRelations < ActiveRecord::Migration
  def change
    add_column :relations, :next_type, :integer
    add_column :relations, :next_button_selector, :text
  end
end
