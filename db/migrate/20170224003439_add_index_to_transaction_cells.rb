class AddIndexToTransactionCells < ActiveRecord::Migration
  def change
    add_column :transaction_cells, :index, :integer
  end
end
