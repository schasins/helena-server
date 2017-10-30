class AddIndexToTransactionLocks < ActiveRecord::Migration
  def change
    add_index :transaction_locks, [:program_id, :program_run_id, :annotation_id, :transaction_items_str], unique: true, :name => 'all_unique_index'
  end
end
