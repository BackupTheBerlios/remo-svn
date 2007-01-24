class RemoveRequest < ActiveRecord::Migration
  def self.up
    drop_table :requests
  end

  def self.down
    create_table :requests do |t|
      t.column  :url,    :string
      t.column  :method, :string
    end
  end
end
