require File.dirname(__FILE__) + '/../test_helper'
require 'requestcrud_controller'

# Re-raise errors caught by the controller.
class RequestcrudController; def rescue_action(e) raise e end; end

class RequestcrudControllerTest < Test::Unit::TestCase
  def setup
    @controller = RequestcrudController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
