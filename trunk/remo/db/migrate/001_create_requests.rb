class CreateRequests < ActiveRecord::Migration
  def self.up
    create_table :requests do |t|
      t.column  :url	:string
      t.column	:method :string
    end
  end

  def self.down
    drop_table :requests
  end
end
