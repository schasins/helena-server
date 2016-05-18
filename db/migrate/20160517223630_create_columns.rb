class CreateColumns < ActiveRecord::Migration
  def change
    create_table :columns do |t|
      t.string :name
      t.text :xpath
      t.text :suffix
      t.references :relation, index: true, foreign_key: true

      t.timestamps null: false
    end
    add_index :columns, :xpath
  end
end
