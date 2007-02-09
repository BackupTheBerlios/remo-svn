class AddRemarks < ActiveRecord::Migration
  def self.up
    add_column :requests, :remarks, :text
  end

  def self.down
    remove_column :requests, :remarks
  end
end
