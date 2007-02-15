require File.dirname(__FILE__) + '/../test_helper'

require 'rules_generator/main'
require 'helpers/various'

REQUEST_DETAIL_FIELDS = [
    { "host" => "Host" },
    { "user_agent" => "User-Agent"},
    { "referer" => "Referer"},
    { "accept" => "Accept"},
    { "accept_language" => "Accept-Language"},
    { "accept_encoding" => "Accept-Encoding"},
    { "accept_charset" => "Accept-Charset"},
    { "keep_alive" => "Keep-Alive"},
    { "guiprefix_connection" => "Connection"},
    { "content_type" => "Content-Type"},
    { "content_length" => "Content-Length"},
    { "cookie" => "Cookie"},
    { "pragma" => "Pragma"},
    { "cache_control" => "Cache-Control"},
    { "remarks" => "Remarks"}
]

def get_startline(rules_array, path)
  # return the line within a ruleset where the rule regarding the 
  # path passed as parameter starts

  rules_array.size.times do |i|
    regexp = /^# allow: .*#{path}/
    return i if regexp.match(rules_array[i])
  end

end

def assert_rule_line (rules_array, line, regexp, initial_comment)
   assert_equal false, regexp.match(rules_array[line]).nil?, "#{initial_comment} (line #{line}):\n Expected : /#{regexp.source}/\n Retrieved:   #{rules_array[line]}" 
end

