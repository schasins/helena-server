class Url < ActiveRecord::Base
  belongs_to :domain

  def self.find_or_make(url)
		urls = Url.where(url: url)
		urlObj = nil
		if urls.length == 0
	          begin
				domain = Domain.find_or_create_by(domain: Domain.domain_of_url(url))
				urlObj = Url.create({url: url, domain: domain})
	          rescue ActiveRecord::RecordNotUnique
	            # sometimes multiple different requests are trying to do this at the same time and another will succeed first
	            # so let's actually grab the existing one out of the db
	            return self.find_or_make(url)
	          end
		else
			urlObj = urls[0] # should only be one, because enforce uniqueness
		end
		return urlObj
  end

end
