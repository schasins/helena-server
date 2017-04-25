class Relation < ActiveRecord::Base
  belongs_to :url
  has_many :columns
  has_many :program_uses_relations
  has_many :programs, through: :program_uses_relations



  def self.save_relation(params)
    relation = nil
    new_relation = false

    # ok, if this is already known to be associated with a particular relation (from retrieve_relation) and the selector is still the same, let's just use that
    relations = Relation.where(selector: params[:selector], selector_version: params[:selector_version], id: params[:relation_id])
    if relations.length > 0
      relation = relations[0]
    else
      # don't have a relation id to go on, so let's see if there's a relation with the same selector on the same url
      urlObj = Url.find_or_make(params[:url])
      relations = Relation.where(selector: params[:selector], selector_version: params[:selector_version], url: urlObj)
      if relations.length > 0
        relation = relations[0] # there had better only be one since we have an index enforcing uniqueness on [selector, selector_version, url]
        else
        # drat, no relation with same selector on same url.  relation with same selector on same domain?
        relations = Relation.joins(:url).where(urls: { domain_id: urlObj.domain_id }, relations: {selector: params[:selector], selector_version: params[:selector_version]})
        if relations.length > 0
          # let's guess that we want to merge this newly found relation with the existing relation
          # it's a little weird that this would arise, but since it's been tested on a couple members of the domain it's probably reasonable to try this
          relation = relations[0]
        else
          # what about the root domain?  todo: someday may be better to do root domain also.  not going to worry about it for now, unless we end up repeating across many subdomains

          # ok, now we really don't think there's an existing relation in here, better make a new one
          new_relation = true
          parameters = ActionController::Parameters.new(params) # see strong parameters for more details on this
          parameters = parameters.permit(:name, :selector, :selector_version, :url, :num_rows_in_demonstration, :exclude_first, :next_type, :next_button_selector)
          parameters[:url] = urlObj
          puts parameters
          relation = Relation.create(parameters)
        end
        end
    end

    # ok, now we have the relation with which we should store the columns
    columns = params[:columns]
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
    relation.next_type = params[:next_type]
    relation.next_button_selector = params[:next_button_selector]
    relation.name = params[:name]

    # if this version of the selector was actually demonstrated on more rows, we should probably go ahead and trust it more...
    if params[:num_rows_in_demonstration].to_i > relation.num_rows_in_demonstration
      relation.num_rows_in_demonstration = params[:num_rows_in_demonstration].to_i
    end

    relation.save
    return relation
  end

end
