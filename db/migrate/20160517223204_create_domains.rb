class CreateDomains < ActiveRecord::Migration
  def change
    create_table :domains do |t|
      t.text :url

      t.timestamps null: false
    end
  end
end
