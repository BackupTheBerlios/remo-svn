#!/usr/bin/env ruby
# == Synopsis
#
# read a modsecurity audit log and parse it.
#
# == Usage
#
# ...
# headers, qs, cookies and postparameters only supported for regex filtering
#

require "getoptlong"                                                         
require "find"
require "rdoc/usage"

FIELDSYMBOLS=[:request_id, :status, :status_message ,:method, :path, :http_version, :response_http_version, :message, :apache_handler, :microtimestamp, :duration, :modsectime1, :modsectime2, :modsectime3, :producer, :server]

# ------------------------------------------
# Initialization
# ------------------------------------------


# ------------------------------------------
# Subfunctions
# ------------------------------------------

def read_parameters
  # What   : read command line parameters
  # Input  : none (command line parameters will be fetched by function)
  # Output : hash with command line parameters
  # Example: params = read_parameters()
  # Remarks: parameters are read, but not sanitized and not checked

  params = Hash.new

  begin
    opts = GetoptLong.new(
      [ '-h', '--help', '-?', '-u', '--usage',  GetoptLong::NO_ARGUMENT ],
      [ '-d', '--debug',                        GetoptLong::NO_ARGUMENT ],
      [ '-f', '--filter',                       GetoptLong::REQUIRED_ARGUMENT ]
    )

    opts.each do |opt, arg|
      case opt
        when '-h'
          RDoc::usage
          exit
        when '--help'
          RDoc::usage
          exit
        when '-u'
          RDoc::usage
          exit
        when '--usage'
          RDoc::usage
          exit
        when '-?'
          RDoc::usage
          exit
        when '-d'
          params["debug"] = true
        when '--debug'
          params["debug"] = true
        when '-f'
          params["filterstring"] = arg
        when '--filter'
          params["filterstring"] = arg
      end
    end
  rescue
    RDoc::usage
    exit
  end

  params["filenames"] = ARGV

  if params["debug"]
    puts "read_parameters debug:          #{params["debug"]}"
    puts "read_parameters filenames:      #{params["filenames"].each do |file| file ; end}"
    puts "read_parameters filterstring:   #{params["filterstring"]}"
  end

  return params

end

def sanitize_check_parameters(params)
  # What   : sanitize and check the command line parameters
  # Input  : hash with command line parameters
  # Output : cleaned hash with command line parameters
  # Example: params = sanitize_check_parameters(params)
  # Remarks: function will exit, if it can not cope with a certain parameter 
  #          or if it is really illegal. An inexisting/unreadable file will 
  #          be ignored unless it is the only input.

  params["filters"] = parse_filter(params["filterstring"])

  if params["filenames"].length == 0 and not check_stdin()
      $stderr.puts "No filenames passed. This is fatal. Aborting."
      RDoc::usage
      exit 1
  else
    params["filenames"].each do |filename|
      unless File::exists?(filename)
        $stderr.puts "File #{filename} not found. This is fatal. Aborting."
        exit 1
      end
    end
  end
      
  if not defined?(params["output"])
    params["output"] = ""
  end

  if params["debug"]
    puts "sanitize_check_parameters debug:         #{params["debug"]}"
    puts "sanitize_check_parameters filenames:     #{params["filenames"].each do |file| file; end}"
    puts "sanitize_check_parameters filters.size:  #{params["filters"].size}"
    puts "sanitize_check_parameters output:        #{params["output"]}"
  end

  return params

end

