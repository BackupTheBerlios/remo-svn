require File.dirname(__FILE__) + '/../test_helper'
require 'main_controller'

# Re-raise errors caught by the controller.
class MainController; def rescue_action(e) raise e end; end

class MainControllerTest < Test::Unit::TestCase
  def setup
    Request.delete_all

    @controller = MainController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    # setup the test data in the database. This will be deleted automatically after the test
    list = [[1, "GET",  "/myindex.html", 1],
                [2, "POST", "/action/post.php", 2],
                [3, "GET",  "/detail.html",   3],
                [4, "GET",  "/view,html",     4],
                [5, "GET",  "/detail.html",   5],
                [6, "GET",  "/index.html",    6],
                [7, "GET",  "/info.html",     7],
                [8, "POST", "/action/delete.php", 8]]

    list.each do |item|
                r = Request.create(:id           => item[0],
                                   :http_method  => item[1],
                                   :path         => item[2],
                                   :weight       => item[3])
                r.save!
    end

  end

  def test_flash_notice

    get :hello
    assert_equal nil, flash[:notice]
    assert_select "div.flash-nok", 1  # it is nok by default
    assert_select "div#rules-statusarea", "Status: active"

    get :hello, :id => "500011100"
    assert_equal "Attempt to access invalid request record 500011100", flash[:notice]
    assert_select "div.flash-nok", 1 

  end

  def test_hello_basic
    # test layout hello view without any parameters

    get :hello
    assert_response :success
    assert_template "hello"	
    assert_select "title", 1

    def assert_exist_elementlist (list, num=1)
    	list.each do |item|
		# check that item exists <num> of times in the page
    		assert_select item, num, "FAILURE: Page item " + item + " not found " + num.to_s + " time(s) as expected." 
	end
    end

    # make sure we have the correct set of page elements
    #   classes
    elements = ["div.maincolumn",
    		"div.detailarea", 
		"div.mainarea", 
		"div.statusarea"]
    assert_exist_elementlist elements, 2
    
    #   individual elements via id
    elements = ["div#banner", 
		"div#title",
		"div#logodiv",
		"div#flash-notice",
		"div#rules-mainarea",
		"div#source-mainarea",
		"div#banner",
		"div#title",
		"div#logodiv",
		"div#maindiv",
		"div#source",
		"div#source-toolsetarea",
		"div#source-detailarea",
		"div#source-mainarea",
		"div#source-statusarea",
		"div#rules",
		"div#rules-toolsetarea",
		"div#rules-detailarea",
		".submit",	# detailarea submit button
		"div#rules-mainarea",
		"div#rules-statusarea", 
		"div#rules-statusarea"]
    assert_exist_elementlist elements



    # check link to remo.netnea.com and www.modsecurity.org
    assert_select "div#title > h1 > a:first-child", /remo/
    assert_select "div#title > h1 > a[href=http://remo.netnea.com]", 1
    assert_select "div#title > h1 > a:nth-child(2)", /modsecurity/
    assert_select "div#title > h1 > a[href=http://www.modsecurity.org]", 1


    # check existence of logo
    assert_select "img#logo[src=/images/logo.png]", 1

 
    # the existence of all test data record items in page
    elements = []

    1.upto(8) do |n|
    	elements << "div#request-item-#{n}"
    	elements << "div#request-item-#{n}-http_method"
    	elements << "div#request-item-#{n}-path"
    end
    assert_exist_elementlist elements

    # check for detailarea form
    regexp = /<form(.*?)action="\/main\/submit_detailarea"(.*?)method="post"/
    assert false, "No detailarea form found."  if regexp.match(@response.body).nil?

    regexp = /<input id="actionflag" name="actionflag" type="hidden" value="add" \/>/
    assert false, "No proper detailarea form hidden field actionflag found."  if regexp.match(@response.body).nil?

    # check for existence and correct title of submit button detailarea
    regexp = /<input(.*?)type="submit"(.*?)value="Add request"(.*?)>/
    assert false, "No button found with button text: \"Add request\"."  if regexp.match(@response.body).nil?

    # check for non-existence submit button "Save request" in detailarea
    regexp = /<input(.*?)type="submit"(.*?)value="Save request"(.*?)>/
    assert true, "Button found with button text: \"Save request\"."  if regexp.match(@response.body).nil?

    # check for non-existence submit button "Update request" in detailarea
    regexp = /<input(.*?)type="submit"(.*?)value="Update request"(.*?)>/
    assert true, "Button found with button text: \"Update request\"."  if regexp.match(@response.body).nil?

    # check for non-existence submit button "Delete request" in detailarea
    regexp = /<input(.*?)type="submit"(.*?)value="Delete request"(.*?)>/
    assert true, "Button found with button text: \"Delete request\"."  if regexp.match(@response.body).nil?



    # request list: testing content of the first data item
    assert_select "div#request-item-1-lens a[href=/main/hello/1]", 1
    assert_select "div#request-item-1-http_method", 'GET'
    assert_select "div#request-item-1-path", '/myindex.html'

    # test for existence of javascript onclick link: we search for exactly 1 occurrence of a link with the 
    # onclick value matching the html sourcecode expected.
    # testing a http_method item and a path item will do
    assert_select "div#request-item-1-http_method a[onclick=new Ajax.Request('/main/display_detail/1', {asynchronous:true, evalScripts:true}); return false;]", 1
    assert_select "div#request-item-1-path a[onclick=new Ajax.Request('/main/display_detail/1', {asynchronous:true, evalScripts:true}); return false;]", 1

  end

  def test_display_hello_detail_selected
    # test of hello view with GET parameter id=1 (clicking on the lens in request list, thus loading view again with parameter)
    get :hello, :id => 1
    assert_response :success

    assert_template "hello"
    
    # two example items will do.
    assert_select "div.lens-selected a[href=/main/hello/1]", 1  # this one is the one called as GET parameter
    assert_select "div.lens a[href=/main/hello/2]", 1
  end

  def test_display_detail
    # test display_detail ajax request
    get :display_detail, :id => 1
    assert_response :success

    assert_template "display_detail"

    body = @response.body

    assert_match /Element.update\("rules-statusarea", "Selected request item 1"\);/, body

    # checking for http_method items will do 
    assert_match /\$\$\(".http_method-selected"\).each\(function\(value, index\) \{/, body
    assert_match /Element.addClassName\("request-item-1-http_method", "http_method-selected"\);/, body
    assert_match /Element.removeClassName\("request-item-1-http_method", "http_method"\);/, body
    
    # reset vim syntax highlighting with another request (vim is a bit puzzled by the regexes)
    assert_match /\$\$\(".path-selected"\).each\(function\(value, index\) \{/, body

    # with this we did not actually test the look of the view with the detail displayed, but some
    # items in the javascript code returned


    # check for existence submit button "Clear" 
    regexp = /<input(.*?)type=\\"submit\\"(.*?)value=\\"Clear\\"(.*?)>/
    assert false, "No button found with button text: \"Clear\"."  if regexp.match(@response.body).nil?

    # check for existence submit button "Update request"
    regexp = /<input(.*?)type=\\"submit\\"(.*?)value=\\"Update request\\"(.*?)>/
    assert false, "No button found with button text: \"Update request\"."  if regexp.match(@response.body).nil?

    # check for existence submit button "Delete request"
    regexp = /<input(.*?)type=\\"submit\\"(.*?)value=\\"Delete request\\"(.*?)>/
    assert false, "No button found with button text: \"Delete request\"."  if regexp.match(@response.body).nil?


  end



  def test_clear
    post :submit_detailarea, :actionflag => "clear"
    assert_redirected_to :action => "hello"
    
    follow_redirect
    assert_response :success

    assert_select "div.flash-nok", 1		# is hidden and nok, as it is nok by default when it is empty
    assert_select "div#rules-statusarea", "Status: active"

    # check for existence and correct title of submit button detailarea
    regexp = /<input(.*?)type="submit"(.*?)value="Add request"(.*?)>/
    assert false, "No button found with button text: \"Add request\"."  if regexp.match(@response.body).nil?

    # check for non-existence submit button "Save request" in detailarea
    regexp = /<input(.*?)type="submit"(.*?)value="Save request"(.*?)>/
    assert true, "Button found with button text: \"Save request\"."  if regexp.match(@response.body).nil?

    # check for non-existence submit button "Update request" in detailarea
    regexp = /<input(.*?)type="submit"(.*?)value="Update request"(.*?)>/
    assert true, "Button found with button text: \"Update request\"."  if regexp.match(@response.body).nil?

    # check for non-existence submit button "Delete request" in detailarea
    regexp = /<input(.*?)type="submit"(.*?)value="Delete request"(.*?)>/
    assert true, "Button found with button text: \"Delete request\"."  if regexp.match(@response.body).nil?

  end

  def test_add_successful
    post :submit_detailarea, :actionflag => "add", :update_http_method => "GET", :update_path => "/detail2.html", :update_weight => "1000"
    assert_redirected_to :action => "hello"
    
    follow_redirect
    assert_response :success

    assert_select "div.flash-ok", /Successfully added new item/
  end

  def test_add_failure
    post :submit_detailarea, :actionflag => "add", :update_http_method => "GET_XXX", :update_path => "/detail2.html", :update_weight => "1000"
    assert_redirected_to :action => "hello"
    
    follow_redirect
    assert_response :success

    assert_select "div.flash-nok", /Adding failed! Validation failed: Http method has to be a valid http method, i.e. GET, PUT, etc./

  end

  def test_update_successful
    post :submit_detailarea, :actionflag => "save", :update_id => "3", :update_http_method => "GET", :update_path => "/detail2.html", :update_weight => "3"
    assert_redirected_to :action => "hello"
    
    follow_redirect
    assert_response :success

    assert_select "div.flash-ok", /Successfully saved item 3!/
  end

  def test_update_failure
    post :submit_detailarea, :actionflag => "save", :update_id => "3", :update_http_method => "GET_XXX", :update_path => "/detail2.html", :update_weight => "3"
    assert_redirected_to :action => "hello"
    
    follow_redirect
    assert_response :success

    assert_select "div.flash-nok", /Saving failed! Validation failed: Http method has to be a valid http method, i.e. GET, PUT, etc./

  end

  def test_delete_successful
    post :submit_detailarea, :actionflag => "delete", :update_id => "1"
    assert_redirected_to :action => "hello"
    
    follow_redirect
    assert_response :success

    assert_select "div.flash-ok", /Successfully deleted item 1!/
  end

  def test_delete_failure
    post :submit_detailarea, :actionflag => "delete", :update_id => "24"
    assert_redirected_to :action => "hello"
    
    follow_redirect
    assert_response :success

    assert_select "div.flash-nok", /Can't update. You have not selected a valid request to be updated. Requested id 24./

  end


end
