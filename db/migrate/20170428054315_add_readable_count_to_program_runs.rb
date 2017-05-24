class AddReadableCountToProgramRuns < ActiveRecord::Migration
  def change

  	add_column :program_runs, :run_count, :integer

  end
end
