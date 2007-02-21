require "#{File.dirname(__FILE__)}/../test_helper"

class UserStory6Test < ActionController::IntegrationTest

  def regular_user
    open_session do |user|
      def user.adds_request()
        count_pre = Request.find(:all).size

        post "/main/add_request"
        assert_response :success
        assert_template "add_request"
        # the rest of display is tested in the controller test

        # checking for existence of new request
        request = Request.find(:first, :order => "weight DESC") 
        assert_equal "GET",     request.http_method
        assert_equal "click-to-edit",	      request.path
        assert_equal "click-to-edit",	      request.remarks

        assert_equal Request.find(:all).size, count_pre + 1
      end

      def user.removes_request(id)
        count_pre = Request.find(:all).size

        post "/main/remove_request", :id => id
        assert_response :success
        assert_template "remove_request"
        # the rest of display is tested in the controller test

        assert_equal Request.find(:all).size, count_pre - 1 
        assert_equal Request.find(:all, :conditions => "id = #{id}").size, 0
        assert_equal Header.find(:all, :conditions => "request_id = #{id}").size, 0
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

        if ( fieldname == "http_method" ||
             fieldname == "path" ||
             fieldname == "remarks" )
          post "/main/set_request_#{fieldname}/#{id}", "value" => savevalue
          assert_response :success
          dbvalue = Request.find(id)[fieldname]
        else
          header_id = Header.find(:first, :conditions => "request_id = #{id} AND name = '#{fieldname}'").id
          unless fieldname == "click-to-edit" 
            post "/main/set_header_domain/#{header_id}", "value" => savevalue
            assert_response :success
            dbvalue = Header.find(header_id).domain
          else # setting the name of a new header (default-name is "click-to-edit")
            post "/main/set_header_name/#{header_id}", "value" => savevalue
            assert_response :success
            dbvalue = Header.find(header_id).name
          end
        end

        assert_equal savevalue, dbvalue

      end

      def user.adds_header(id)
        # add a header to the request #id
        # the header will have the name "click-to-edit" per default

        count_pre = Header.find(:all).size

        post "/main/add_header", :id => id
        assert_response :success
        
        assert_equal Header.find(:all).size, count_pre + 1 

        assert_equal Header.find(:first, :order => "id DESC").name, "click-to-edit"

      end

      def user.removes_header(id, headername)
        # add a header to the request #id
        # the header will have the name "click-to-edit" per default

        count_pre = Header.find(:all).size

        header_id = Header.find(:first, :conditions => "request_id = #{id} AND name = '#{headername}'").id

        post "/main/remove_header", :id => header_id
        assert_response :success
        
        assert_equal Header.find(:all).size, count_pre - 1 

      end
    end
  end

  def test_user_working
    Request.delete_all

    colin = regular_user

    colin.adds_request
    colin.uses_inline_editor(id=1, "http_method", "GET")
    colin.uses_inline_editor(id=1, "path", "/index.html")
    colin.uses_inline_editor(id=1, "remarks", "foo")
    colin.adds_request
    colin.uses_inline_editor(id=2, "http_method", "POST")
    colin.uses_inline_editor(id=2, "path", "/index.php")
    colin.uses_inline_editor(id=2, "remarks", "bar")
    colin.adds_request
    colin.uses_inline_editor(id=3, "http_method", "GET")
    colin.uses_inline_editor(id=3, "path", "/index.cgi")
    colin.uses_inline_editor(id=3, "remarks", "")
    colin.adds_request
    colin.uses_inline_editor(id=4, "http_method", "GET")
    colin.uses_inline_editor(id=4, "path", "/start.html")
    colin.uses_inline_editor(id=4, "remarks", "")

    colin.rearranges_requests(["4", "1", "2", "3"])
    colin.uses_inline_editor(1, "Accept", ".*")
    colin.uses_inline_editor(1, "Accept", ".*\"*")
    colin.uses_inline_editor(1, "Accept", "'`\".*+?!&$")

    colin.adds_header(1)
    colin.uses_inline_editor(id=1, "click-to-edit", "foobar")
    colin.uses_inline_editor(id=1, "foobar", "\d*")
    colin.removes_header(id=1, "foobar")
    colin.adds_header(1)
    colin.uses_inline_editor(id=1, "click-to-edit", "bar")

    colin.generates_ruleset
    colin.removes_request(2)
    colin.rearranges_requests(["3", "1", "4"])
    colin.uses_inline_editor(4, "remarks", "ooo\nxxx")
    colin.removes_request(1)

    colin.removes_request(3)
    colin.removes_request(4)

  end

end
