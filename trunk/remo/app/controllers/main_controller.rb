class MainController < ApplicationController
  def redirect_to_hello(id, ok = false, msg = nil)
  	flash[:notice] = msg if msg
	if ok
	  	flash[:ok] = true
	else
  		flash[:ok] = false
	end
	
	if id 
		redirect_to :action => :hello, :id => id
	else
		redirect_to :action => :hello
	end

  end

  def hello
  	@requests = Request.find_requests

	@detail_request = nil
	unless params[:id].nil?
  		begin
			@detail_request = Request.find(params[:id])
		rescue ActiveRecord::RecordNotFound
			logger.error("Attempt to access invalid request record #{params[:id]}")
			flash[:notice] = "Attempt to access invalid request record #{params[:id]}"
		end
	end

	@rules_status = nil
	if flash[:notice]
		@rules_status = flash[:notice]
	elsif not params[:id].nil?
		@rules_status = "Selected request item #{params[:id]}"
	else
		@rules_status = "Status: active"
	end


  end

  def display_detail
  	begin
		@detail_request = Request.find(params[:id])
	rescue ActiveRecord::RecordNotFound
		logger.error("Attempt to access invalid request record #{params[:id]}")
		flash[:notice] = "Attempt to access invalid request record #{params[:id]}"
	end
  end

  def update_request
	begin
		@detail_request = Request.find(params[:update_id])
	rescue ActiveRecord::RecordNotFound
		logger.error("Attempt to access invalid request record #{params[:update_id]}")
		redirect_to_hello 0, false, "Record could not be saved."
	end
	
	@detail_request.http_method = params[:update_http_method]
	@detail_request.path = params[:update_path]
	@detail_request.weight = params[:update_weight]

	begin
		@detail_request.save!
		redirect_to_hello params[:update_id], true, "Successfully saved item #{params[:update_id]}!"
	rescue => err
		redirect_to_hello params[:update_id], false, "Saving failed! " + err
	end
  end
end
