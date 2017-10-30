class AddFinishedToTransactionRecords < ActiveRecord::Migration
  def change
    add_column :transaction_records, :finished, :boolean
  end
end
