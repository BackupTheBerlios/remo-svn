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

def assert_rule_line_regex (rules_array, line, regexp, initial_comment)
   assert_equal false, regexp.match(rules_array[line]).nil?, "#{initial_comment} (line #{line+1}):\n Expected : /#{regexp.source}/\n Retrieved:   #{rules_array[line]}" 
   # it's line + 1 as the ruley_array works with cardinal numbers and we display an ordinary one.
end

def assert_rule_line_string (rules_array, line, template, initial_comment)
   assert_equal true, rules_array[line].chomp == template, "#{initial_comment} (line #{line+1}):\n Expected : #{template}\n Retrieved: #{rules_array[line]}" 
   # it's line + 1 as the ruley_array works with cardinal numbers and we display an ordinary one.
end

def build_rule_regex(string)
  string.gsub!("\\", "\\\\\\") # this is exactly what is needed for single backslashes
  string.gsub!("^", "\\^")
  string.gsub!("(", "\\(")
  string.gsub!(")", "\\)")
  string.gsub!("{", "\\{")
  string.gsub!("}", "\\}")
  string.gsub!("[", "\\[")
  string.gsub!("]", "\\]")
  string.gsub!("$", "\\$")
  regex = /^  #{string}$/
  return regex
end

def check_crosscheck(rules_array, i, rulename, rulename_commentname, name, id, type)
  assert_rule_line_regex rules_array, i,
    build_rule_regex("SecRule #{rulename} \"^#{name}\[=&\]|^#{name}$\" \"t:none,deny,id:#{id},status:501,severity:3,msg:'#{type.capitalize} #{name} is present in #{rulename_commentname}. This is illegal.'\""),
      "Request argument crosscheck for #{type} #{name} is not correct"
end

def assert_empty_line (rules_array, i)
  assert_rule_line_regex rules_array, i, /^$/, "Line not empty"
  return 1
end

