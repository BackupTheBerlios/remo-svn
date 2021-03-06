require File.dirname(__FILE__) + '/../test_helper'

class RequestTest < Test::Unit::TestCase
  fixtures :requests

  def test_valid_request_save
    # save request to database
    
    request = Request.new(:http_method  => requests(:valid_get).http_method,
    			  :path   	=> requests(:valid_get).path,
    			  :weight  	=> 1000,  # has to be unique
    			  :remarks   	=> requests(:valid_get).remarks)
    assert request.save
    
    request = Request.new(:http_method  => requests(:valid_post).http_method,
    			  :path   	=> requests(:valid_post).path,
    			  :weight  	=> 1001,  # has to be unique
    			  :remarks   	=> requests(:valid_post).remarks)
    assert request.save

  end
  def test_invalid_request_save
    # save request to database
    request = Request.new(:http_method  => "HEAD_ILLEGAL",
    			  :path   	=> nil,
    			  :weight  	=> requests(:valid_get).weight,
    			  :remarks   	=> requests(:valid_get).remarks)
    assert !request.save
    assert_equal "has to be a valid http method, i.e. GET, PUT, etc.", request.errors.on(:http_method)
    assert_equal "can't be blank", request.errors.on(:path)


    request = Request.new(:http_method  => nil,
    			  :path   	=> nil,
    			  :weight  	=> nil,
    			  :remarks  	=> nil)
    assert !request.save
    assert_equal ["can't be blank", "has to be a valid http method, i.e. GET, PUT, etc."], request.errors.on(:http_method)
    assert_equal "can't be blank", request.errors.on(:path)
    assert_equal ["is not a number", "can't be blank"], request.errors.on(:weight)
  end

  def test_valid_request_delete

    requests = Request.find(:all)
    requests.each do |item|
        count_pre = Request.find(:all).size
    	assert Request.delete(item.id)
        assert_equal Request.find(:all).size, count_pre -1
    end

  end

end
