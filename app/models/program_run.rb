class ProgramRun < ActiveRecord::Base

        belongs_to :program

	module Scraped # todo: shouldn't have this in both the model and the controller
		TEXT = 1
		LINK = 2
	end

	def self.save_slice_internals(params)

	  	# {id: this.id, values: this.sentDatasetSlice}
	  	run_id = params[:run_id]
	  	run = ProgramRun.find(run_id)
	  	prog_id = run.program_id
	  	sub_run_id = params[:sub_run_id]
        run_timestamp = Time.at(params[:pass_start_time].to_i/1000)

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
		  			parameters = {
	            	dataset_value_id: text_object.id, 
	            	dataset_link_id: link_object.id, 
	            	scraped_attribute: scraped_attribute_num,
	                scraped_timestamp: date,
	            	source_url_id: source_url_object.id,
	            	top_frame_source_url_id: top_frame_source_url_object.id,
	            	col: coords[1]}
		  			cell = DatasetCell.create(parameters)
		  			# ok, for now we're still making redundant cells because we're doing this once for each entry in the position list
		  			# which means since the col may not even be changing, we may be very redundant!  todo: go back and remove this redundancy in future
		  			# but we also need to make sure we have a DatasetRow for this cell.
		  			run_row_index = coords[0]
		  			dataset_rows = DatasetRow.where({program_run_id: run_id, program_sub_run_id: sub_run_id, run_row_index: run_row_index})
		  			row = nil
		  			if (dataset_rows.empty?)
		  				# ok, we don't yet have a row, have to make a new one
		  				row = DatasetRow.create({program_id: prog_id, program_run_id: run_id, program_sub_run_id: sub_run_id, run_row_index: run_row_index})
		  			else
		  				row = dataset_rows[0]
		  			end
		  			# and now that we definitely have the dataset row, let's make the relationship between the row and the cell
		  			DatasetRowDatasetCellRelationship.create({dataset_row_id: row.id, dataset_cell_id: cell.id})
		  		}
		    }
		end
	end

end
