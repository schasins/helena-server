class RelationsController < ApplicationController

	# save_relation is going to be coming from the Chrome extension, so can't get the CSRF token.  in future should consider whether we should require some kind of authentication for this
	protect_from_forgery with: :null_session, :only =>[:save_relation], raise: false

  def index
    @relations = Relation.all
  end

  def save_relation
    relation = Relation.save_relation(params[:relation])
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

    puts "**** frequent_rels"
    puts frequent_rels.to_yaml
    puts "****"

    # frequent_rels now stores the relation ids of the relations that have the largest number of our target xpaths

    frequent_relations = frequent_rels.map { |rel_id| relation_ids_to_relations[rel_id] }


    puts "**** frequent_relations"
    puts frequent_relations.to_yaml
    puts "****"

    # if we have some options that actually include next button types, let's stick with just considering those.  else, just try with everything
    next_type_present_relations = frequent_relations.select {|relation| relation.next_type.present?}
    puts next_type_present_relations
    puts "^^^^^"
    puts next_type_present_relations.length
    if (next_type_present_relations.length > 0)
      frequent_relations = next_type_present_relations
    end

    # of the ones with the most target xpaths, which have the most rows?  and have probably therefore been most carefully trained/crafted...
    max_rows = 0
    many_row_relations = []
    frequent_relations.each{ |relation|
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
