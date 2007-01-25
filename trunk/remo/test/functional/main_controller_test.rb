require File.dirname(__FILE__) + '/../test_helper'
require 'main_controller'

# Re-raise errors caught by the controller.
class MainController; def rescue_action(e) raise e end; end

class MainControllerTest < Test::Unit::TestCase
  def setup
    @controller = MainController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
  
  def test_hello
    get :hello
    assert_template "hello"	
    assert_select "title", 1

    def assert_exist_elementlist (list, num=1)
    	list.each do |item|
    		assert_select item, num, "FAILURE: Page item " + item + " not found " + num.to_s + " time(s) as expected." # check that item exists <num> of times in the page
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

  end
end
