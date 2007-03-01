def generate(request=nil, version=nil)
  filename = "rulefile.conf"
  prepend_filename= "prepend-file.conf"
  append_filename= "append-file.conf"

  requests = Request.find(:all, :order => "weight ASC")

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

  def add_check_http_method (file, value, id)
    # check the http method
    #
    # it is problematic, that remo allows a single method per path so far.
    # remo gui should allow regexes on this field.
    #
    file.puts "  # Checking request method"
    file.puts "  SecRule REQUEST_METHOD \"!^#{value}$\" \"t:none,deny,id:#{id},status:501,severity:3,msg:'Request method wrong (it is not #{value}).'\""
    file.puts ""
  end

  def add_check_strict_headers (file, id)
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

    header_string = ""
    Header.find(:all, :conditions => "request_id = #{id}").each do |header|
        header_string += "|" unless header_string.size == 0
        header_string += header.name
    end

    file.puts "  # Strict headercheck (make sure the request contains only predefined request headers)"
    file.puts "  SecRule REQUEST_HEADERS_NAMES \"!^(#{header_string})$\" \"t:none,deny,id:#{id},status:501,severity:3,msg:'Strict headercheck: At least one request header is not predefined for this path.'\""
    file.puts ""

  end

  def add_check_strict_postparameters (file, id)
    # "strict postparametercheck" is a modsecurity construct.
    # it guarantees that only known headers are accepted.
    # every path can have it's own strict set of postparameters.

    # The rule looks like the following:
    #
    # SecRule ARGS_NAMES "!^(username|password)$" "t:none,deny,id:2,status:501,severity:3,msg:'Strict Argumentcheck: At least one request parameter is not predefined for this path.'"
    #
    # A problem is that ARGS_NAMES includes query string arguments and post payload arguments
    # mixed into a single collection
    #

    string = ""
    Postparameter.find(:all, :conditions => "request_id = #{id}").each do |postparameter|
        string += "|" unless string.size == 0
        string += postparameter.name
    end

    unless string.size == 0
      file.puts "  # Strict argument check (make sure the request contains only predefined request arguments)"
      file.puts "  SecRule ARGS_NAMES \"!^(#{string})$\" \"t:none,deny,id:#{id},status:501,severity:3,msg:'Strict Argumentcheck: At least one request parameter is not predefined for this path.'\""
      file.puts ""
    end

  end

  def add_check_individual_header (file, name, domain, id)
    # write a rule that checks a single header for compliance with rules
    # the header is optional
    # but it is in the request, then it is checked
    file.puts "  # Checking request header \"#{name}\""
    file.puts "  SecRule &REQUEST_HEADERS:#{name} \"!@eq 0\" \"chain,t:none,deny,id:#{id},status:501,severity:3,msg:'Request header #{name} failed validity check.'\""
    file.puts "  SecRule REQUEST_HEADERS:#{name} \"!^(#{domain})$\" \"t:none\""
  end

  def add_check_individual_postparameter (file, name, domain, id)
    # write a rule that checks a single header for compliance with rules
    # the header is optional
    # but it is in the request, then it is checked
    file.puts "  # Checking argument \"#{name}\""
    file.puts "  SecRule &ARGS:#{name} \"@eq 0\" \"t:none,deny,id:2,status:501,severity:3,msg:'Argument #{name} is mandatory, but it is not present in request.'\""
    file.puts "  SecRule &ARGS:#{name} \"!@eq 0\" \"chain,t:none,deny,id:2,status:501,severity:3,msg:'Argument #{name} failed validity check.'\""
    file.puts "  SecRule ARGS:#{name} \"!^(#{domain})$\" \"t:none\""
  end

  File.open(filename, "w") do |file|

    append_file(file, prepend_filename, request, version)

    requests.each do |r|
      file.puts "# allow: #{r.http_method} #{r.path} (request id / rule group #{r.id})"
      file.puts "# #{r.remarks}" unless r.remarks.nil?
      file.puts "<LocationMatch \"^#{r.path}$\">"

      # check http method
      add_check_http_method(file, r.http_method, r.id)
  
      # check names of the headers
      add_check_strict_headers(file, r.id)

      # check individual headers
      Header.find(:all, :conditions => "request_id = #{r.id}").each do |header|
        add_check_individual_header(file, header.name, header.domain, r.id) 
      end
      file.puts "" unless Header.find(:all, :conditions => "request_id = #{r.id}").size == 0

      # check names of the postparameters
      add_check_strict_postparameters(file, r.id)

      # check individual headers
      Postparameter.find(:all, :conditions => "request_id = #{r.id}").each do |postparameter|
        add_check_individual_postparameter(file, postparameter.name, postparameter.domain, r.id) 
      end
      file.puts "" unless Postparameter.find(:all, :conditions => "request_id = #{r.id}").size == 0

      # all checks for this path passed. So we can allow the request
      file.puts "  # All checks passed for this path. Request is allowed."
      file.puts "  SecAction \"allow,id:#{r.id},t:none,msg:'Request passed all checks, it is thus allowed.'\""

      file.puts "</LocationMatch>"
      file.puts ""
    end

    append_file(file, append_filename, request, version)

  end

  return filename

end


