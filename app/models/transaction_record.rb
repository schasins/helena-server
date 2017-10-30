class TransactionRecord < ActiveRecord::Base

  belongs_to :program
  belongs_to :program_run
  belongs_to :dataset # get rid of this in future

  	def self.transaction_saving_internals(params)
  		program_id = params[:program_id]
	    program_run_id = params[:program_run_id]
	    annotation_id = params[:annotation_id]
	    commit_time = Time.at(params[:commit_time].to_i/1000)

	    parameters = {program_id: program_id, program_run_id: program_run_id, annotation_id: annotation_id, commit_time: commit_time}
	    transaction = TransactionRecord.create(parameters)

	    transaction_items = JSON.parse(URI.decode(params[:transaction_attributes]))
	    index = -1
	    transaction_items.each{ |item|
	      index += 1
	      attri = item["attr"]
	      val = item["val"]
	      if (attri == "TEXT")
	        val_obj = DatasetValue.find_or_make(val)
	      elsif (attri == "LINK")
	        val_obj = DatasetLink.find_or_make(val)
	      else
	        puts "Uh oh, don't know the attribute type for a transaction cell."
	      end
	      params = {transaction_record_id: transaction.id,
	                index: index,
	                attr_value: val_obj.id}
	      TransactionCell.create(params)
	    }

	    return transaction
	end

	def self.exists(params)
	    program_id = params[:program_id]
	    program_run_id = params[:program_run_id]
	    annotation_id = params[:annotation_id]
	    commit_time = Time.at(params[:commit_time].to_i/1000)

	    physical_time_diff_seconds = (params[:physical_time_diff_seconds])
	    logical_time_diff = (params[:logical_time_diff])

	    # this is tricky.  need to select transactions based on having all the cells we want
	    transaction_query = TransactionRecord.where(program_id: program_id, annotation_id: annotation_id)
	    
	    # above only filters based on having the same program, but can also use time and program_run to filter
	    if (physical_time_diff_seconds)
	      # use time (physical time)
	      physical_time_diff_seconds = physical_time_diff_seconds.to_i
	      threshold_time = Time.now - physical_time_diff_seconds
	      transaction_query = transaction_query.where("commit_time > ?", threshold_time)
	    elsif (logical_time_diff)
	      # use program run (logical time)
	      logical_time_diff = logical_time_diff.to_i
	      # ok, for this we need to figure out what program runs we've done for the program.
	      # if logical_time_diff is 2, we're allowed to skip if we've seen a duplicate in the last two runs
	      # that is, this run plus either of the last 2
	      runs = ProgramRun.where(program_id: program_id).order(created_at: :desc)
	      if (runs.size < (logical_time_diff + 1))
	        # don't actually need to do any filtering.  the whole history of the executions falls in our target range
	      else
	        # if the logical_time_diff is 2, we'll skip if we see duplicates in the curr run or prior 2, so we're
	        # interested in the set of transaction records made after the the time when the third prog run in runs was created
	        threshold_time = runs[logical_time_diff].created_at
	        transaction_query = transaction_query.where("commit_time > ?", threshold_time)
	      end
	    end

	    # ok, now let's go through and mention all the cells that need to be associated with the record
	    transaction_items = JSON.parse(URI.decode(params[:transaction_attributes]))
	    index = -1
	    transaction_items.each{ |item|
	      # puts item
	      # puts "****"
	      index += 1
	      attri = item["attr"]
	      val = item["val"]
	      if (attri == "TEXT")
	        val_obj = DatasetValue.find_or_make(val)
	      elsif (attri == "LINK")
	        val_obj = DatasetLink.find_or_make(val)
	      else
	        puts "Uh oh, don't know the attribute type for a transaction cell."
	      end

	      # and now edit the transaction query based on requiring this additional cell to be attached
	      transaction_query = transaction_query.where(id: TransactionCell.where(attr_value: val_obj.id, index: index).select(:transaction_record_id))
	    }

	    exists = false;
	    # ok, our transaction query is ready.
	    if (transaction_query.length > 0)
	      exists = true;
	    end

	    return exists
	end
end
