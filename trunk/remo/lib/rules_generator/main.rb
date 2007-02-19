require 'helpers/various'

def generate(request=nil, version=nil, request_detail_fields=[])
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
    file.puts "  SecRule REQUEST_METHOD \"!^#{value}$\" \"t:none,deny,id:#{id},t:none,status:501,severity:3,msg:'Request method wrong (it is not #{value}).'\""
  end

  def add_check_strict_headers (file, id)
    # "strict headercheck" is a modsecurity construct.
    # it guarantees that only known headers are accepted.
    # every path can have it's own strict headerset.

    # The rule looks like the following:
    #
    # SecRule REQUEST_HEADERS_NAMES "!^(User-Agent|Host|Accept|ZZZ|XXX|YYY)$" "setvar:TX.INVALID=1,t:none,pass"
    # SecRule "TX:INVALID"  "^1$" "deny,status:501,severity:3,msg:'Strict headercheck: At least one request header unknown for this path.'"
    #
    # In this example, only User-Agent, Host, Accept and ZZZ are accepted as headers.
    # Every other header would lead to a denial of the request.
    #

    # FIXME: Check for empty headerlist

    header_string = ""
    Header.find(:all, :conditions => "request_id = #{id}").each do |header|
        header_string += "|" unless header_string.size == 0
        header_string += header.name
    end

    file.puts "  # Strict headercheck (make sure the request contains only predefined request headers)"
    file.puts "  SecRule REQUEST_HEADERS_NAMES \"!^(#{header_string})$\" \"t:none,deny,id:#{id},status:501,severity:3,msg:'Strict headercheck: At least one request header is not predefined for this path.'\""

  end

  def add_check_individual_header (file, name, value, id)
    # write a rule that checks a single header for compliance with rules
    # the header is optional
    # but it is in the request, then it is checked
    file.puts "  # Checking request header \"#{name}\""
    file.puts "  SecRule &HTTP_#{name} \"!^0$\" \"chain,t:none,deny,id:#{id},status:501,severity:3,msg:'Request header #{name} failed validity check.'\""
    file.puts "  SecRule HTTP_#{name} \"!^(#{value})$\" \"t:none\""
  end



  File.open(filename, "w") do |file|

    append_file(file, prepend_filename, request, version)

    requests.each do |r|
      file.puts "# allow: #{r.http_method} #{r.path} (request id / rule group #{r.id})"
      file.puts "# #{r.remarks}" unless r.remarks.nil?
      file.puts "<LocationMatch \"^#{r.path}$\">"

      # check http method
      add_check_http_method(file, r.http_method, r.id)
      file.puts ""
  
      # check names of the headers
      add_check_strict_headers(file, r.id)
      file.puts ""

      # check individual headers
      Header.find(:all, :conditions => "request_id = #{r.id}").each do |header|
        add_check_individual_header(file, header.name, header.domain, r.id) 
      end
      file.puts ""

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


