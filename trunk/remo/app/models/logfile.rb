class Logfile < ActiveRecord::Base

  after_save :process
  
  def file_data=(file_data)
    @file_data = file_data
    write_attribute 'name', @file_data.original_filename
  end
  
  #######
  private
  #######
	
  def process
    if @file_data # this calls the function above implicitely
      save_content
      @file_data = nil
      @name = nil
    end
  end

  def save_content
    data = @file_data.read
    record = Logfile.find(self.id)
    record.content = data
    record.save!
  end

end
