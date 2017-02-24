class AddTransactionCellsIndex < ActiveRecord::Migration
  def change
    add_index :transaction_cells, [:index, :attr_value]
  end
end
