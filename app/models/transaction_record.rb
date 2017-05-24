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
end
