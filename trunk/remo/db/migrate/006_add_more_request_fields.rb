class AddMoreRequestFields < ActiveRecord::Migration
  def self.up
        add_column :requests, :host, :text, :default => '.*'
        add_column :requests, :user_agent, :text, :default => '.*'
        add_column :requests, :referer, :text, :default => '.*'
        add_column :requests, :accept, :text, :default => '.*'
        add_column :requests, :accept_language, :text, :default => '.*'
        add_column :requests, :accept_encoding, :text, :default => '.*'
        add_column :requests, :accept_charset, :text, :default => '.*'
        add_column :requests, :keep_alive, :text, :default => '.*'
        add_column :requests, :connection, :text, :default => '.*'
        add_column :requests, :content_type, :text, :default => '.*'
        add_column :requests, :content_length, :text, :default => '.*'
        add_column :requests, :cookie, :text, :default => '.*'
        add_column :requests, :pragma, :text, :default => '.*'
        add_column :requests, :cache_control, :text, :default => '.*'
  end

  def self.down
        remove_column :requests, :host
        remove_column :requests, :user_agent
        remove_column :requests, :referer
        remove_column :requests, :accept
        remove_column :requests, :accept_language
        remove_column :requests, :accept_encoding
        remove_column :requests, :accept_charset
        remove_column :requests, :keep_alive
        remove_column :requests, :connection
        remove_column :requests, :content_type
        remove_column :requests, :content_length
        remove_column :requests, :cookie
        remove_column :requests, :pragma
        remove_column :requests, :cache_control
  end
end
