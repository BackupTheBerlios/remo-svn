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

  logfile.content.each do |line|
    requests, r, phase, phaseline, n = parse_line(requests, r, filename, linenum, line, phase, phaseline, n)
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
    string += "<div id=\"srequest-#{r[:num]}\" class=\"sourcerequest\">#{statusimage}&nbsp;<a href=\"../displaylogfilerequest/index/#{logfile.id}&#{r[:num]}\" target=\"_blank\">view</a> #{r[:num]}: #{r[:http_method]} #{r[:uri]} #{r[:version]} #{r[:status_code]}</div>"
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

  parameters = model.find(:all, :conditions => "request_id='#{h(rid)}'")

  parameters.each do |item|
    unless item.standard_domain == "Custom"
      item_domain = STANDARD_DOMAINS[item.standard_domain]
    else
      item_domain = item.custom_domain
    end

    if not /^(#{item.name})$/.match(name).nil? and not /^(#{item_domain})$/.match(value).nil?
      return "passed"
    end
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

  rid = get_check_logfile_requestid(r[:http_method], r[:path])

  if rid.nil?
    return false
  end

  if check_mandatory_parameters(r, rid).size > 0
    return false
  end

  def myfunc(model, rid, item)
    if check_logfile_request_parameter(model, rid, item[:name], item[:value]) == "passed"
      return true
    else
      return false
    end
  end

  model = Header
  r[:headers].each do |item|
    unless myfunc(model, rid, item)
      return false
    end
  end

  model = Cookieparameter
  r[:cookieparameters].each do |item|
    unless myfunc(model, rid, item)
      return false
    end
  end

  model = Querystringparameter
  r[:querystringparameters].each do |item|
    unless myfunc(model, rid, item)
      return false
    end
  end

  model = Postparameter
  r[:postparameters].each do |item|
    unless myfunc(model, rid, item)
      return false
    end
  end

  return true
end
