class Logfile < ActiveRecord::Base

  after_save :process
  
  def file_data=(file_data)
    unless file_data.nil? or file_data.size == 0
      @file_data = file_data
      write_attribute 'name', @file_data.original_filename
    end
  end
  
  #######
  private
  #######
	
  def process
    if @file_data # this calls the function above implicitly
      save_content
      @file_data = nil
      @name = nil
    end
  end

  def save_content
    require "audit-log-parser"

    logfile = @file_data.read

    record = Logfile.find(self.id)
    record.content = logfile
    filename = record.name

    if is_serial_log(logfile)

      requests = []
      phase = nil
      phaseline = 0
      current_request = nil
      linenum = 0
      n = 0

      logfile.each do |line|
        # loop over the lines and add one request after the other to the requests array
        requests, current_request, phase, phaseline, n = parse_line(requests, current_request, filename, linenum, line, phase, phaseline, n)
      end

      record.save!
    else

      logger.error "Import logfile: Unknown logfile type or logfile corrupt: #{filename}. Aborting import."

    end

  end

end
