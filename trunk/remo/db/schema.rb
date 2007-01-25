# This file is autogenerated. Instead of editing this file, please use the
# migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.

ActiveRecord::Schema.define(:version => 3) do

  create_table "requests", :force => true do |t|
    t.column "http_method", :string,  :limit => 10, :default => "", :null => false
    t.column "path",        :text,                  :default => "", :null => false
    t.column "weight",      :integer,               :default => 0,  :null => false
  end

end
