class DatasetsController < ApplicationController

	require 'csv'

	skip_before_action :protect_from_forgery, :only =>[:new] # save_relation is going to be coming from the Chrome extension, so can't get the CSRF token.  in future should consider whether we should require some kind of authentication for this
	protect_from_forgery with: :null_session, :only =>[:new]

  def new
  	dataset = Dataset.create()
  	render json: { id: dataset.id }
  end

  module Scraped
    TEXT = 1
    LINK = 2
  end

  def save_slice
  	# {id: this.id, values: this.sentDatasetSlice}
  	dataset_id = params[:id]

  	# using transactions for bulk insertion
  	# still won't be super fast, but should be sufficient for now.  todo: make it even better~
  	ActiveRecord::Base.transaction do
      nodes = JSON.parse(URI.decode(params[:nodes]))
      positionLists = JSON.parse(params[:position_lists])
	  	nodes.each{ |index, node|
	  		#puts positionList
        text = node.text
        link = node.link
        scraped_attribute = node.scraped_attribute
        source_url = node.source_url
        top_frame_source_url = node.top_frame_source_url

        text_object = DatasetValue.find_or_make(text)
        link_object = DatasetLink.find_or_make(link)
        scraped_attribute_num = Scraped::TEXT # default to scraping text
        if (scraped_attribute == "LINK"){
          scraped_attribute_num = Scraped::LINK
        }
        source_url_object = Url.find_or_make(source_url)
        top_frame_source_url_object = Url.find_or_make(top_frame_source_url)
	  		positionLists[index].each{ |coords|
	  			parameters = {dataset_id: dataset_id, 
            dataset_value_id: text_object.id, 
            dataset_link_id: link_object.id, 
            scraped_attribute: scraped_attribute_num, 
            source_url: source_url_object.id,
            top_frame_source_url: top_frame_source_url_object.id,
            row: coords[0], 
            col: coords[1]}
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

  	cells = DatasetCell.includes(:dataset_value, :dataset_link, :scraped_attribute).where({dataset_id: params[:id]}).order(row: :asc, col: :asc)
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

  def downloadforgiving
  	dataset = Dataset.find(params[:id])
  	filename = dataset.name
  	if (filename == nil or filename == "")
  		filename = "dataset"
  	end

  	cells = DatasetCell.includes(:dataset_value, :dataset_link, :scraped_attribute).where({dataset_id: params[:id]}).order(row: :asc, col: :asc)
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
