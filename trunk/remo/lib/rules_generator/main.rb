def append_file(file, app_file, request, version)
  File.foreach(app_file) do |line|
    line.gsub!("__VERSION__", version) unless version.nil?
    line.gsub!("__DATE__", Time.now.strftime("%x %X")) # i.e. 02/05/07 14:05:56
    line.gsub!("__CLIENTIP__", request.remote_ip) unless request.nil?
    file.puts line
  end
end

def map_dbname_httpname (string)
  # map a remo db name to a real http header.
  # see http://remo.netnea.com/twiki/bin/view/Main/Task30Start
  # for the mapping rules

  string = string.gsub("guiprefix_", "")
  string = string.gsub("_", "-") 

  # capitalize substrings (-> accept-language to Accept-Language)
  words = string.split("-")
  string = ""
  words.each do |word|
    string += "-" unless string.size == 0
    string += word.capitalize
  end

  return string

end

def get_check_http_method (value, id)
  # check the http method
  #
  # it is problematic, that remo allows a single method per path so far.
  # remo gui should allow regexes on this field.
  #
  string = ""
  string += "  # Checking request method\n"
  string += "  SecRule REQUEST_METHOD \"!^#{value}$\" \"t:none,deny,id:#{id},status:501,severity:3,msg:'Request method wrong (it is not #{value}).'\"\n"
  string += "\n"
  return string
end

def get_check_strict_headers (id)
  # "strict headercheck" is a modsecurity construct.
  # it guarantees that only known headers are accepted.
  # every path can have it's own strict headerset.

  # The rule looks like the following:
  #
  # SecRule REQUEST_HEADERS_NAMES "!^(Host|Referer|...)$" "t:none,deny,id:2,status:501,severity:3,msg:'Strict headercheck: At least one request header is not predefined for this path.'"
  #
  # In this example, only Host, Referer, etc. are accepted as headers.
  # Every other header would lead to a denial of the request.
  #

  string = ""

  header_string = ""
  Header.find(:all, :conditions => "request_id = #{id}").each do |header|
    header_string += "|" unless header_string.size == 0
    header_string += header.name
  end

  string += "  # Strict headercheck (make sure the request contains only predefined request headers)\n"
  string += "  SecRule REQUEST_HEADERS_NAMES \"!^(#{header_string})$\" \"t:none,deny,id:#{id},status:501,severity:3,msg:'Strict headercheck: At least one request header is not predefined for this path.'\"\n"
  string += "\n"

  return string
end

def get_check_strict_requestparameters (id)
  # "strict requestparametercheck" is a modsecurity construct.
  # it guarantees that only known parameters are accepted.
  # every path can have it's own strict set of get- and post-parameters.
  # in modsecurity they are combined into a single collection called ARGS_NAMES.

  # The rule looks like the following:
  #
  # SecRule ARGS_NAMES "!^(username|password)$" "t:none,deny,id:2,status:501,severity:3,msg:'Strict Argumentcheck: At least one request parameter is not predefined for this path.'"
  #
  # A problem is that ARGS_NAMES includes query string arguments and post payload arguments
  # mixed into a single collection
  #
  string = ""

  mystring = ""
  Postparameter.find(:all, :conditions => "request_id = #{id}").each do |parameter|
    mystring += "|" unless mystring.size == 0
    mystring += parameter.name
  end
  Getparameter.find(:all, :conditions => "request_id = #{id}").each do |parameter|
    mystring += "|" unless mystring.size == 0
    mystring += parameter.name
  end

  unless mystring.size == 0
    string += "\n"
    string += "  # Strict argument check (make sure the request contains only predefined request arguments)\n"
    string += "  SecRule ARGS_NAMES \"!^(#{mystring})$\" \"t:none,deny,id:#{id},status:501,severity:3,msg:'Strict Argumentcheck: At least one request parameter is not predefined for this path.'\"\n"
    string += "\n"
  end

  return string
end

