class Url < ActiveRecord::Base
  belongs_to :domain

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

  def self.find_or_make(url)
		urls = Url.where(url: url)
		urlObj = nil
		if urls.length == 0
			domain = Domain.find_or_create_by(domain: domain_of_url(parameters[:url]))
			urlObj = Url.create({url: parameters[:url], domain: domain})
		else
			urlObj = urls[0] # should only be one, because enforce uniqueness
		end
		return urlObj
  end

end
