require File.dirname(__FILE__) + '/../../remo_config'
require 'helpers/various'
require "rules_generator/main"

class MainController < ApplicationController

  VALID_ACTIONS_DETAILAREA = ["clear", "add", "save", "delete"]
  RULES_TOOLSET_BUTTONS = [
      # the partial display does not work with the form: array[ hash1, hash2, ...]
      # so we are using array[array1, array2, ...]
      [ "add_request",            # htmlid
        "add_request",            # link
        "/add_request.png",       # image path
        "add http request",       # tooltip
        "new request",                    # button label
        true],                    # ajax request (inline display of javascript result)

      [ "generate_ruleset",       # htmlid
        "generate_ruleset",       # link
        "/generate.png",          # image path
        "generate ruleset",       # tooltip
        "generate",               # button label
        false]                    # ajax request (inline display of javascript result)
  ]


  Request.content_columns.each do |column|
    extended_in_place_edit_for :request, column.name
  end 

  Header.content_columns.each do |column|
    extended_in_place_edit_for :header, column.name
  end  

  Postparameter.content_columns.each do |column|
    extended_in_place_edit_for :postparameter, column.name
  end  


  def index

    @requests = Request.find_requests

    @rules_status = "Status: active"

    if flash[:notice]
      @rules_status = flash[:notice]
    end

    @rules_toolset_buttons = RULES_TOOLSET_BUTTONS

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
    rescue => err
      flash[:notice] = "Removing failed! " + err
    end

  end

  def add_header

    if Request.find(:all, :conditions => "id = #{params[:id]}").size > 0
      @header = Header.new(:request_id => params[:id], 
                           :name => "click-to-edit", 
                           :domain => ".*")
      begin
        @header.save!
      rescue => err
        flash[:notice] = "Adding header failed! " + err
      end

    else
        flash[:notice] = "Adding header failed! Request #{params[:id]} is not existing." 
    end

    render_add_requestparameter @header, "header"

  end

  def remove_header

    remove_requestparameter Header, params[:id]

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

    render_set_requestparameter_name @header, "header", @name_save

  end


  def add_postparameter

    if Request.find(:all, :conditions => "id = #{params[:id]}").size > 0
      @postparameter = Postparameter.new(:request_id => params[:id], 
                           :name => "click-to-edit", 
                           :domain => ".*")
      begin
        @postparameter.save!
      rescue => err
        flash[:notice] = "Adding postparameter failed! " + err
      end

    else
        flash[:notice] = "Adding postparameter failed! Request #{params[:id]} is not existing." 
    end

    render_add_requestparameter @postparameter, "postparameter"

  end

  def remove_postparameter

    remove_requestparameter Postparameter, params[:id]

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

    render_set_requestparameter_name @postparameter, "postparameter", @name_save
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
                           :domain => item.values[0])
      @header.save!
    end

  end

  def remove_requestparameter (model, id)
    # this is a generic function to remove a request parameter
    # i tried to do the same with the "add" and the "set_name" too, but it would not work 
    # due to scope problems with partials and such (page_insert is the problem)
    # as remove does not need a page_insert code can here be simplified and a
    # generic routine can be used.
    begin
      request_id = model.find(id).request_id
      name = model.find(id).name
      model.delete(id)
    rescue => err
      flash[:notice] = "Removing failed! " + err
    end
    
    render_remove_requestparameter request_id, id, name, model.name.downcase

  end

  def render_add_requestparameter (requestparameter, requestparametername)

    require "#{RAILS_ROOT}/app/views/main/lib/display"

    render(:update) do |page|

      # handle flash notice div. flash[:before] is written in the main controller
      if flash[:notice].nil? and ! flash[:before].nil?        
        page["flash-notice"].visual_effect :blind_up        # no error anymore
      elsif ! flash[:notice].nil? and flash[:before].nil?  
        page["flash-notice"].visual_effect :blind_down      # new error
      elsif ! flash[:notice].nil? and ! flash[:before].nil? 
        page["flash-notice"].visual_effect :highlight      # new error
      end

      if flash[:notice].nil?
        page.insert_html(:bottom, "request-item_#{requestparameter.request_id}_#{requestparametername}s",  :partial => "requestparameter", :object => requestparameter, :locals => { :requestparametername => requestparametername})
        page["request-item_#{requestparameter.request_id}_#{requestparametername}s_header"].visual_effect :highlight
        statusmessage = "Successfully added new #{requestparametername}"
      else
        statusmessage = flash[:notice]
      end
      page.replace_html("rules-statusarea", "<div>#{statusmessage}</div>" )
    end

  end

  def render_remove_requestparameter (request_id, item_id, name, requestparametername)

    require "#{RAILS_ROOT}/app/views/main/lib/display"

    render(:update) do |page|

      # handle flash notice div. flash[:before] is written in the main controller
      if flash[:notice].nil? and ! flash[:before].nil?        
        page["flash-notice"].visual_effect :blind_up        # no error anymore
      elsif ! flash[:notice].nil? and flash[:before].nil?  
        page["flash-notice"].visual_effect :blind_down      # new error
      elsif ! flash[:notice].nil? and ! flash[:before].nil? 
        page["flash-notice"].visual_effect :highlight      # new error
      end

      page.replace_html("flash-notice", "<div>#{flash[:notice]}</div>")

      if flash[:notice].nil?
        page.remove "request-item_#{request_id}-#{name}-#{item_id}" if flash[:notice].nil?
        statusmessage = "Successfully removed #{requestparametername} item #{request_id}, #{name}!" 
      else
        statusmessage = flash[:notice]
      end

      page.replace_html("rules-statusarea", "<div>#{statusmessage}</div>" )

      page.sortable 'rules-mainarea-sortlist', :url => {:action => "rearrange_requests"} 

    end
  end

  def render_set_requestparameter_name (requestparameter, requestparametername, name_save)

    require "#{RAILS_ROOT}/app/views/main/lib/display"

    render(:update) do |page|


      # handle flash notice div. flash[:before] is written in the main controller
      if flash[:notice].nil? and ! flash[:before].nil?        
        page["flash-notice"].visual_effect :blind_up        # no error anymore
      elsif ! flash[:notice].nil? and flash[:before].nil?  
        page["flash-notice"].visual_effect :blind_down      # new error
      elsif ! flash[:notice].nil? and ! flash[:before].nil? 
        page["flash-notice"].visual_effect :highlight      # new error
      end

      page.replace_html("flash-notice", "<div>#{flash[:notice]}</div>")

      if flash[:notice].nil?
        page.remove("request-item_#{requestparameter.request_id}-#{name_save}-#{requestparameter.id}")
        page.insert_html(:bottom, "request-item_#{requestparameter.request_id}_#{requestparametername}s",  :partial => "requestparameter", :object => requestparameter, :locals => { :requestparametername => requestparametername})
        statusmessage = "Successfully updated #{requestparametername} name #{requestparameter.request_id}, #{name_save} to #{requestparameter.name}!" 
      else
        statusmessage = flash[:notice]
      end

      page.replace_html("rules-statusarea", "<div>#{statusmessage}</div>" )

      page.sortable 'rules-mainarea-sortlist', :url => {:action => "rearrange_requests"} 

    end

  end

end
