require "#{File.dirname(__FILE__)}/../test_helper"

class UserStory6Test < ActionController::IntegrationTest

  def regular_user
    open_session do |user|
      def user.clicks_clear()
        post "/main/submit_detailarea", :actionflag => "clear"
        assert_response :success
        assert_template "submit_detailarea"
        # the rest of display is tested in the controller test

      end

      def user.adds_request_new()
        count_pre = Request.find(:all).size

        post "/main/add_request"
        assert_response :success
        assert_template "add_request"
        # the rest of display is tested in the controller test

        # checking for existence of new request
        request = Request.find(:first, :order => "weight DESC") 
        assert_equal "GET",     request.http_method
        assert_equal "Click to edit",	      request.path
        assert_equal "Click to edit",	      request.remarks

        assert_equal Request.find(:all).size, count_pre + 1
      end

      def user.adds_request(http_method, path, remarks)
        post "/main/submit_detailarea", :actionflag => "add", :update_http_method => http_method, :update_path => path, :update_remarks => remarks
        assert_response :success
        assert_template "submit_detailarea"
        # the rest of display is tested in the controller test

        # checking for existence of new request
        request = Request.find(:first, :conditions => ["path = ?", path], :order => "weight DESC") # this should work even with multiple requests of the same path
        assert_equal http_method,     request.http_method
        assert_equal path,	      request.path
        assert_equal remarks,	      request.remarks
      end

      def user.updates_request(id, http_method, path, remarks)
        post "/main/submit_detailarea", :actionflag => "save", :update_id => id, :update_http_method => http_method, :update_path => path, :update_remarks => remarks
        assert_response :success
        assert_template "submit_detailarea"
        # the rest of display is tested in the controller test

        # checking the updated request
        assert_equal 1, Request.find(:all, :conditions => ["id = ?", id]).size

        request = Request.find(:first, :conditions => ["id = ?", id])
        assert_equal http_method,     request.http_method
        assert_equal path,	      request.path
        assert_equal remarks,	      request.remarks
      end

      def user.deletes_request(id)
        count_pre = Request.find(:all).size

        post "/main/submit_detailarea", :actionflag => "delete", :update_id => id
        assert_response :success
        assert_template "submit_detailarea"
        # the rest of display is tested in the controller test

        assert_equal Request.find(:all).size, count_pre -1
      end

      def user.requests_detailarea(id)
        xml_http_request "/main/display_detailarea", :id => id
        assert_response :success
        assert_template "display_detailarea"
        # the rest of display is tested in the controller test

      end

      def user.rearranges_requests(order)
        post "/main/rearrange_requests", "rules-mainarea-sortlist" => order
        assert_response :success
        assert_template "rearrange_requests"
        # the rest of display is tested in the controller test

        requests = Request.find(:all, :order => "weight")

        # example order:
        # ["4", "1", "2", "3"]
        # should bring the following values
        # i   id  weight
        # 1 : 4     1
        # 2 : 1     2
        # 3 : 2     3
        # 4 : 3     4
        order.size.times do |i|
          assert_equal order[i], requests[i].id.to_s
        end

      end

      def user.generates_ruleset()
        get "/main/generate_ruleset"
        assert_response :success

        assert_equal "text/ascii", headers["content-type"][0]
        assert_equal "attachment; filename=\"rulefile.conf\"", headers["content-disposition"][0]
        assert headers["content-length"][0].to_i > 300    # 300 bytes seems to be a reasonable minimum value.

        # do not know how to look into file. So this will have to do. 
        # actually, the file is checked in seperate functional tests.

      end

      def user.uses_inline_editor(id, fieldname, savevalue)
        # save the inline editor form for the field:fieldname; set the field to savevalue.

        if fieldname == "remarks"
          post "/main/set_request_remarks/#{id}", "value" => savevalue
          assert_response :success
          dbvalue = Request.find(id).remarks
        else
          header_id = Header.find(:first, :conditions => "request_id = #{id} AND name = '#{fieldname}'").id
          post "/main/set_header_domain/#{header_id}", "value" => savevalue
          assert_response :success
          dbvalue = Header.find(header_id).domain
        end

        assert_equal savevalue, dbvalue

      end

    end
  end

  def test_user_working
    Request.delete_all

    colin = regular_user

    colin.clicks_clear
    colin.adds_request("GET", "/index.html", "foo")
    colin.adds_request("POST", "/index.php", "bar")
    colin.adds_request("GET", "/index.cgi", "")
    colin.adds_request("GET", "/start.html", "")
    colin.adds_request_new

    colin.requests_detailarea(4)
    colin.rearranges_requests(["4", "1", "2", "3"])
    colin.requests_detailarea(3)
    colin.uses_inline_editor(3, "remarks", "foobar")
    colin.uses_inline_editor(3, "Accept", "")
    colin.uses_inline_editor(3, "Accept", "foo")
    colin.uses_inline_editor(3, "Accept", "foo bar")
    colin.uses_inline_editor(3, "Accept", ".*")
    colin.uses_inline_editor(3, "Accept", ".*\"*")
    colin.uses_inline_editor(3, "Accept", "'`\".*+?!&$")
    colin.generates_ruleset
    colin.clicks_clear
    colin.requests_detailarea(1)
    colin.requests_detailarea(2)
    colin.deletes_request(2)
    colin.rearranges_requests(["3", "1", "4"])
    colin.uses_inline_editor(4, "remarks", "ooo\nxxx")
    colin.deletes_request(1)

    colin.updates_request(3, "POST", "/info.html", "foo")
    colin.clicks_clear
    colin.updates_request(4, "GET", "/start2.html", "bar foobar")
    colin.clicks_clear
    colin.deletes_request(3)
    colin.clicks_clear
    colin.deletes_request(4)
    colin.clicks_clear
  end

end
