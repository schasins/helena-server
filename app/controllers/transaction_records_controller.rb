class TransactionRecordsController < ApplicationController

  skip_before_action :protect_from_forgery, :only =>[:new, :exists, :new_with_dataset_slice] # save_relation is going to be coming from the Chrome extension, so can't get the CSRF token.  in future should consider whether we should require some kind of authentication for this
  protect_from_forgery with: :null_session, :only =>[:new, :exists, :new_with_dataset_slice]

  def new
    transaction = TransactionRecord.transaction_saving_internals(params)
    render json: { transaction_id: transaction.id }
  end

  def new_with_dataset_slice
    ActiveRecord::Base.transaction do # put this all in a transaction bc we want to add the dataset slice iff commit record is saved
      transaction = TransactionRecord.transaction_saving_internals(params)
      ProgramRun.save_slice_internals(params)
      render json: { transaction_id: transaction.id }
    end
  end

  def exists
    program_id = params[:program_id]
    program_run_id = params[:program_run_id]
    annotation_id = params[:annotation_id]
    commit_time = Time.at(params[:commit_time].to_i/1000)

    # this is tricky.  need to select transactions based on having all the cells we want
    transaction_query = TransactionRecord.where(program_id: program_id, annotation_id: annotation_id)
    # for here we only filter based on having the same program, but can also use commit time and program_run to filter

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

    render json: { exists: exists }

  end

  
end
