class DatasetValue < ActiveRecord::Base

  def self.find_or_make(text)
  		text_hash = nil
  		if (text.nil?)
  			text_hash = nil
  		else
  			text_hash = Digest::SHA1.hexdigest(text)
  		end
		values = DatasetValue.where({text_hash: text_hash, text: text})
		valueObj = nil
		if values.length == 0
	          begin
				valueObj = DatasetValue.create({text: text, text_hash: text_hash})
	          rescue ActiveRecord::RecordNotUnique
	            # sometimes multiple different requests are trying to do this at the same time and another will succeed first
	            # so let's actually grab the existing one out of the db
	            return self.find_or_make(text)
	          end
		else
			valueObj = values[0] # should only be one, because enforce uniqueness
		end
		return valueObj
  end

  def self.add_text_hashes_to_rows_that_lack_them()
  	DatasetValue.find_each do |value|
	  if value[:text_hash].nil?
	  	value[:text_hash] = Digest::SHA1.hexdigest(value[:text])
	  	value.save()
	  end
	end
  end

end
