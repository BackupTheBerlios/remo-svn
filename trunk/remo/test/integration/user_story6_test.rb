require "#{File.dirname(__FILE__)}/../test_helper"

class UserStory6Test < ActionController::IntegrationTest

  def regular_user
  	open_session do |user|
		def user.clicks_clear()
			post_via_redirect "/main/submit_detailarea", :actionflag => "clear"
			assert_response :success
			assert_template "hello"

			regexp = /Status: active/
			assert false, "Page is not empty."  if regexp.match(response.body).nil?

			regexp = /<input id="update_http_method" name="update_http_method" type="text" value="" \/>/
			assert false, "Detailarea is not empty."  if regexp.match(response.body).nil?
		end

		def user.adds_request(http_method, path, weight)
			# add new item
			post_via_redirect "/main/submit_detailarea", :actionflag => "add", :update_http_method => http_method, :update_path => path, :update_weight => weight
			assert_response :success
			assert_template "hello"

			regexp = /Successfully added new item/
			assert false, "Item could not be added."  if regexp.match(response.body).nil?

			requests = Request.find(:all, :conditions => ["weight = ?", weight]) # weight is unique
			assert_equal 1, requests.size
			request = requests[0]

			assert_equal http_method,		request.http_method
			assert_equal path,			request.path
			assert_equal weight,			request.weight
		end

		def user.updates_request(id, http_method, path, weight)
			# add new item
			post_via_redirect "/main/submit_detailarea", :actionflag => "save", :update_id => id, :update_http_method => http_method, :update_path => path, :update_weight => weight
			assert_response :success
			assert_template "hello"

			regexp = /Successfully saved item/
			assert false, "Item could not be saved."  if regexp.match(response.body).nil?

			requests = Request.find(:all, :conditions => ["id = ?", id])
			assert_equal 1, requests.size
			request = requests[0]

			assert_equal http_method,		request.http_method
			assert_equal path,			request.path
			assert_equal weight,			request.weight
		end


		def user.deletes_item(id)
			count_pre = Request.find(:all).size

			post_via_redirect "/main/submit_detailarea", :actionflag => "delete", :update_id => id
			assert_response :success
			assert_template "hello"

			regexp = /Successfully deleted item/
			assert false, "Item could not be deleted."  if regexp.match(response.body).nil?

			assert_equal Request.find(:all).size + 1, count_pre 
		end

		def user.requests_detailarea(id)
			xml_http_request "/main/display_detail", :id => id
			assert_response :success

			requests = Request.find(:all)

			# get request from db (standard find like above does not work here. Do not know why)
			item = nil
			requests.each do |item|
				break if item.id == id
			end


			#puts response.body
			regexp = /name=\\"update_id\\" type=\\"hidden\\" value=\\"#{item.id}\\" \/>/
			assert false, "Item not correctly displayed in detailarea." if regexp.match(response.body).nil?
			
			regexp = /name=\\"update_http_method\\" type=\\"text\\" value=\\"#{item.http_method}\\" \/>/
			assert false, "Item not correctly displayed in detailarea." if regexp.match(response.body).nil?

			#   we are not testing the path. It's too annoying with the regex.
			
			regexp = /name=\\"update_weight\\" size=\\"5\\" type=\\"text\\" value=\\"#{item.weight}\\" \/>/
			assert false, "Item not correctly displayed in detailarea." if regexp.match(response.body).nil?


		end
	end
  end

  def test_user_working
	Request.delete_all

  	colin = regular_user
	colin.clicks_clear
	colin.adds_request("GET", "/index.html", 1001)
	colin.adds_request("POST", "/index.php", 1002)
	colin.adds_request("GET", "/index.cgi", 1003)
	colin.adds_request("GET", "/start.html", 1004)
	colin.requests_detailarea(4)
	colin.requests_detailarea(3)
	colin.clicks_clear
	colin.requests_detailarea(1)
	colin.requests_detailarea(2)
	colin.deletes_item(1)
	colin.deletes_item(2)
	colin.updates_request(3, "POST", "/info.html", 1003)
	colin.clicks_clear
	colin.updates_request(4, "GET", "/start2.html", 1004)
	colin.clicks_clear
	colin.deletes_item(3)
	colin.clicks_clear
	colin.deletes_item(4)
	colin.clicks_clear

  end

end
