require File.dirname(__FILE__) + '/../test_helper'

require 'rules_generator/main'
require 'helpers/various'

def get_startline(rules_array, path)
  # return the line within a ruleset where the rule regarding the 
  # path passed as parameter starts

  # first we identify the path in the ruleset, then we step
  # backwards to the start of the rule
  # Attention: method is not checked so far.

  start_line = nil
  escaped_path = escape_path(escape_path(path)) # double escaping for use with regex afterwards

  path_hit = nil

  rules_array.size.times do |i|
    regexp = /#{escaped_path}/
    if regexp.match(rules_array[i])
      path_hit = i  # we hit the path on this line on the ruleset
      break
    end
  end

  # now stepping backwards to the start of the rule
  # the delimiter between two rules is always an empty line
  i = path_hit
  start_rule = 0
  until i == 0 do
    regexp = /^(#|$)/
    start_rule = i unless regexp.match(rules_array[i])  # counting down start_rule until we hit the comments
    regexp = /^$/
    if regexp.match(rules_array[i])
      start_line = i + 1  # i is the empty line
      break
    end

    i -= 1
  end

  return start_line, start_rule

end

class RulesGeneratorTest < Test::Unit::TestCase
  def test_main
    filename = generate    
    rules_array = IO.readlines(filename)

    Request.find(:all).each do |item|
      start, start_rule = get_startline(rules_array, item.path)

      # start + 0 has to be remarks field
      assert_equal false, /^#/.match(rules_array[start]).nil?, "First line of rule is not a comment" 
      assert_equal false, /^# #{item.remarks}/.match(rules_array[start]).nil?, "First line of comment does not match the remarks field" 

      # start + 1 has to be comment outlining path
      assert_equal false, /^#/.match(rules_array[start]).nil?, "First line of rule is not a comment" 
      assert_equal false, /^# allow/.match(rules_array[start + 1]).nil?, "Second line of comment does not start with 'allow'" 

      # start_rule has to be the start of the rule and the method
      regexp = /SecRule REQUEST_METHOD "\^#{item.http_method}\$" "chain,allow,nolog,id:#{item.id}"/
      assert_equal false, regexp.match(rules_array[start_rule]).nil?, "First line of rule is not correct" 

      # start_rule + 1 has to be the path
      regexp = /REQUEST_URI "#{escape_path(escape_path(item.path))}"/ # double escaping it
      assert_equal false, regexp.match(rules_array[start_rule+1]).nil?, "Second line of rule is not correct" 

      # start_rule + 2 has to be empty
      assert_equal false, /^$/.match(rules_array[start_rule+2]).nil?, "Third line of rule (delimiter) of rule is not empty" 

    end

  end

end

