require File.dirname(__FILE__) + '/../test_helper'
require 'helpers/various'

class LibVariousTest < Test::Unit::TestCase
  def test_escape_path
    path = "/apache2-default/index.html"
    expected_result = "\\/apache2-default\\/index\\.html" # you have to double-escape it to work

    assert_equal escape_path(path), expected_result, "Escaping of path did not work our correctly."
  end

end
