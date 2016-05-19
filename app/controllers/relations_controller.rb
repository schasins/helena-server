class RelationsController < ApplicationController

	skip_before_action :protect_from_forgery, :only =>[:save_relation] # save_relation is going to be coming from the Chrome extension, so can't get the CSRF token.  in future should consider whether we should require some kind of authentication for this
	protect_from_forgery with: :null_session, :only =>[:save_relation]

  def index
    @relations = Relation.all
  end

  def save_relation
    relation = nil
    new_relation = false

    # ok, if this is already known to be associated with a particular relation (from retrieve_relation) and the selector is still the same, let's just use that
    relations = Relation.where(selector: params[:relation][:selector], selector_version: params[:relation][:selector_version], id: params[:relation][:relation_id])
    if relations.length > 0
      relation = relations[0]
    else
      # don't have a relation id to go on, so let's see if there's a relation with the same selector on the same url
      urlObj = Url.find_or_make(params[:relation][:url])
    	relations = Relation.where(selector: params[:relation][:selector], selector_version: params[:relation][:selector_version], url: urlObj)
      if relations.length > 0
        relation = relations[0] # there had better only be one since we have an index enforcing uniqueness on [selector, selector_version, url]
    	else
        # drat, no relation with same selector on same url.  relation with same selector on same domain?
        relations = Relation.joins(:url).where(urls: { domain_id: urlObj.domain_id }, relations: {selector: params[:relation][:selector], selector_version: params[:relation][:selector_version]})
        if relations.length > 0
          # let's guess that we want to merge this newly found relation with the existing relation
          # it's a little weird that this would arise, but since it's been tested on a couple members of the domain it's probably reasonable to try this
          relation = relations[0]
        else
          # ok, now we really don't think there's an existing relation in here, better make a new one
          new_relation = true
          parameters = ActionController::Parameters.new(params[:relation]) # see strong parameters for more details on this
          parameters = parameters.permit(:name, :selector, :selector_version, :url, :num_rows_in_demonstration)
          parameters[:url] = urlObj
          relation = Relation.create(parameters)
        end
    	end
    end

  	# ok, now we have the relation with which we should store the columns
    columns = params[:columns]
    columns.each{|i, column_params|
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