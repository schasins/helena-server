class DatasetValue < ActiveRecord::Base

  def self.find_or_make(text)
  		hash = Digest::SHA1.hexdigest(text)
		values = DatasetValue.where({hash: hash, text: text})
		valueObj = nil
		if values.length == 0
			valueObj = DatasetValue.create({text: text, hash: hash})
		else
			valueObj = values[0] # should only be one, because enforce uniqueness
		end
		return valueObj
  end

end
