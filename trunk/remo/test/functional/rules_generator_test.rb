require File.dirname(__FILE__) + '/../test_helper'

require 'rules_generator/main'
require 'helpers/various'


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
    filename = generate(nil, nil)  
    rules_array = IO.readlines(filename)

    Request.find(:all).each do |item|
      startline = get_startline(rules_array, item.path)

      # Example rule group should look as follows:

      #  0 |# allow: GET /info.html (request id / rule group 6)
      #  1 |# Basic get request
      #  2 |<LocationMatch "^/info.html$">
      #  3 |  # Checking request method
      #  4 |  SecRule REQUEST_METHOD "!^GET$" "t:none,deny,id:6,t:none,status:501,severity:3,msg:'Request method wrong (it is not GET).'"
      #  5 |
      #  6 |  # Strict headercheck (make sure the request contains only predefined request headers)
      #  7 |  SecRule REQUEST_HEADERS_NAMES "!^(Host|User-Agent|...)$" "t:none,deny,id:6,status:501,severity:3,msg:'Strict headercheck: At least one request header is not predefined for this path.'"
      #  8 |
      #  9 |  # Checking request header "Host"
      # 10 |  SecRule &HTTP_User-Agent "!^0$" "chain,t:none,deny,id:6,status:501,severity:3,msg:'Request header User-Agent failed validity check.'"
      # 11 |  SecRule HTTP_User-Agent "!^(curl.*)$" "t:none,"
      # 12 |  # Checking request header "User-Agent"
      # 13 |  ...
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
        /^  SecRule REQUEST_METHOD "!\^#{item.http_method}\$" "t:none,deny,id:#{item.id},t:none,status:501,severity:3,msg:'Request method wrong \(it is not #{item.http_method}\).'"$/, 
        "Request method check faulty"
      assert_rule_line rules_array, startline + 5, 
        /^$/, "Line not empty"

      # Check the strict headercheck of the rule group
      assert_rule_line rules_array, startline + 6,
        /^  # Strict headercheck \(make sure the request contains only predefined request headers\)$/, 
        "Comment \"Strict headercheck\" not correct"
      header_string = ""
      Header.find(:all, :conditions => "request_id = #{item.id}").each do |header|
          header_string += "|" unless header_string.size == 0
          header_string += header.name
      end
      assert_rule_line rules_array, startline + 7,
        /^  SecRule REQUEST_HEADERS_NAMES "!\^\(#{header_string}\)\$" "t:none,deny,id:#{item.id},status:501,severity:3,msg:'Strict headercheck: At least one request header is not predefined for this path.'"$/,
        "\"Strict headercheck\" not correct"

      # Loop and check every headercheck of the rule group
      assert_rule_line rules_array, startline + 8,
        /^$/, "Line not empty"
      n = 9
      Header.find(:all, :conditions => "request_id = #{item.id}").each do |header|
        assert_rule_line rules_array, startline + n, 
          /^  # Checking request header "#{header.name}"$/,
          "Request header check comment for header #{header.name} is not correct"
        assert_rule_line rules_array, startline + n + 1, 
          /^  SecRule &HTTP_#{header.name} "!\^0\$" "chain,t:none,deny,id:#{item.id},status:501,severity:3,msg:'Request header #{header.name} failed validity check.'\"$/,
          "Request header check first line for header #{header.name} is not correct"
        assert_rule_line rules_array, startline + n + 2, 
          /^  SecRule HTTP_#{header.name} "!\^\(#{header.domain}\)\$" "t:none"$/,
          "Request header check 2nd line for header #{header.name} is not correct"
        n += 3
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