def check_single_requestparameter(rules_array, id, i, type, rulename, name, domain, mandatory, crosscheck=false)
  lines = 0
  assert_rule_line_regex rules_array, i + lines,
    build_rule_regex("# Checking #{type} \"#{name}\""),
    "Argument check comment for #{type} #{name} is not correct"
  lines += 1

  if crosscheck and type == "postparameter"
    # post parameter crosscheck
    check_crosscheck(rules_array, i + lines, "QUERY_STRING", "query string", name, id, type)
    lines += 1
  end
  
  if crosscheck and type == "querystringparameter"
    # querystring parameter crosscheck
    check_crosscheck(rules_array, i + lines, "REQUEST_BODY", "post payload", name, id, type)
    lines += 1
  end

  if mandatory
    assert_rule_line_regex rules_array, i + lines,
      build_rule_regex("SecRule &#{rulename}:#{name} \"@eq 0\" \"t:none,deny,id:#{id},status:501,severity:3,msg:'#{type.capitalize} #{name} is mandatory, but it is not present in request.'\""),
      "Request argument mandatory check for #{type} #{name} is not correct"
  lines += 1
  end

  commentname=get_commentname(name)
  doubleescapedname=get_doubleescapedname(name)
  paramname = ""  
  if /\\[dDwWstrn]/.match(name).nil? and /\[/.match(name).nil?
    paramname = name
  else
    paramname = "'/^#{doubleescapedname}$/'"
  end

  assert_rule_line_string rules_array, i + lines,
    "  SecRule #{rulename}:#{paramname} \"!^(#{domain})$\" \"t:none,deny,id:#{id},status:501,severity:3,msg:'#{type.capitalize} #{commentname} failed validity check.'\"",
    "Request argument domain check for #{type} #{name} is not correct" 
  lines += 1
  
  return lines

end

def check_rulegroup_header (rules_array, i, http_method, path, remarks, id)
  assert_rule_line_regex rules_array, i + 0,
    /^# allow: #{http_method} #{path} \(request id \/ rule group #{id}\)$/, "Rule start does not start with '# allow'" 
  assert_rule_line_regex rules_array, i + 1,
    /^# #{remarks}/, "Remarks comment does not match the remarks field"
  assert_rule_line_regex rules_array, i + 2,
    /^<LocationMatch "\^#{path}\$">$/, "LocationMatch line is not correct"
  assert_rule_line_regex rules_array, i + 3, 
    /^  # Checking request method$/, "Comment \"request method\" not correct"
  assert_rule_line_regex rules_array, i + 4, 
   /^  SecRule REQUEST_METHOD "!\^#{http_method}\$" "t:none,deny,id:#{id},status:501,severity:3,msg:'Request method wrong \(it is not #{http_method}\).'"$/, 
   "Request method check faulty"

  assert_empty_line(rules_array, i + 5)

  return 6

end

def strict_parametercheck (rules_array, model, collectionname, i, id)
  # Check the strict headercheck of the rule group
  string = ""

  assert_rule_line_regex rules_array, i, 
        /^  # Strict #{model.name.downcase}check \(make sure the request contains only predefined request #{model.name.downcase}s\)$/, 
        "Comment \"Strict #{model.name.downcase}check\" not correct"
  
  model.find(:all, :conditions => "request_id = #{id}").each do |item|
    string += "|" unless string.size == 0
    string += item.name
  end

  assert_rule_line_regex rules_array, i + 1,
    build_rule_regex("SecRule #{collectionname} \"!^(#{string})$\" \"t:none,deny,id:#{id},status:501,severity:3,msg:'Strict #{model.name.downcase}check: At least one request #{model.name.downcase} is not predefined for this path.'\""),
    "\"Strict #{model.name.downcase}check\" not correct"

  assert_empty_line(rules_array, i + 2)

  return 3
end

def strict_combined_parametercheck (rules_array, models, collectionname, i, id)
  # postparameters and querystring parameters are combined in modsecurity into a single collection
  assert_rule_line_regex rules_array, i, 
        /^  # Strict argumentcheck \(make sure the request contains only predefined request arguments\)$/, 
        "Comment \"Strict argumentcheck\" not correct"
  string = ""
  
  models.each do |model|
    model.find(:all, :conditions => "request_id = #{id}").each do |item|
      string += "|" unless string.size == 0
      string += item.name
    end
  end

  assert_rule_line_regex rules_array, i + 1,
    build_rule_regex("SecRule #{collectionname} \"!^(#{string})$\" \"t:none,deny,id:#{id},status:501,severity:3,msg:'Strict argumentcheck: At least one request parameter is not predefined for this path.'\""),
    "\"Strict argument check\" not correct"

  assert_empty_line(rules_array, i + 2)

  return 3
end

def check_rulegroup_footer(rules_array, id, i)
  # Check the end of the rule group
  assert_rule_line_regex rules_array, i,
    /^  # All checks passed for this path. Request is allowed.$/, 
    "Final comment for request not correct"
  assert_rule_line_regex rules_array, i + 1,
    /^  SecAction "allow,id:#{id},t:none,msg:'Request passed all checks, it is thus allowed.'"$/, 
    "Rule allowing request not correct."
  assert_rule_line_regex rules_array, i + 2,
    /^<\/LocationMatch>$/, "Closing LocationMatch is not correct."

    return 3
end

class RulesGeneratorTest < Test::Unit::TestCase
  fixtures :requests
  fixtures :headers
  fixtures :cookieparameters
  fixtures :querystringparameters
  fixtures :postparameters

  def test_main
    filename = generate(nil, nil)  
    rules_array = IO.readlines(filename)

    Request.find(:all).each do |item|
      startline = get_startline(rules_array, item.path)
      n = 0

      # Start of the rulegroup (header)
      n += check_rulegroup_header(rules_array, startline + n, item.http_method, item.path, item.remarks, item.id)
      n += strict_parametercheck(rules_array, Header, "REQUEST_HEADER_NAMES", startline + n, item.id)

      # Http headers
      Header.find(:all, :conditions => "request_id = #{item.id}").each do |myitem|
         n += check_single_requestparameter(rules_array, 
                                           item.id, 
                                           startline + n, 
                                           "header", 
                                           "REQUEST_HEADERS", 
                                           myitem.name, 
                                           myitem.domain, 
                                           myitem.mandatory)       
      end
      n += assert_empty_line(rules_array, startline + n)

      # Cookies
      n += strict_parametercheck(rules_array, Cookieparameter, "REQUEST_COOKIES_NAMES", startline + n, item.id)
      Cookieparameter.find(:all, :conditions => "request_id = #{item.id}").each do |myitem|
        n += check_single_requestparameter(rules_array,
                                           item.id,
                                           startline + n,
                                           "cookie",
                                           "REQUEST_COOKIES",
                                           myitem.name,
                                           myitem.domain,
                                           myitem.mandatory)
      end

      # Querystring and post parameters 
      n += assert_empty_line(rules_array, startline + n)
      n += strict_combined_parametercheck(rules_array, [Querystringparameter, Postparameter], "ARGS_NAMES", startline + n, item.id)

      Querystringparameter.find(:all, :conditions => "request_id = #{item.id}").each do |myitem|
        if Postparameter.find(:first, :conditions => "request_id = #{item.id} and name = '#{myitem.name}'").nil?
          crosscheck = true
        else
          crosscheck = false
        end
        n += check_single_requestparameter(rules_array, 
                                           item.id, 
                                           startline + n, 
                                           "querystringparameter", 
                                           "ARGS", 
                                           myitem.name, 
                                           myitem.domain, 
                                           myitem.mandatory,
                                           crosscheck)
      end

      Postparameter.find(:all, :conditions => "request_id = #{item.id}").each do |myitem|
        if Querystringparameter.find(:first, :conditions => "request_id = #{item.id} and name = '#{myitem.name}'").nil?
          crosscheck = true
        else
          crosscheck = false
        end
        n += check_single_requestparameter(rules_array, 
                                           item.id, 
                                           startline + n, 
                                           "postparameter", 
                                           "ARGS", 
                                           myitem.name, 
                                           myitem.domain, 
                                           myitem.mandatory,
                                           crosscheck)
      end
      n += assert_empty_line(rules_array, startline + n)

      n += check_rulegroup_footer(rules_array, item.id, startline + n)

   end

  end

end

