class MainController < ApplicationController
  REMO_VERSION = "0.0.1"
  VALID_ACTIONS_DETAILAREA = ["clear", "add", "save", "delete"]
  RULES_TOOLSET_BUTTONS = [
      # the partial display does not work with the form: array[ hash1, hash2, ...]
      # so we are using array[array1, array2, ...]
      [ "generate_ruleset",       # htmlid
        "generate_ruleset",       # link
        "/generate.png",          # image path
        "generate ruleset" ]      # title
  ]

  REQUEST_DETAIL_FIELDS = [
    { "host" => "Host" },
    { "user_agent" => "User-Agent"},
    { "referer" => "Referer"},
    { "accept" => "Accept"},
    { "accept_language" => "Accept-Language"},
    { "accept_encoding" => "Accept-Encoding"},
    { "accept_charset" => "Accept-Charset"},
    { "keep_alive" => "Keep-Alive"},
    { "guiprefix_connection" => "Connection"},
    { "content_type" => "Content-Type"},
    { "content_length" => "Content-Length"},
    { "cookie" => "Cookie"},
    { "pragma" => "Pragma"},
    { "cache_control" => "Cache-Control"},
    { "remarks" => "Remarks"}
  ]

  Request.content_columns.each do |column|
    in_place_edit_for :request, column.name
  end 
  
  before_filter :set_request_detail_fields  # this sets the @request_detail_fields variable 
                                            # needed inside the _request partial. This is the
                                            # preferred way of passing it.
                                                

  def index
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

    @rules_toolset_buttons = RULES_TOOLSET_BUTTONS

  end

  def display_detailarea
    begin
      @detail_request = Request.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      logger.error("Attempt to access invalid request record #{params[:id]}")
      flash[:notice] = "Attempt to access invalid request record #{params[:id]}"
      @detail_request = Request.new(:weight => "")
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
      begin
        new_weight = Request.find(:first, :order => "weight DESC").weight + 1
      rescue
        new_weight = 1
      end
      @detail_request = Request.new(:http_method => params[:update_http_method],
                                    :path => params[:update_path],
                                    :weight => new_weight, # max(weight) + 1
                                    :remarks => params[:update_remarks])
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
        @detail_request.remarks = params[:update_remarks]
        logger.error("#{params[:update_remarks]}")
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

  def rearrange_requests
    if params["rules-mainarea-sortlist"].nil?
      logger.error("Rearrange_requests called without order array.")
      return
    end
    orderlist = params["rules-mainarea-sortlist"]

    @rearrangefail = false

    1.upto(orderlist.size) do |i|
      begin
        request = Request.find(orderlist[i-1])
        request.weight = i
        request.save!
      rescue => err
        logger.error("Rearranging error on item #{orderlist[i-1]}! " + err)
        # FIXME: not writing flash notice here. It would be very cumbersome to interacting with visibility of the item. Also there
        # are likely to be multiple errors...
        # See task http://remo.netnea.com/twiki/bin/view/Main/Task18Start
        @rearrangefail = true
      end
    end

  end

  def generate_ruleset
    require "rules_generator/main"

    filename = generate(request, REMO_VERSION)
    send_file(filename, :type => "text/ascii") if FileTest::exists?(filename)
  end


  private


    def set_request_detail_fields
      # this sets the @request_detail_fields variable 
      # needed inside the _request partial. This is the
      # preferred way of passing it.
      @request_detail_fields = REQUEST_DETAIL_FIELDS
    end

end
