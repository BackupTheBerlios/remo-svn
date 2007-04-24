#!/usr/bin/env ruby
#
# read a modsecurity audit log and parse it.
#

require "getoptlong"                                                         
require "net/http"
require "find"

def main ()
  display, filenames, ids, quiet, reinject, stdin, summary, verbose = get_options 
    # filename is checked for existence/readability in get_options

  request_limit=nil
  unless ids.nil?
    ids.each do |item|
      request_limit = [request_limit.to_i, item.to_i].max if item.max == item.max.to_i.to_s # only numerical ids are taken as request_limit
    end
  end
  requests = parse_logfiles(filenames, stdin, request_limit)

  display_requests(requests, ids, verbose) if display
  successes, failures = reinject_requests(requests, ids, verbose, quiet) if reinject
  display_summary(requests, verbose, successes, failures) if summary

  unless failures.nil?
    if failures > 0
      exit 1
    end
  end

  exit 0

end

def print_usage
   puts "usage:"
   puts "    #{$0} filename [...]"
   puts "    <STDIN> | #{$0}"
   puts 
   puts " filename can be serial logfile or path to tree of concurrent logfiles"
   puts
   puts "-h --help      help, print this usage information"
   puts "-i --id str    request id or comma-separated list of request ids"
   puts "               id can be an index number or the unique_id"
   puts "               of the request."
   puts "-l --list      display requests"
   puts "-r --reinject  reinject requests"
   puts "-q --quiet     be quiet"
   puts "-s --summary   bring a summary report at the end"
   puts "-v --verbose   be verbose"
   puts
   puts "Filename is a mandatory parameter unless STDIN is provided."
   puts
   puts "#{0} returns 0 if all reinjections were successful."
   puts "1 in case there has been a failure."
   puts 
end

def parse_line(requests, r, filename, linenum, line, phase, phaseline, n)
     phaseline += 1
      regex_serial_phase_start=

      if /^--[\w\d]+-[A-Z]--$/.match(line)
        # serial phase starting
        phase = line.split("-")[3]
        phaseline = 0
      end

      # data retrieval
      if phase == "A" and phaseline == 0
        r = {}
        r[:num] = n
        r[:filename] = filename
        r[:startline] = linenum
        phase = line.split("-")[3]
        n += 1
      end
      if phase == "A" and phaseline == 1
        r[:remote_address] = get_token(line, 3)
        r[:request_id] = get_token(line, 2)
      end
      if phase == "B" and phaseline == 1
        r[:http_method] = get_token(line, 0)
        r[:uri] = get_token(line,1)
        r[:path] = get_token(r[:uri], 0, "?")
        if /\?/.match(r[:uri])
          r[:querystring] = r[:uri].sub(/.*?\?/, "") # querystring, even if it comes with "?" in it. Using a non-greedy regular expression to find the first "?"
        else
          r[:querystring] = ""
        end
        r[:version] = get_token(line, 2)
        r[:querystringparameters] = []
        r[:headers] = []
        r[:cookieparameters] = []
        r[:postparameters] = []
        r[:response_content_length] = ""
        unless r[:querystring].nil?
          r[:querystring].split("&").each do |item|
            name = item.split("=")[0]
            if item.split("=").size > 1
              value = item.gsub(name + "=", "")
            else
              value = ""
            end
            r[:querystringparameters] << {:name => name, :value => value.chomp}
          end
        end
      end
      if phase == "B" and phaseline > 1 and line.size > 1
        name = line.split[0].gsub(":", "")
        value = line[name.size + 2,100000]
        r[:headers] << {:name => name, :value => value.chomp}
        if name.downcase == "host"
          r[:host] = value.chomp
        end
        if name.downcase == "cookie"
          value.split("; ").each do |item|
          name = item.split("=")[0]
          if item.split("=").size > 1
            value = item.gsub(name + "=", "")
          else
            value = ""
          end
          r[:cookieparameters] << {:name => name, :value => value.chomp}
          end
        end
      end
      if phase == "C" and phaseline > 0 and line.size > 1
        line.split("&").each do |item|
          name = item.split("=")[0]
          if item.split("=").size > 1
            value = item.gsub(name + "=", "")
          else
            value = ""
          end
          r[:postparameters] << {:name => name, :value => value.chomp}
        end
      end
      if phase == "F" and phaseline == 1 and line.size > 1
        r[:status_code] = line.split[1].to_i
        r[:status_code_name] = line.split[2]
      end
      if phase == "F" and phaseline >= 1 and not /^Content-Length:/.match(line).nil?
        r[:response_content_length] = get_token(line, 1)
      end
      if phase == "F" and phaseline >= 1 and not /^Location:/.match(line).nil?
        r[:response_location] = get_token(line, 1)
      end
      if phase == "H" and phaseline == 1 and /^Message/.match(line) and line.size > 1 and
        r[:modsecurity_message] = line.gsub("Message: ", "").chomp
      end
      if phase == "Z" and phaseline == 0
        requests << r
      end

      return requests, r, phase, phaseline, n
