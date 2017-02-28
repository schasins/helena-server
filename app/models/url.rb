class Url < ActiveRecord::Base
  belongs_to :domain

  def self.find_or_make(url)
		urls = Url.where(url: url)
		urlObj = nil
		if urls.length == 0
			domain = Domain.find_or_create_by(domain: Domain.domain_of_url(url))
			begin
				Url.transaction(requires_new: true) do
					urlObj = Url.create({url: url, domain: domain})
	            end
	        rescue
                # sometimes multiple different requests are trying to do this at the same time and another will succeed first
                # so let's actually grab the existing one out of the db
                # todo: actually all my other custom find_or_make methods should do this same thing
	        	return self.find_or_make(url)
	        end
		else
			urlObj = urls[0] # should only be one, because enforce uniqueness
		end
		return urlObj
  end

end