def parse_filter(filterstring)
  # What   : parse a filterstring as passed by the user
  # Input  : filterstring
  # Output : array of hashes with the filter
  # Example: params["filters"] = parse_filter(params["filterstring"])
  # Remarks: function will abort on certain conditions
  #          AND is supported. OR is not supported yet.
  #          But an OR can be done via regular expressions

  filters = []
  fieldname, operator, parameter = nil
  
  unless filterstring.nil?
    myfilterstring = filterstring.gsub(" and ", " AND ")  # capitalize AND
    myfilterstring = myfilterstring.gsub(" or ", " OR ")  # capitalize OR (which is not supported. see below)
    
    if myfilterstring.split(" OR ").length > 1
      $stderr.puts "Filter contains \"OR\" resp. \"or\". This is not supported. Aborting."
      exit 1
    end

    begin
      filterstringparts = myfilterstring.split(" AND ")

      filterstringparts.each do |item|
        fieldname, operator, parameter = item.split(" ", 3)
        if fieldname.nil? or operator.nil? or parameter.nil?
          # garbled filteritem
          raise
        end
        
        # canonify fieldname
        fieldname = fieldname.gsub(":", "_sub_").gsub("-", "_strike_")
          # turn Header:Accept-Encoding into Header_sub_Accept_strike_Encoding
          # the fieldname will be turned into ruby symbol, which does not allow
          # certain characters
        
        # canonify operator
        operator = "==" if operator == "="  
        if ["==", "!=", ">=", "<=", ">", "<", "=~", "!=~" ].index(operator).nil?
          # check for known operators
          $stderr.puts "Filter operator #{operator} is not known. This is fatal. Aborting."
          exit 1
        end

        # canonify parameter
        parameter = parameter.chomp.strip
        if ["==", "!="].index(operator)
          parameter = parameter[1..parameter.length] if parameter[0..0] == "\"" # remove beginning " if there is one
          parameter = parameter[0..parameter.length-2] if parameter[-1..-1] == "\"" # remove trailing " if there is one
        end

        if operator == "=~" or operator == "!=~"
          parameter = parameter[1..parameter.length] if parameter[0..0] == "/" # remove beginning slash if there is one
          parameter = parameter[0..parameter.length-2] if parameter[-1..-1] == "/"  # remove trailing slash if there is one
        end

        fieldsymbol = fieldname.intern # map string to symbol

        # check field (we only take predefined ones)
        if FIELDSYMBOLS.index(fieldsymbol).nil? \
           and /^(header_|cookie_|querystringparameter_|postparameter_)/i.match(fieldname.downcase).nil? 
           $stderr.puts "Filter field #{fieldname} not supported. This is fatal. Aborting."
            exit 1
        end

        if fieldsymbol == :message and (operator != "=~" and operator != "!=~")
           $stderr.puts "Filter field message only supports operator =~ and !=~. Aborting."
           exit 1
        end

        filters << {"field" => fieldsymbol, "operator" => operator , "parameter" => parameter}

      end

    rescue
      $stderr.puts "Could not parse filter (current subitem is fieldname/operator/paramter: #{fieldname}/#{operator}/#{parameter}). This is fatal. Aborting."
      exit 1
    end
  end

  return filters

end

def is_serial_log(content)
  # What   : check wether a string is a serial audit-log
  # Input  : string (content of file)
  # Output : true if it is a serial log, false if it is not
  # Example: foo = is_serial_log(file.read)
  # Remarks: none

  content.each do |line|
    unless /^#/.match(line) or /^$/.match(line)
      # this is the first non-comment and non-empty line
      if /^--[\w\d]+-[A-Z]--$/.match(line)
        return true
      else
        return false
      end
    end
  end
  return false
end

def check_stdin ()
  # What   : check for existence of stdin
  # Input  : none
  # Output : true if there is stdin, false if there is none
  # Example: foo = check_stdin()
  # Remarks: none

  if STDIN.tty?
    # no stdin
    return false
  else
    # stdin
    return true
  end
end

def parse_line(item, line)
  # What   : parse a single line within a modsecurity audit log
  # Input  : partial request item (hash), a line
  # Output : updated partial request item (hash)
  # Example: item = parse_line(item, line)
  # Remarks: this function is mainly used to split the request item within
  #          the file into multiple parts.
  #          this is done by calling the function line after line and
  #          it will shuffle the line into the item and return the updated
  #          item.
  #          The parts of a modsecurity audit log are identified by a line 
  #          with the following format (example)
  #          --c7036611-H--
  #          for more info see
  #          http://www.modsecurity.org/blog/archives/2008/01/modsecurity_dat.html
  #          If a new request is starting with ..-A-- without an old one being 
  #          finished we are bailing out. (FIXME)

  item["current_part_linenum"] += 1

  if /^--[\w\d]+-[A-Z]--$/.match(line)
    # part start identified
    delimiter = line.split("-")[2]
    if line.split("-")[3] == "A"
      # new request starting
      item[delimiter] = Hash.new 
      item[delimiter]["partial_request"] = Hash.new
      item[delimiter]["partial_request"]["delimiter"] = delimiter
      item[delimiter]["partial_request"]["parts"] = Hash.new
    end
    item["current_delimiter"] = delimiter
    item["current_part"] = line.split("-")[3]
    item["current_part_linenum"] = 0
  elsif not item["current_delimiter"].nil? \
        and (item["current_part"] != "Z" or \
            (item["current_part"] == "Z" and item["current_part_linenum"] == 0) \
            )
    delimiter = item["current_delimiter"]
    if item[item["current_delimiter"]]["partial_request"]["parts"][item["current_part"]].nil?
       item[item["current_delimiter"]]["partial_request"]["parts"][item["current_part"]] = ""
    end
    item[item["current_delimiter"]]["partial_request"]["parts"][item["current_part"]] += line 
  end

  return item