end

def parse_logfiles(filenames, stdin, request_limit=nil, n=0)

  requests = []

  def is_serial_log(filename)
    IO.foreach(filename) do |line|
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

  if stdin

    phase = nil
    phaseline = 0
    r = nil

    until $stdin.eof? do
      requests, r, phase, phaseline, n = parse_line(requests, r, filename, "stdin", $stdin.readline, phase, phaseline, n)
    end

  else

    filenames.each do |filename|
      if FileTest::directory?(filename)
    
        Find.find(filename) do |path|
          Find.prune if [".",".."].include? path
          unless FileTest::directory?(path)
            if request_limit.nil?
              requests = requests | parse_logfiles([path], false, request_limit, requests.size) # append new requests to requests (union of sets)
            elsif (requests.size <= request_limit.to_i) 
              requests = requests | parse_logfiles([path], false, request_limit, requests.size) # append new requests to requests (union of sets)
            else
              break
            end
          end
        end
      elsif is_serial_log(filename)
        phase = nil
        phaseline = 0
        r = nil

        linenum = 0
        IO.foreach(filename) do |line|
          if request_limit.nil?
            requests, r, phase, phaseline, n = parse_line(requests, r, filename, linenum, line, phase, phaseline, n)
          elsif (requests.size <= request_limit.to_i) 
            requests, r, phase, phaseline, n = parse_line(requests, r, filename, linenum, line, phase, phaseline, n)
          else
            break
          end
          linenum += 1
        end
      else
        puts "Unknown logfile type: #{filename}. Aborting."
      end
    end
  end

  return requests

end

def get_token(line, num, separator=" ")
  return line.split(separator)[num]
end

def get_integer_id_from_alphanumerical_id(requests, id)
  requests.size.times do |i|
    return i if requests[i][:request_id] == id
  end
  return nil
end

def get_number_of_requests(requests, http_method="GET")
  # get the number of requests for a give http_method
  n = 0
  requests.size.times do |i|
    n += 1 if requests[i][:http_method] == http_method
  end
  return n
end

def display_summary(requests, verbose, successes=nil, failures=nil)
  puts "Number of requests: #{requests.size}"
  if verbose
    ["GET", "POST", "HEAD", "TRACE", "PUT", "DELETE", "CONNECT", "OPTIONS"].each do |http_method|
      num = get_number_of_requests(requests, http_method)
      puts "Number of #{http_method} requests: #{num}" unless num == 0
    end
  end
  unless successes.nil?
    puts "Reinjection produced #{successes} success."
  end
  unless failures.nil?
    puts "Reinjection produced #{failures} failures."
  end
end

def reinject_single_request(r, verbose=false, quiet=false)
  response = nil
  success = false

  display_single_request(r, verbose) if verbose

  if r[:host].nil?
    puts "Host header not set. Can't reinject."
    return 1
  end

  if r[:http_method] == "GET"
    result = http_get(r[:host], r[:path], r[:querystringparameters], r[:headers])
  else
    result = http_post(r[:host], r[:path], r[:querystringparameters], r[:headers], r[:postparameters])
  end

  unless result.nil?
    hit_code = false
    if result.code.to_i == r[:status_code]
      hit_code = true
    end

    hit_length = nil
    if result.body.size > 0
      if result.read_header["Content-Length"] == r[:response_content_length]
        hit_length = true
      else
        hit_length = false
      end
    end

    hit_location = nil
    if result.code.to_i == 201 or (result.code.to_i >= 300 and result.code.to_i < 400)
      if result.read_header["Location"] == r[:response_location]
        hit_location = true
      else
        hit_location = false
      end
    end

    string = ""
    string += "#{r[:num]}: #{r[:status_code]}/#{result.code} - #{r[:http_method]} - "

    if not hit_length.nil? and not hit_location.nil?
      # length and location
      if hit_code and hit_length and hit_location
        string += "OK. Logrequest and Injection have identical status, identical content-length and identical location."
        success = true
      elsif hit_code and hit_length and not hit_location
        string += "FAILURE. Logrequest and Injection have identical status, identical content-length, but different location header: Logrequest: #{r[:response_location]}, Injection: #{result.read_header["Location"]}."
      elsif hit_code and not hit_length and hit_location
        string += "FAILURE. Logrequest and Injection have identical status, identical location header, but different content-length: Logrequest: #{r[:response_content_length]}, Injection: #{result.content_length}."
      elsif hit_code and not hit_length and not hit_location
        string += "FAILURE. Logrequest and Injection have identical status but differring location header and content-length: Location logrequest: #{r[:response_location]}, Location injection: #{result.read_header["Location"]}, length logrequest: #{r[:response_content_length]}, length injection:  #{result.content_length}."
      else
        string += "FAILURE. Not able to qualify response."
      end
    elsif hit_length.nil? and not hit_location.nil?
      # no length, but a location
      if hit_code and hit_location
        string += "OK. Logrequest and Injection have identical status and identical location."
        success = true
      elsif hit_code and not hit_location
        string += "FAILURE. Logrequest and Injection have identical status, but differring location: Logrequest: #{r[:response_location]}, Injection: #{result.read_header["Location"]}."
      else
        string += "FAILURE. Not able to qualify response."
      end
    elsif not hit_length.nil? and hit_location.nil?
      # length, but no location
      if hit_code and hit_length
        string += "OK. Logrequest and Injection have identical status and identical content length."
        success = true
      elsif hit_code and not hit_length
        string += "FAILURE. Logrequest and Injection have identical status, but differring content length: Logrequest: #{r[:response_content_length]}, Injection: #{result.content_length}."
      else
        string += "FAILURE. Not able to qualify response."
      end
    elsif hit_length.nil? and hit_location.nil?
      # no length, no location
      if hit_code
        string += "OK. Logrequest and Injection have identical status and neither content-lenght nor a location."
        success = true
      else
        string += "FAILURE. Logrequest and Injection have different status codes: Logrequest: #{r[:http_method]}}, Injection: #{result.code}}"
      end
    else
      string += "FAILURE. Not able to qualify response."
    end

    puts string unless quiet

  end

  return success

