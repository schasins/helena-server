class RevampProgDatasets < ActiveRecord::Migration
  def change
    
	  create_table "program_runs", force: :cascade do |t|
	    t.string   "name"
	    t.integer  "program_id"
	    t.datetime "created_at", null: false
	    t.datetime "updated_at", null: false
	  end

	  add_index "program_runs", ["program_id"], name: "index_program_runs_on_program_id", using: :btree

	  create_table "program_sub_runs", force: :cascade do |t|
	    t.integer  "program_run_id"
	    t.datetime "created_at", null: false
	    t.datetime "updated_at", null: false
	  end

	  create_table "dataset_rows", force: :cascade do |t|
	    t.integer  "program_id"
	    t.integer  "program_run_id"
	    t.integer  "program_sub_run_id"
	    t.integer  "run_row_index"
	    t.datetime "created_at", null: false
	    t.datetime "updated_at", null: false
	  end

	  add_index "dataset_rows", ["program_id"], name: "index_dataset_rows_on_program_id", using: :btree
	  add_index "dataset_rows", ["program_run_id", "run_row_index"], name: "index_dataset_rows_on_program_run_id_and_run_row_index", using: :btree

	  create_table "dataset_row_dataset_cell_relationships", force: :cascade do |t|
	    t.integer  "dataset_row_id"
	    t.integer  "dataset_cell_id"
	    t.datetime "created_at", null: false
	    t.datetime "updated_at", null: false
	  end

	  add_index "dataset_row_dataset_cell_relationships", ["dataset_row_id"], name: "index_dataset_row_dataset_cell_relationships_on_dataset_row_id", using: :btree

  end
end
