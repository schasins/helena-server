class DatasetsController < ApplicationController

	require 'csv'

	skip_before_action :protect_from_forgery, :only =>[:new] # save_relation is going to be coming from the Chrome extension, so can't get the CSRF token.  in future should consider whether we should require some kind of authentication for this
	protect_from_forgery with: :null_session, :only =>[:new]

  def new
  	dataset = Dataset.create()
  	render json: { id: dataset.id }
  end

  def save_slice
  	# {id: this.id, values: this.sentDatasetSlice}
  	dataset_id = params[:id]

  	# using transactions for bulk insertion
  	# still won't be super fast, but should be sufficient for now.  todo: make it even better~
  	ActiveRecord::Base.transaction do
                vals = JSON.parse(URI.decode(params[:values]))
	  	vals.each{ |value_text, positionList|
	  		#puts positionList
                        valueObject = DatasetValue.find_or_make(value_text)
	  		positionList.each{ |coords|
	  			parameters = {dataset_id: dataset_id, dataset_value_id: valueObject.id, row: coords[0], col: coords[1]}
	  			DatasetCell.create(parameters)
	  		}
	    }
	  end

  	render json: { }

  end

  def download
  	dataset = Dataset.find(params[:id])
  	filename = dataset.name
  	if (filename == nil or filename == "")
  		filename = "dataset"
  	end

  	cells = DatasetCell.includes(:dataset_value).where({dataset_id: params[:id]}).order(row: :asc, col: :asc)
  	rows = []
  	currentRowIndex = -1;
  	cells.each{ |cell|
  		if (cell.row != currentRowIndex)
  			currentRowIndex = cell.row
  			rows.push([])
  		end
  		rows[currentRowIndex].push(cell.dataset_value.text)
  	}

  	@rows = rows

    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = 'attachment; filename=' + filename + '.csv'    
    render :template => "datasets/download.csv.erb"

  end

  def downloadforgiving
  	dataset = Dataset.find(params[:id])
  	filename = dataset.name
  	if (filename == nil or filename == "")
  		filename = "dataset"
  	end

  	cells = DatasetCell.includes(:dataset_value).where({dataset_id: params[:id]}).order(row: :asc, col: :asc)
  	rows = []
  	currentRowIndex = -1
    currentDatasetRowIndex = -1
  	cells.each{ |cell|
  		if (cell.row != currentDatasetRowIndex)
        if (!cell.row)
          puts cell
          next
        end
  			currentRowIndex += 1
        currentDatasetRowIndex = cell.row
        rows.push([])
  		end
  		rows[currentRowIndex].push(cell.dataset_value.text)
  	}

  	@rows = rows

    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = 'attachment; filename=' + filename + '.csv'    
    render :template => "datasets/download.csv.erb"

  end

end