end

def reinject_requests(requests, ids=nil, verbose=false, quiet=false)
  successes = 0
  failures = 0
  if ids.nil?
    requests.each do |r|
      success = reinject_single_request(r, verbose, quiet)
      if success 
        successes += 1
      else
        failures += 1
      end
    end
  else
    ids.each do |id|
      unless /\w/.match(id).nil?
        # numerical id
        unless id.to_i > requests.size - 1
          success = reinject_single_request(requests[id.to_i], verbose, quiet)
          if success 
            successes += 1
          else
            failures += 1
          end
        else
          puts "Id #{id} is too big. There are only #{requests.size} requests. Ids are starting from 0; maximum id is thus #{requests.size-1}."
          failures += 1
        end
      else
        # alphanumerical
        intid = get_integer_id_from_alphanumerical_id(requests, id) # translate the alphanumerical id into a integer id
        unless intid.nil?
          success = reinject_single_request(requests[intid], verbose, quiet)
          if success 
            successes += 1
          else
            failures += 1
          end
        else
          puts "Id #{id} not found."
          failures += 1
        end
      end
    end
  end

  return successes, failures
end

def display_single_request(r, verbose=false)
    # display
    puts "------------------------------------" if verbose
    puts "#{r[:num]}: #{r[:http_method]} #{r[:uri]} #{r[:version]} #{r[:request_id]} #{r[:status_code]}"
    if verbose
      puts "file: #{r[:filename]} (startline: #{r[:startline]})"
      r[:querystringparameters].each do |item|
        puts "Q: #{item[:name]}: #{item[:value]}"
      end
      r[:headers].each do |item|
        puts "H: #{item[:name]}: #{item[:value]}"
      end
      r[:cookieparameters].each do |item|
        puts "C: #{item[:name]}: #{item[:value]}"
      end
      r[:postparameters].each do |item|
        puts "P: #{item[:name]}: #{item[:value]}"
      end
      puts "Status: #{r[:status_code]} #{r[:status_code_name]}" unless r[:status_code].nil? or r[:status_code_name].nil?
      puts "ModSecurity Message: #{r[:modsecurity_message]}" unless r[:modsecurity_message].nil?
    end
end

def display_requests(requests, ids=nil, verbose=false)
  if ids.nil?
    requests.each do |r|
      display_single_request(r, verbose)
    end
  else
    ids.each do |id|
      if /[A-Z]/.match(id).nil?
        # numerical id
        unless id.to_i > requests.size - 1 
          display_single_request(requests[id.to_i], verbose)
        else
          puts "Id #{id} is too big. There are only #{requests.size} requests. Ids are starting from 0; maximum id is thus #{requests.size-1}."
        end
      else
        # alphanumerical
        intid = get_integer_id_from_alphanumerical_id(requests, id) # translate the alphanumerical id into a integer id
        unless intid.nil?
          display_single_request(requests[intid], verbose)
        else
          puts "Id #{id} not found."
        end
      end
    end
  end
