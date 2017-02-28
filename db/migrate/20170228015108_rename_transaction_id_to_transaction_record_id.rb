class RenameTransactionIdToTransactionRecordId < ActiveRecord::Migration
  def change
    rename_column :transaction_cells, :transaction_id, :transaction_record_id
  end
end
