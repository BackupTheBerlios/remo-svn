require File.dirname(__FILE__) + '/../../remo_config'

def append_file(file, app_file, request, version)
  File.foreach(app_file) do |line|
    line.gsub!("__VERSION__", version) unless version.nil?
    line.gsub!("__DATE__", Time.now.strftime("%x %X")) # i.e. 02/05/07 14:05:56
    line.gsub!("__CLIENTIP__", request.remote_ip) unless request.nil?
    file.puts line
  end
end

def get_commentname (name)
  myname = name.clone # otherwise name is updated too
  myname.gsub!("\\", "")
  return myname
end

def get_escapedname (name)
  myname = name.clone # otherwise name is updated too
  myname.gsub!('\\', '\\\\')
  myname.gsub!('"', '\"')
  return myname
end

def get_doubleescapedname (name)
  # modsecurity wants \d, \r, \s etc. escaped as \\\d, \\\r etc. when used as argument selector.
  # see http://remo.netnea.com/twiki/bin/view/Main/Task48Start
  myname = name.clone # otherwise name is updated too
  myname.gsub!('\\', '\\\\\\\\\\')
  return myname
end

def get_domain(standard_domain, custom_domain)
  domain=""
  if standard_domain == "Custom"
    domain = get_escapedname(custom_domain)
  else
    domain = get_escapedname(STANDARD_DOMAINS[standard_domain]) unless STANDARD_DOMAINS[standard_domain].nil?
  end
  return domain
end

def get_check_http_method (value, id)
  # check the http method
  #
  # it is problematic, that remo allows a single method per path so far.
  # remo gui should allow regexes on this field.
  #

  status = get_domain_status 

  string = ""
  string += "  # Checking request method\n"
  string += "  SecRule REQUEST_METHOD \"!^#{value}$\" \"t:none,id:#{id},#{get_action}#{status},severity:3,msg:'Request method wrong (it is not #{value}).'\"\n"
  string += "\n"
  return string
end

def get_check_strict_http_methods(requests)
  status = get_domain_status

  string = ""
  string += "  # Checking request method\n"
  unless requests.length > 1
    string += "  SecRule REQUEST_METHOD \"!^(#{requests[0].http_method})$\" \"t:none,id:#{requests[0].id},#{get_action}#{status},severity:3,msg:'Request method wrong (it is not #{requests[0].http_method}).'\"\n"
  else
    # check http_methods
    mystring = ""
    requests.each do |r|
      mystring += "|" unless mystring.size == 0
      mystring += r.http_method
    end
    string += "  SecRule REQUEST_METHOD \"!^(#{mystring})$\" \"t:none,id:#{requests[0].id},#{get_action}#{status},severity:3,msg:'Request method wrong (it is not one of #{mystring}).'\"\n"
    # note that the id is the request id of the first request in the set. this is a convention.
  end
  string += "\n"
  return string
end

def get_check_strict_parametertype (model, id)
  # "strict headercheck" is a modsecurity construct.
  # it guarantees that only known headers are accepted.
  # every path can have it's own strict headerset.

  # The rule looks like the following:
  #
  # SecRule REQUEST_HEADERS_NAMES "!^(Host|Referer|...)$" "t:none,pass,id:2,severity:3,msg:'Strict headercheck: At least one request header is not predefined for this path.'"
  #
  # In this example, only Host, Referer, etc. are accepted as headers.
  # Every other header would lead to a denial of the request.
  #

  status = get_domain_status

  string = ""
  collection_name = MOD_SECURITY_COLLECTIONS[model.name.downcase] + "_NAMES"

  unless model == Querystringparameter 
    name = model.name.downcase
  else
    #query string parameters and post parameters are in the same collection
    name = "querystringparameter-/postparameter"
  end

  my_string = ""
  model.find(:all, :conditions => "request_id = #{id}").each do |item|
    my_string += "|" unless my_string.size == 0
    my_string += item.name
  end
  if model == Querystringparameter
    # query strings and postparameter form part of the same collection. 
    # so postparameter have to be added to the query string check.
    # this is not particularly nice code, but modsecurity should get
    # seperate collections soon. (April 07)
    Postparameter.find(:all, :conditions => "request_id = #{id}").each do |parameter|
    my_string += "|" unless my_string.size == 0
    my_string += parameter.name
  end
  end

  string += "  # Strict #{name}check (make sure the request contains only predefined request #{name}s)\n"
  string += "  SecRule #{collection_name} \"!^(#{my_string})$\" \"t:none,id:#{id},#{get_action}#{status},severity:3,msg:'Strict #{name}check: At least one request #{name} is not predefined for this path.'\"\n"

  return string
