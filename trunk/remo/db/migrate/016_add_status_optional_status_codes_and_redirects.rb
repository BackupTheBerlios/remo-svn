class AddStatusOptionalStatusCodesAndRedirects < ActiveRecord::Migration
  def self.up

    add_column :headers, :domain_status_code, :string, :limit => 10, :null => false, :default => 'Default'
    add_column :querystringparameters, :domain_status_code, :string, :limit => 10, :null => false, :default => 'Default'
    add_column :cookieparameters, :domain_status_code, :string, :limit => 10, :null => false, :default => 'Default'
    add_column :postparameters, :domain_status_code, :string, :limit => 10, :null => false, :default => 'Default'

    add_column :headers, :domain_location, :string, :limit => 255
    add_column :querystringparameters, :domain_location, :string, :limit => 255
    add_column :cookieparameters, :domain_location, :string, :limit => 255
    add_column :postparameters, :domain_location, :string, :limit => 255

    add_column :headers, :mandatory_status_code, :string, :limit => 10, :null => false, :default => 'Default'
    add_column :querystringparameters, :mandatory_status_code, :string, :limit => 10, :null => false, :default => 'Default'
    add_column :cookieparameters, :mandatory_status_code, :string, :limit => 10, :null => false, :default => 'Default'
    add_column :postparameters, :mandatory_status_code, :string, :limit => 10, :null => false, :default => 'Default'

    add_column :headers, :mandatory_location, :string, :limit => 255
    add_column :querystringparameters, :mandatory_location, :string, :limit => 255
    add_column :cookieparameters, :mandatory_location, :string, :limit => 255
    add_column :postparameters, :mandatory_location, :string, :limit => 255


  end

  def self.down
    remove_column :headers, :mandatory_status_code
    remove_column :querystringparameters, :mandatory_status_code
    remove_column :cookieparameters, :mandatory_status_code
    remove_column :postparameters, :mandatory_status_code

    remove_column :headers, :mandatory_location
    remove_column :querystringparameters, :mandatory_location
    remove_column :cookieparameters, :mandatory_location
    remove_column :postparameters, :mandatory_location

    remove_column :headers, :domain_status_code
    remove_column :querystringparameters, :domain_status_code
    remove_column :cookieparameters, :domain_status_code
    remove_column :postparameters, :domain_status_code

    remove_column :headers, :domain_location
    remove_column :querystringparameters, :domain_location
    remove_column :cookieparameters, :domain_location
    remove_column :postparameters, :domain_location
  end
end
