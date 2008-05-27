class CreateLogfiles < ActiveRecord::Migration
  def self.up
    create_table :logfiles do |t|
      t.column  :name,    :string
      t.column  :content,    :binary
    end
  end

  def self.down
    drop_table :logfiles
  end
end