class RulesGeneratorTest < Test::Unit::TestCase
  def test_main
    filename = generate(nil, nil, REQUEST_DETAIL_FIELDS)  
    rules_array = IO.readlines(filename)

    Request.find(:all).each do |item|
      startline = get_startline(rules_array, item.path)

      # Example rule group should look as follows:

      #  0 |# allow: GET /info.html (request id / rule group 6)
      #  1 |# Basic get request
      #  2 |<LocationMatch "^/info.html$">
      #  3 |  # Checking request method
      #  4 |  SecRule REQUEST_METHOD "!^GET$" "t:none,setvar:tx.invalid=1,pass"
      #  5 |  SecRule "TX:INVALID" "^1$" "deny,id:6,t:none,status:501,severity:3,msg:'Request method wrong (it is not GET).'"
      #  6 |
      #  7 |  # Strict headercheck (make sure the request contains only predefined request headers)
      #  8 |  SecRule REQUEST_HEADERS_NAMES "!^(Host|User-Agent|...)$" "setvar:tx.invalid=1,t:none,pass"
      #  9 |  SecRule "TX:INVALID" "^1$" "deny,id:6,status:501,severity:3,msg:'Strict headercheck: At least one request header is not predefined for this path.'"
      # 10 |
      # 11 |  # Checking request header "Host"
      # 12 |  SecRule &HTTP_Host "!^0$" "chain,t:none,pass"
      # 13 |  SecRule HTTP_Host "!^(railsmachine)$" "t:none,setvar:tx.invalid=1"
      # 14 |  SecRule "TX:INVALID" "^1$" "deny,id:6,t:none,status:501,severity:3,msg:'Request header Host failed validity check.'"
      # 15 |  # Checking request header "User-Agent"
      # 16 |  ...
      #
      # n  |
      # n+1|  # All checks passed for this path. Request is allowed.
      # n+2|  SecAction "allow,id:6,t:none,msg:'Request passed all checks, it is thus allowed.'"
      # n+3|</LocationMatch>


      # Check start of rule group
      assert_rule_line rules_array, startline + 0,
        /^# allow: #{item.http_method} #{item.path} \(request id \/ rule group #{item.id}\)$/, "Rule start does not start with '# allow'" 
      assert_rule_line rules_array, startline + 1,
        /^# #{item.remarks}/, "Remarks comment does not match the remarks field"
      assert_rule_line rules_array, startline + 2,
        /^<LocationMatch "\^#{item.path}\$">$/, "LocationMatch line is not correct"
      assert_rule_line rules_array, startline + 3, 
        /^  # Checking request method$/, "Comment \"request method\" not correct"
      assert_rule_line rules_array, startline + 4, 
        /^  SecRule REQUEST_METHOD "!\^#{item.http_method}\$" "t:none,setvar:tx.invalid=1,pass"$/, 
        "Request method check faulty"
      assert_rule_line rules_array, startline + 5, 
        /^  SecRule "TX:INVALID" "\^1\$" "deny,id:#{item.id},t:none,status:501,severity:3,msg:'Request method wrong \(it is not #{item.http_method}\).'"$/,
        "Request method check faulty"
      assert_rule_line rules_array, startline + 6, 
        /^$/, "Line not empty"

      # Check the strict headercheck of the rule group
      assert_rule_line rules_array, startline + 7,
        /^  # Strict headercheck \(make sure the request contains only predefined request headers\)$/, 
        "Comment \"Strict headercheck\" not correct"
      header_string = ""
      REQUEST_DETAIL_FIELDS.each do |requestitem|
        unless requestitem.keys[0] == "remarks"
          header_string += "\\|" unless header_string.size == 0
          header_string += map_dbname_httpname(requestitem.keys[0])
        end
      end
      assert_rule_line rules_array, startline + 8,
        /^  SecRule REQUEST_HEADERS_NAMES "!\^\(#{header_string}\)\$" "setvar:tx.invalid=1,t:none,pass"$/,
        "\"Strict headercheck\" not correct"
      assert_rule_line rules_array, startline + 9,
        /^  SecRule "TX:INVALID" "\^1\$" "deny,id:#{item.id},status:501,severity:3,msg:'Strict headercheck: At least one request header is not predefined for this path.'"$/, 
        "\"Strict headercheck\" not correct"

      # Loop and check every headercheck of the rule group
      assert_rule_line rules_array, startline + 10,
        /^$/, "Line not empty"
      n = 11
      REQUEST_DETAIL_FIELDS.each do |requestitem|
        unless requestitem.keys[0] == "remarks"
          assert_rule_line rules_array, startline + n, 
            /^  # Checking request header "#{map_dbname_httpname(requestitem.keys[0])}"$/,
            "Request header check comment for header #{map_dbname_httpname(requestitem.keys[0])} is not correct"
          assert_rule_line rules_array, startline + n + 1, 
            /^  SecRule &HTTP_#{map_dbname_httpname(requestitem.keys[0])} "!\^0\$" "chain,t:none,pass"$/,
            "Request header check first line for header #{map_dbname_httpname(requestitem.keys[0])} is not correct"
          assert_rule_line rules_array, startline + n + 2, 
            /^  SecRule HTTP_#{map_dbname_httpname(requestitem.keys[0])} "!\^\(#{item[requestitem.keys[0]]}\)\$" "t:none,setvar:tx.invalid=1"$/,
            "Request header check first line for header #{map_dbname_httpname(requestitem.keys[0])} is not correct"
          assert_rule_line rules_array, startline + n + 3,
            /^  SecRule "TX:INVALID" "\^1\$" "deny,id:#{item.id},t:none,status:501,severity:3,msg:'Request header #{map_dbname_httpname(requestitem.keys[0])} failed validity check.'"$/,
            "Request header check first line for header #{map_dbname_httpname(requestitem.keys[0])} is not correct"
          n += 4
        end
      end

      # Check the end of the rule group
      assert_rule_line rules_array, startline + n,
        /^$/, "Line not empty"
      assert_rule_line rules_array, startline + n + 1,
        /^  # All checks passed for this path. Request is allowed.$/, 
        "Final comment for request not correct"
      assert_rule_line rules_array, startline + n + 2, 
        /^  SecAction "allow,id:#{item.id},t:none,msg:'Request passed all checks, it is thus allowed.'"$/, 
        "Rule allowing request not correct."
      assert_rule_line rules_array, startline + n + 3, 
        /^<\/LocationMatch>$/, "Closing LocationMatch is not correct."


   end

  end

end

