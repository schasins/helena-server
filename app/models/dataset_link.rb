class DatasetLink < ActiveRecord::Base

  def self.find_or_make(link)
		values = DatasetLink.where({link: link})
		valueObj = nil
		if values.length == 0
			valueObj = DatasetLink.create({link: link})
		else
			valueObj = values[0] # should only be one, because enforce uniqueness
		end
		return valueObj
  end

end
