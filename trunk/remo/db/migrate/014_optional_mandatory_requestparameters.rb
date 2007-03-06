class OptionalMandatoryRequestparameters < ActiveRecord::Migration
  def self.up
    add_column :headers, :mandatory, :boolean, :default => false
    add_column :querystringparameters, :mandatory, :boolean, :default => false
    add_column :cookieparameters, :mandatory, :boolean, :default => true
    add_column :postparameters, :mandatory, :boolean, :default => true
  end

  def self.down
    remove_column :headers, :mandatory
    remove_column :querystringparameters, :mandatory
    remove_column :cookieparameters, :mandatory
    remove_column :postparameters, :mandatory
  end
end
