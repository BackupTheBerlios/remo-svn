require File.dirname(__FILE__) + '/../test_helper'

class PostparameterTest < Test::Unit::TestCase
  fixtures :postparameters

  def test_valid_save

    postparameter = Postparameter.new(:request_id     => 1,
    			:name           => "X-Test",
    			:standard_domain         => "Custom",
    			:custom_domain         => ".*")
    assert postparameter.save
  end
  def test_invalid_save

    postparameter = Postparameter.new(:request_id     => 1,
    			:name           => nil,
    			:standard_domain         => "Custom",
    			:custom_domain         => ".*")
    assert !postparameter.save
    assert_equal "can't be blank", postparameter.errors.on(:name)
  end
end
