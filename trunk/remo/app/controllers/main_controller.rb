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
    in_place_edit_for :request, column.name
  end 

  Header.content_columns.each do |column|
    in_place_edit_for :header, column.name
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

  end

  def remove_header

    begin
      @request_id = Header.find(params[:id]).request_id
      @name = Header.find(params[:id]).name
      Header.delete(params[:id])
    rescue => err
      flash[:notice] = "Removing failed! " + err
    end

  end

  def set_header_name
    
    unless params[:value].nil?
      begin
        @header = Header.find(params[:id])
        @name_save = @header.name
        @header.name = params[:value] 

        @header.save!
      rescue => err
        flash[:notice] = "Setting name failed! " + err
      end
    else
      flash[:notice] = "No value submitted!"
    end

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

end
