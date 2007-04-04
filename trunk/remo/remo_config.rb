unless defined? REMO_RELEASE_VERSION
  # Remo Release Version
  REMO_RELEASE_VERSION = "0.1.4-dev"

  # This is a list of default headers that are added to a new request in remo by default
  DEFAULT_HEADERS = [
    # Header-Name -> [Standard_Domain, Custom_Domain]
    {"Host"  =>             ["Header: Host", ""]},
    {"Referer" =>           ["Header: User-Agent", ""]},
    {"User-Agent" =>        ["Custom", ".*"]},
    {"Accept" =>            ["Custom", ".*"]},
    {"Accept-Language" =>   ["Custom", ".*"]},
    {"Accept-Encoding" =>   ["Custom", ".*"]},
    {"Accept-Charset" =>    ["Custom", ".*"]},
    {"Keep-Alive" =>        ["Integer, max. 16 characters", ""]}, 
    {"Connection" =>        ["Custom", ".*"]},
    {"Cookie" =>            ["Custom", ".*"]},
    {"If-Modified-Since" => ["Custom", ".*"]},
    {"If-None-Match" =>     ["Custom", ".*"]},
    {"Cache-Control" =>     ["Custom", ".*"]},
    {"Via" =>               ["Custom", ".*"]},
    {"X-Forwarded-For" =>   ["Custom", ".*"]},
    {"From" =>              ["Custom", ".*"]},
    {"Content-Length" =>    ["Custom", ".*"]},
    {"Content-Type" =>      ["Custom", ".*"]},
  ]

  WEBDAV_METHODS = ["BCOPY", "BDELETE", "BMOVE", "BPROPFIND", "BPROPPATCH", "COPY", "LOCK", "MKCOL", "MOVE", "NOTIFY", "POLL", "PROPFIND", "PROPPATCH", "SEARCH", "SUBSCRIBE", "UNLOCK", "UNSUBSCRIBE", "X-MS-ENUMATTS"]
  HTTP_METHODS = ["GET", "POST", "GET|POST", "HEAD", "TRACE", "PUT", "DELETE", "CONNECT", "OPTIONS"] + WEBDAV_METHODS


  STANDARD_DOMAINS = {
    # name - value pairs
    "Hostname" => "[0-9a-zA-Z-.]{1,64}",
    "IP Address V4" => "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}",
    "IP Address V6" => "([0-9a-fA-F]{4}|0)(\:([0-9a-fA-F]{4}|0)){7}",
    "Base64, max. 16 characters" => "[0-9a-zA-Z+/]{0,16}={0,2}",
    "Integer, max. 16 characters" => "\d{0,16}",
    "Flag, single character" => "[0-9a-zA-Z]",
    "Header: User-Agent" => "[0-9a-zA-Z +:;!()/.-]{1,256}",
    "Header: Host" => "[0-9a-zA-Z-.]{3,64}",
    "Header: Basic Authorization" => "Basic\s[0-9a-zA-Z+/]{0,256}={0,2}"
  }

  common_domains = ["Custom"] + ["Hostname", "IP Address V4", "IP Address V6", "Base64, max. 16 characters", "Integer, max. 16 characters", "Flag, single character"].sort

  HEADER_DOMAINS = common_domains + ["Header: User-Agent", "Header: Host", "Header: Basic Authorization"].sort unless defined? HEADER_DOMAINS
  COOKIE_DOMAINS = common_domains unless defined? COOKIE_DOMAINS
  QUERY_STRING_DOMAINS = common_domains unless defined? QUERY_STRING_DOMAINS
  POST_DOMAINS = common_domains unless defined? POST_DOMAINS

  HTTP_METHODS = ["GET", "POST", "GET|POST", "HEAD", "TRACE", "PUT", "DELETE", "CONNECT", "OPTIONS"] unless defined? HTTP_METHODS

end
