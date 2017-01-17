class CreatePrograms < ActiveRecord::Migration
  def change
    create_table :programs do |t|
      t.string :name
      t.text :serialized_program

      t.timestamps null: false
    end
  end
end
