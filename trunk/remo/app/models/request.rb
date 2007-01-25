class Request < ActiveRecord::Base
	validates_presence_of :http_method, :path, :weight
	validates_numericality_of :weight
	validates_uniqueness_of  :weight

	def validate
		# make sure only valid http methods are used
		if ["GET", "POST", "HEAD", "TRACE", "PUT", "DELETE", "CONNECT", "OPTIONS"].select { |e| e == http_method }.size == 0
			errors.add(:http_method, "has to be a valid http method, i.e. GET, PUT, etc.") 
		end
	end

end
