class AddRelationsSelectorSelectorVersionIndex < ActiveRecord::Migration
  def change
    add_index :relations, [:selector, :selector_version], :unique => true
  end
end
