<?php
print "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n";
print "<html>\n";
print "<head>\n";
print "</head>\n";
print "<body>\n";
print "<h1>hello world</h1>\n";

print "<h2>general</h2>\n";
print "uri: " . $_SERVER['REQUEST_URI'] . "<br />\n";
print "http_method: " . $_SERVER['REQUEST_METHOD'] . "<br />\n";

print "<h2>query string</h2>\n";
foreach (split("&", $_SERVER['QUERY_STRING']) as $item) {
	print "$item<br />\n";
}

print "<h2>cookies</h2>\n";
foreach ($_COOKIE as $key => $value) {
	print "$key: $value<br />\n";
}

print "<h2>post payload</h2>\n";
foreach ($_POST as $key => $value) {
	print "$key: $value<br />\n";
}

print "</body>\n";
print "</html>\n";
?>
