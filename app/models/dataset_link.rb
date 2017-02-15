class DatasetLink < ActiveRecord::Base

  def self.find_or_make(linkText)
		values = DatasetLink.where({link: linkText})
		valueObj = nil
		if values.length == 0
                  begin
                    valueObj = DatasetLink.create({link: linkText})
                  rescue ActiveRecord::RecordNotUnique
                    # sometimes multiple different requests are trying to do this at the same time and another will succeed first
                    # so let's actually grab the existing one out of the db
                    # todo: actually all my other custom find_or_make methods should do this same thing
                    # ActiveRecord::Base.connection.execute 'ROLLBACK'
                    return self.find_or_make(linkText)
                  end
		else
			valueObj = values[0] # should only be one, because enforce uniqueness
		end
		return valueObj
  end

end
