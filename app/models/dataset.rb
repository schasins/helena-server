class Dataset < ActiveRecord::Base

	module Scraped # todo: shouldn't have this in both the model and the controller
		TEXT = 1
		LINK = 2
	end

	def self.save_slice_internals(params)

	  	# {id: this.id, values: this.sentDatasetSlice}
	  	dataset_id = params[:id]

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
	            dataset_value_id: text_object.id, 
	            dataset_link_id: link_object.id, 
	            scraped_attribute: scraped_attribute_num, 
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
