class RelationsController < ApplicationController

	skip_before_action :protect_from_forgery, :only =>[:save_relation] # save_relation is going to be coming from the Chrome extension, so can't get the CSRF token.  in future should consider whether we should require some kind of authentication for this
	protect_from_forgery with: :null_session, :only =>[:save_relation]

  def index
    @relations = Relation.all
  end

  def save_relation
  	puts "save_relation"
  	puts params
    urlObj = Url.find_or_make(params[:relation][:url])
  	relations = Relation.where(selector: params[:relation][:selector], selector_version: params[:relation][:selector_version], url: urlObj)
  	puts relations.length
  	relation = nil
    new_relation = false
  	if relations.length == 0
      puts "no matching relation, must make new one"
      new_relation = true
  		parameters = ActionController::Parameters.new(params[:relation]) # see strong parameters for more details on this
  		parameters = parameters.permit(:name, :selector, :selector_version, :url, :num_rows_in_demonstration)
  		parameters[:url] = urlObj
  		relation = Relation.create(parameters)
  	else
      puts "existing relation"
  		relation = relations[0] # there had better only be one since we have an index enforcing uniqueness on [selector, selector_version, url]
  	end
  	puts relation

  	# ok, now we have the relation with which we should store the columns
    columns = params[:columns]
    columns.each{|i, column_params|
      puts column_params

      puts column_params[:xpath]

      if new_relation or Column.where(xpath: column_params[:xpath], relation: relation).length == 0
        # either the relation is new so all columns must be added, or the pre-existing relationship doesn't yet have the col
        parameters = ActionController::Parameters.new(column_params) # see strong parameters for more details on this
        parameters = parameters.permit(:name, :xpath, :suffix)
        parameters[:relation] = relation
        column = Column.create(parameters)
      end
    }
    # let's make sure we still have the right number of columns recorded in the relation record
    num_rel_columns = Column.where(relation_id: relation.id).count
    relation.num_columns = num_rel_columns
    relation.save

    render json: { relation: relation }
  end

  def retrieve_relation
    puts "retrieve_relation"
    puts params
    render json: { placeholder: "p" }

  end

end