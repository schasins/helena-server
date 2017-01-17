class CreateProgramUsesRelations < ActiveRecord::Migration
  def change
    create_table :program_uses_relations do |t|
      t.references :program, index: true, foreign_key: true
      t.references :relation, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
