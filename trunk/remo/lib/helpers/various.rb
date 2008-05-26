
def escape_path(path)
  replacements = [ 
    ['/', '\/'], 
    ['.', '\.']]

  replacements.each do |item|
    path = path.gsub(item[0], item[1])
  end

  return path
end

def get_release_version
  begin
    return REMO_RELEASE_VERSION
  rescue
    require File.dirname(__FILE__) + '/../../remo_config'
    return REMO_RELEASE_VERSION
  end
end

def extended_in_place_edit_for (object, attribute, options = {})
  # this is an extended version of in_place_edit_for
  # it accepts only post requests, uses validation and checks for empty values (which are dropped)

  define_method("set_#{object}_#{attribute}") do
    @item = object.to_s.camelize.constantize.find(params[:id])

    if request.post? and not params[:value].nil? and params[:value].size > 0 
      previous_value = @item[attribute]
      @item[attribute] = params[:value]
      unless @item.save # save does validation and returns true if successfully saved
        @item[attribute] = previous_value
        logger.error "Request could not be saved. A db or validation error is likely."
      end
    end

    render :text => @item.send(attribute)
  end
end
