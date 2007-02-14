class ReplaceConnectionField < ActiveRecord::Migration
  def self.up
    remove_column :requests, :connection
    add_column :requests, :guiprefix_connection, :text, :default => '.*'
  end

  def self.down
    remove_column :requests, :guiprefix_connection
    add_column :requests, :connection, :text, :default => '.*'
  end
end
