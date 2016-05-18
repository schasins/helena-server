class RelationsController < ApplicationController

	skip_before_action :protect_from_forgery, :only =>[:save_relation] # save_relation is going to be coming from the Chrome extension, so can't get the CSRF token.  in future should consider whether we should require some kind of authentication for this
	protect_from_forgery with: :null_session, :only =>[:save_relation]

	def domain_of_url(url)
      domain = ""
      # don't need http and so on
      if (url.index("://") != nil) 
          domain = url.split('/')[2]
      else
          domain = url.split('/')[0]
      end
      domain = domain.split(':')[0] # there can be site.com:1234 and we don't want that
      return domain
	end

  def save_relation
  	puts "save_relation"
  	puts params
  	relations = Relation.where(selector: params[:relation][:selector], selector_version: params[:relation][:selector_version])
  	puts relations.length
  	relation = nil
  	if relations.length == 0
  		parameters = ActionController::Parameters.new(params[:relation]) # see strong parameters for more details on this
  		parameters = parameters.permit(:name, :selector, :selector_version, :url)
  		urls = Url.where(url: parameters[:url])
  		url = nil
  		if urls.length == 0
  			domain = Domain.find_or_create_by(domain: domain_of_url(parameters[:url]))
  			url = Url.new({url: parameters[:url], domain: domain})
  		else
  			url = urls[0] # again, should only be one
  		end
  		parameters[:url] = url
  		relation = Relation.new(parameters)
  	else
  		relation = relations[0] # there had better only be one since we have an index enforcing uniqueness on [selector, selector_version]
  	end
  	puts relation
  	puts "************"

  	# ok, now we have the relation with which we should store the columns
  	
  end
end