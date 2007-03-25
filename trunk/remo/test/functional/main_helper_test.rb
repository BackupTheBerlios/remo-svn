require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../../app/helpers/main_helper'
#require 'main_controller'

class MainHelperTest < Test::Unit::TestCase

  def test_main
  
    assert true, MainHelper::HTTP_METHODS.size > 0

  end   

end

