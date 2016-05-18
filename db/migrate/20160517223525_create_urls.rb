class CreateUrls < ActiveRecord::Migration
  def change
    create_table :urls do |t|
      t.text :url
      t.references :domain, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
