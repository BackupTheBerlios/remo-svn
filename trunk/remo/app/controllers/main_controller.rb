class MainController < ApplicationController
  def hello
  	@requests = Request.find_requests
	@detail_request = Request.find(params[:id]) unless params[:id].nil?
  end

  def display_detail
  	begin
		@detailrequest = Request.find(params[:id])
	rescue ActiveRecord::RecordNotFound
		logger.error("Attempt to access invalid request record #{params[:id]}")
	end
  end
end
