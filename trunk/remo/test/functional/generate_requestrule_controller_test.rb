require File.dirname(__FILE__) + '/../test_helper'
require 'generate_requestrule_controller'

# Re-raise errors caught by the controller.
class GenerateRequestruleController; def rescue_action(e) raise e end; end

class GenerateRequestruleControllerTest < Test::Unit::TestCase
  def setup
    @controller = GenerateRequestruleController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_index
    get :index, :id => 2
    assert_response :success    
    assert_template "index"

    assert_match /(request id \/ rule group 2)/, @response.body  # header

    assert_match /&lt;LocationMatch/, @response.body             # frame
    assert_match /&lt;\/LocationMatch/, @response.body           # frame

    assert_match /SecRule REQUEST_HEADERS_NAMES/, @response.body  # a bit of content

    # The rest is tested in rules_generator_test.rb

  end
end