end

def get_http_method_skip_block(requests)
  string = ""
  requests.each do |r|
    skip = get_http_method_skip_distance(requests, r.http_method)
    string += "  SecRule REQUEST_METHOD \"^#{r.http_method}$\" \"t:none,pass,skip:#{skip}\"\n"
  end
  string += "\n" unless string.length == 0
  return string
end

def get_crosscheck (parametername, commentname, item)
  # crosscheck (postparameters and querystringparameters form part of the same collection, 
  #            we have to make sure they are not present in the query-string or payload unless 
  #            this is really wanted)

  status = get_domain_status item

  string = ""

  if (parametername == "querystringparameter" and Postparameter.find(:all, :conditions => "request_id = #{item.request_id} and name = \"#{item.name}\"").size == 0)
    string += "  SecRule REQUEST_BODY \"^#{item.name}[=&]|^#{item.name}$\" \"t:none,id:#{item.request_id},#{get_action}#{status},severity:3,msg:'Querystringparameter #{commentname} is present in post payload. This is illegal.'\"\n"
  end
  if (parametername == "postparameter" and Querystringparameter.find(:all, :conditions => "request_id = #{item.request_id} and name = \"#{item.name}\"").size == 0)
    string += "  SecRule QUERY_STRING \"^#{item.name}[=&]|^#{item.name}$\" \"t:none,id:#{item.request_id},#{get_action}#{status},severity:3,msg:'Postparameter #{commentname} is present in query string. This is illegal.'\"\n"
  end

  return string
end

def get_mandatorycheck (parametername, commentname, collection_name, item)

  status = get_mandatory_status item
  redirect = get_mandatory_redirect item

  string = ""

  if item.mandatory
    string += "  SecRule &#{collection_name}:#{item.name} \"@eq 0\" \"t:none,id:#{item.request_id},#{get_action}#{status}#{redirect},severity:3,msg:'#{parametername.capitalize} #{commentname} is mandatory, but it is not present in request.'\"\n" 
  end

  return string
end

def get_status(status_code)
    string = ""
    unless status_code.downcase.gsub("'", "") == "default" 
      if get_action == "deny"
        string = ",status:#{status_code}"
      end
    else
      if get_action == "deny"
        string = ",status:#{HTTP_DEFAULT_DENY_STATUS_CODE}"
      end
    end
    return string
end

def get_domain_status(item=nil)
  unless item.nil?
    return get_status(item.domain_status_code)
  else
    return get_status(HTTP_DEFAULT_DENY_STATUS_CODE)
  end
end
def get_mandatory_status(item)
  return get_status(item.mandatory_status_code)
end

