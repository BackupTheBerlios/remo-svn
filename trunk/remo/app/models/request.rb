class Request < ActiveRecord::Base
  VALID_HTTP_METHODS = ["GET", "POST", "HEAD", "TRACE", "PUT", "DELETE", "CONNECT", "OPTIONS"]

  attr_accessible :http_method, :path, :weight, :remarks

  validates_presence_of :http_method, :path, :weight
  validates_numericality_of :weight

  def validate
    # make sure only valid http methods are used
    if VALID_HTTP_METHODS.select { |e| e == http_method }.size == 0
      errors.add(:http_method, "has to be a valid http method, i.e. GET, PUT, etc.") 
    end
  end

  def self.find_requests
    find(:all, :order => "weight")
  end
end
