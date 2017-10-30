class CreateTransactionLocks < ActiveRecord::Migration
  def change
    create_table :transaction_locks do |t|
      t.integer :program_id
      t.integer :program_run_id
      t.integer :annotation_id
      t.text :transaction_items_str
    end
  end
end
