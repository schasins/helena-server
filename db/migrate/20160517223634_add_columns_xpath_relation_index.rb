class AddColumnsXpathRelationIndex < ActiveRecord::Migration
  def change
    add_index :columns, [:xpath, :relation_id], :unique => true
    add_column :relations, :num_columns, :integer
    add_column :relations, :num_rows_in_demonstration, :integer
    remove_index :relations, :column => [:selector, :selector_version]
    add_index :relations, [:selector, :selector_version, :url_id], :unique => true
  end
end
