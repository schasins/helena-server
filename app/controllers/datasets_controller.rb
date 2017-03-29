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

      rows[currentRowIndex].push(cell.scraped_timestamp.to_i)
  	}

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