def get_redirect(status_code, location)
  string = ""
  if HTTP_REDIRECT_STATUS_CODES.grep(/#{status_code}/).size == 1 and get_action == "deny"
    string = ",redirect:#{location}"
  end
  return string
end
def get_domain_redirect(item)
  unless item.nil?
    return get_redirect(item.domain_status_code, item.domain_location)
  else
    return ""
  end
end
def get_mandatory_redirect(item)
  unless item.nil?
    return get_redirect(item.mandatory_status_code, item.mandatory_location)
  else
    return ""
  end
end

def get_http_method_position(requests, http_method)
  # get the position of the request with the http_method in the requests array passed

    pos_http_method = nil # position of the http_method in question within the requests set
                          # the requests set is the set of requests with the same path
    0.upto(requests.length-1) do |i|
      logger.error "#{i} #{requests[i].http_method} #{http_method}"
      pos_http_method = i if requests[i].http_method == http_method
    end

    return pos_http_method
end

def get_total_num_parameters_of_request(request_id)
  n = 0
  [Header, Cookieparameter, Querystringparameter, Postparameter].each do |model|
    n += model.find(:all, :conditions => "request_id = #{request_id}").length
  end
  return n
end

def get_total_num_mandatory_parameters_of_request(request_id)
  n = 0
  [Header, Cookieparameter, Querystringparameter, Postparameter].each do |model|
    n += model.find(:all, :conditions => "request_id = #{request_id} and mandatory = 't' ").length
  end
  return n
end

def get_total_num_crosscheck_parameters_of_request(request_id)
  n = 0
  Querystringparameter.find(:all, :conditions => "request_id = #{request_id}").each do |item|
    n += 1 if Postparameter.find(:first, :conditions => "request_id = #{request_id} and name = '#{item.name}'").nil?
  end
  Postparameter.find(:all, :conditions => "request_id = #{request_id}").each do |item|
    n += 1 if Querystringparameter.find(:first, :conditions => "request_id = #{request_id} and name = '#{item.name}'").nil?
  end
  return n
end

def get_http_method_skip_distance(requests, http_method)
    skip = 0

    pos_http_method = get_http_method_position(requests, http_method)

    if pos_http_method.nil?
      logger.error "http_method is not part of the requests set. This is illegal."
      return 0
    end

    skip += (requests.length - pos_http_method - 1) # skipping the other methods in the "skip"-block

    0.upto(pos_http_method - 1) do |i|
      skip += 3 # strict header check, strict cookie check, strict query string/post parameter check (the later two share the collection)
      skip += get_total_num_parameters_of_request(requests[i].id) # one rule per parameter
      skip += get_total_num_mandatory_parameters_of_request(requests[i].id) # one rule per mandatory parameter
      skip += get_total_num_crosscheck_parameters_of_request(requests[i].id)
      skip += 1 unless i >= requests.length # Skipping SecAction rule at the end, but not at the last one
    end

    return skip

end

def get_remaining_skip_rule(requests, http_method)
  # A rule that will skip all the other http_method rule blocks
  skip = 0
  string = ""
  
  pos_http_method = get_http_method_position(requests, http_method) + 1

  unless pos_http_method >= requests.length 
    pos_http_method.upto(requests.length - 1) do |i|
      skip += 3 # strict header check, strict cookie check, strict query string/post parameter check (the later two share the collection)
      skip += get_total_num_parameters_of_request(requests[i].id) # one rule per parameter
      skip += get_total_num_mandatory_parameters_of_request(requests[i].id) # one rule per mandatory parameter
      skip += get_total_num_crosscheck_parameters_of_request(requests[i].id)
      skip += 1 unless i >= (requests.length - 1) # Skipping SecAction rule at the end, but not at the last one
    end

    string += "  # skip the remaining http_method blocks until the fall back rule\n"
    string += "  SecAction \"t:none,pass,skip:#{skip}\"\n"
    string += "\n"
  end

  return string
end

def get_check_the_four_parameter_types(r)
  string = ""

  [Header, Cookieparameter, Querystringparameter, Postparameter].each do |model|
    unless model == Postparameter
      # postparameters are being tested together with the querystringparameters as they are part of the same collection
      string += get_check_strict_parametertype(model, r.id)
    end

    model.find(:all, :conditions => "request_id = #{r.id}").each do |item| # loop over parameters
      string += get_check_individual_parameter(model.name.downcase, item)
    end
    string += "\n" unless string.length == 0
  end
  return string
end

def get_action ()
  # return mod_security action
  action = "pass"
  if RULESET_MODE == "detect"
    action = "pass"
  elsif RULESET_MODE == "block"
    action = "deny"
  else
    logger.error "Ruleset mode #{RULESET_MODE} is unknown. Falling back to detect."
  end

  return action
end

def get_check_individual_parameter (parametername, item)
  # write a rule that checks a single post parameter for compliance with rules
  # the header is optional
  # but it is in the request, then it is checked

  collection_name = MOD_SECURITY_COLLECTIONS[parametername]
  commentname = get_commentname(item.name) # we have to replace "\d" with "d" etc., as mod_security complains otherwise
  paramname = ""
  domain = get_domain(item.standard_domain, item.custom_domain)
  if /\\[dDwWstrn.]/.match(item.name).nil? and /\[/.match(item.name).nil? and /\(/.match(item.name).nil? and /\.\{/.match(item.name).nil?
    paramname = item.name
  else
    paramname = "'/^#{get_doubleescapedname(item.name)}$/'"
  end
  string = ""
  string += "  # Checking #{parametername} \"#{item.name}\"\n"

  string += get_crosscheck parametername, commentname, item
  string += get_mandatorycheck parametername, commentname, collection_name, item

  status = get_domain_status item
  redirect = get_domain_redirect item

  string += "  SecRule #{collection_name}:#{paramname} \"!^(#{domain})$\" \"t:none,id:#{item.request_id},#{get_action}#{status}#{redirect},severity:3,msg:'#{parametername.capitalize} #{commentname} failed validity check. Value domain: #{item.standard_domain}.'\"\n"

  return string

end

def get_fallback_rule()
  action = get_action
  status = get_domain_status
  string =  "# Fallback rule (unknown request)"
  string +=  "<LocationMatch \"^/.*$\">\n"
  string += "  SecAction \"#{action}#{status},severity:3,msg:'Unknown request. Access denied by fallback rule.'\"\n"
  string += "</LocationMatch>\n"
end

def get_requestrule(r)
  # do a request rule block for this request and all other requests with the same path
  string = ""

  # request rule group header
  string += "# allow: #{r.http_method} #{r.path} (request id / rule group #{r.id})\n"
  string += "# #{r.remarks}\n" unless r.remarks.nil?
  string += "<LocationMatch \"^#{r.path}$\">\n"

  requests = Request.find(:all, :conditions => "path = '#{r.path}'")

  string += get_check_strict_http_methods(requests)

  string += get_http_method_skip_block(requests) if requests.length > 1
    # if there are multiple requests with the same path
    # we have to work with skips. 
    # See http://remo.netnea.com/twiki/bin/view/Main/Task50Start for more infos

  # parameter blocks
  requests.each do |r|
      string += "  # skip-destination for http_method #{r.http_method}\n" if requests.length > 1
        # this comment is not necessary of there is no skipping
      string += get_check_the_four_parameter_types(r)
      string += get_remaining_skip_rule(requests, r.http_method) if requests.length > 1
  end

  # all checks for this path passed. So we can allow the request
  string += "  # All checks passed for this path. Request is allowed.\n"
  string += "  SecAction \"allow,id:#{r.id},t:none,msg:'Request passed all checks, it is thus allowed.'\"\n"

  # request rule group footer
  string += "</LocationMatch>\n"
  string += "\n"

  return string
end

def generate(request=nil, version=nil)
  filename = "rulefile.conf"
  prepend_filename= "prepend-file.conf"
  append_filename= "append-file.conf"

  requests = Request.find(:all, :order => "path, weight ASC")

  File.open(filename, "w") do |file|

    append_file(file, prepend_filename, request, version)

    old_path = nil
    requests.each do |r|
      file.puts get_requestrule(r) unless r.path == old_path
      old_path = r.path
    end

    file.puts get_fallback_rule

    append_file(file, append_filename, request, version)

  end

  return filename

end


