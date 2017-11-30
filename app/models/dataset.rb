class Dataset < ActiveRecord::Base

	module Scraped # todo: shouldn't have this in both the model and the controller
		TEXT = 1
		LINK = 2
	end

#--------------------

	  def self.batch_based_construction(dataset, &block)
	  	currentRowIndex = -1;
        prevTimeStamp = -1
        currentPassTimeStamp = -1
        currentBaseLength = rows.length

        currRow = []

    	DatasetCell.includes(:dataset_value, :dataset_link)
    		.where({dataset_id: dataset.id})
    		.order(pass_timestamp: :asc, row: :asc, col: :asc)
    		.find_in_batches do |group|

    		group.each { |cell|
				if (cell.row + currentBaseLength != currentRowIndex)
					# before we add a fresh row, let's add the pass timestamp (which is also the pass identifier) to the row
					if (currentRowIndex >= 0)
						# puts "pushing currentPassTimeStamp bc cell.row is new", cell.row, cell.col, "****"
						currRow.push(currentPassTimeStamp.to_i)
					end

					if (cell.pass_timestamp != currentPassTimeStamp)
						# remember that each individual pass will start at row 0 again
						# we're about to swap to a new one
						currentBaseLength = rows.length
						currentPassTimeStamp = cell.pass_timestamp
					end

					# yield the row we've built so far...
					yield currRow

					# ok, now start a new row
					currentRowIndex = cell.row + currentBaseLength
					# puts "new currentRowIndex", currentRowIndex
					currRow = []
				end

				if (cell.scraped_attribute == Scraped::TEXT)
					currRow.push(cell.dataset_value.text)
				elsif (cell.scraped_attribute == Scraped::LINK)
					currRow.push(cell.dataset_link.link)
				else
					# for now, default to putting the text in
					currRow.push(cell.dataset_value.text)
				end
    		}
    	end
	  end

#--------------------

	def self.save_slice_internals(params)

	  	# {id: this.id, values: this.sentDatasetSlice}
	  	dataset_id = params[:id]
                pass_timestamp = Time.at(params[:pass_start_time].to_i/1000)

	  	# using transactions for bulk insertion
	  	# still won't be super fast, but should be sufficient for now.  todo: make it even better~
	  	ActiveRecord::Base.transaction do
	        nodes = JSON.parse(URI.decode(params[:nodes]))
	        positionLists = JSON.parse(params[:position_lists])
	        index = -1
            
		  	nodes.each{ |node|
                
	        index += 1
	        text = node["text"]
	        link = node["link"]
                if (node["date"])
                  date = Time.at(node["date"]/1000)
	        else
                  date = nil
                end
                scraped_attribute = node["scraped_attribute"]
	        source_url = node["source_url"]
	        top_frame_source_url = node["top_frame_source_url"]

	        text_object = DatasetValue.find_or_make(text)
	        link_object = DatasetLink.find_or_make(link)
	        scraped_attribute_num = Scraped::TEXT # default to scraping text
	        if (scraped_attribute == "LINK")
	          scraped_attribute_num = Scraped::LINK
	        end
	        source_url_object = Url.find_or_make(source_url)
	        top_frame_source_url_object = Url.find_or_make(top_frame_source_url)
		  		positionLists[index].each{ |coords|
		  			parameters = {dataset_id: dataset_id,
                    pass_timestamp: pass_timestamp,
	            dataset_value_id: text_object.id, 
	            dataset_link_id: link_object.id, 
	            scraped_attribute: scraped_attribute_num,
                    scraped_timestamp: date,
	            source_url_id: source_url_object.id,
	            top_frame_source_url_id: top_frame_source_url_object.id,
	            row: coords[0], 
	            col: coords[1]}
		  			DatasetCell.create(parameters)
		  		}
		    }
		end
	end

end
