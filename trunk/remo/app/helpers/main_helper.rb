module MainHelper

  unless defined? self::HTTP_METHODS
    require File.dirname(__FILE__) + '/../../remo_config'

    # include constants into helper namespace to make them available for the 
    # partial views
    HTTP_METHODS = HTTP_METHODS

    HEADER_DOMAINS = HEADER_DOMAINS
    COOKIE_DOMAINS = COOKIE_DOMAINS
    QUERY_STRING_DOMAINS = QUERY_STRING_DOMAINS
    POST_DOMAINS = POST_DOMAINS
  end

end
