class AddAnnotationIdToTransactionRecords < ActiveRecord::Migration
  def change
    add_column :transaction_records, :annotation_id, :integer
  end
end
