# This is a list of default headers that are added to a new request in remo.

DEFAULT_HEADERS = {
  # Header-Name -> Domain
  "Host"  => ".*",
  "User-Agent" => ".*",
  "Accept" => ".*",
  "Accept-Language" => ".*",
  "Accept-Encoding" => ".*",
  "Accept-Charset" => ".*",
  "Keep-Alive" => "\\d*", # -> \d* escaped
  "Referer" => ".*",
  "Cookie" => ".*",
  "If-Modified-Since" => ".*",
  "If-None-Match" => ".*",
  "Cache-Control" => ".*",
  "From" => ".*",
  "Content-Length" => ".*",
  "Content-Type" => ".*",
  "Via" => ".*",
  "X-Forwarded-For" => ".*"}

