class CreateTransactionCells < ActiveRecord::Migration
  def change
    create_table :transaction_cells do |t|
      t.references :transaction, index: true, foreign_key: true
      t.integer :attr_value

      t.timestamps null: false
    end
  end
end
