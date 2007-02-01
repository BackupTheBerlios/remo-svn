class MainController < ApplicationController
  VALID_ACTIONS_DETAILAREA = ["clear", "add", "save", "delete"]

  def hello
    @requests = Request.find_requests

    unless params[:id].nil?
      begin
        @detail_request = Request.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        logger.error("Attempt to access invalid request record #{params[:id]}")
        flash[:notice] = "Attempt to access invalid request record #{params[:id]}"
        @detail_request = Request.new(:weight => "")
      end
    else
      @detail_request = Request.new(:weight => "")
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

  def display_detailarea
    begin
      @detail_request = Request.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      logger.error("Attempt to access invalid request record #{params[:id]}")
      flash[:notice] = "Attempt to access invalid request record #{params[:id]}"
    end
  end

  def submit_detailarea
    flash[:before] = flash[:notice]
    flash[:notice] = nil
    # Forminput validation
    if VALID_ACTIONS_DETAILAREA.select { |e| e == params[:actionflag]}.size == 0
      logger.error("Attempt to post illegal form actionflag. Manual manipulation of hidden form field.")
      flash[:notice] = "Form submission error. Actionflag is illegal: #{params[:actionflag]}"
      @detail_request = Request.new(:weight => "")
      return
    end

    if params[:actionflag] != "add" && params[:actionflag] != "clear"
      if params[:update_id].nil?  || params[:update_id].to_i.to_s != params[:update_id] # id not a valid integer
        flash[:notice] = "Can't execute action. You have not submitted a valid request id to be handled."
        @detail_request = Request.new(:weight => "")
        return
      end
    end

    # The rest of the attributes can be accepted without problem, 
    # as the save method will take care of correct quoting of dangerous input.

    case params[:actionflag]
    when "clear"
      @detail_request = Request.new(:weight => "")
    when "add"
      @detail_request = Request.new(:http_method => params[:update_http_method],
                                    :path => params[:update_path],
                                    :weight => params[:update_weight])
      begin
        @detail_request.save!
      rescue => err
        flash[:notice] = "Adding failed! " + err
      end

    when "save"
      # Request lookup / check
      begin
        @detail_request = Request.find(params[:update_id])
        @detail_request.http_method = params[:update_http_method] 
        @detail_request.path = params[:update_path]
        @detail_request.weight = params[:update_weight]
        @detail_request.save!
      rescue ActiveRecord::RecordNotFound
        logger.error("Attempt to access invalid request record #{params[:update_id]}")
        flash[:notice] = "Can't update. You have not selected a valid request to be updated. Requested id #{params[:update_id]}."
      rescue => err
        flash[:notice] = "Saving failed! " + err
      end

    when "delete"
      # Request lookup / check
      begin
        @detail_request = Request.find(params[:update_id])
        Request.delete(params[:update_id])
      rescue => err
        logger.error("Attempt to access invalid request record #{params[:update_id]}")
        flash[:notice] = "Removing failed! " + err
      end

    @detail_request = Request.new(:weight => "")

    end

    @requests = Request.find_requests

  end
end
