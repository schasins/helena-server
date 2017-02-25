class RenameTransactionTable < ActiveRecord::Migration
  def change
    rename_table :transactions, :transaction_records
  end
end