end

def parse_request_parts(partial_request)
  # What   : parse the individual parts of a request
  # Input  : partial_request hash
  # Output : parsed request as hash
  # Example: request = parse_request_parts(item["partial_request"])
  # Remarks: see http://www.modsecurity.org/blog/archives/2008/01/modsecurity_dat.html
  #          for information about the audit-log parts
  
  def parse_request_part_A(request, part)
    # What   : parse a audit-log part and fill it into a request hash
    # Input  : request hash and part string
    # Output : request hash
    # Example: request = parse_request_part_A(request, partial_request["parts"]["A"])
    # Remarks: none

    begin
      line = part.split("\n")[0]
      request[:timestamp] = line.split(/[\[\]]/)[1]
      foo, bar, request[:request_id], \
        request[:remote_addr], request[:remote_port], \
        request[:local_addr], request[:local_port] = line.split(" ")
    rescue
      puts "Problems parsing request with delimiter #{request[:request_delimiter]} in part A. Ignoring problems."
    end

    return request
  end

  def parse_request_part_B(request, part)
    # What   : parse a audit-log part and fill it into a request hash
    # Input  : request hash and part string
    # Output : request hash
    # Example: request = parse_request_part_B(request, partial_request["parts"]["A"])
    # Remarks: none

    begin
      lines = part.split("\n")

      # treat first request line
      request[:method] = lines[0].split(" ")[0]
      request[:path] = lines[0].split(" ")[1]
      request[:http_version] = lines[0].split(" ")[2]
      request[:path], request[:querystring] = request[:path].split("?", 2)
      request[:querystringparameters] = Hash.new
      request[:cookieparameters] = Hash.new

      if not request[:querystring].nil?
        request[:querystring].split("&").each do |item|
          request[:querystringparameters][item.split("=")[0]] = item.split("=")[1]
        end
      end

      # treat remaining request lines
      request[:headers] = Hash.new
      for i in 1..lines.size-1
        request[:headers][lines[i].split(":")[0]] = lines[i].split(":", 2)[1].strip
      end

      if request[:headers]["Cookie"]
        request[:headers]["Cookie"].split("; ").each do |item|
          name, value = item.split("=", 2)
          request[:cookieparameters][name] = value 
        end
      end

    rescue
      puts "Problems parsing request with delimiter #{request[:request_delimiter]} in part A. Ignoring problems."
    end

    return request
  end

  def parse_request_part_C(request, part)
    # What   : parse a audit-log part and fill it into a request hash
    # Input  : request hash and part string
    # Output : request hash
    # Example: request = parse_request_part_C(request, partial_request["parts"]["A"])
    # Remarks: none

    begin
      request[:postparameters] = Hash.new

      content_type = ""
      unless request[:headers].select { |key,value| key.downcase == "content-type" }[0].nil?
        content_type = request[:headers].select { |key,value| key.downcase == "content-type" }[0][1]
      end
      if defined?(content_type) and part
        multipart_name, multipart_value = nil
        if /^multipart\/form-data/.match(content_type).nil? == false
          # multipart form data
          boundary = content_type.split("boundary=", 2)[1]

          multipart_name = nil
          part.each do |line|
            if not /#{boundary}/.match(line).nil?
              # boundary line
              if defined?(multipart_name) and not multipart_name.nil?
                # finished an item with the boundary, adding the item to the post parameters
                request[:postparameters][multipart_name] = multipart_value
                multipart_name = nil
                multipart_value = nil
              end
            elsif /^Content-Disposition: form-data/i.match(line)
              # disposition line
              name = line.split("=", 2)[1]
              name.sub!(/^"/, "")
              name.chomp!
              name.sub!(/"$/, "")
              multipart_name = name
              multipart_value = nil  # define it as nil
            else
              if defined?(multipart_name)
                if multipart_value.nil? and line.size <= 2
                  multipart_value = "" # set from nil to "" on the empty line after the content disposition
                else
                  # now adding to the value
                  if not defined?(multipart_value) or multipart_value.nil?
                    multipart_value=""
                  end
                  multipart_value = multipart_value + line
                end
             end
            end
          end

        elsif /^application\/x-www-form-urlencoded/.match(content_type).nil? == false
          # form urlencoded
          items = part.split("&")
          if items.size > 0
            items.each do |item|
              item.chomp!
              request[:postparameters][item.split("=")[0]] = item.split("=")[1]
            end
          end
        else
          puts "Content type unknown in request with delimiter #{request[:request_delimiter]} in part A. Ignoring body."
        end
      
      end
    rescue
      puts "Problems parsing request with delimiter #{request[:request_delimiter]} in part C. Ignoring problems."
    end

    return request
  end

  def parse_request_part_E(request, part)
    # What   : parse a audit-log part and fill it into a request hash
    # Input  : request hash and part string
    # Output : request hash
    # Example: request = parse_request_part_E(request, partial_request["parts"]["A"])
    # Remarks: none

    begin
      request[:response_body] = part
    rescue
      puts "Problems parsing request with delimiter #{request[:request_delimiter]} in part E. Ignoring problems."
    end

    return request
  end

  def parse_request_part_F(request, part)
    # What   : parse a audit-log part and fill it into a request hash
    # Input  : request hash and part string
    # Output : request hash
    # Example: request = parse_request_part_F(request, partial_request["parts"]["A"])
    # Remarks: none
    # http response headers
    
    begin
      lines = part.split("\n")

      # treat first request line
      request[:response_http_version] = lines[0].split(" ")[0]
      request[:status] = lines[0].split(" ")[1]
      request[:status_message] = lines[0].split(" ")[2]

      # treat remaining request lines
      request[:response_headers] = Hash.new
      for i in 1..lines.size-1
        request[:response_headers][lines[i].split(":")[0]] = lines[i].split(":", 2)[1].strip
      end

    rescue
      puts "Problems parsing request with delimiter #{request[:request_delimiter]} in part F. Ignoring problems."
    end

    return request
  end

  def parse_request_part_H(request, part)
    # What   : parse a audit-log part and fill it into a request hash
    # Input  : request hash and part string
    # Output : request hash
    # Example: request = parse_request_part_H(request, partial_request["parts"]["A"])
    # Remarks: none
  
    request[:modsec_messages] = Array.new
    begin
      request[:audit_trailer] = part
      lines = part.split("\n")
      for i in 0..lines.size-1
        if not /^Message: /.match(lines[i]).nil? 
          # ModSecurity message
          request[:modsec_messages] << lines[i].chomp.gsub("Message: ", "")
        elsif not /^Apache-Handler: /.match(lines[i]).nil? 
          request[:apache_handler] = lines[i].chomp.gsub("Apache-Handler: ", "")
        elsif not /^Stopwatch: /.match(lines[i]).nil? 
          foo = lines[i].chomp.gsub("Stopwatch: ", "").split(" ")
          request[:microtimestamp] = foo[0]
          request[:duration] = foo[1]
          request[:modsectime1] = foo[2].gsub("(", "")
          request[:modsectime2] = foo[3]
          request[:modsectime3] = foo[4].gsub(")", "")
        elsif not /^Producer: /.match(lines[i]).nil? 
          request[:producer] = lines[i].chomp.gsub("Producer: ", "")
        elsif not /^Server: /.match(lines[i]).nil? 
          request[:server] = lines[i].chomp.gsub("Server: ", "")
        end
      end

    rescue
      puts "Problems parsing request with delimiter #{request[:request_delimiter]} in part H. Ignoring problems."
    end

    return request
  end

  def parse_request_part_I(request, part)
    # What   : parse a audit-log part and fill it into a request hash
    # Input  : request hash and part string
    # Output : request hash
    # Example: request = parse_request_part_I(request, partial_request["parts"]["A"])
    # Remarks: FIXME: this is not yet supported

    if part
      $stderr.puts "Part I not supported yet. Ignoring."
    end

    return request
  end

  def parse_request_part_K(request, part)
    # What   : parse a audit-log part and fill it into a request hash
    # Input  : request hash and part string
    # Output : request hash
    # Example: request = parse_request_part_K(request, partial_request["parts"]["A"])
    # Remarks: FIXME: this is not yet supported

    if part
      $stderr.puts "Part K not supported yet. Ignoring."
    end

    return request
  end

  request = Hash.new

  request[:delimiter] = partial_request["delimiter"]
  request[:filename] = partial_request[:filename]

  ["A", "B", "C", "E", "F", "H", "I", "K"]. each do |part|
    case part
    when "A"
      request = parse_request_part_A(request, partial_request["parts"]["A"])
    when "B"
      request = parse_request_part_B(request, partial_request["parts"]["B"])
    when "C"
      request = parse_request_part_C(request, partial_request["parts"]["C"])
    when "D"
      # reserved in ModSecurity, but not implemented yet in ModSecurity
    when "E"
      request = parse_request_part_E(request, partial_request["parts"]["E"])
    when "F"
      request = parse_request_part_F(request, partial_request["parts"]["F"]) 
    when "G"
      # reserved in ModSecurity, but not implemented yet in ModSecurity
    when "H"
      request = parse_request_part_H(request, partial_request["parts"]["H"])
    when "I"
      request = parse_request_part_I(request, partial_request["parts"]["I"])
    when "J"
      # reserved in ModSecurity, but not implemented yet in ModSecurity
    when "K"
      request = parse_request_part_I(request, partial_request["parts"]["K"])
    end
  end

  request[:parts]=partial_request["parts"] # the parts string is being preserved

  return request

end

def apply_filter (request, params)
  # What   : apply a filter to a request and determine wether it should be displayed or not
  # Input  : request hash and params hash
  # Output : display bool
  # Example: display = apply_filter(request, params)
  # Remarks: none

  display = true

  params["filters"].each do |filter|
    if filter["field"] == :message
      # special treatment below
    elsif /(_sub_|_strike_)/.match(filter["field"].to_s).nil?
      value = request[filter["field"]].to_s
    else
      prefix, name = filter["field"].to_s.gsub("_strike_", "-").split("_sub_")
      if prefix.downcase == "header"
        value = request[:headers][name]
      elsif prefix.downcase == "querystringparameter"
        value = request[:querystringparameters][name]
      elsif prefix.downcase == "cookie"
        value = request[:cookieparameters][name]
      elsif prefix.downcase == "postparameter"
        value = request[:postparameters][name]
      end
    end
    operator = filter["operator"]
    parameter = filter["parameter"]

    puts "run_parser applying filter: #{value} #{operator} #{parameter}" if params["debug"]

    if filter["field"] == :message
      mydisplay = false
      if operator == "=~"
        request[:modsec_messages].each do |value|
          if not /#{parameter}/.match(value).nil?
            mydisplay = true
          end
        end
      elsif operator == "!=~"
        request[:modsec_messages].each do |value|
          if /#{parameter}/.match(value).nil?
            mydisplay = true
          end
        end
      end
      display = false if not mydisplay
    elsif value.nil?
      # looks like the field was not part of the request
      display = false
    elsif value == value.to_i.to_s and ["==", "!=", ">=", "<=", ">", "<"].index(operator)
      # filtering for number
      if not eval "#{value} #{operator} #{parameter}"
        display = false
      end
    elsif operator == "=~"
      if /#{parameter}/.match(value).nil?
        display = false
      end
    elsif operator == "!=~"
      unless /#{parameter}/.match(value).nil?
        display = false
      end
    elsif value.to_s == "-" and parameter.to_i > 0
        # filtering for number, but there is "-" in the logfile instead.
        # this happens with modsectime[1-3] in some situations
        display = false
    elsif value.to_s.length > 0 and ["==", "!="].index(operator)
      # filtering for string
      if not eval "\"#{value}\" #{operator} \"#{parameter.gsub("\"","")}\""
        display = false
      end
      # puts "#{value} #{operator} #{parameter} #{display}"
    else 
      $stderr.puts "Can not cope with filter value/operator/parameter (#{value} #{operator} #{parameter}) in request with id #{request[:request_id]}. Not applying this filter to this request."
    end

  end

  return display

