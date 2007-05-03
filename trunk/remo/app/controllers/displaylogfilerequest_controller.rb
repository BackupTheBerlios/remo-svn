class DisplaylogfilerequestController < ApplicationController
  def index
    require "#{RAILS_ROOT}/lib/logfile"

    id = params[:id].split("&")[0].to_i
    rid = params[:id].split("&")[1].to_i
    
    begin
      logfile=Logfile.find(id)
      requests = get_logfile_requests(logfile)
      @r=requests[rid]
    rescue => err
      flash[:notice] = "Displaying request #{rid} from logfile id #{id} failed! " + err
    end


  end

end
