module MainHelper
  HTTP_METHODS = ["GET", "POST", "GET|POST", "HEAD", "TRACE", "PUT", "DELETE", "CONNECT", "OPTIONS"]
  
  common_domains = ["Custom"] + ["Hostname", "IP Address V4", "IP Address V6", "Base64, max. 16 characters", "Integer, max. 16 characters", "Flag, single character"].sort

  HEADER_DOMAINS = common_domains + ["Header: User-Agent", "Header: Host", "Header: Basic Authorization"].sort
  COOKIE_DOMAINS = common_domains
  QUERY_STRING_DOMAINS = common_domains
  POST_DOMAINS = common_domains

end
