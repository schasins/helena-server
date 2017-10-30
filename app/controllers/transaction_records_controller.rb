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
    exists = TransactionRecord.exists(params)
    render json: { exists: exists }
  end

  
end