end

 
def get_options
  parser = GetoptLong.new
  parser.set_options(
                     ["-h", "--help", GetoptLong::NO_ARGUMENT],
                     ["-l", "--list", GetoptLong::NO_ARGUMENT],
                     ["-i", "--ids", GetoptLong::REQUIRED_ARGUMENT],
                     ["-r", "--reinject", GetoptLong::NO_ARGUMENT],
                     ["-q", "--quiet", GetoptLong::NO_ARGUMENT],
                     ["-s", "--summary", GetoptLong::NO_ARGUMENT],
                     ["-v", "--verbose", GetoptLong::NO_ARGUMENT])

  return read_options(parser) 
end

def read_options(parser)
  display = false
  filenames = []
  ids = nil
  reinject = false
  stdin = false
  quiet = false
  summary = false
  verbose = false

  loop do
    begin
      opt, arg = parser.get
      break if not opt

      case opt                                                               
      when "-h"
        print_usage
        exit 1
      when "-i"
        ids = []
        myids = arg
        myids = myids.split(",")
        myids.each do |item|
          unless item.index("-").nil?
            myids = item.split("-")
            myids[0].upto(myids[1]) do |myitem|
              ids << myitem.strip
            end
          else
            ids << item.strip
          end
        end
      when "-l"
        display = true
      when "-r"
        reinject = arg
      when "-q"
        quiet = true
      when "-s"
        summary = true
      when "-v"
        verbose = true
      end

    rescue => err
      print_usage
      exit 1           # exit if option unknown
    end

  end

  if ARGV.size > 0
    filenames = ARGV
  end

  if not $stdin.tty?
    stdin = true
  else
    if filenames.size == 0
      print_usage
      exit 1
    end
  end


  def validate_file(filename)
    # validate file
    # validation: existence, readability
    unless FileTest::exists?(filename)
      puts "File #{filename} is not existing. Aborting."
      return false
    end
    unless FileTest::readable?(filename)
      puts "File #{filename} is not readable. Aborting."
      return false
    end
    return true
  end

  def validate_ids(ids)
    if ids.nil?
      return true
    end
    ids.each do |item|
      if /^([\d\w@-]{24}+|[\d]+)$/.match(item).nil?
        puts "Ids string includes bad ids: #{item}. Aborting."
        return false
      end
    end
    return true
  end

  unless stdin
    filenames.each do |filename|
      exit 1 unless validate_file(filename)
    end
  end
  exit 1 unless validate_ids(ids)

  return display, filenames, ids, quiet, reinject, stdin, summary, verbose
end


def http_get(host, path, querystring={}, headers = {})
  myheaders = {}
  headers.each do |item|
    myheaders[item[:name]] = item[:value]
  end
  myquerystring = ""
  querystring.each do |item|
    unless myquerystring.size == 0
      myquerystring += "&"
    end
    myquerystring += item[:name]
    myquerystring += "=" + item[:value] unless item[:value].chomp.size == 0
  end
  if myquerystring.size > 0
    myquerystring = "?" + myquerystring 
  end

  begin
    url = URI.parse("http://" + host + path)
    request = Net::HTTP::Get.new(url.path + myquerystring, myheaders) 
      # unfortunately, headers come in random order in ruby
      # do not know how to prevent his
    result = Net::HTTP.start(url.host, url.port) {|http|
      http.request(request)
    }
  rescue Errno::ECONNREFUSED
    puts "Connection refused."
    return nil
  rescue 
    puts "Unknown error."
    return nil
  end

  return result

end

def http_post(host, path, querystring={}, headers = {}, data = {})
  myheaders = {}
  headers.each do |item|
    myheaders[item[:name]] = item[:value]
  end

  myquerystring = ""
  querystring.each do |item|
    unless myquerystring.size == 0
      myquerystring += "&"
    end
    myquerystring += item[:name] + "=" + item[:value]
  end
  if myquerystring.size > 0
    myquerystring = "?" + myquerystring 
  end

  mybody = ""
  data.each do |item|
    unless mybody.size == 0
      mybody += "&"
    end
    mybody += item[:name] + "=" + item[:value]
  end

  begin
    url = URI.parse("http://" + host + path )
    request = Net::HTTP::Post.new(url.path + myquerystring, myheaders)
      # unfortunately, headers come in random order in ruby
      # do not know how to prevent his
    request.body = mybody 
      # we have to use our own function, as ruby translates certain characters to HEX characters
    result = Net::HTTP.start(url.host, url.port) {|http|
      http.request(request)
    }
  rescue Errno::ECONNREFUSED
    puts "Connection refused."
    return nil
  rescue 
    puts "Unknown error."
    return nil
  end

  return result

end


if __FILE__ == $0
  main
end


