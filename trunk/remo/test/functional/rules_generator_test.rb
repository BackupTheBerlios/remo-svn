require File.dirname(__FILE__) + '/../test_helper'

require 'rules_generator/main'
require 'helpers/various'

def assert_regex_match (needle, haystack, comment="")
  assert_equal false, build_regex(needle).match(haystack).nil?, comment
end
def assert_regex_no_match (needle, haystack, comment="")
  assert_equal true, build_regex(needle).match(haystack).nil?, comment
end

def build_regex(string)
  string.gsub!("\\", "\\\\\\") # this is exactly what is needed for single backslashes
  string.gsub!("^", "\\^")
  string.gsub!("(", "\\(")
  string.gsub!(")", "\\)")
  string.gsub!("{", "\\{")
  string.gsub!("}", "\\}")
  string.gsub!("[", "\\[")
  string.gsub!("]", "\\]")
  string.gsub!("$", "\\$")
  string.gsub!(":", "\\:")
  regex = /#{string}/
  return regex
end


class RulesGeneratorTest < Test::Unit::TestCase
  fixtures :requests
  fixtures :headers
  fixtures :cookieparameters
  fixtures :querystringparameters
  fixtures :postparameters

  def test_get_commentname
    assert_equal 'd', get_commentname('\d')
  end

  def test_get_escapedname
    assert_equal '\\d', get_escapedname('\d')
  end

  def test_get_doubleescapedname
    assert_equal '\\\\\\d', get_doubleescapedname('\d')
  end

  def test_get_domain
    assert_equal '\d', get_domain("Custom", '\d')
    assert_equal '\d{0,16}', get_domain("Integer, max. 16 characters", '\d')
    assert_equal '', get_domain("Integer XXX", '\d')
  end

  def test_get_status
    assert_equal '', get_status("Default")
    assert_equal ',status:501', get_status("501")
  end
  
  def test_get_redirect
    assert_equal '', get_redirect("200", "http://remo.netnea.com")
    assert_equal ',redirect:http://remo.netnea.com', get_redirect("302", "http://remo.netnea.com")
  end

  def test_get_check_http_method
    string = get_check_http_method("GET", "1")
    assert_regex_match "# Checking request method", string, "Comment not found"
    assert_regex_match "SecRule REQUEST_METHOD", string, "Error in 1st part of the rule:\n#{string}"
    assert_regex_match "!^GET$", string, "Error in the 2nd part of the rule:\n#{string}"
    assert_regex_match "t:none,deny,id:1,status:501,severity:3,msg:'Request method wrong (it is not GET).'",
                        string , "Error in the 3rd part of the rule:\n#{string}"
  end

  def test_get_check_strict_parametertype
    string = get_check_strict_parametertype(Header, 1)

    assert_regex_match "# Strict headercheck (make sure the request contains only predefined request headers)", string, "Comment not found"
    assert_regex_match "SecRule REQUEST_HEADERS_NAMES", string, "Error in 1st part of the rule:\n#{string}"
    assert_regex_match "!^(Host|Accept|Accept-Language|Accept-Encoding|Accept-Charset|Keep-Alive|Referer|Cookie|If-Modified-Since|If-None-Match|Cache-Control)$",
                        string, "Error in 2nd part of the rule:\n#{string}"
    assert_regex_match "t:none,deny,id:1,status:501,severity:3,msg:'Strict headercheck: At least one request header is not predefined for this path.'", 
                        string, "Error in 3rd part of the rule:\n#{string}"

    string = get_check_strict_parametertype(Querystringparameter, 1)
      # querystringparameters and postparameters are part of the same collection. So querystring checking involves postparameter checking too
    assert_regex_match "# Strict querystringparameter-/postparametercheck (make sure the request contains only predefined request querystringparameter-/postparameters)", string, "Comment not found"

  end

  def test_get_crosscheck

    item = Querystringparameter.find(:first, :conditions => "name = 'q_single_integer'")
    string = get_crosscheck "querystringparameter", get_commentname(item.name), item

    # crosscheck needed
    assert_regex_match "SecRule REQUEST_BODY", string, "Error in 1st part of the rule:\n#{string}"
    assert_regex_match "^q_single_integer[=&]|^q_single_integer$",
                        string, "Error in crosscheck:\n#{string}"
    assert_regex_match "t:none,deny,id:3,status:501,severity:3,msg:'Querystringparameter q_single_integer is present in post payload. This is illegal.'",
                        string, "Error in crosscheck:\n#{string}"

    # crosscheck not needed                       
    item = Querystringparameter.find(:first, :conditions => "name = 'qp_single_integer'")
    string = get_crosscheck "querystringparameter", get_commentname(item.name), item
    assert_regex_no_match "t:none,deny,id:3,status:501,severity:3,msg:'Querystringparameter q_single_integer is present in post payload. This is illegal.'",
                        string, "Crosscheck is there, but parameter does not need a crosscheck:\n#{string}"

  end

  def test_get_mandatorycheck

    # mandatory not needed
    item = Querystringparameter.find(:first, :conditions => "name = 'q_single_integer'")
    string = get_mandatorycheck "querystringparameter", get_commentname(item.name), "ARGS", item
    assert_regex_no_match "is mandatory", string, "Error, because there is a mandatory check, but there should not be one:\n#{string}"

    # mandatory needed                        
    item = Cookieparameter.find(:first, :conditions => "name = 'c_session'")
    string = get_mandatorycheck "cookieparameter", get_commentname(item.name), "REQUEST_COOKIES", item
    assert_regex_match( 
      'SecRule &REQUEST_COOKIES:c_session "@eq 0" "t:none,deny,id:4,status:501,severity:3,msg:\'Cookieparameter c_session is mandatory, but it is not present in request.\'',
      string, 
      "Error in mandatory check:\n#{string}")

  end

  def test_get_check_individual_parameter
    item = Querystringparameter.find(:first, :conditions => "name = 'q_single_integer'")
    string = get_check_individual_parameter("querystringparameter", item)

    # main rule
    assert_regex_match '# Checking querystringparameter "q_single_integer"', string, "Comment not found"
    assert_regex_match "SecRule ARGS:q_single_integer", string, "Error in 1st part of the rule:\n#{string}"
    assert_regex_match '!^(\d)$', string, "Error in 2nd part of the rule:\n#{string}"

    assert_regex_match "t:none,id:3,deny,status:501,severity:3,msg:'Querystringparameter q_single_integer failed validity check. Value domain: Custom.'",
                        string, "Error in 3rd part of the rule:\n#{string}"

    # crosscheck is tested seperately above. 
    # mandatory is tested seperately above.

  end

  def test_domain_status_redirect
    # test the correct status code and redirect URL for a failed domain check
    item = Cookieparameter.find(:first, :conditions => "id = 50")
    string = get_check_individual_parameter("querystringparameter", item)
    assert_regex_match 'status:301,redirect:http://www.netnea.com', string, "Domain failed status code/redirect not correct:\n#{string}"
  end
  def test_mandatory_status_redirect
    # test the correct status code and redirect URL for a failed mandatory check
    item = Cookieparameter.find(:first, :conditions => "id = 50")
    string = get_check_individual_parameter("querystringparameter", item)
    assert_regex_match 'status:302,redirect:http://remo.netnea.com', string, "Mandatory failed status code/redirect not correct:\n#{string}"
  end

  def test_get_requestrule
    string = get_requestrule(Request.find(:first))

    assert_regex_match '# Basic get request', string, "Rulegroup comment not found."
    assert_regex_match '<LocationMatch "^/index.html$">', string, "Rulegroup header not found."
    
    # middle part is checked in individula checking functions above

    assert_regex_match "# All checks passed for this path. Request is allowed.", string, "Rulegroup fallback comment not found."
    assert_regex_match 'SecAction "allow,id:1,t:none,msg:\'Request passed all checks, it is thus allowed.\'', string, "Rulegroup fallback comment not found."
    assert_regex_match "</LocationMatch>", string, "Rulegroup footer not found."

    assert string.size > 200, "Requestrule is too short to be correct:\n#{string}"
  end


end

