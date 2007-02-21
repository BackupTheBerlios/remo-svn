# Remo Release Version
REMO_RELEASE_VERSION = "0.1.1"

# This is a list of default headers that are added to a new request in remo.

DEFAULT_HEADERS = [
  # Header-Name -> Domain
  {"Host"  => ".*"},
  {"Referer" => ".*"},
  {"User-Agent" => ".*"},
  {"Accept" => ".*"},
  {"Accept-Language" => ".*"},
  {"Accept-Encoding" => ".*"},
  {"Accept-Charset" => ".*"},
  {"Keep-Alive" => "\\d*"}, # -> \d* escaped
  {"Connection" => ".*"},
  {"Cookie" => ".*"},
  {"If-Modified-Since" => ".*"},
  {"If-None-Match" => ".*"},
  {"Cache-Control" => ".*"},
  {"Via" => ".*"},
  {"X-Forwarded-For" => ".*"},
  {"From" => ".*"},
  {"Content-Length" => ".*"},
  {"Content-Type" => ".*"},
]

