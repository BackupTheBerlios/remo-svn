def generate()
  filename = "rulefile.conf"
  requests = Request.find(:all, :order => "weight DESC")

  File.open(filename, "w") do |file|
    file.puts ""
    file.puts "SecDefaultAction \"log,pass,phase:2,status:500,t:urlDecodeUni,t:htmlEntityDecode,t:lowercase\""
    file.puts ""
    file.puts ""
    requests.each do |r|
      file.puts "SecRule REQUEST_URI #{r.path}  \"pass,log,id:#{r.id}\""
    end
    file.puts ""
    file.puts ""
    file.puts "SecRule REQUEST_URI \"/.*\" \"deny,log,status:501,severity:2,msg:'Unknown request'\""
    file.puts ""
  end

  return filename

end
