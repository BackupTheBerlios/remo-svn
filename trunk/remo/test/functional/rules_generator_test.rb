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
  # the start of the rule is either an empty line or a line starting with a comment
  i = path_hit
  until i == 0 do
    regexp = /^(#|$)/
    if regexp.match(rules_array[i])
      start_line = i
      break
    end
    i -= 1
  end

  return start_line

end

class RulesGeneratorTest < Test::Unit::TestCase
  def test_main
    filename = generate    
    rules_array = IO.readlines(filename)

    Request.find(:all).each do |item|
      start = get_startline(rules_array, item.path)

      # start + 0 has to be comment
      assert_equal false, /^#/.match(rules_array[start]).nil?, "First line of rule is not a comment" 

      # start + 1 has to be the start of the rule and the method
      regexp = /SecRule REQUEST_METHOD "\^#{item.http_method}\$" "chain,allow,nolog,id:#{item.id}"/
      assert_equal false, regexp.match(rules_array[start+1]).nil?, "Second line is not correct" 

      # start + 2 has to be the path
      regexp = /REQUEST_URI "#{escape_path(escape_path(item.path))}"/ # double escaping it
      assert_equal false, regexp.match(rules_array[start+2]).nil?, "Third line is not correct" 

      # start + 3 has to be empty
      assert_equal false, /^$/.match(rules_array[start+3]).nil?, "Fourth line (delimiter) of rule is not empty" 

    end

  end

end