def get_check_individual_header (name, domain, id)
  # write a rule that checks a single header for compliance with rules
  # the header is optional
  # but it is in the request, then it is checked
  string = ""
  string += "  # Checking request header \"#{name}\"\n"
  string += "  SecRule &REQUEST_HEADERS:#{name} \"!@eq 0\" \"chain,t:none,deny,id:#{id},status:501,severity:3,msg:'Request header #{name} failed validity check.'\"\n"
  string += "  SecRule REQUEST_HEADERS:#{name} \"!^(#{domain})$\" \"t:none\"\n"

  return string
end

def get_check_individual_getparameter (name, domain, id)
  # write a rule that checks a single query string argument for compliance with rules
  # the header is optional
  # but it is in the request, then it is checked
  string = ""
  string += "  # Checking query string argument \"#{name}\"\n"
  string += "  SecRule REQUEST_BODY \"#{name}[=&]|#{name}$\" \"t:none,deny,id:2,status:501,severity:3,msg:'Query string argument #{name} is present in post payload. This is illegal.'\"\n"
  string += "  SecRule &ARGS:#{name} \"!@eq 0\" \"chain,t:none,deny,id:2,status:501,severity:3,msg:'Query string argument #{name} failed validity check.'\"\n"
  string += "  SecRule ARGS:#{name} \"!^(#{domain})$\" \"t:none\"\n"
  return string
end

def get_check_individual_postparameter (name, domain, id)
  # write a rule that checks a single post parameter for compliance with rules
  # the header is optional
  # but it is in the request, then it is checked
  string = ""
  string += "  # Checking post argument \"#{name}\"\n"
  string += "  SecRule QUERY_STRING \"#{name}[=&]|#{name}$\" \"t:none,deny,id:2,status:501,severity:3,msg:'Post argument #{name} is present in query string. This is illegal.'\"\n"
  string += "  SecRule &ARGS:#{name} \"@eq 0\" \"t:none,deny,id:2,status:501,severity:3,msg:'Post argument #{name} is mandatory, but it is not present in request.'\"\n"
  string += "  SecRule &ARGS:#{name} \"!@eq 0\" \"chain,t:none,deny,id:2,status:501,severity:3,msg:'Post argument #{name} failed validity check.'\"\n"
  string += "  SecRule ARGS:#{name} \"!^(#{domain})$\" \"t:none\"\n"
  return string
end

def get_requestrule(r)
  string = ""

  string += "# allow: #{r.http_method} #{r.path} (request id / rule group #{r.id})\n"
  string += "# #{r.remarks}\n" unless r.remarks.nil?
  string += "<LocationMatch \"^#{r.path}$\">\n"

  # check http method
  string += get_check_http_method(r.http_method, r.id)

  # check names of the headers
  string += get_check_strict_headers(r.id)

  # check individual headers
  Header.find(:all, :conditions => "request_id = #{r.id}").each do |header|
    string += get_check_individual_header(header.name, header.domain, r.id) 
  end
  string += "" unless Header.find(:all, :conditions => "request_id = #{r.id}").size == 0

  # check names of the postparameters and getparameters
  string += get_check_strict_requestparameters(r.id)

  # check individual getparameters
  Getparameter.find(:all, :conditions => "request_id = #{r.id}").each do |getparameter|
    string += get_check_individual_getparameter(getparameter.name, getparameter.domain, r.id) 
  end
  string += "" unless Getparameter.find(:all, :conditions => "request_id = #{r.id}").size == 0

  # check individual postparameters
  Postparameter.find(:all, :conditions => "request_id = #{r.id}").each do |postparameter|
    string += get_check_individual_postparameter(postparameter.name, postparameter.domain, r.id) 
  end
  string += "" unless Postparameter.find(:all, :conditions => "request_id = #{r.id}").size == 0

  string += "\n"
  # all checks for this path passed. So we can allow the request
  string += "  # All checks passed for this path. Request is allowed.\n"
  string += "  SecAction \"allow,id:#{r.id},t:none,msg:'Request passed all checks, it is thus allowed.'\"\n"

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


