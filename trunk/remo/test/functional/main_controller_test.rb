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
    	elements << "div#request-item_#{n}-head"
    	elements << "div#request-item_#{n}-details"
    end
    assert_exist_elementlist elements

    # request list: testing content of the first data item
    assert_select "li#request-item_1 > div#request-item_1-head", 1
    assert_select "div#request-item_1-head > div#request-item_1-expanded", 1
    assert_select "div#request-item_1-head > div#request-item_1-collapsed", 1
    assert_select "div#request-item_1-head > div#request-item_1-expanded > a", 1
    assert_select "div#request-item_1-head > div#request-item_1-collapsed > a", 1
    assert_select "div#request-item_1-head > div#request-item_1-expanded > a > img[src=/expanded.png]", 1
    assert_select "div#request-item_1-head > div#request-item_1-collapsed > a > img[src=/collapsed.png]", 1
    assert_select "div#request-item_1-head > a:nth-child(3)", 'GET'
    assert_select "div#request-item_1-head > a:nth-child(3)[onclick=new Ajax.Request('/main/display_detailarea/1', {asynchronous:true, evalScripts:true}); return false;]", 1
    assert_select "div#request-item_1-head > a:nth-child(4)", '/myindex.html'
    assert_select "div#request-item_1-head > a:nth-child(4)[onclick=new Ajax.Request('/main/display_detailarea/1', {asynchronous:true, evalScripts:true}); return false;]", 1
    assert_select "li#request-item_1 > div#request-item_1-details", 1
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
    get :add_request
    assert_response :success
    assert_template "add_request"	

    # add_request javascript reply
    assert_select_rjs "rules-mainarea-sortlist" do
      assert_select "li > div", 2                    # head and details
      assert_select "li > div:nth-child(2) > div", DEFAULT_HEADERS.size + 1 # number of detail fields
      # with this we are quite sure we got a real request item 
    end

  end

  def test_index_detailarea
    # plain index call, checking the detailarea seperately
    get :index
    assert_response :success
    assert_template "index"	

    assert_select "div#rules-detailarea > div#requestitem > form[action=/main/submit_detailarea]"
    assert_select "div#requestitem input#actionflag[value=add]"
    assert_select "div#requestitem input#update_id"
    assert_select "div#requestitem table#requestitem-maintable"
    assert_select "table#requestitem-maintable table#requestitem-requesttable"
    assert_select "table#requestitem-maintable table#requestitem-submittable"

    assert_select "table#requestitem-submittable > tr", 1
    assert_select "table#requestitem-submittable input[value='Add request']"
    assert_select "table#requestitem-submittable input[value='Clear form']", 0
    assert_select "table#requestitem-submittable input[value='Save request']", 0
    assert_select "table#requestitem-submittable input[value='Delete request']", 0

    assert_select "table#requestitem-requesttable > tr ", 3
    assert_select "table#requestitem-requesttable input[id='update_http_method']"
    assert_select "table#requestitem-requesttable input[id='update_path']"
    assert_select "table#requestitem-requesttable input[id='update_remarks']"

  end

  def test_index_detailarea_selected
    # index call with GET parameter id=1
    #  -> by clicking on the lens in request list, thus loading view again with id parameter
    get :index, :id => 1
    assert_response :success

    assert_template "index"
    
    assert_select "div#rules-detailarea > div#requestitem > form[action=/main/submit_detailarea]"
    assert_select "div#requestitem input#actionflag[value=save]"
    assert_select "div#requestitem input#update_id"
    assert_select "div#requestitem table#requestitem-maintable"
    assert_select "table#requestitem-maintable table#requestitem-requesttable"
    assert_select "table#requestitem-maintable table#requestitem-submittable"

    assert_select "table#requestitem-submittable > tr", 3
    assert_select "table#requestitem-submittable input[value='Add request']", 0
    assert_select "table#requestitem-submittable input[value='Clear form']", 1
    assert_select "table#requestitem-submittable input[value='Save request']", 1
    assert_select "table#requestitem-submittable input[value='Delete request']", 1

    assert_select "table#requestitem-requesttable > tr ", 3
    assert_select "table#requestitem-requesttable input[id='update_http_method'][value='GET']"
    assert_select "table#requestitem-requesttable input[id='update_path'][value$='index.html']"
    assert_select "table#requestitem-requesttable input[id='update_remarks'][value$='bla bla']"

  end

  def test_display_detailarea
    # test display_detailarea ajax request
    get :display_detailarea, :id => 1
    assert_response :success

    assert_template "display_detailarea"

    body = @response.body

    #detailarea
    assert_select_rjs "requestitem" do
      assert_select "form[action=/main/submit_detailarea]"
      assert_select "div#requestitem input#actionflag[value=save]"
      assert_select "div#requestitem input#update_id"
      assert_select "div#requestitem table#requestitem-maintable"
      assert_select "table#requestitem-maintable table#requestitem-requesttable"
      assert_select "table#requestitem-maintable table#requestitem-submittable"

      assert_select "table#requestitem-submittable > tr", 3
      assert_select "table#requestitem-submittable input[value='Add request']", 0
      assert_select "table#requestitem-submittable input[value='Clear form']", 1
      assert_select "table#requestitem-submittable input[value='Save request']", 1
      assert_select "table#requestitem-submittable input[value='Delete request']", 1

      assert_select "table#requestitem-requesttable > tr ", 3
      assert_select "table#requestitem-requesttable input[id='update_http_method'][value='GET']"
      assert_select "table#requestitem-requesttable input[id='update_path'][value$='index.html']"
      assert_select "table#requestitem-requesttable input[id='update_remarks'][value$='bla bla']"
    end

    # checking for highlight (select) statements
    assert_match /addClassName\("request-item_1-head", "requesthead-selected"\)/, @response.body
    assert_match /removeClassName\("request-item_1-head", "requesthead"\)/, @response.body
    
    #statusarea
    assert_select_rjs "rules-statusarea" do
      assert_select "div", /Selected request item 1/
    end
  end

  def test_display_detailarea_clear
    post :submit_detailarea, :actionflag => "clear"
    assert_response :success

    assert_template "submit_detailarea"

    # detailarea
    assert_select_rjs "requestitem" do
      assert_select "form[action=/main/submit_detailarea]"
      assert_select "div#requestitem input#actionflag[value=add]"
      assert_select "div#requestitem input#update_id"
      assert_select "div#requestitem table#requestitem-maintable"
      assert_select "table#requestitem-maintable table#requestitem-requesttable"
      assert_select "table#requestitem-maintable table#requestitem-submittable"

      assert_select "table#requestitem-submittable > tr", 1
      assert_select "table#requestitem-submittable input[value='Add request']"
      assert_select "table#requestitem-submittable input[value='Clear form']", 0
      assert_select "table#requestitem-submittable input[value='Save request']", 0
      assert_select "table#requestitem-submittable input[value='Delete request']", 0

      assert_select "table#requestitem-requesttable > tr ", 3
      assert_select "table#requestitem-requesttable input[id='update_http_method']"
      assert_select "table#requestitem-requesttable input[id='update_path']"
      assert_select "table#requestitem-requesttable input[id='update_remarks']"
    end

    # statusarea
    assert_select_rjs "rules-statusarea" do
      assert_select "div", /Status: active/
    end

  end

  def test_display_detailarea_add_successful
    post :submit_detailarea, :actionflag => "add", :update_http_method => "GET", :update_path => "/detail2.html", :update_weight => "1000", :update_remarks => "foo"
    assert_response :success

    assert_template "submit_detailarea"

    # detailarea
    assert_select_rjs "requestitem" do
      assert_select "form[action=/main/submit_detailarea]"
      assert_select "div#requestitem input#actionflag[value=save]"
      assert_select "div#requestitem input#update_id"
      assert_select "div#requestitem table#requestitem-maintable"
      assert_select "table#requestitem-maintable table#requestitem-requesttable"
      assert_select "table#requestitem-maintable table#requestitem-submittable"

      assert_select "table#requestitem-submittable > tr", 3
      assert_select "table#requestitem-submittable input[value='Add request']", 0
      assert_select "table#requestitem-submittable input[value='Clear form']", 1
      assert_select "table#requestitem-submittable input[value='Save request']", 1
      assert_select "table#requestitem-submittable input[value='Delete request']", 1

      assert_select "table#requestitem-requesttable > tr ", 3
      assert_select "table#requestitem-requesttable input[id='update_http_method'][value='GET']"
      assert_select "table#requestitem-requesttable input[id='update_path'][value$='detail2.html']"
      assert_select "table#requestitem-requesttable input[id='update_remarks'][value$='foo']"
    end

    # mainarea
    assert_select_rjs "rules-mainarea-sortlist" do
      assert_select "li > div", 2                    # head and details
      assert_select "li > div:nth-child(2) > div", DEFAULT_HEADERS.size + 1 # number of detail fields
      # with this we are quite sure we got a real request item 
    end

    # statusarea
    assert_select_rjs "rules-statusarea" do
      assert_select "div", /Successfully added new item/
    end

  end

  def test_display_detailarea_add_failure
    post :submit_detailarea, :actionflag => "add", :update_http_method => "GET_XXX", :update_path => "/detail2.html", :update_weight => "1000", :update_remarks => "bar"
    assert_response :success

    assert_template "submit_detailarea"

    # flash-notice
    assert_select_rjs "flash-notice" do
      assert_select "div", /Adding failed! Validation failed: Http method has to be a valid http method, i.e. GET, PUT, etc./
    end

    # statusarea
    assert_select_rjs "rules-statusarea" do
      assert_select "div", /Adding failed! Validation failed: Http method has to be a valid http method, i.e. GET, PUT, etc./
    end
  end

  def test_display_detailarea_update_successful
    post :submit_detailarea, :actionflag => "save", :update_id => "3", :update_http_method => "GET", :update_path => "/detail2.html", :update_weight => "3", :update_remarks => "bar"
    assert_response :success

    assert_template "submit_detailarea"

    # mainarea
    assert_select_rjs "request-item_3" do
      assert_select "li > div", 2                    # head and details
      assert_select "li > div:nth-child(2) > div", DEFAULT_HEADERS.size + 1 # number of detail fields
      # with this we are quite sure we got a real request item 
    end

    # statusarea
    assert_select_rjs "rules-statusarea" do
      assert_select "div", /Successfully saved item 3!/
    end

  end

  def test_display_detailarea_update_failure
    post :submit_detailarea, :actionflag => "save", :update_id => "3", :update_http_method => "GET_XXX", :update_path => "/detail2.html", :update_weight => "3", :update_remarks => "bar"
    assert_response :success

    assert_template "submit_detailarea"

    # flash-notice
    assert_select_rjs "flash-notice" do
      assert_select "div", /Saving failed! Validation failed: Http method has to be a valid http method, i.e. GET, PUT, etc./
    end

    # statusarea
    assert_select_rjs "rules-statusarea" do
      assert_select "div", /Saving failed! Validation failed: Http method has to be a valid http method, i.e. GET, PUT, etc./
    end

  end

  def test_display_detailarea_delete_successful
    post :submit_detailarea, :actionflag => "delete", :update_id => "1"
    assert_response :success

    assert_template "submit_detailarea"

    # mainarea
    assert_match /Element.remove\("request-item_1"\)/, @response.body

    assert_equal Header.find(:all, :conditions => "'request_id' = 1").size, 0

    # statusarea
    assert_select_rjs "rules-statusarea" do
      assert_select "div", /Successfully deleted item 1!/
    end
  end

  def test_display_detailarea_delete_failure
    post :submit_detailarea, :actionflag => "delete", :update_id => "24"
    assert_response :success

    assert_template "submit_detailarea"

    # flash-notice
    assert_select_rjs "flash-notice" do
      assert_select "div", /Removing failed! Couldn't find Request with ID=24/
    end

    # statusarea
    assert_select_rjs "rules-statusarea" do
      assert_select "div", /Removing failed! Couldn't find Request with ID=24/
    end

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
