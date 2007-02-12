require File.dirname(__FILE__) + '/../test_helper'

class RequestTest < Test::Unit::TestCase
  fixtures :requests

  def test_valid_request_save
    # save request to database
    request = Request.new(:http_method  => requests(:valid_get).http_method,
    			  :path   	=> requests(:valid_get).path,
    			  :weight  	=> 1000,  # has to be unique
    			  :remarks   	=> requests(:valid_get).remarks,
                          :host		=> requests(:valid_get).host,
                          :user_agent	=> requests(:valid_get).user_agent,
                          :referer	=> requests(:valid_get).referer,
                          :accept	=> requests(:valid_get).accept,
                          :accept_language  => requests(:valid_get).accept_language,
                          :accept_encoding  => requests(:valid_get).accept_encoding,
                          :accept_charset   => requests(:valid_get).accept_charset,
                          :keep_alive	=> requests(:valid_get).keep_alive,
                          :connection	=> requests(:valid_get).connection,
                          :content_type	=> requests(:valid_get).content_type,
                          :content_length => requests(:valid_get).content_length,
                          :cookie	=> requests(:valid_get).cookie,
                          :pragma	=> requests(:valid_get).pragma,
                          :cache_control  => requests(:valid_get).cache_control)
    assert request.save
    request = Request.new(:http_method  => requests(:valid_post).http_method,
    			  :path   	=> requests(:valid_post).path,
    			  :weight  	=> 1001,  # has to be unique
    			  :remarks   	=> requests(:valid_post).remarks,
                          :host		=> requests(:valid_post).host,
                          :user_agent	=> requests(:valid_post).user_agent,
                          :referer	=> requests(:valid_post).referer,
                          :accept	=> requests(:valid_post).accept,
                          :accept_language  => requests(:valid_post).accept_language,
                          :accept_encoding  => requests(:valid_post).accept_encoding,
                          :accept_charset   => requests(:valid_post).accept_charset,
                          :keep_alive	=> requests(:valid_post).keep_alive,
                          :connection	=> requests(:valid_post).connection,
                          :content_type	=> requests(:valid_post).content_type,
                          :content_length => requests(:valid_post).content_length,
                          :cookie	=> requests(:valid_post).cookie,
                          :pragma	=> requests(:valid_post).pragma,
                          :cache_control  => requests(:valid_post).cache_control)
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
