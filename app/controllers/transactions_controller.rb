class TransactionsController < ApplicationController

  def new
    dataset_id = params[:id]
    parameters = {dataset_id: dataset_id}
    transaction = Transaction.create(parameters)

    transaction_items = JSON.parse(URI.decode(params[:transaction]))
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
      params = {transaction_id: transaction.id,
                index: index,
                attr_value: val}
      TransactionCell.create(params)
    end
    render json: { transaction_id: transaction.id }
  end

  def exists
    dataset_id = params[:id]

    # this is tricky.  need to select transactions based on having all the cells we want
    transaction_query = Transaction.where(dataset_id: dataset_id)
    #.where(id: TransactionCell.where(attr_val: val, index: i).select(transaction_id))

    transaction_items = JSON.parse(URI.decode(params[:transaction]))
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
      transaction_query = transaction_query.where(id: TransactionCell.where(attr_val: val, index: index).select(transaction_id))
    end

    exists = false;

    # ok, our transaction query is ready.
    if (transaction_query.length > 0){
      exists = true;
    }

    render json: { exists: exists }

  end

  
end
