require File.dirname(__FILE__) + '/../test_helper'
require 'displaylogfilerequest_controller'

# Re-raise errors caught by the controller.
class DisplaylogfilerequestController; def rescue_action(e) raise e end; end

class DisplaylogfilerequestControllerTest < Test::Unit::TestCase
  def setup
    @controller = DisplaylogfilerequestController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
