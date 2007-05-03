require File.dirname(__FILE__) + '/../../remo_config'
require 'helpers/various'
require "rules_generator/main"

ActionController::Base.send :include, RespondsToParent

class MainController < ApplicationController

  VALID_ACTIONS_DETAILAREA = ["clear", "add", "save", "delete"]
  RULES_TOOLSET_BUTTONS = [
      # the partial display does not work with the form: array[ hash1, hash2, ...]
      # so we are using array[array1, array2, ...]
      [ "add_request",            # htmlid
        "add_request",            # link
        "/add_request.png",       # image path
        "add http request",       # tooltip
        "new request",            # button label
        true],                    # ajax request (inline display of javascript result)

      [ "generate_ruleset",       # htmlid
        "generate_ruleset",       # link
        "/generate.png",          # image path
        "generate ruleset",       # tooltip
        "generate",               # button label
        false]                    # ajax request (inline display of javascript result)
  ]
  SOURCE_TOOLSET_BUTTONS = [
      # the partial display does not work with the form: array[ hash1, hash2, ...]
      # so we are using array[array1, array2, ...]
      [ "load_logfile",           # htmlid
        "load_logfile",           # link
        "/load_logfile.png",      # image path
        "load logfile",           # tooltip
        "load logfile",           # button label
        true],                    # ajax request (inline display of javascript result)
      [ "clean_logfile_area",     # htmlid
        "clean_logfile_area",     # link
        "/clean_logfile_area.png", # image path
        "clean logfile area and show list of logfiles",     # tooltip
        "clean logfile area",     # button label
        true],                    # ajax request (inline display of javascript result)
  ]


  Request.content_columns.each do |column|
    extended_in_place_edit_for :request, column.name
  end 

  Header.content_columns.each do |column|
    extended_in_place_edit_for :header, column.name
  end  

  Cookieparameter.content_columns.each do |column|
    extended_in_place_edit_for :cookieparameter, column.name
  end  

  Postparameter.content_columns.each do |column|
    extended_in_place_edit_for :postparameter, column.name
  end  

  Querystringparameter.content_columns.each do |column|
    extended_in_place_edit_for :querystringparameter, column.name
  end  

  def index
    @requests = Request.find_requests
    @rules_status = "Status: active"

    @logfiles = Logfile.find(:all)

    if flash[:notice]
      @rules_status = flash[:notice]
    end

    @rules_toolset_buttons = RULES_TOOLSET_BUTTONS
    @source_toolset_buttons = SOURCE_TOOLSET_BUTTONS

  end

  def load_logfile
  end

  def load_logfile_action
    require "#{RAILS_ROOT}/lib/logfile"

    @logfile = Logfile.create(params[:logfile])
    @logfile = Logfile.find(@logfile.id) unless @logfile.id.nil? # has to be reloaded, otherwise the @logfile.content is empty
    responds_to_parent do
      # this is a special module in lib/responds_to_parent.rb
      render :update do |page|
        # we have to render this locally. actually I just do know how to move it into an rjs file
        page.replace_html("source-toolsetarea-content", "<div id=\"source-toolsetarea-content\"></div>")
        page.insert_html(:bottom, "source-toolsetarea-content",  render(:partial => "source_toolset", :collection => SOURCE_TOOLSET_BUTTONS))
        unless @logfile.content.nil?
          string = get_html_display_logfile(@logfile) # from main_helper
          page.replace_html("source-mainarea-content",  string)
        end
      end
    end
  end

  def remove_logfile
    begin
      Logfile.delete(params[:id])
    rescue => err
      flash[:notice] = "Removing failed! " + err
    end
  end

  def clean_logfile_area
    @logfiles = Logfile.find(:all)
  end

  def display_logfile
    @logfile = Logfile.find(params[:id])
  end

  def rearrange_requests

    if params["rules-mainarea-sortlist"].nil?
      logger.error("Rearrange_requests called without order array.")
    else
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

  end

  def add_request

      begin
        new_weight = Request.find(:first, :order => "weight DESC").weight + 1
      rescue
        new_weight = 1
      end
      
      @request = Request.new(:http_method => "GET",
                             :path => "click-to-edit",
                             :weight => new_weight, # max(weight) + 1
                             :remarks => "click-to-edit")

      begin
        @request.save!
      rescue => err
        flash[:notice] = "Adding failed! " + err
      end

      unless @request.id.nil?
        begin
          add_standard_headers(@request.id)
        rescue => err
          flash[:notice] = "Adding failed! " + err
          Request.delete(@request.id)
        end
      end

  end

  def remove_request

    begin
      Request.delete(params[:id])
      Header.delete_all(['request_id = ?' , params[:id]])
      Postparameter.delete_all(['request_id = ?' , params[:id]])
      Querystringparameter.delete_all(['request_id = ?' , params[:id]])
      Cookieparameter.delete_all(['request_id = ?' , params[:id]])
    rescue => err
      flash[:notice] = "Removing failed! " + err
    end

  end

  def set_request_http_method
    # in place select edit
    
    request = Request.find(params[:id])
    http_method_save = request.http_method

    unless params[:value].nil? || params[:value].size == 0 || MainHelper::HTTP_METHODS.select { |e| e == params[:value] }.size == 0
      begin
        request.http_method = params[:value] 
        request.save!
      rescue => err
        flash[:notice] = "Setting http_method failed! " + err
        request.http_method = http_method_save
      end
    else
      logger.error "Invalid form submission. Value: #{params[:value]}"
    end

    render(:text => request.http_method)

  end

  def add_header

    if Request.find(:all, :conditions => "id = #{params[:id]}").size > 0
      @header = Header.new(:request_id => params[:id], 
                           :name => "click-to-edit", 
                           :standard_domain => "click-to-edit",
                           :custom_domain => "\\d",
                           :domain_status_code => "Default",
                           :domain_location => "click-to-edit",
                           :mandatory_status_code => "Default",
                           :mandatory_location => "click-to-edit")
      begin
        @header.save!
      rescue => err
        flash[:notice] = "Adding header failed! " + err
      end

    else
        flash[:notice] = "Adding header failed! Request #{params[:id]} is not existing." 
    end

    render_add_requestparameter @header, "header", MainHelper::HEADER_DOMAINS, MainHelper::HTTP_STATUS_CODES_WITH_DEFAULT

  end

  def remove_header
    id = params[:id]
    begin
      @request_id = Header.find(id).request_id
      @name = Header.find(id).name
      Header.delete(id)
    rescue => err
      flash[:notice] = "Removing failed! " + err
    end

    remove_requestparameter Header, id

  end

  def set_headerparameter_standard_domain
    set_requestparameter_standard_domain(params[:id], params[:value], Headerparameter, MainHelper::HEADER_DOMAINS)
  end
  def set_cookieparameter_standard_domain
    set_requestparameter_standard_domain(params[:id], params[:value], Cookieparameter, MainHelper::COOKIE_DOMAINS)
  end  
  def set_querystringparameter_standard_domain
    set_requestparameter_standard_domain(params[:id], params[:value], Querystringparameter, MainHelper::QUERY_STRING_DOMAINS)
  end
  def set_postparameter_standard_domain
    set_requestparameter_standard_domain(params[:id], params[:value], Postparameter, MainHelper::POST_DOMAINS)
  end

  def set_requestparameter_standard_domain (id, value, model, value_domain)
    # in place select edit
    
    record = model.find(id)
    domain_save = record.standard_domain

    display = nil

    unless value.nil? || value.size == 0 || value_domain.select { |e| e == value }.size == 0
      begin
        record.standard_domain = value
        record.save!
      rescue => err
        flash[:notice] = "Setting parameter failed! " + err
        record.domain = domain_save
      end
    else
      logger.error "Invalid form submission. Value: #{value}"
    end

    render(:text => value )

  end

  def set_cookieparameter_domain_custom
    set_requestparameter_domain_custom(params[:id], params[:value], Cookieparameter)
  end

  def set_requestparameter_domain_custom (id, value, model)
    # in place select edit
    
    record = model.find(id)
    domain_save = record.domain

    display = nil

    unless value.nil? || value.size == 0 
      begin
        record.domain = value
        record.save!
      rescue => err
        flash[:notice] = "Setting parameter failed! " + err
        record.domain = domain_save
      end
    else
      logger.error "Invalid form submission. Value: #{value}"
    end

    render(:text => value)

  end

  def add_postparameter

    if Request.find(:all, :conditions => "id = #{params[:id]}").size > 0
      @postparameter = Postparameter.new(:request_id => params[:id], 
                           :name => "click-to-edit", 
                           :standard_domain => "click-to-edit",
                           :custom_domain => "\\d",
                           :domain_status_code => "Default",
                           :domain_location => "click-to-edit",
                           :mandatory_status_code => "Default",
                           :mandatory_location => "click-to-edit")
      begin
        @postparameter.save!
      rescue => err
        flash[:notice] = "Adding postparameter failed! " + err
      end

    else
        flash[:notice] = "Adding postparameter failed! Request #{params[:id]} is not existing." 
    end

    render_add_requestparameter @postparameter, "postparameter", MainHelper::POST_DOMAINS, MainHelper::HTTP_STATUS_CODES_WITH_DEFAULT

  end

  def add_querystringparameter

    if Request.find(:all, :conditions => "id = #{params[:id]}").size > 0
      @querystringparameter = Querystringparameter.new(:request_id => params[:id], 
                           :name => "click-to-edit", 
                           :standard_domain => "click-to-edit",
                           :custom_domain => "\\d",
                           :domain_status_code => "Default",
                           :domain_location => "click-to-edit",
                           :mandatory_status_code => "Default",
                           :mandatory_location => "click-to-edit")
      begin
        @querystringparameter.save!
      rescue => err
        flash[:notice] = "Adding querystringparameter failed! " + err
      end

    else
        flash[:notice] = "Adding querystringparameter failed! Request #{params[:id]} is not existing." 
    end

    render_add_requestparameter @querystringparameter, "querystringparameter", MainHelper::QUERY_STRING_DOMAINS, MainHelper::HTTP_STATUS_CODES_WITH_DEFAULT 

  end

  def add_cookieparameter

    if Request.find(:all, :conditions => "id = #{params[:id]}").size > 0
      @cookieparameter = Cookieparameter.new(:request_id => params[:id], 
                           :name => "click-to-edit", 
                           :standard_domain => "click-to-edit",
                           :custom_domain => "\\d",
                           :domain_status_code => "Default",
                           :domain_location => "click-to-edit",
                           :mandatory_status_code => "Default",
                           :mandatory_location => "click-to-edit")      
      begin
        @cookieparameter.save!
      rescue => err
        flash[:notice] = "Adding cookieparameter failed! " + err
      end

    else
        flash[:notice] = "Adding cookieparameter failed! Request #{params[:id]} is not existing." 
    end

    render_add_requestparameter @cookieparameter, "cookieparameter", MainHelper::COOKIE_DOMAINS, MainHelper::HTTP_STATUS_CODES_WITH_DEFAULT 

  end

  def remove_postparameter
    id = params[:id]

    begin
      @request_id = Postparameter.find(id).request_id
      @name = Postparameter.find(id).name
      Postparameter.delete(id)
    rescue => err
      flash[:notice] = "Removing failed! " + err
    end

    remove_requestparameter Postparameter, id

  end

  def remove_querystringparameter
    id = params[:id]

    begin
      @request_id = Querystringparameter.find(id).request_id
      @name = Querystringparameter.find(id).name
      Querystringparameter.delete(id)
    rescue => err
      flash[:notice] = "Removing failed! " + err
    end

    remove_requestparameter Querystringparameter, id

  end

  def remove_cookieparameter
    id = params[:id]

    begin
      @request_id = Cookieparameter.find(id).request_id
      @name = Cookieparameter.find(id).name
      Cookieparameter.delete(id)
    rescue => err
      flash[:notice] = "Removing failed! " + err
    end

    remove_requestparameter Cookieparameter, id

  end

  def set_header_name
    # the header name is "click-to-edit" by default. It can be updated to a real name. But only once.
    
    @header = Header.find(params[:id])
    @name_save = @header.name
    unless params[:value].nil? || params[:value].size == 0
      begin
        @header.name = params[:value] 

        @header.save!
      rescue => err
        flash[:notice] = "Setting name failed! " + err
        @header.name = @name_save
      end
    end

    render_set_requestparameter_name @header, "header", @name_save, MainHelper::HEADER_DOMAINS, MainHelper::HTTP_STATUS_CODES_WITH_DEFAULT 

  end

  def set_cookieparameter_name
    # the cookieparameter name is "click-to-edit" by default. It can be updated to a real name. But only once.
    
    @cookieparameter = Cookieparameter.find(params[:id])
    @name_save = @cookieparameter.name
    unless params[:value].nil? || params[:value].size == 0
      begin
        @cookieparameter.name = params[:value] 

        @cookieparameter.save!
      rescue => err
        flash[:notice] = "Setting name failed! " + err
        @cookieparameter.name = @name_save
      end
    end

    render_set_requestparameter_name @cookieparameter, "cookieparameter", @name_save, MainHelper::COOKIE_DOMAINS, MainHelper::HTTP_STATUS_CODES_WITH_DEFAULT 
  end

  def set_querystringparameter_name
    # the querystringparameter name is "click-to-edit" by default. It can be updated to a real name. But only once.
    
    @querystringparameter = Querystringparameter.find(params[:id])
    @name_save = @querystringparameter.name
    unless params[:value].nil? || params[:value].size == 0
      begin
        @querystringparameter.name = params[:value] 

        @querystringparameter.save!
      rescue => err
        flash[:notice] = "Setting name failed! " + err
        @querystringparameter.name = @name_save
      end
    end

    render_set_requestparameter_name @querystringparameter, "querystringparameter", @name_save, MainHelper::QUERY_STRING_DOMAINS, MainHelper::HTTP_STATUS_CODES_WITH_DEFAULT 
  end

  def set_postparameter_name
    # the postparameter name is "click-to-edit" by default. It can be updated to a real name. But only once.
    
    @postparameter = Postparameter.find(params[:id])
    @name_save = @postparameter.name
    unless params[:value].nil? || params[:value].size == 0
      begin
        @postparameter.name = params[:value] 

        @postparameter.save!
      rescue => err
        flash[:notice] = "Setting name failed! " + err
        @postparameter.name = @name_save
      end
    end

    render_set_requestparameter_name @postparameter, "postparameter", @name_save, MainHelper::POST_DOMAINS, MainHelper::HTTP_STATUS_CODES_WITH_DEFAULT 
  end

  def toggle_header_mandatory
    toggle_requestparameter_mandatory(Header, params[:id])
  end 
  def toggle_cookieparameter_mandatory
    toggle_requestparameter_mandatory(Cookieparameter, params[:id])
  end
  def toggle_querystringparameter_mandatory
    toggle_requestparameter_mandatory(Querystringparameter, params[:id])
  end
  def toggle_postparameter_mandatory
    toggle_requestparameter_mandatory(Postparameter, params[:id])
  end

  def generate_ruleset
    
    filename = generate(request, get_release_version)
    send_file(filename, :type => "text/ascii") if FileTest::exists?(filename)

  end


  private


  def add_standard_headers (request_id)

    DEFAULT_HEADERS.each do |item|
      @header = Header.new(:request_id => request_id, 
                           :name => item.keys[0],
                           :standard_domain => item.values[0][0],
                           :custom_domain => item.values[0][1],
                           :domain_status_code => "Default",
                           :domain_location => "click-to-edit",
                           :mandatory_status_code => "Default",
                           :mandatory_location => "click-to-edit")
      @header.save!
    end

  end

  def remove_requestparameter (model, id)

    @requestparametername = model.name.downcase # parameters have to be passed to rjs as instance variables.
    @id = id

    render(:template => "main/remove_requestparameter") 

  end

  def render_add_requestparameter (requestparameter, requestparametername, domainarray, statuscodearray)

    @requestparameter = requestparameter    # parameters have to be passed to rjs as instance variables.
    @requestparametername = requestparametername
    @domainarray = domainarray 
    @statuscodearray = statuscodearray 

    render(:template => "main/add_requestparameter")
  
  end


  def render_set_requestparameter_name (requestparameter, requestparametername, name_save, domainarray, statuscodearray)

    @requestparameter = requestparameter    # parameters have to be passed to rjs as instance variables.
    @requestparametername = requestparametername
    @name_save = name_save
    @domainarray = domainarray 
    @statuscodearray = statuscodearray 

    render(:template => "main/set_requestparameter_name") 
 
  end

  def toggle_requestparameter_mandatory (model, id)
    unless id.nil?
      begin
        @item = model.find(params[:id])
        @item.mandatory = !@item.mandatory
        @item.save!
        if @item.mandatory
          @string = "mandatory"
        else
          @string = "optional"
        end
      rescue => err
        flash[:notice] = "Toggling mandatory status failed! " + err
      end
    end
    @requestparametername = model.name.downcase
    render(:template => "main/toggle_requestparameter_mandatory")
  end

end
