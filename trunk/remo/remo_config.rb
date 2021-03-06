unless defined? REMO_RELEASE_VERSION
  # Remo Release Version
  REMO_RELEASE_VERSION = "0.2.1-dev"

  # This is a list of default headers that are added to a new request in remo by default
  DEFAULT_HEADERS = [
    # Header-Name -> [Standard_Domain, Custom_Domain]
    {"Host"  =>             ["Header: Host", ""]},
    {"Referer" =>           ["Custom", ".*"]},
    {"User-Agent" =>        ["Header: User-Agent", ""]},
    {"Accept" =>            ["Custom", ".*"]},
    {"Accept-Language" =>   ["Custom", ".*"]},
    {"Accept-Encoding" =>   ["Custom", ".*"]},
    {"Accept-Charset" =>    ["Custom", ".*"]},
    {"Keep-Alive" =>        ["Integer, max. 16 characters", ""]}, 
    {"Connection" =>        ["Custom", ".*"]},
    {"Cookie2?" =>          ["Custom", ".*"]},
    {"If-Modified-Since" => ["Custom", ".*"]},
    {"If-None-Match" =>     ["Custom", ".*"]},
    {"Cache-Control" =>     ["Custom", ".*"]},
    {"Via" =>               ["Custom", ".*"]},
    {"X-Forwarded-For" =>   ["Custom", ".*"]},
    {"From" =>              ["Custom", ".*"]},
    {"Content-Length" =>    ["Custom", ".*"]},
    {"Content-Type" =>      ["Custom", ".*"]},
    {"UA-CPU" =>            ["Letters/Numbers/Space/-/_, max. 16 characters", ""]},
    {"Pragma" =>            ["Letters/Numbers/Space/-/_, max. 16 characters", ""]},
  ]

  # http methods
  WEBDAV_METHODS = ["BCOPY", "BDELETE", "BMOVE", "BPROPFIND", "BPROPPATCH", "COPY", "LOCK", "MKCOL", "MOVE", "NOTIFY", "POLL", "PROPFIND", "PROPPATCH", "SEARCH", "SUBSCRIBE", "UNLOCK", "UNSUBSCRIBE", "X-MS-ENUMATTS"]
  HTTP_METHODS = ["GET", "POST", "HEAD", "TRACE", "PUT", "DELETE", "CONNECT", "OPTIONS"] + WEBDAV_METHODS


  # Standard domain to regex mapping
  # It is really annoying to do this without IDs, but with the stringname as ID, but
  # the rails support for inplace select-form-fields editor is really minimal and
  # we would not be able to display the string if the value would be a numerical ID.
  # So for the time being, the ID is the string name.
  STANDARD_DOMAINS = {
    # name - value pairs
    "Hostname" => '[0-9a-zA-Z\-.]{1,64}',
    "IP Address V4" => '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}',
    "IP Address V6" => '([0-9a-fA-F]{4}|0)(\:([0-9a-fA-F]{4}|0)){7}',
    "Base64, max. 16 characters" => '[0-9a-zA-Z+/]{0,16}={0,2}',
    "Integer, max. 16 characters" => '\d{0,16}',
    "Flag, max. single character" => '[0-9a-zA-Z]{0,1}',
    "Sessionid, alphanumerical, max. 16 characters" => '[0-9a-zA-Z]{1,16}',
    "Username" => '[0-9-a-zA-Z_\-\]{0,32}',
    "Emailaddress" => '[0-9a-zA-Z\-_.]{1,32}\x40[0-9a-zA-Z\-.]{1,32}',
    "Anything, max. 16 characters" => '.{0,16}',
    "Letters/Numbers, max. 16 characters" => '[0-9a-zA-Z]{0,16}',
    "Letters/Numbers/Space/-/_, max. 16 characters" => '[0-9a-zA-Z\-\x20_]{0,16}',
    "Letters/Numbers, max. 32 characters" => '[0-9a-zA-Z]{0,32}',
    "Letters/Numbers/Space/-/_, max. 32 characters" => '[0-9a-zA-Z\-\x20_]{0,32}',
    "Header: User-Agent" => '[0-9a-zA-Z #+:;,!()|&\[\]\{\}/.=_\-]{1,320}',
    "Header: Host" => '[0-9a-zA-Z\-:.]{3,64}',
    "Header: Basic Authorization" => 'Basic\s[0-9a-zA-Z+/]{0,256}={0,2}'
  }

  # Standard domains per parameter type
  common_domains = ["Custom"] + 
    ["Hostname", 
    "IP Address V4", 
    "IP Address V6", 
    "Base64, max. 16 characters", 
    "Integer, max. 16 characters", 
    "Flag, max. single character",
    "Sessionid, alphanumerical, max. 16 characters", 
    "Username", 
    "Emailaddress", 
    "Anything, max. 16 characters", 
    "Letters/Numbers, max. 16 characters", 
    "Letters/Numbers/Space/-/_, max. 16 characters", 
    "Letters/Numbers, max. 32 characters", 
    "Letters/Numbers/Space/-/_, max. 32 characters"].sort

  HEADER_DOMAINS = common_domains + ["Header: User-Agent", "Header: Host", "Header: Basic Authorization"].sort unless defined? HEADER_DOMAINS
  COOKIE_DOMAINS = common_domains unless defined? COOKIE_DOMAINS
  QUERY_STRING_DOMAINS = common_domains unless defined? QUERY_STRING_DOMAINS
  POST_DOMAINS = common_domains unless defined? POST_DOMAINS

  
  # All the http status codes and "Default" as an array.
  HTTP_STATUS_CODES_WITH_DEFAULT = ["Default", "100", "101", "200", "201", "202", "203", "204", "205", "206", "300", "301", "302", "303", "304", "305", "306", "307", "400", "401", "402", "403", "404", "405", "406", "407", "408", "409", "410", "411", "412", "413", "414", "415", "416", "417", "500", "501", "502", "503", "504", "505"]

  # Those status codes, that result in a redirect to the user agent
  HTTP_REDIRECT_STATUS_CODES = ["300", "301", "302", "303", "305", "307"]

  # Ruleset Mode
  # - block
  # - detect
  # When blocking is selected, HTTP_DEFAULT_DENY_STATUS_CODE will be used.
  RULESET_MODE = "detect"

  # The status code is part of every deny rule in a remo ruleset. 
  # This is the default value when the RULESET_MODE is set to "block"
  HTTP_DEFAULT_DENY_STATUS_CODE = "501"

  # ModSecurity collection names
  MOD_SECURITY_COLLECTIONS = {
    "header" => "REQUEST_HEADERS",
    "cookieparameter" => "REQUEST_COOKIES",
    "querystringparameter" => "ARGS",
    "postparameter" => "ARGS"
  }

  # Rule Generator rule id base
  RULE_ID_BASE = 20001

end
