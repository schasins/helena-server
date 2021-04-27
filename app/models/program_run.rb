class ProgramRun < ActiveRecord::Base

        belongs_to :program

	module Scraped # todo: shouldn't have this in both the model and the controller
		TEXT = 1
		LINK = 2
	end

#--------------------

	def self.batch_based_report(program, timeLimitInHours)

		uncached do

			# first let's grab the ids for all the rows we're going to show, so that we can break them down into batches
			# (in order that we can stream the results to the user, to break up large download tasks)
			row_ids = DatasetRow.select(:id)

			# let's get the basics.  what kind of row do we want in the first place?  all runs?  one run?

			row_ids = row_ids.where({program_id: program.id})

			if (timeLimitInHours)
	            adjusted_datetime = (DateTime.now.to_time - (timeLimitInHours.to_i).hours).to_datetime
				row_ids = row_ids.where('created_at > ?', adjusted_datetime)
			end

			count = row_ids.count
			run_count = row_ids.distinct.count(:program_run_id)
			run_details = DatasetRow.where(id: row_ids).group(:program_run_id).select(:program_run_id).select(
				  "MIN(created_at) AS starttime",
				  "MAX(created_at) AS endtime",
				  'COUNT(id) AS numrows'
				)

			return {numrows: count, numruns: run_count, rundetails: run_details}
		end

	end

	def self.batch_based_construction(allRuns, detailedRows, run, program, timeLimitInHours, rowLimit, &block)

		uncached do

			# first let's grab the ids for all the rows we're going to show, so that we can break them down into batches
			# (in order that we can stream the results to the user, to break up large download tasks)
			row_ids = DatasetRow.select(:id)

			# let's get the basics.  what kind of row do we want in the first place?  all runs?  one run?
			if (allRuns)
				row_ids = row_ids.where({program_id: program.id})
			else
				row_ids = row_ids.where({program_run_id: run.id})
			end

			# and how should we order them?  if we're limiting to the most recent rows, we'll want to order by time added
			# (to grab only the most recent x rows)
			# otherwise, let's order them by run, then subrun (parallel worker), then row index
			# (to group rows that came from the same parallel worker)
			if (rowLimit)
				row_ids = row_ids.order(created_at: :desc).limit(rowLimit) # the only one where it's *descending*!
			elsif (allRuns)
				# need to also order by the prog run since we're collecting all the prog runs
				row_ids = row_ids.order(program_run_id: :asc, program_sub_run_id: :asc, run_row_index: :asc)
			else
				# there's no limit and it's just one run, so...
				row_ids = row_ids.order(program_sub_run_id: :asc, run_row_index: :asc)
			end


			if (timeLimitInHours)
	            adjusted_datetime = (DateTime.now.to_time - (timeLimitInHours.to_i).hours).to_datetime
				row_ids = row_ids.where('created_at > ?', adjusted_datetime)
			end

			# ok, now we have all the row ids.  now break them into batches, do the actual processing
			batch_size = 50
			row_ids.each_slice(batch_size) do |row_ids|

				# let's retrieve all the information we actually need about the current batch of rows
				rows = DatasetRow.where(id: row_ids)
							.includes(:program_run, dataset_cells: [:dataset_value, :dataset_link])
				if (rowLimit)
					rows = rows.order(created_at: :desc) # remember this order must match the order above
				elsif (allRuns)
					rows = rows.order(program_run_id: :asc, program_sub_run_id: :asc, run_row_index: :asc)
				else
					rows = rows.order(program_sub_run_id: :asc, run_row_index: :asc)
				end

				# now let's process each row
				group_rows_str = ""
				rows.each { |row|
					currRow = []
					progRunObj = row.program_run
					currentProgRunCounter = progRunObj.run_count

					cells = row.dataset_cells.order(col: :asc)
					scraped_times = []
					cells.each{ |cell|

						if (cell.scraped_attribute == Scraped::TEXT)
							currRow.push(cell.dataset_value.text)
						elsif (cell.scraped_attribute == Scraped::LINK)
							currRow.push(cell.dataset_link.link)
						else
							# for now, default to putting the text in
							currRow.push(cell.dataset_value.text)
						end
						if (detailedRows and cell.scraped_timestamp)
							scraped_times.push(cell.scraped_timestamp)
						end
					}

					if (allRuns)
						# and at the end of the row, go ahead and add the program_run_id to let the user know which pass produced the row
						currRow.push(currentProgRunCounter)
					end

					if (detailedRows)
	                                  currRow.push(row.program_run_id)
	                                  currRow.push(row.program_sub_run_id)
					currRow.push(scraped_times.max.to_i)
					end

					# ok, we've put together the whole current row.  add it to our accumulator
					group_rows_str << CSV.generate_line(currRow)
				}
				# now that we've finished processing the group, yield the accumulator
				yield group_rows_str
			end
		end

	end

#--------------------

	def gen_filename()
		fn = self.name
		if (fn == nil or fn == "")
		  fn = "dataset"
		end
		fn = fn + "_" + self.program_id.to_s + "_" + self.id.to_s
		return fn
	end

	def get_output_rows(detailedRows)
	    rows = DatasetRow.
	      where({program_run_id: self.id}).
	      includes(dataset_cells: [:dataset_value, :dataset_link]).
	      order(program_sub_run_id: :asc, run_row_index: :asc)

	    outputrows = []
	    currentRowIndex = -1
	    rows.each{ |row|
	      outputrows.push([])
	      currentRowIndex += 1

	      cells = row.dataset_cells.order(col: :asc)
	      scraped_times = []
	      cells.each{ |cell|

		      if (cell.scraped_attribute == Scraped::TEXT)
		        outputrows[currentRowIndex].push(cell.dataset_value.text)
		  	  elsif (cell.scraped_attribute == Scraped::LINK)
		        outputrows[currentRowIndex].push(cell.dataset_link.link)
		      else
		        # for now, default to putting the text in
		        outputrows[currentRowIndex].push(cell.dataset_value.text)
		      end
		      if (detailedRows and cell.scraped_timestamp)
		      	scraped_times.push(cell.scraped_timestamp)
		      end
          }
          if (detailedRows)
          	outputrows[currentRowIndex].push(scraped_times.max.to_i)
          end
	    }
	    return outputrows
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
