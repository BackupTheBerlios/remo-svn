require File.dirname(__FILE__) + '/../test_helper'
require 'main_controller'

# Re-raise errors caught by the controller.
class MainController; def rescue_action(e) raise e end; end

class MainControllerTest < Test::Unit::TestCase
  def setup
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

  def test_hello
    # test layout hello view

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

    # testing content of the first data item
    assert_select "div#request-item-1-http_method", 'GET'
    assert_select "div#request-item-1-path", '/myindex.html'

    # test for existence of javascript onclick link: we search for exactly 1 occurrence of a link with the 
    # onclick value matching the html sourcecode expected.
    # testing a http_method item and a path item will do
    assert_select "div#request-item-1-http_method a[onclick=new Ajax.Request('/main/display_detail/1', {asynchronous:true, evalScripts:true}); return false;]", 1
    assert_select "div#request-item-1-path a[onclick=new Ajax.Request('/main/display_detail/1', {asynchronous:true, evalScripts:true}); return false;]", 1

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

    # with this we did not actually test the look of the view with the detail displayed

  end

end
