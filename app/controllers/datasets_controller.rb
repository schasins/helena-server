class DatasetsController < ApplicationController

	require 'csv'

	skip_before_action :protect_from_forgery, :only =>[:new] # save_relation is going to be coming from the Chrome extension, so can't get the CSRF token.  in future should consider whether we should require some kind of authentication for this
	protect_from_forgery with: :null_session, :only =>[:new]

  def new
        dataset = Dataset.create(params.permit(:program_id, :name))
  	render json: { id: dataset.id }
  end

  module Scraped
    TEXT = 1
    LINK = 2
  end

  def save_slice
    Dataset.save_slice_internals(params)
  	render json: { }
  end

  def updatedataset
    dataset = Dataset.find(params[:id])
    dataset.name = params[:name]
    dataset.program_id = params[:program_id]
    dataset.save

    render json: {}
  end

  def programfordataset
    dataset = Dataset.find(params[:id])
    prog_id = dataset.program_id
    render json: {program_id: prog_id}
  end

  def gen_filename(dataset)
      fn = dataset.name
      if (fn == nil or fn == "")
          fn = "dataset"
      end
      fn = fn + "_" + dataset.id.to_s
      return fn
  end

  def download
  	dataset = Dataset.find(params[:id])
  	filename = gen_filename(dataset)

  	cells = DatasetCell.includes(:dataset_value, :dataset_link).where({dataset_id: params[:id]}).order(row: :asc, col: :asc)
  	rows = []
  	currentRowIndex = -1;
  	cells.each{ |cell|
  		if (cell.row != currentRowIndex)
  			currentRowIndex = cell.row
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

  	@rows = rows

    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = 'attachment; filename=' + filename + '.csv'    
    render :template => "datasets/download.csv.erb"

  end


  def downloaddetailed
  	dataset = Dataset.find(params[:id])
  	filename = gen_filename(dataset)

  	cells = DatasetCell.includes(:dataset_value, :dataset_link).where({dataset_id: params[:id]}).order(row: :asc, col: :asc, scraped_timestamp: :asc)
  	laterCells = [] # this is a gross way to handle the fact that different passes through a dataset generate the same indexes, so just sorting by row and column isn't enough.  todo: do something better


    rows = []
    while (cells.length > 0)
      #puts "starting while again"

  	currentRowIndex = -1
        currentColumnIndex = -1
        currentTimestamp = -1
        fullDatasetRowIndex = rows.length - 1
  	cells.each{ |cell|
                # puts "row " +  cell.row.to_s + " col " + cell.col.to_s + " ri " + currentRowIndex.to_s + " ci " + currentColumnIndex.to_s + " fdri " + fullDatasetRowIndex.to_s + " created_at " + cell.created_at.to_s
                if (cell.row == currentRowIndex && cell.col == currentColumnIndex)
                  # ok, this is a repeat cell, must have gotten it in multiple passes
                  # first let's check if it's even a different cell; if it was created at the same time, can just skip it forever
                  # if not created at the same time, have to handle it later
                  # not actually pleased with created_at as a way to handle this; todo:  look at values?  something else?; really just need a pass id on cells
                  if (cell.scraped_timestamp != currentTimestamp)
                    laterCells.push(cell)
                  end
                  next
                end
  		if (cell.row != currentRowIndex)
  			currentRowIndex = cell.row
  			rows.push([])
                        fullDatasetRowIndex += 1
  		end
                currentColumnIndex = cell.col
                currentTimestamp = cell.scraped_timestamp

      if (cell.scraped_attribute == Scraped::TEXT)
        rows[fullDatasetRowIndex].push(cell.dataset_value.text)
  		elsif (cell.scraped_attribute == Scraped::LINK)
        rows[fullDatasetRowIndex].push(cell.dataset_link.link)
      else
        # for now, default to putting the text in
        rows[fullDatasetRowIndex].push(cell.dataset_value.text)
      end

      rows[fullDatasetRowIndex].push(cell.scraped_timestamp.to_i)
  	}
      cells = laterCells
      laterCells = []
end

  	@rows = rows

    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = 'attachment; filename=' + filename + '.csv'    
    render :template => "datasets/download.csv.erb"

  end

  def downloaddetailedallattributes
  	dataset = Dataset.find(params[:id])
  	filename = gen_filename(dataset)

  	cells = DatasetCell.includes(:dataset_value, :dataset_link).where({dataset_id: params[:id]}).order(row: :asc, col: :asc)
  	rows = []
  	currentRowIndex = -1;
  	cells.each{ |cell|
  		if (cell.row != currentRowIndex)
  			currentRowIndex = cell.row
  			rows.push([])
  		end

      # just go ahead and put in both text and link
        rows[currentRowIndex].push(cell.dataset_value.text)
        rows[currentRowIndex].push(cell.dataset_link.link)

      rows[currentRowIndex].push(cell.scraped_timestamp.to_i)
  	}

  	@rows = rows

    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = 'attachment; filename=' + filename + '.csv'    
    render :template => "datasets/download.csv.erb"

  end

  def downloadforgiving
  	dataset = Dataset.find(params[:id])
  	filename = gen_filename(dataset)

  	cells = DatasetCell.includes(:dataset_value, :dataset_link).where({dataset_id: params[:id]}).order(row: :asc, col: :asc)
  	rows = []
  	currentRowIndex = -1
    currentDatasetRowIndex = -1
  	cells.each{ |cell|
  		if (cell.row != currentDatasetRowIndex)
        if (!cell.row)
          puts "bad cell:", cell
          next
        end
  			currentRowIndex += 1
        currentDatasetRowIndex = cell.row
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

  	@rows = rows

    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = 'attachment; filename=' + filename + '.csv'    
    render :template => "datasets/download.csv.erb"

  end

end
