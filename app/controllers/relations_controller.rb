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
          # what about the root domain?  todo: someday may be better to do root domain also.  not going to worry about it for now, unless we end up repeating across many subdomains

          # ok, now we really don't think there's an existing relation in here, better make a new one
          new_relation = true
          parameters = ActionController::Parameters.new(params[:relation]) # see strong parameters for more details on this
          parameters = parameters.permit(:name, :selector, :selector_version, :url, :num_rows_in_demonstration, :exclude_first, :next_type, :next_button_selector)
          parameters[:url] = urlObj
          puts parameters
          relation = Relation.create(parameters)
        end
    	end
    end

  	# ok, now we have the relation with which we should store the columns
    columns = params[:relation][:columns]
    columns.each{|i, column_params|
      parameters = ActionController::Parameters.new(column_params) # see strong parameters for more details on this
      parameters = parameters.permit(:name, :xpath, :suffix)
      if new_relation or Column.where(xpath: column_params[:xpath], relation: relation).length == 0
        # either the relation is new so all columns must be added, or the pre-existing relationship doesn't yet have the col
        parameters[:relation] = relation
        column = Column.create(parameters)
      else
        # allowed to rename columns
        column = Column.where(xpath: column_params[:xpath], relation: relation)[0] # there should only be one of these!  if not, something is very weird
        column.name = parameters[:name]
        column.save
      end
    }
    # let's make sure we still have the right number of columns recorded in the relation record
    num_rel_columns = Column.where(relation_id: relation.id).count
    relation.num_columns = num_rel_columns

    # although the selector and selector_version are guaranteed to be the same, based on how we grabbed our relation out of the database, the next button selector may have changed
    relation.next_type = params[:relation][:next_type]
    relation.next_button_selector = params[:relation][:next_button_selector]
    relation.name = params[:relation][:name]

    # if this version of the selector was actually demonstrated on more rows, we should probably go ahead and trust it more...
    if params[:relation][:num_rows_in_demonstration].to_i > relation.num_rows_in_demonstration
      relation.num_rows_in_demonstration = params[:relation][:num_rows_in_demonstration].to_i
    end

    relation.save
    render json: { relation: relation }
  end

  def best_relation(column_list)
    if column_list.length == 0
      return nil # we don't know any relations :(
    end

    # first find the relation that has the largest number of our target xpaths
    relation_ids_to_freq = {}
    relation_ids_to_relations = {}
    column_list.each{ |columnObj|
      rel_id = columnObj.relation_id
      relation_ids_to_freq[rel_id] = relation_ids_to_freq.fetch(rel_id, 0) + 1
      relation_ids_to_relations[rel_id] = columnObj.relation
    }
    frequent_rel_count = 0
    frequent_rels = []
    relation_ids_to_freq.each{ |rel_id, freq|
      if freq > frequent_rel_count
        frequent_rel_count = freq
        frequent_rels = [rel_id]
      elsif freq == frequent_rel_count
        frequent_rels.push(rel_id)
      end
    }
    # frequent_rels now stores the relation ids of the relations that have the largest number of our target xpaths

    # of the ones with the most target xpaths, which have the most rows?  and have probably therefore been most carefully trained/crafted...
    max_rows = 0
    many_row_relations = []
    frequent_rels.each{ |rel_id|
      relation = relation_ids_to_relations[rel_id]
      relation_num_rows = relation.num_rows_in_demonstration
      if relation_num_rows > max_rows
        max_rows = relation_num_rows
        many_row_relations = [relation]
      elsif relation_num_rows == max_rows
        many_row_relations.push(relation)
      end
    }
    # many_row_relations now stores the relation objects with the most rows, of those that have the largest number of our target xpaths

    # of those, which has the most columns?
    # at this point, we could just resolve ties arbitrarily...  better to do it in an orderly way, so that we're consistent in always building on one, but at this point let's leave it be
    best_relation = many_row_relations.max_by{|r| r.num_columns}

    return best_relation
  end

  def column_representation(column_obj)
    return {xpath: column_obj.xpath, suffix: column_obj.suffix, name: column_obj.name, id: column_obj.id}
  end

  def relation_representation(relation_obj)
    if relation_obj == nil
      return nil
    end

    columns = relation_obj.columns
    column_jsons = []
    columns.each{ |col| 
      column_jsons.push(column_representation(col)) 
    }

    return {selector_version: relation_obj.selector_version, selector: relation_obj.selector, name: relation_obj.name, exclude_first: relation_obj.exclude_first, id: relation_obj.id, columns: column_jsons, num_rows_in_demonstration: relation_obj.num_rows_in_demonstration, next_type: relation_obj.next_type, next_button_selector: relation_obj.next_button_selector}
  end

  def retrieve_relation_helper(params)
    # we want to get the best selector (selector with most shared xpaths, then with most rows, then with most columns) for a couple categories:
    # first for a relation associated with same url (if any) then with one associated with the same domain (if any)
    # for any xpaths that don't have associated columns in one or more returned relations, try to come up with a name for those

    xpath_strings = params[:xpaths]
    columns_with_same_xpaths = Column.includes(:relation => :url).where(columns: {xpath: xpath_strings})

    urlObj = Url.find_or_make(params[:url])

    same_url_columns , same_domain_columns = [], []
    columns_with_same_xpaths.each do |column|
      same_url_columns << column if column.relation.url == urlObj
      same_domain_columns << column if column.relation.url.domain == urlObj.domain
    end

    result = {}
    result[:same_url_best_relation] = relation_representation(best_relation(same_url_columns))
    result[:same_domain_best_relation] = relation_representation(best_relation(same_domain_columns))

    return result
  end

  def retrieve_relation
    render json: retrieve_relation_helper(params)
  end

  def retrieve_relations
    result = {pages: []}
    params[:pages].each do |index, page_relation|
      result[:pages].push({url: page_relation[:url], page_var_name: page_relation[:page_var_name], relations: retrieve_relation_helper(page_relation)})
    end
    render json: result
  end

  def all_page_relations
    url = params[:url]
    urlObj = Url.find_or_make(url)
    # let's find all the relations associated with this domain
    relations = Relation.includes(:columns).joins(:url).where(urls: { domain_id: urlObj.domain_id })
    relation_objects = []
    relations.each do |relation|
      relation_objects.push(relation_representation(relation))
    end
    render json: {relations: relation_objects}
  end

end