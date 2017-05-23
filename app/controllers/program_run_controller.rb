class ProgramRunsController < ApplicationController

	require 'csv'

	skip_before_action :protect_from_forgery, :only =>[:new] # save_relation is going to be coming from the Chrome extension, so can't get the CSRF token.  in future should consider whether we should require some kind of authentication for this
	protect_from_forgery with: :null_session, :only =>[:new]

  def new
    run = ProgramRun.create(params.permit(:program_id, :name))
    subrun = ProgramSubRun.create({:program_run_id: run.id})
  	render json: { run_id: run.id, sub_run_id: subrun.id }
  end

  def new_sub_run
    run = ProgramRun.find(params.permit(:program_run_id))
    subrun = ProgramSubRun.create({:program_run_id: run.id})
    render json: { sub_run_id: subrun.id }
  end

  module Scraped
    TEXT = 1
    LINK = 2
  end

  def save_slice
    ProgramRun.save_slice_internals(params)
  	render json: { }
  end

  def update_run_name
    run = ProgramRun.find(params[:id])
    run.name = params[:name]
    run.save

    render json: {}
  end

  def gen_filename_for_prog(program)
      fn = program.name
      if (fn == nil or fn == "")
          fn = "dataset"
      end
      return fn
  end

  def gen_filename_for_run(run)
      fn = run.name
      if (fn == nil or fn == "")
          fn = "dataset"
      end
      fn = fn + "_" + run.program_id.to_s + "_" + run.id.to_s
      return fn
  end

  def render_rows(rows)
    @rows = rows
    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = 'attachment; filename=' + filename + '.csv'    
    render :template => "datasets/download.csv.erb"
  end

  def download_run
  	run = ProgramRun.find(params[:id])
  	filename = gen_filename_for_run(run)

    cells = DatasetCell.joins(:dataset_row_dataset_cell_relationship).joins(:dataset_row).
      where("dataset_rows.program_run_id = ?", run.id).
      includes(:dataset_value, :dataset_link).
      order("dataset_rows.run_row_index ASC", col_index: :asc)

  	rows = []
  	currentRowIndex = -1;
  	cells.each{ |cell|
      cellRowIndex = cell.dataset_row_dataset_cell_relationship.dataset_row
  		if (cellRowIndex != currentRowIndex)
  			currentRowIndex = cellRowIndex
  			rows.push([])
  		end
      if (cell.scraped_attribute == Scraped::TEXT)
        rows[currentRowIndex].push(cell.dataset_value.text)
  		elsif (cell.scraped_attribute == Scraped::LINK)
        rows[currentRowIndex].push(cell.dataset_link.link)
      else
        # for now, default to putting the text in
        rows[currentRowIndex].push(cell.dataset_value.text)
      end
  	}
    render_rows(rows)

  end

  def download_all
    prog = Program.find(params[:id])
    filename = gen_filename_for_prog(prog)

    cells = DatasetCell.joins(:dataset_row_dataset_cell_relationship).joins(:dataset_row).
      where("dataset_rows.program_id = ?", prog.id).
      includes(:dataset_value, :dataset_link).
      order("dataset_rows.id ASC, dataset_rows.run_row_index ASC", col_index: :asc) # order first on the run, then on the index w/in the run, then col

    rows = []
    currentRowIndex = -1;
    currentDatasetRowIndex = -1
    cells.each{ |cell|
      cellRowIndex = cell.dataset_row_dataset_cell_relationship.dataset_row
      if (cellRowIndex != currentDatasetRowIndex)
        currentDatasetRowIndex = cellRowIndex
        currentRowIndex += 1
        rows.push([])
      end
      if (cell.scraped_attribute == Scraped::TEXT)
        rows[currentRowIndex].push(cell.dataset_value.text)
      elsif (cell.scraped_attribute == Scraped::LINK)
        rows[currentRowIndex].push(cell.dataset_link.link)
      else
        # for now, default to putting the text in
        rows[currentRowIndex].push(cell.dataset_value.text)
      end
    }
    render_rows(rows)
  end

end
