class MainController < ApplicationController
  def hello
  	@requests = Request.find_requests
  end

end
