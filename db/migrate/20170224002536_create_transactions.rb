class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.references :dataset, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