end

def run_parser(filename, requests, params)
  # What   : parse and process a single file and optionally return the requests
  # Input  : filename, requests array, params hash
  # Output : requests array
  # Example: requests = run_parser(params["filenames"][0], requests, params)
  # Remarks: parsing includes display

  def print_debug_line_information (item)
    # What   : print debug information about a line being processed
    # Input  : request hash
    # Output : none
    # Example: print_debug_line_information (item) if params["debug"]
    # Remarks: none

    puts "run_parser line parsed"
    puts "run_parser partial_request.request_delimiter:    #{item["partial_request"]["request_delimiter"]}"
    puts "run_parser part:                #{item["part"]}"
    puts "run_parser part_linenum:        #{item["part_linenum"]}"
    puts "run_parser partial_request.parts.size: #{item["partial_request"]["parts"].size}"
  end

  def print_debug_request_information (request)
    # What   : print debug information about complete request
    # Input  : request hash
    # Output : none
    # Example: print_debug_request_information (request) if params["debug"]
    # Remarks: none

    puts "run_parser new request delimiter:      #{request[:delimiter]}"
    puts "run_parser new request timestamp:      #{request[:timestamp]}"
    puts "run_parser new request request_id:     #{request[:request_id]}"
    puts "run_parser new request remote_addr:    #{request[:remote_addr]}"
    puts "run_parser new request remote_port:    #{request[:remote_port]}"
    puts "run_parser new request local_addr:     #{request[:local_addr]}"
    puts "run_parser new request local_port:     #{request[:local_port]}"
    puts "run_parser new request method:         #{request[:method]}"
    puts "run_parser new request path:           #{request[:path]}"
    puts "run_parser new request version:        #{request[:http_version]}"
    puts "run_parser new request querystring:    #{request[:querystring]}"
    request[:querystringparameters].each do |key,value|
      puts "run_parser new request querystringparameter: #{key}=#{value}"
    end
    request[:headers].each do |key,value|
      puts "run_parser new request header: #{key}: #{value}"
    end
    request[:postparameters].each do |key,value|
      puts "run_parser new request postparameter: #{key}: #{value}"
    end
    puts "run_parser new request response body.size: #{request[:response_body].size}"
    puts "run_parser new request response version: #{request[:response_http_version]}"
    puts "run_parser new request response status:  #{request[:status]}"
    puts "run_parser new request response status message:  #{request[:status_message]}"
    request[:response_headers].each do |key,value|
      puts "run_parser new request response headers: #{key}: #{value}"
    end
    puts "run_parser new request audit trailer.size:  #{request[:audit_trailer].size}"
  end


  def display_request(request)
    # What   : display a request in ModSecurity audit-log format
    # Input  : request hash
    # Output : request via STDOUT, no return value
    # Example: display_request(request) if display
    # Remarks: none

    ["A", "B", "C", "F", "E", "H", "I", "K"]. each do |part|
      if request[:parts][part]
        puts "--#{request[:delimiter]}-#{part}--"
        puts request[:parts][part]
      end
    end
    puts "--#{request[:delimiter]}-Z--"
    puts
  end

  def run_parser_io (filename, requests, item, line, params)
    puts "run_parser parsing line #{item["linenum"]}:      #{line}" if params["debug"]
   
    # parse line
    item = parse_line(item, line)

    print_debug_line_information (item) if params["debug"]

    if item["current_part"] == "Z" and item["current_part_linenum"] == 0
      # request finished, handling complete request

      puts "run_parser adding request with delimiter #{item[item["current_delimiter"]]["partial_request"]["request_delimiter"]}" if params["debug"]

      # interprete request
      request = parse_request_parts(item[item["current_delimiter"]]["partial_request"])
      delimiter = item["current_delimiter"]
      item[delimiter] = nil # undef won't work, this is equally effective, all we want is freeing the memory
      request[:filename] = filename
      request[:num] = requests.size + 1

      print_debug_request_information (request) if params["debug"]

      # filter code
      display = apply_filter(request, params)
      puts "run_parser filter code done. Display has value #{display}" if params["debug"]

      display_request(request) if display and not params["output"] == "none"

      # adding request
      if params["collect_requests"]
        requests << request
      end

    end
    
    item["linenum"] += 1

  end

  item = Hash.new
  item["current_part"] = ""
  item["current_part_linenum"] = 0
  item["linenum"] = 1
  requests = Array.new

  if filename == STDIN
    STDIN.each do |line|
      run_parser_io("STDIN", requests, item, line, params)
    end
  else
    unless /ascii/i.match(`file #{filename}`.chomp) or /unicode text/i.match(`file #{filename}`.chomp) or /: data$/i.match(`file #{filename}`.chomp) or /iso-8859/i.match(`file #{filename}`.chomp)
      $stderr.puts "Unknown filetype of file #{filename}. This is fatal. Aborting."
      exit 1
    end
    File.open(filename) do |handler|
      handler.each do |line|
        run_parser_io(filename, requests, item, line, params)
      end
    end
  end

  return requests

end

# ----------------------------------
# MAIN
# ----------------------------------

def main
  params = read_parameters()

  params = sanitize_check_parameters(params)

  requests = Array.new

  requests = run_parser(STDIN, requests, params) if check_stdin()
  params["filenames"].each do |filename|
    requests = run_parser(filename, requests, params)
  end
end

if __FILE__ == $0
  main
end
  
