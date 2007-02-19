class FillHeaderTable < ActiveRecord::Migration
  def self.up
    down

    list = [
            [1, 1, "Host", ".*"],
            [2, 1, "User-Agent", ".*"],
            [3, 1, "Accept", ".*"],
            [4, 1, "Accept-Language", ".*"],
            [5, 1, "Accept-Encoding", ".*"],
            [6, 1, "Accept-Charset", ".*"],
            [7, 1, "Keep-Alive", "\\d*"], # -> \d* escaped
            [8, 1, "Referer", ".*"],
            [9, 1, "Cookie", ".*"],
            [10, 1, "If-Modified-Since", ".*"],
            [11, 1, "If-None-Match", ".*"],
            [12, 1, "Cache-Control", ".*"],

            [1, 2, "Host", ".*"],
            [2, 2, "User-Agent", ".*"],
            [3, 2, "Accept", ".*"],
            [4, 2, "Accept-Language", ".*"],
            [5, 2, "Accept-Encoding", ".*"],
            [6, 2, "Accept-Charset", ".*"],
            [7, 2, "Keep-Alive", "\\d*"],# -> \d* escaped
            [8, 2, "Referer", ".*"],
            [9, 2, "Cookie", ".*"],
            [10, 2, "If-Modified-Since", ".*"],
            [11, 2, "If-None-Match", ".*"],
            [12, 2, "Cache-Control", ".*"],


            [1, 3, "Host", ".*"],
            [2, 3, "User-Agent", ".*"],
            [3, 3, "Accept", ".*"],
            [4, 3, "Accept-Language", ".*"],
            [5, 3, "Accept-Encoding", ".*"],
            [6, 3, "Accept-Charset", ".*"],
            [7, 3, "Keep-Alive", "\\d*"],# -> \d* escaped
            [8, 3, "Referer", ".*"],
            [9, 3, "Cookie", ".*"],
            [10, 3, "If-Modified-Since", ".*"],
            [11, 3, "If-None-Match", ".*"],
            [12, 3, "Cache-Control", ".*"],


            [1, 4, "Host", ".*"],
            [2, 4, "User-Agent", ".*"],
            [3, 4, "Accept", ".*"],
            [4, 4, "Accept-Language", ".*"],
            [5, 4, "Accept-Encoding", ".*"],
            [6, 4, "Accept-Charset", ".*"],
            [7, 4, "Keep-Alive", "\\d*"],# -> \d* escaped
            [8, 4, "Referer", ".*"],
            [9, 4, "Cookie", ".*"],
            [10, 4, "If-Modified-Since", ".*"],
            [11, 4, "If-None-Match", ".*"],
            [12, 4, "Cache-Control", ".*"],


            [1, 5, "Host", ".*"],
            [2, 5, "User-Agent", ".*"],
            [3, 5, "Accept", ".*"],
            [4, 5, "Accept-Language", ".*"],
            [5, 5, "Accept-Encoding", ".*"],
            [6, 5, "Accept-Charset", ".*"],
            [7, 5, "Keep-Alive", "\\d*"],# -> \d* escaped
            [8, 5, "Referer", ".*"],
            [9, 5, "Cookie", ".*"],
            [10, 5, "If-Modified-Since", ".*"],
            [11, 5, "If-None-Match", ".*"],
            [12, 5, "Cache-Control", ".*"],


            [1, 6, "Host", ".*"],
            [2, 6, "User-Agent", ".*"],
            [3, 6, "Accept", ".*"],
            [4, 6, "Accept-Language", ".*"],
            [5, 6, "Accept-Encoding", ".*"],
            [6, 6, "Accept-Charset", ".*"],
            [7, 6, "Keep-Alive", "\\d*"],# -> \d* escaped
            [8, 6, "Referer", ".*"],
            [9, 6, "Cookie", ".*"],
            [10, 6, "If-Modified-Since", ".*"],
            [11, 6, "If-None-Match", ".*"],
            [12, 6, "Cache-Control", ".*"],


            [1, 7, "Host", ".*"],
            [2, 7, "User-Agent", ".*"],
            [3, 7, "Accept", ".*"],
            [4, 7, "Accept-Language", ".*"],
            [5, 7, "Accept-Encoding", ".*"],
            [6, 7, "Accept-Charset", ".*"],
            [7, 7, "Keep-Alive", "\\d*"],# -> \d* escaped
            [8, 7, "Referer", ".*"],
            [9, 7, "Cookie", ".*"],
            [10, 7, "If-Modified-Since", ".*"],
            [11, 7, "If-None-Match", ".*"],
            [12, 7, "Cache-Control", ".*"],

            [1, 8, "Host", ".*"],
            [2, 8, "User-Agent", ".*"],
            [3, 8, "Accept", ".*"],
            [4, 8, "Accept-Language", ".*"],
            [5, 8, "Accept-Encoding", ".*"],
            [6, 8, "Accept-Charset", ".*"],
            [7, 8, "Keep-Alive", "\\d*"],# -> \d* escaped
            [8, 8, "Referer", ".*"],
            [9, 8, "Cookie", ".*"],
            [10, 8, "If-Modified-Since", ".*"],
            [11, 8, "If-None-Match", ".*"],
            [12, 8, "Cache-Control", ".*"]
           ]

    list.each do |item|
            r = Header.create( :id           => item[0],
                               :request_id   => item[1],
                               :name         => item[2],
                               :domain       => item[3])
            r.save!
    end

  end

  def self.down
    Header.delete_all
  end
end
