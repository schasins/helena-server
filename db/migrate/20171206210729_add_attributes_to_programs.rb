class AddAttributesToPrograms < ActiveRecord::Migration
  def change
    add_column :programs, :associated_string, :text
    add_column :programs, :tool_id, :integer
    add_index :programs, :tool_id
  end
end
