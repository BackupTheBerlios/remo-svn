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
  string = ""
  string += "  # Checking request method\n"
  string += "  SecRule REQUEST_METHOD \"!^#{value}$\" \"t:none,deny,id:#{id},severity:3,msg:'Request method wrong (it is not #{value}).'\"\n"
  string += "\n"
  return string
end



def get_check_strict_parametertype (model, id)
  # "strict headercheck" is a modsecurity construct.
  # it guarantees that only known headers are accepted.
  # every path can have it's own strict headerset.

  # The rule looks like the following:
  #
  # SecRule REQUEST_HEADERS_NAMES "!^(Host|Referer|...)$" "t:none,deny,id:2,severity:3,msg:'Strict headercheck: At least one request header is not predefined for this path.'"
  #
  # In this example, only Host, Referer, etc. are accepted as headers.
  # Every other header would lead to a denial of the request.
  #

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
  string += "  SecRule #{collection_name} \"!^(#{my_string})$\" \"t:none,deny,id:#{id},severity:3,msg:'Strict #{name}check: At least one request #{name} is not predefined for this path.'\"\n"
  string += "\n"

  return string
end

def get_crosscheck (parametername, commentname, item)
  # crosscheck (postparameters and querystringparameters form part of the same collection, 
  #            we have to make sure they are not present in the query-string or payload unless 
  #            this is really wanted)
  string = ""

  if (parametername == "querystringparameter" and Postparameter.find(:all, :conditions => "request_id = #{item.request_id} and name = \"#{item.name}\"").size == 0)
    string += "  SecRule REQUEST_BODY \"^#{item.name}[=&]|^#{item.name}$\" \"t:none,deny,id:#{item.request_id},severity:3,msg:'Querystringparameter #{commentname} is present in post payload. This is illegal.'\"\n"
  end
  if (parametername == "postparameter" and Querystringparameter.find(:all, :conditions => "request_id = #{item.request_id} and name = \"#{item.name}\"").size == 0)
    string += "  SecRule QUERY_STRING \"^#{item.name}[=&]|^#{item.name}$\" \"t:none,deny,id:#{item.request_id},severity:3,msg:'Postparameter #{commentname} is present in query string. This is illegal.'\"\n"
  end

  return string
end

def get_mandatorycheck (parametername, commentname, collection_name, item)
  string = ""
  
  status = get_mandatory_status item
  redirect = get_mandatory_redirect item

  if item.mandatory
    string += "  SecRule &#{collection_name}:#{item.name} \"@eq 0\" \"t:none,deny,id:#{item.request_id}#{status}#{redirect},severity:3,msg:'#{parametername.capitalize} #{commentname} is mandatory, but it is not present in request.'\"\n" 
  end

  return string
end

def get_status(status_code)
    string = ""
    unless status_code.downcase.gsub("'", "") == "default" 
      string = ",status:#{status_code}"
    end
    return string
end

def get_domain_status(item)
  return get_status(item.domain_status_code)
end
def get_mandatory_status(item)
  return get_status(item.mandatory_status_code)
end

def get_redirect(status_code, location)
  string = ""
  if HTTP_REDIRECT_STATUS_CODES.grep(/#{status_code}/).size == 1
    string = ",redirect:#{location}"
  end
  return string
end
def get_domain_redirect(item)
  return get_redirect(item.domain_status_code, item.domain_location)
end
def get_mandatory_redirect(item)
  return get_redirect(item.mandatory_status_code, item.mandatory_location)
end

def get_check_individual_parameter (parametername, item)
  # write a rule that checks a single post parameter for compliance with rules
  # the header is optional
  # but it is in the request, then it is checked

  collection_name = MOD_SECURITY_COLLECTIONS[parametername]
  commentname = get_commentname(item.name) # we have to replace "\d" with "d" etc., as mod_security complains otherwise
  paramname = ""
  domain = get_domain(item.standard_domain, item.custom_domain)
  if /\\[dDwWstrn]/.match(item.name).nil? and /\[/.match(item.name).nil?
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

  string += "  SecRule #{collection_name}:#{paramname} \"!^(#{domain})$\" \"t:none,deny,id:#{item.request_id}#{status}#{redirect},severity:3,msg:'#{parametername.capitalize} #{commentname} failed validity check. Value domain: #{item.standard_domain}.'\"\n"

  return string

end

def get_requestrule(r)
  models = [Header, Cookieparameter, Querystringparameter, Postparameter]
  string = ""

  # request rule group header
  string += "# allow: #{r.http_method} #{r.path} (request id / rule group #{r.id})\n"
  string += "# #{r.remarks}\n" unless r.remarks.nil?
  string += "<LocationMatch \"^#{r.path}$\">\n"

  # check http method
  string += get_check_http_method(r.http_method, r.id)

  # check the 4 parameter types
  models.each do |model|
    unless model == Postparameter
      # postparameters are being tested together with the querystringparameters as they are part of the same collection
      string += get_check_strict_parametertype(model, r.id)
    end

    model.find(:all, :conditions => "request_id = #{r.id}").each do |item| # loop over parameters
      string += get_check_individual_parameter(model.name.downcase, item)
    end
    string += "\n"
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

  requests = Request.find(:all, :order => "weight ASC")

  File.open(filename, "w") do |file|

    append_file(file, prepend_filename, request, version)

    requests.each do |r|
      file.puts get_requestrule(r)
    end

    append_file(file, append_filename, request, version)

  end

  return filename

end


