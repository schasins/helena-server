class EditTransactions < ActiveRecord::Migration
  def change

  	add_column :transaction_records, :program_id, :integer
  	add_column :transaction_records, :program_run_id, :integer
  	add_column :transaction_records, :commit_time, :timestamp

	add_index "transaction_records", ["program_id", "program_run_id"], name: "index_transaction_records_on_program_id_and_program_run_id", using: :btree
	add_index "transaction_records", ["program_id", "commit_time"], name: "index_transaction_records_on_program_id_and_commit_time", using: :btree
    
  end
end
