class DatasetValue < ActiveRecord::Base

  def self.find_or_make(text)
		values = DatasetValue.where(text: text)
		valueObj = nil
		if values.length == 0
			valueObj = DatasetValue.create({text: text})
		else
			valueObj = values[0] # should only be one, because enforce uniqueness
		end
		return valueObj
  end

end
