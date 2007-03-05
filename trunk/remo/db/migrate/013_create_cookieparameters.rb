class CreateCookieparameters < ActiveRecord::Migration
  def self.up
    execute "CREATE TABLE cookieparameters (
              id           INTEGER PRIMARY KEY,
              request_id   INTEGER NOT NULL,
              name         STRING NOT NULL,
              domain       TEXT,
              FOREIGN KEY (request_id) REFERENCES request(id) ON DELETE CASCADE);"

    # sqlite does not support the "add foreign keys" statement, so we had do it within
    # the create statement, meaning we had to do the create statement by hand


    #    execute "alter table headers add constraint fk_headers_requests 
    #      foreign key (request_id) references requests(id)"

  end

  def self.down
    drop_table :cookieparameters
  end

end
