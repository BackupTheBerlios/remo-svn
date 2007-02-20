require File.dirname(__FILE__) + '/../test_helper'
require 'main_controller'

# Re-raise errors caught by the controller.
class MainController; def rescue_action(e) raise e end; end

class MainControllerTest < Test::Unit::TestCase
  def setup
    Request.delete_all
    Header.delete_all

    @controller = MainController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    # setup the test data in the database. This will be deleted automatically after the test
    # working with fixtures seems to be just as complicated
    list = [[1, "GET",  "/myindex.html", 1, "bla bla"],
            [2, "POST", "/action/post.php", 2, "none"],
            [3, "GET",  "/detail.html",   3, ""],
            [4, "GET",  "/view,html",     4, "some comment\nadditional comment"],
            [5, "GET",  "/detail.html",   5, "some comment
                                              more comment"],
            [6, "GET",  "/index.html",    6, ""],
            [7, "GET",  "/info.html",     7, ""],
            [8, "POST", "/action/delete.php", 8, ""]]

    list.each do |item|
                r = Request.create(:id           => item[0],
                                   :http_method  => item[1],
                                   :path         => item[2],
                                   :weight       => item[3],
                                   :remarks      => item[4])
                r.save!
    end

    8.times do |i|
      DEFAULT_HEADERS.each do |name,domain|
        h = Header.new(:request_id  => i,
                       :name        => name,
                       :domain      => domain)
        h.save!
      end
    end

  end

  def test_flash_notice

    get :index
    assert_equal nil, flash[:notice]
    assert_select "div.flash-nok", 1  # it is nok by default
    assert_select "div#rules-statusarea", "Status: active"

    get :index, :id => "500011100"
    assert_equal "Attempt to access invalid request record 500011100", flash[:notice]
    assert_select "div.flash-nok", 1 

  end

  def test_index
    # test layout index view without any parameters

    get :index
    assert_response :success
    assert_template "index"	
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
		"div#source-mainarea",
		"div#source-statusarea",
		"div#rules",
		"div#rules-toolsetarea",
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
    	elements << "li#request-item_#{n}"
    	elements << "table#request-item_#{n}-head"
    	elements << "div#request-item_#{n}-details"
    end
    assert_exist_elementlist elements

    # request list: testing content of the first data item
    assert_select "li#request-item_1 > table#request-item_1-head", 1
    assert_select "table#request-item_1-head > tr > td > div#request-item_1-expanded"
    assert_select "table#request-item_1-head > tr > td > div#request-item_1-collapsed"
    assert_select "table#request-item_1-head > tr > td > div#request-item_1-expanded > a"
    assert_select "table#request-item_1-head > tr > td > div#request-item_1-collapsed > a"
    assert_select "table#request-item_1-head > tr > td > div#request-item_1-expanded > a > img[src=/expanded.png]"
    assert_select "table#request-item_1-head > tr > td > div#request-item_1-collapsed > a > img[src=/collapsed.png]"
    assert_select "table#request-item_1-head > tr > td:nth-child(2) > span.in_place_editor_field", 'GET'
    assert_select "table#request-item_1-head > tr > td:nth-child(3) > span.in_place_editor_field", '/myindex.html'
    assert_select "table#request-item_1-head > tr > td:nth-child(4) > form"
    assert_select "table#request-item_1-head > tr > td:nth-child(4) > form > input[src^=/trash.png]"
    assert_select "li#request-item_1 > div#request-item_1-details"
    assert_select "div#request-item_1-details > div", DEFAULT_HEADERS.size + 1 # number of detail fields on display per default
    

    # testing just one of the detail fields
    assert_select "div#request-item_1-details > div#request-item_1-remarks", 1
    id="request-item6-remarks"
    assert_select "div#request-item_1-remarks > div", 2
    assert_select "div#request-item_1-remarks > div#request-item_1-remarks-label", "Remarks:&nbsp;"
    assert_select "div#request-item_1-remarks > div#request-item_1-remarks-fieldedit", /bla bla/
    assert_select "div#request-item_1-remarks > div#request-item_1-remarks-fieldedit", /request_remarks_1_in_place_editor/
  end

  def test_index_rules_toolsetarea
    # plain index call, checking the rules-toolsetarea seperately
    get :index
    assert_response :success
    assert_template "index"	

    # add_request POST ajax form
    assert_select "div#rules-toolsetarea > div#add_request", 1
    assert_select "div#rules-toolsetarea > div#add_request > form > input" do
      assert_select "input", 1
      assert_select "input[title]", 1, "Image without title."
      assert_select "input[title=""]", 0, "Title tag of image is empty."
      assert_select "input[alt]", 1, "Image without alt tag."
      assert_select "input[alt=""]", 0, "Alt tag of image is empty."
    end

    # generate_ruleset GET link
    assert_select "div#rules-toolsetarea > div#generate_ruleset", 1
    assert_select "div#rules-toolsetarea > div#generate_ruleset" do
      assert_select "img", 1
      assert_select "img[title]", 1, "Image without title."
      assert_select "img[title=""]", 0, "Title tag of image is empty."
      assert_select "img[alt]", 1, "Image without alt tag."
      assert_select "img[alt=""]", 0, "Alt tag of image is empty."
    end
  end

  def test_add_request
    post :add_request
    assert_response :success
    assert_template "add_request"	

    # add_request javascript reply
    assert_select_rjs "rules-mainarea-sortlist" do
      assert_select "li > table", 1                  # head 
      assert_select "li > div", 1                    # details
      assert_select "li > div > div", DEFAULT_HEADERS.size + 1 # number of detail fields
      # with this we are quite sure we got a real request item 
    end

  end

  def test_remove_request
    post :remove_request, :id => 1
    assert_response :success
    assert_template "remove_request"	

    # add_request javascript reply
    assert_match /Element.remove\("request-item_1"\)/, @response.body
    assert_match /Element.update\("rules-statusarea", "<div>Successfully removed item 1!<\/div>"\)/, @response.body
  end

  def test_rearrange_requests_success

    post :rearrange_requests, "rules-mainarea-sortlist" => ["8", "1", "2", "3", "4", "5", "6", "7"]
    assert_response :success
      
    assert_template "rearrange_requests"

    assert_equal Request.find(:first, :order => "weight").id, 8
    
    # statusarea
    assert_select_rjs "rules-statusarea" do
      assert_select "div", /Rearranged items./
    end

  end

  def test_set_request_remarks_success
    post :set_request_remarks, :id => "3", :value => "foobar"
    assert_response :success
    
    assert_template nil
  end

  def test_generate_ruleset
    get :generate_ruleset
    assert_response :success

    # the content of the downloaded file transfer is difficult to test.
    # this is done in the integration tests

  end
end
