class CreateRelations < ActiveRecord::Migration
  def change
    create_table :relations do |t|
      t.string :name
      t.string :selector
      t.integer :selector_version
      t.references :url, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
