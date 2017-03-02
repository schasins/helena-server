class TransactionRecordsController < ApplicationController

  skip_before_action :protect_from_forgery, :only =>[:new, :exists] # save_relation is going to be coming from the Chrome extension, so can't get the CSRF token.  in future should consider whether we should require some kind of authentication for this
  protect_from_forgery with: :null_session, :only =>[:new, :exists]

  def new
    dataset_id = params[:dataset]
    annotation_id = params[annotation_id]
    parameters = {dataset_id: dataset_id, annotation_id: annotation_id}
    transaction = TransactionRecord.create(parameters)

    transaction_items = JSON.parse(URI.decode(params[:transaction_attributes]))
    index = -1
    transaction_items.each{ |item|
      index += 1
      attri = item["attr"]
      val = item["val"]
      if (attri == "TEXT")
        val_id = DatasetValue.find_or_make(val)
      elsif (attri == "LINK")
        val_id = DatasetLink.find_or_make(val)
      else
        puts "Uh oh, don't know the attribute type for a transaction cell."
      end
      params = {transaction_record_id: transaction.id,
                index: index,
                attr_value: val_id}
      TransactionCell.create(params)
    }
    render json: { transaction_id: transaction.id }
  end

  def exists
    dataset_id = params[:dataset]
    annotation_id = params[:annotation_id]

    # this is tricky.  need to select transactions based on having all the cells we want
    transaction_query = TransactionRecord.where(dataset_id: dataset_id, annotation_id: annotation_id)
    #.where(id: TransactionCell.where(attr_val: val, index: i).select(transaction_id))

    transaction_items = JSON.parse(URI.decode(params[:transaction_attributes]))
    index = -1
    transaction_items.each{ |item|
      index += 1
      attri = item["attr"]
      val = item["val"]
      if (attri == "TEXT")
        val_id = DatasetValue.find_or_make(val)
      elsif (attri == "LINK")
        val_id = DatasetLink.find_or_make(val)
      else
        puts "Uh oh, don't know the attribute type for a transaction cell."
      end

      # and now edit the transaction query based on requiring this additional cell to be attached
      transaction_query = transaction_query.where(id: TransactionCell.where(attr_value: val_id, index: index).select(:transaction_record_id))
    }

    exists = false;
    # ok, our transaction query is ready.
    if (transaction_query.length > 0)
      exists = true;
    end

    render json: { exists: exists }

  end

  
end
