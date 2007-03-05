class Cookieparameter < ActiveRecord::Base
  belongs_to :request

  validates_presence_of :request_id
  validates_presence_of :name

  def self.find_cookieparameters
    find(:all)
  end
end
