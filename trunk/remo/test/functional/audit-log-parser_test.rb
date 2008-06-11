require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../../lib/audit-log-parser'

require 'rules_generator/main'
require 'helpers/various'

class AuditLogParserNewTest < Test::Unit::TestCase

  $testfile1 = File.dirname(__FILE__) + "/data/modsec_audit_log_1.log"            # logfile with 1 request
  $testfile2 = File.dirname(__FILE__) + "/data/modsec_audit_log_2.log"            # logfile with 3 requests
  $testfile3 = File.dirname(__FILE__) + "/data/modsec_audit_log_3.log"            # logfile with 3 requests, new request starting without old request being finished

  $script_path = File.dirname(__FILE__) + "/../../lib/audit-log-parser.rb"

  $params = {
    "collect_requests" => true,
    "debug" => false,
    "filters" => Array.new,
    "output" => "none"
  }

  def test_parametercheck
    # Unknown option
    call = "#{$script_path} --foo 2>&1"
    assert_match /unrecognized option/i, `#{call}`, "Unknown option passed, but not recognized as such in call to \"#{call}\"."

    # Usage
    call = "#{$script_path} -u 2>&1"
    assert_match /^usage/i, `#{call}`, "Usage not working with call to \"#{call}\"."
    assert_no_match /^invalid option/i, `#{call}`, "Usage not working with call to \"#{call}\"."
    call = "#{$script_path} --usage 2>&1"
    assert_match /^usage/i, `#{call}`, "Usage not working with call to \"#{call}\"."
    assert_no_match /^invalid option/i, `#{call}`, "Usage not working with call to \"#{call}\"."
    call = "#{$script_path} -h 2>&1"
    assert_match /^usage/i, `#{call}`, "Usage not working with call to \"#{call}\"."
    assert_no_match /^invalid option/i, `#{call}`, "Usage not working with call to \"#{call}\"."
    call = "#{$script_path} --help 2>&1"
    assert_match /^usage/i, `#{call}`, "Usage not working with call to \"#{call}\"."
    assert_no_match /^invalid option/i, `#{call}`, "Usage not working with call to \"#{call}\"."
    call = "#{$script_path} -? 2>&1"
    assert_match /^usage/i, `#{call}`, "Usage not working with call to \"#{call}\"."
    assert_no_match /^invalid option/i, `#{call}`, "Usage not working with call to \"#{call}\"."

    # Input files and folders
    call = "#{$script_path} /tmp/audit-log-parser-test-file 2>&1"
    assert_match /file.*not found/i, `#{call}`, "Nonexisting file passed, but not recognized as such."
    call = "#{$script_path} #{$testfile1} 2>&1"
    assert_no_match /file.*not found/i, `#{call}`, "Existing file passed, but not found by script."

  end

  def test_parameter_sanitation
    call = "#{$script_path} #{$testfile3} 2>&1"
    assert_no_match /file not found/i, `#{call}`, "Existing file passed, but not found by script."
