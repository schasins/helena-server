class AddExcludeFirstToRelations < ActiveRecord::Migration
  def change
    add_column :relations, :exclude_first, :integer
    remove_column :relations, :selector
    add_column :relations, :selector, :text

  	add_index "relations", ["selector", "selector_version", "url_id"], name: "index_relations_on_selector_and_selector_version_and_url_id", unique: true, using: :btree
  end
end
