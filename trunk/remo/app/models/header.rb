class Header < ActiveRecord::Base
  belongs_to :request

  validates_presence_of :request_id
  validates_presence_of :name

  def self.find_headers
    find(:all)
  end
end
