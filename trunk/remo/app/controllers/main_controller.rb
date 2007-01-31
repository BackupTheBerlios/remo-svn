class MainController < ApplicationController
  ACTIONS_DETAILAREA = ["clear", "add", "save", "delete"]

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

  def submit_detailarea
  	# Forminput validation
	if ACTIONS_DETAILAREA.select { |e| e == params[:actionflag]}.size == 0
		logger.error("Attempt to post illegal form actionflag. Manual manipulation of hidden form field.")
		redirect_to_hello nil, false, "Form submission error. Actionflag is illegal: #{params[:actionflag]}"
		return
	end
	
	if params[:actionflag] != "add" && params[:actionflag] != "clear"
		if params[:update_id].nil?  || params[:update_id].to_i.to_s != params[:update_id] # id not a valid integer
			redirect_to_hello nil, false, "Can't execute action. You have not submitted a valid request id to be handled." 
			return
		end
	end

	# The rest of the attributes can be accepted without problem, 
	# as the save method will take care of correct quoting of dangerous input.

	case params[:actionflag]
		when "clear"
			redirect_to_hello nil, false
		when "add"
			@detail_request = Request.new(	:http_method => params[:update_http_method],
							:path => params[:update_path],
							:weight => params[:update_weight])
			begin
				@detail_request.save!
				redirect_to_hello @detail_request.id, true, "Successfully added new item #{@detail_request.id}!"
				return
			rescue => err
				redirect_to_hello nil, false, "Adding failed! " + err
				return
			end

		when "save"
			begin
				@detail_request = Request.find(params[:update_id])
			rescue ActiveRecord::RecordNotFound
				logger.error("Attempt to access invalid request record #{params[:update_id]}")
				redirect_to_hello nil, false, "Can't update. You have not selected a valid request to be updated. Requested id  #{params[:update_id]}." 
				return
			end

			@detail_request.http_method = params[:update_http_method] 
			@detail_request.path = params[:update_path]
			@detail_request.weight = params[:update_weight]

			begin
				@detail_request.save!
				redirect_to_hello params[:update_id], true, "Successfully saved item #{params[:update_id]}!"
				return
			rescue => err
				redirect_to_hello params[:update_id], false, "Saving failed! " + err
				return
			end

		when "delete"
			# Request lookup
			begin
				@detail_request = Request.find(params[:update_id])
			rescue ActiveRecord::RecordNotFound
				logger.error("Attempt to access invalid request record #{params[:update_id]}")
				redirect_to_hello nil, false, "Can't update. You have not selected a valid request to be updated. Requested id  #{params[:update_id]}." 
				return
			end
			
			begin
				Request.delete(params[:update_id])
				redirect_to_hello nil, true, "Successfully deleted item #{params[:update_id]}!"
				return
			rescue => err
				redirect_to_hello params[:update_id], false, "Removing failed! " + err
				return
			end
			@detail_request.save!
			
	end

	

  end
end
