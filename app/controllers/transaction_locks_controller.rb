class TransactionLocksController < ApplicationController

  skip_before_action :protect_from_forgery, :only =>[:new, :exists, :new_with_dataset_slice] # save_relation is going to be coming from the Chrome extension, so can't get the CSRF token.  in future should consider whether we should require some kind of authentication for this
  protect_from_forgery with: :null_session, :only =>[:new, :exists, :new_with_dataset_slice]

  def new
    transaction = TransactionLock.transaction_saving_internals(params)
    render json: { transaction_id: transaction.id }
  end

  def make_if_not_exists
    exists = TransactionLock.exists(params)
    # for the exists case, we just tell the user that it already exists
    if (exists)
      render json: { task_yours: false } # this thread shouldn't do this task
      return
    end

    # for the not exists case, we want to make the lock record.  but only if no one else got it first
    begin
      transaction = TransactionLock.transaction_saving_internals(params)
      # handle success here
      render json: { task_yours: true, transaction_lock_id: transaction.id }
      return
    rescue ActiveRecord::RecordInvalid => invalid
       # handle failure here
       # remember that we require unique (program_id, program_run_id, annotation_id, transaction_items_str) tuple
      render json: { task_yours: false } # this thread shouldn't do this task because failure means someone else already claimed it
    end
  end

  
end
