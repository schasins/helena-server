class Domain < ActiveRecord::Base

	def self.domain_of_url(url)
    if (url.nil?)
      return nil
    end
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

end
