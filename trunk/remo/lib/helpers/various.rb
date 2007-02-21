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
  return REMO_RELEASE_VERSION
end
