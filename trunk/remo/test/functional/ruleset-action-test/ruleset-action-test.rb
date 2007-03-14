require File.dirname(__FILE__) + '/../../test_helper'

class ModSecurityTest < ActionController::IntegrationTest

  fixtures :requests
  fixtures :headers
  fixtures :cookieparameters
  fixtures :querystringparameters
  fixtures :postparameters

 
  def self.major_teardown
    Dir.chdir("./test/functional/ruleset-action-test/")
    system("./apache2 stop") if File::exists?("./httpd.pid")

    File.delete("modsec_debug.log") if FileTest::exists?("modsec_audit.log")
    File.delete("modsec_audit.log") if FileTest::exists?("modsec_audit.log")
    File.delete("error.log") if FileTest::exists?("error.log")

    Dir.chdir("../../..")
  end
  
  def self.suite
    mysuite = super
    def mysuite.run(*args)
      super
      ModSecurityTest.major_teardown
    end

    mysuite

  end

  def test_run

   def write_requestrule(id, filename)

      get "/generate_requestrule/index/#{id}"

      File.open(filename, "w") do |file|
        response.body.gsub!("<html>", "")
        response.body.gsub!("</html>", "")
        response.body.gsub!(/<title>.*/, "")
        response.body.gsub!(/<!DOCTYP.*/, "")
        response.body.gsub!(/^"http.*/, "")
        response.body.gsub!("<head>", "")
        response.body.gsub!("</head>", "")
        response.body.gsub!("<body>", "")
        response.body.gsub!("</body>", "")
        response.body.gsub!("<pre>", "")
        response.body.gsub!("</pre>", "")
        response.body.gsub!("<br />", "\n")
        response.body.gsub!("&lt;", "<")
        response.body.gsub!("&gt;", ">")
        response.body.gsub!("&nbsp;", " ")
        file.puts response.body
      end

    end

    Dir.chdir("./test/functional/ruleset-action-test/")

    system("./apache2 stop") if File::exists?("./httpd.pid")
    system("./apache2 start")

    Dir.chdir("../../..")

    write_requestrule(3, "test/functional/ruleset-action-test/rulefile-index.php.conf")
    write_requestrule(4, "test/functional/ruleset-action-test/rulefile-submit.php.conf")
    write_requestrule(5, "test/functional/ruleset-action-test/rulefile-redirect.php.conf")

    require "test/functional/ruleset-action-test/audit-log-parser"

    requests = parse_logfiles(["test/functional/ruleset-action-test/blueprints/blueprint_redirect.php.log"], nil)
    successes, failures = reinject_requests(requests, nil, false, true) if requests.size > 0

    assert_equal 0, failures, "Active Apache/ModSecurity rule checking failed."
    
  end


end

