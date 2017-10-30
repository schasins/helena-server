class TransactionLock < ActiveRecord::Base

  validates :transaction_items_str, uniqueness: {scope: [:program_id, :program_run_id , :annotation_id]}

  belongs_to :program
  belongs_to :program_run
  belongs_to :dataset # get rid of this in future

  	def self.transaction_items_str(transaction_items)
	    items_str = ""
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
	      items_str += index.to_s + "_" + attri + "_" + val_obj.id.to_s + "___"
	    }
	    return items_str
  	end

  	def self.params_to_params(params)
  		program_id = params[:program_id]
	    program_run_id = params[:program_run_id]
	    annotation_id = params[:annotation_id]

	    transaction_items = JSON.parse(URI.decode(params[:transaction_attributes]))
	    items_str = self.transaction_items_str(transaction_items)

	    parameters = {program_id: program_id, program_run_id: program_run_id, annotation_id: annotation_id, transaction_items_str: items_str}
	   	return parameters
  	end

  	def self.transaction_saving_internals(params)
  		parameters = self.params_to_params(params)
	    transaction_lock = TransactionLock.create(parameters)

	    return transaction_lock
	end

	def self.exists(params)
  		ps = self.params_to_params(params)
	    transaction_lock = TransactionLock.where(program_id: ps[:program_id], program_run_id: ps[:program_run_id], annotation_id: ps[:annotation_id], transaction_items_str: ps[:transaction_items_str])
	    
	    exists = false;
	    # ok, our transaction query is ready.
	    if (transaction_lock.length > 0)
	      exists = true;
	    end

	    return exists
	end
end