#    assert_match /sanitize_check_parameters filenames.*modsec_audit_log_1.*modsec_audit_log_2/i, `#{call}`, "Zipped tar archive not expanded correctly."
#    call = "#{$script_path} #{$testfile4} 2>&1"
#    assert_no_match /file not found/i, `#{call}`, "Existing file passed, but not found by script."
#    assert_match /sanitize_check_parameters filenames.*modsec_audit_log_1.*modsec_audit_log_2/i, `#{call}`, "Unzipped tar archive not expanded correctly."
  end

  def test_run_parser
    assert_equal run_parser($testfile1, Array.new, $params).size, 1, "Audit-log parsed, but wrong number of requests returned"
    assert_equal run_parser($testfile2, Array.new, $params).size, 3, "Audit-log parsed, but wrong number of requests returned"
    assert_equal run_parser($testfile3, Array.new, $params).size, 3, "Audit-log parsed, but wrong number of requests returned"
    assert_match /delimiter00003a24/i, run_parser($testfile3, Array.new, $params).to_s, "Audit-log parsed, but individual request not returned"
    assert_match /delimiter00003fh2/i, run_parser($testfile3, Array.new, $params).to_s, "Audit-log parsed, but individual request not returned"
    assert_match /delimiter000025j3/i, run_parser($testfile3, Array.new, $params).to_s, "Audit-log parsed, but individual request not returned"
  end

  def test_stdin
    call = "cat #{$testfile1} | #{$script_path} -f \"method = GET \" 2>&1"
    assert_match /A--/i, `#{call}`, "STDIN processing failed with call to \"#{call}\"."
  end

  def test_filter
    # *** filter for a static data items

    #request_id
    call = "#{$script_path} -f \"request_id = 6JH5wqwfsQsAAF9ZAxMAAAAX \" #{$testfile1} 2>&1"
    assert_match /A--/i, `#{call}`, "Filter for method failed with call to \"#{call}\"."
    call = "#{$script_path} -f \"request_id = XXX6JH5wqwfsQsAAF9ZAxMAAAAX \" #{$testfile1} 2>&1"
    assert_no_match /A--/i, `#{call}`, "Filter for method failed with call to \"#{call}\"."

    # method
    call = "#{$script_path} -f \"method = GET \" #{$testfile1} 2>&1"
    assert_match /A--/i, `#{call}`, "Filter for method failed with call to \"#{call}\"."
    call = "#{$script_path} -f \"method = POST \" #{$testfile1} 2>&1"
    assert_no_match /A--/i, `#{call}`, "Filter for method failed with call to \"#{call}\"."

    # path
    call = "#{$script_path} -f \"path =~ /\\/index\.html/ \" #{$testfile1} 2>&1"
    assert_match /A--/i, `#{call}`, "Filter for path failed with call to \"#{call}\"."
    call = "#{$script_path} -f \"path =~ /\/index\.php/ \" #{$testfile1} 2>&1"
    assert_no_match /A--/i, `#{call}`, "Filter for path failed with call to \"#{call}\"."

    # http_version
    call = "#{$script_path} -f \"http_version == HTTP/1.1 \" #{$testfile1} 2>&1"
    assert_match /A--/i, `#{call}`, "Filter for http_version failed with call to \"#{call}\"."
    call = "#{$script_path} -f \"http_version == HTTP/1.0 \" #{$testfile1} 2>&1"
    assert_no_match /A--/i, `#{call}`, "Filter for http_version failed with call to \"#{call}\"."

    # status
    call = "#{$script_path} -f \"status == 200\" #{$testfile1} 2>&1"
    assert_match /A--/i, `#{call}`, "Filter for status failed with call to \"#{call}\"."
    call = "#{$script_path} -f \"status == 404\" #{$testfile1} 2>&1"
    assert_no_match /A--/i, `#{call}`, "Filter for status failed with call to \"#{call}\"."

    # status_message
    call = "#{$script_path} -f \"status_message == OK \" #{$testfile1} 2>&1"
    assert_match /A--/i, `#{call}`, "Filter for status_message failed with call to \"#{call}\"."
    call = "#{$script_path} -f \"status_message == File not found \" #{$testfile1} 2>&1"
    assert_no_match /A--/i, `#{call}`, "Filter for status failed with call to \"#{call}\"."

    # http_response_version
    call = "#{$script_path} -f \"response_http_version == HTTP/1.1 \" #{$testfile1} 2>&1"
    assert_match /A--/i, `#{call}`, "Filter for response_http_version failed with call to \"#{call}\"."
    call = "#{$script_path} -f \"response_http_version == HTTP/1.0 \" #{$testfile1} 2>&1"
    assert_no_match /A--/i, `#{call}`, "Filter for response_http_version failed with call to \"#{call}\"."

    # microtimestamp
    call = "#{$script_path} -f \"microtimestamp = 1211884759022018 \" #{$testfile1} 2>&1"
    assert_match /A--/i, `#{call}`, "Filter for microtimestamp failed with call to \"#{call}\"."
    call = "#{$script_path} -f \"microtimestamp < 1211884759022018 \" #{$testfile1} 2>&1"
    assert_no_match /A--/i, `#{call}`, "Filter for microtimestamp failed with call to \"#{call}\"."

    # duration
    call = "#{$script_path} -f \"duration > 2000 \" #{$testfile1} 2>&1"
    assert_match /A--/i, `#{call}`, "Filter for duration failed with call to \"#{call}\"."
    call = "#{$script_path} -f \"duration < 2000 \" #{$testfile1} 2>&1"
    assert_no_match /A--/i, `#{call}`, "Filter for duration failed with call to \"#{call}\"."

    # modsectime1-3
    call = "#{$script_path} -f \"modsectime1 = 1293 \" #{$testfile1} 2>&1"
    assert_match /A--/i, `#{call}`, "Filter for modsectime1 failed with call to \"#{call}\"."
    call = "#{$script_path} -f \"modsectime1 > 1293 \" #{$testfile1} 2>&1"
    assert_no_match /A--/i, `#{call}`, "Filter for modsectime1 failed with call to \"#{call}\"."
    call = "#{$script_path} -f \"modsectime2 = 1305 \" #{$testfile1} 2>&1"
    assert_match /A--/i, `#{call}`, "Filter for modsectime2 failed with call to \"#{call}\"."
    call = "#{$script_path} -f \"modsectime2 > 1305 \" #{$testfile1} 2>&1"
    assert_no_match /A--/i, `#{call}`, "Filter for modsectime2 failed with call to \"#{call}\"."
    call = "#{$script_path} -f \"modsectime3 = 1879 \" #{$testfile1} 2>&1"
    assert_match /A--/i, `#{call}`, "Filter for modsectime3 failed with call to \"#{call}\"."
    call = "#{$script_path} -f \"modsectime3 > 1879 \" #{$testfile1} 2>&1"
    assert_no_match /A--/i, `#{call}`, "Filter for modsectime3 failed with call to \"#{call}\"."
    
    # producer
    call = "#{$script_path} -f \"producer = ModSecurity v2.1.4 (Apache 2.x) \" #{$testfile1} 2>&1"
    assert_match /A--/i, `#{call}`, "Filter for producer failed with call to \"#{call}\"."
    call = "#{$script_path} -f \"producer = XModSecurity v2.1.4 (Apache 2.x) \" #{$testfile1} 2>&1"
    assert_no_match /A--/i, `#{call}`, "Filter for producer failed with call to \"#{call}\"."
    
    # server
    call = "#{$script_path} -f \"server = Apache \" #{$testfile1} 2>&1"
    assert_match /A--/i, `#{call}`, "Filter for server failed with call to \"#{call}\"."
    call = "#{$script_path} -f \"server != Apache \" #{$testfile1} 2>&1"
    assert_no_match /A--/i, `#{call}`, "Filter for server failed with call to \"#{call}\"."


    # *** filter for a dynamic / multiline data items

    # message
    call = "#{$script_path} -f \"message =~ Warning \" #{$testfile1} 2>&1"
    assert_match /A--/i, `#{call}`, "Filter for message failed with call to \"#{call}\"."
    call = "#{$script_path} -f \"message =~ XWarning \" #{$testfile1} 2>&1"
    assert_no_match /A--/i, `#{call}`, "Filter for message failed with call to \"#{call}\"."
    call = "#{$script_path} -f \"message =~ /Warning.*/ \" #{$testfile1} 2>&1"
    assert_match /A--/i, `#{call}`, "Filter for message failed with call to \"#{call}\"."
    call = "#{$script_path} -f \"message =~ /Warning.*REQUEST_PROTOCOL/ \" #{$testfile1} 2>&1"
    assert_match /A--/i, `#{call}`, "Filter for message failed with call to \"#{call}\"."
    call = "#{$script_path} -f \"message =~ /Warning.*not\ predefined/ \" #{$testfile1} 2>&1"
    assert_match /A--/i, `#{call}`, "Filter for message failed with call to \"#{call}\"."


    # headers
    call = "#{$script_path} -f \"Header:Connection = Keep-Alive \" #{$testfile1} 2>&1"
    assert_match /A--/i, `#{call}`, "Filter for header failed with call to \"#{call}\"."
    call = "#{$script_path} -f \"Header:Connection != Keep-Alive \" #{$testfile1} 2>&1"
    assert_no_match /A--/i, `#{call}`, "Filter for header failed with call to \"#{call}\"."
    call = "#{$script_path} -f \"Header:Connection =~ /^.*$/ \" #{$testfile1} 2>&1"
    assert_match /A--/i, `#{call}`, "Filter for header failed with call to \"#{call}\"."

    # querystringparameters
    call = "#{$script_path} -f \"Querystringparameter:foo = 1 \" #{$testfile1} 2>&1"
    assert_match /A--/i, `#{call}`, "Filter for querystringparameter failed with call to \"#{call}\"."
    call = "#{$script_path} -f \"Querystringparameter:foo = 2 \" #{$testfile1} 2>&1"
    assert_no_match /A--/i, `#{call}`, "Filter for querystringparameter failed with call to \"#{call}\"."

    # cookies
    call = "#{$script_path} -f \"Cookie:testcookie = foo \" #{$testfile1} 2>&1"
    assert_match /A--/i, `#{call}`, "Filter for cookie failed with call to \"#{call}\"."
    call = "#{$script_path} -f \"Cookie:testcookie = bar \" #{$testfile1} 2>&1"
    assert_no_match /A--/i, `#{call}`, "Filter for cookie failed with call to \"#{call}\"."

    # postparameters
    call = "#{$script_path} -f \"Postparameter:foo = x \" #{$testfile2} 2>&1"  # url-encoded
    assert_match /A--/i, `#{call}`, "Filter for postparameter failed with call to \"#{call}\"."
    call = "#{$script_path} -f \"Postparameter:foo = bar\\n \" #{$testfile2} 2>&1"  # multipart
    assert_match /A--/i, `#{call}`, "Filter for postparameter failed with call to \"#{call}\"."
    call = "#{$script_path} -f \"Postparameter:foo =~ bar \" #{$testfile2} 2>&1"  # multipart
    assert_match /A--/i, `#{call}`, "Filter for postparameter failed with call to \"#{call}\"."
    call = "#{$script_path} -f \"Postparameter:foo =~ XXbar \" #{$testfile2} 2>&1"
    assert_no_match /A--/i, `#{call}`, "Filter for postparameter failed with call to \"#{call}\"."

    # *** Combined filter
    call = "#{$script_path} -f \"Cookie:testcookie = foo and status = 200 \" #{$testfile1} 2>&1"
    assert_match /A--/i, `#{call}`, "Combined Filter failed failed with call to \"#{call}\"."
    call = "#{$script_path} -f \"Cookie:testcookie = foo and duration < 200000 \" #{$testfile1} 2>&1"
    assert_match /A--/i, `#{call}`, "Combined Filter failed failed with call to \"#{call}\"."
    call = "#{$script_path} -f \"Cookie:testcookie = foo and status != 200 \" #{$testfile1} 2>&1"
    assert_no_match /A--/i, `#{call}`, "Combined Filter failed failed with call to \"#{call}\"."

  end
end

