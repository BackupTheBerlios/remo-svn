require 'helpers/various'

def generate(request=nil, version=nil)
  filename = "rulefile.conf"
  prepend_filename= "prepend-file.conf"
  append_filename= "append-file.conf"

  requests = Request.find(:all, :order => "weight ASC")

  def append_file(file, app_file, request, version)
    File.foreach(app_file) do |line|
      line.gsub!("__VERSION__", version) unless version.nil?
      line.gsub!("__DATE__", Time.now.strftime("%x %X")) # i.e. 02/05/07 14:05:56
      line.gsub!("__CLIENTIP__", request.remote_ip) unless request.nil?
      file.puts line
    end
  end

  File.open(filename, "w") do |file|

    append_file(file, prepend_filename, request, version)

    requests.each do |r|
      file.puts "# #{r.remarks}" unless r.remarks.nil?
      file.puts "# allow: #{r.http_method} #{r.path}"
      file.puts "SecRule REQUEST_METHOD \"^#{r.http_method}$\" \"chain,allow,nolog,id:#{r.id}\""
      file.puts "SecRule REQUEST_URI \"#{escape_path r.path}\""
      file.puts ""
    end

    append_file(file, append_filename, request, version)

  end

  return filename


end


