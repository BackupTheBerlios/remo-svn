# This file is autogenerated. Instead of editing this file, please use the
# migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.

ActiveRecord::Schema.define(:version => 6) do

  create_table "requests", :force => true do |t|
    t.column "http_method",     :string,  :limit => 10, :default => "",     :null => false
    t.column "path",            :text,                  :default => "",     :null => false
    t.column "weight",          :integer,               :default => 0,      :null => false
    t.column "remarks",         :text,                  :default => ""
    t.column "host",            :text,                  :default => "'.*'"
    t.column "user_agent",      :text,                  :default => "'.*'"
    t.column "referer",         :text,                  :default => "'.*'"
    t.column "accept",          :text,                  :default => "'.*'"
    t.column "accept_language", :text,                  :default => "'.*'"
    t.column "accept_encoding", :text,                  :default => "'.*'"
    t.column "accept_charset",  :text,                  :default => "'.*'"
    t.column "keep_alive",      :text,                  :default => "'.*'"
    t.column "connection",      :text,                  :default => "'.*'"
    t.column "content_type",    :text,                  :default => "'.*'"
    t.column "content_length",  :text,                  :default => "'.*'"
    t.column "cookie",          :text,                  :default => "'.*'"
    t.column "pragma",          :text,                  :default => "'.*'"
    t.column "cache_control",   :text,                  :default => "'.*'"
  end

end
