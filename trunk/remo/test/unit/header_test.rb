require File.dirname(__FILE__) + '/../test_helper'

class HeaderTest < Test::Unit::TestCase
  fixtures :headers

  def test_valid_save

    header = Header.new(:request_id     => 1,
    			:name           => "X-Test",
    			:custom_domain  => ".*")
    assert header.save
  end
  def test_invalid_save

    header = Header.new(:request_id     => 1,
    			:name           => nil,
    			:custom_domain  => ".*")
    assert !header.save
    assert_equal "can't be blank", header.errors.on(:name)
  end
end
