class RecreateRequests < ActiveRecord::Migration
  def self.up
    create_table :requests do |t| # id column is created automatically
      t.column  :http_method,   :string, :limit => 10, :null => false 	# max 10 characters, may not be null
      t.column  :path,          :text, :null => false    		# may not be null
      t.column  :weight,        :integer, :null => false 		# may not be null
    end
  end

  def self.down
    drop_table :requests
  end
end
