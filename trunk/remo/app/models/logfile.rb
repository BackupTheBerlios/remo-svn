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

    if is_serial_log(logfile)

      record = Logfile.find(self.id)
      record.content = SQLite3::Blob.new(logfile)

      record.save!

    else

      logger.error "Import logfile: Unknown logfile type or logfile corrupt: #{filename}. Aborting import."

    end

  end

end
