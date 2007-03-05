class Getparameter < ActiveRecord::Base
  belongs_to :request

  validates_presence_of :request_id
  validates_presence_of :name

  def self.find_getparameters
    find(:all)
  end
end
