require "#{RAILS_ROOT}/remo_config"

def get_logfile_requests(logfile)
  require "audit-log-parser"

  requests = []
  phase = nil
  phaseline = 0
  r = nil
  filename = logfile.name
  linenum = 0
  n = 0

  item = Hash.new
  item["current_part"] = ""
  item["current_part_linenum"] = 0
  item["linenum"] = 1
  requests = Array.new

  params = Hash.new
  params["filters"] = parse_filter("")
  params["collect_requests"] = true

  logfile.content.each do |line|
    item = parse_line(item, line)
    # requests, r, phase, phaseline, n = parse_line(requests, r, filename, linenum, line, phase, phaseline, n)

    if item["current_part"] == "Z" and item["current_part_linenum"] == 0
      # request finished, handling complete request

      request = parse_request_parts(item[item["current_delimiter"]]["partial_request"])
      delimiter = item["current_delimiter"]
      item[delimiter] = nil # undef won't work, this is equally effective, all we want is freeing the memory
      request[:filename] = filename
      request[:num] = requests.size + 1

      # filter code
      display = apply_filter(request, params)

      # adding request
      if params["collect_requests"]
        requests << request
      end

    end
  end

  return requests
end

def get_html_display_logfile(logfile)
  # return a list of requests in a logfile formatted as html

  requests = get_logfile_requests(logfile)

  string = ""
  requests.each do |r|
    if check_logfile_request(r)
     statusimage = "<img src=\"/ok.png\" width=\"16\" height=\"16\" alt=\"image: /ok.png\">"
    else
     statusimage = "<img src=\"/nok.png\" width=\"16\" height=\"16\" alt=\"image: /nok.png\">"
    end
    string += "<div id=\"srequest-#{r[:num]}\" class=\"sourcerequest\">#{statusimage}&nbsp;<a href=\"../displaylogfilerequest/index/#{logfile.id}&#{r[:num]-1}\" target=\"_blank\">view</a> #{r[:num]}: #{r[:method]} #{r[:path]} #{r[:http_version]} #{r[:status]}</div>"
  end

  return string unless string.size == 0
end

def get_check_logfile_requestid(http_method, path)
  # return the request id of the request matching http_method and path

  requests = Request.find(:all, :select => "id, http_method, path")

  requests.each do |r|
    if r.http_method == http_method and not /^(#{r.path})$/.match(path).nil?
      return r.id
    end
  end

  return nil

end

def check_logfile_request_parameter(model, rid, name, value)
  # check wether a given request parameter in a logfile passes with the given ruleset

  if rid.nil?
    return "failed"
  end

  if value.nil?
    value = ""
  end

  parameters = model.find(:all, :conditions => "request_id='#{h(rid)}'")

  parameters.each do |item|

    unless item.standard_domain == "Custom"
      item_domain = STANDARD_DOMAINS[item.standard_domain]
    else
      item_domain = item.custom_domain
    end

    #$stderr.puts "n:#{name} v:#{value} in:#{item.name} id:#{item_domain}"

    if not /^(#{item.name})$/.match(name).nil? 
      
      #$stderr.puts "name hit"
      
      if not /^(#{item_domain})$/.match(value).nil?
        return "passed"
      end
    end

    #$stderr.puts "no hit"

  end

  return "failed"
end

def check_mandatory_parameters(r, rid)
  # check wether a given request in a logfile has all mandatory parameters

  failed_parameters = []

  [Header, Cookieparameter, Querystringparameter, Postparameter].each do |model|
    parameters = model.find(:all, :conditions => "request_id='#{h(rid)}'")
    parameters.each do |item|
      if item.mandatory
        # mandatory item found, checking
        case model.name.downcase 
        when "header"
          rcollection = r[:headers]
        when "cookieparameter"
          rcollection = r[:cookieparameters]
        when "querystringparameter"
          rcollection = r[:querystringparameters]
        when "postparameter"
          rcollection = r[:postparameters]
        end
        hit = false
        rcollection.each do |ritem|
          # loop over parameters in logfile request
          unless /^(#{item.name})$/.match(ritem[:name]).nil?
            # the mandatory parameter is present
            hit = true
          end
        end
        unless hit
          failed_parameters << model.name + ": " + item.name
        end
      end
    end
  end

  return failed_parameters

end

def check_logfile_request(r)
  # check a request for
  # - rule covering http_method and path
  # - rule covering all parameters
  # return true or false

  def myfunc(model, rid, name, value)
    if check_logfile_request_parameter(model, rid, name, value) == "passed"
      return true
    else
      return false
    end
  end

  rid = get_check_logfile_requestid(r[:method], r[:path])

  if rid.nil?
    return false
  end

  if check_mandatory_parameters(r, rid).size > 0
    return false
  end

  model = Header
  r[:headers].each do |name, value|
    unless myfunc(model, rid, name, value)
      return false
    end
  end

  model = Cookieparameter
  r[:cookieparameters].each do |name, value|
    unless myfunc(model, rid, name, value)
      return false
    end
  end

  model = Querystringparameter
  r[:querystringparameters].each do |name, value|
    unless myfunc(model, rid, name, value)
      return false
    end
  end

  model = Postparameter
  r[:postparameters].each do |name, value|
    if name or value
      # rails tends add an empty parameter to imported logfiles
      # with 0 content-length and no post-parameter. This is a workaround.
      unless myfunc(model, rid, name, value)
        return false
      end
    end
  end

  return true
end
