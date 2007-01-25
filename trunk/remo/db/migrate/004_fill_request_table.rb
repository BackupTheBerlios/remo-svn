class FillRequestTable < ActiveRecord::Migration
  def self.up
  	down

	list = [[1, "GET",  "/myindex.html", 1],
		[2, "POST", "/action/post.php", 2],
	  	[3, "GET",  "/detail.html",   3],
	  	[4, "GET",  "/view,html",     4],
	  	[5, "GET",  "/detail.html",   5],
	  	[6, "GET",  "/index.html",    6],
	  	[7, "GET",  "/info.html",     7],
	  	[8, "POST", "/action/delete.php", 8]]

	list.each do |item|
		r = Request.create(:id 		 => item[0],
			 	   :http_method  => item[1],
				   :path 	 => item[2],
				   :weight 	 => item[3])
		r.save!
	end

  end

  def self.down
  	Request.delete_all
  end
end
