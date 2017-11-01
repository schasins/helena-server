class ProgramRunsController < ApplicationController

	require 'csv'

	skip_before_action :protect_from_forgery, :only =>[:new] # save_relation is going to be coming from the Chrome extension, so can't get the CSRF token.  in future should consider whether we should require some kind of authentication for this
	protect_from_forgery with: :null_session, :only =>[:new]

  def new
    prog_id = params[:program_id]
    runs_so_far = ProgramRun.where({program_id: prog_id}).count
    permitted = params.permit(:program_id, :name)
    permitted[:run_count] = runs_so_far
    run = ProgramRun.create(permitted)
    subrun = ProgramSubRun.create({program_run_id: run.id})
  	render json: { run_id: run.id, sub_run_id: subrun.id }
  end

  def new_sub_run
    run = ProgramRun.find(params.permit(:program_run_id))
    subrun = ProgramSubRun.create({program_run_id: run.id})
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

  def render_rows(rows, filename)
    @rows = rows
    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = 'attachment; filename=' + filename + '.csv'    
    render :template => "datasets/download.csv.erb"
  end

  def download_run
  	run = ProgramRun.find(params[:id])
    filename = run.gen_filename()
    outputrows = run.get_output_rows(false)
    render_rows(outputrows, filename)
  end

  def download_run_detailed
    run = ProgramRun.find(params[:id])
    filename = run.gen_filename()
    outputrows = run.get_output_rows(true)
    render_rows(outputrows, filename)
  end

  def download_all
    prog = Program.find(params[:id])
    filename = gen_filename_for_prog(prog)

    rows = DatasetRow.
      where({program_id: prog.id}).
      includes(:program_run, dataset_cells: [:dataset_value, :dataset_link]).
      order("program_runs.run_count ASC", run_row_index: :asc)

    outputrows = []
    currentRowIndex = -1
    currentProgRun = nil
    currentProgRunCounter = 0
    rows.each{ |row|
      outputrows.push([])
      currentRowIndex += 1
      if (currentProgRun != row.program_run_id)
        progRunObj = row.program_run
        currentProgRunCounter = progRunObj.run_count
        currentProgRun = row.program_run_id
      end

      cells = row.dataset_cells.order(col: :asc)
      cells.each{ |cell|

      if (cell.scraped_attribute == Scraped::TEXT)
        outputrows[currentRowIndex].push(cell.dataset_value.text)
      elsif (cell.scraped_attribute == Scraped::LINK)
        outputrows[currentRowIndex].push(cell.dataset_link.link)
      else
        # for now, default to putting the text in
        outputrows[currentRowIndex].push(cell.dataset_value.text)
      end
        
      }

      # and at the end of the row, go ahead and add the program_run_id to let the user know which pass produced the row
      outputrows[currentRowIndex].push(currentProgRunCounter)
    }
    render_rows(outputrows, filename)
  end

end
