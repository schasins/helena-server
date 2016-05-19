class Url < ActiveRecord::Base
  belongs_to :domain

  def self.find_or_make(url)
		urls = Url.where(url: url)
		urlObj = nil
		if urls.length == 0
			domain = Domain.find_or_create_by(domain: Domain.domain_of_url(url))
			urlObj = Url.create({url: url, domain: domain})
		else
			urlObj = urls[0] # should only be one, because enforce uniqueness
		end
		return urlObj
  end

end
