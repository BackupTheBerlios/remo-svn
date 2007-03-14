#!/bin/bash
export GETURL="http://localhost:16005/index.php"
export CURLOPTIONS=""

curl $CURLOPTIONS "$GETURL"
curl $CURLOPTIONS "$GETURL?q_single_integer=1"
curl $CURLOPTIONS "$GETURL?q_single_integer"
curl $CURLOPTIONS "$GETURL?q_single_integer=10"
curl $CURLOPTIONS "$GETURL?q_single_integer_or_empty"
curl $CURLOPTIONS "$GETURL?q_single_integer_or_empty=1"
curl $CURLOPTIONS "$GETURL?q_single_integer_or_empty=10"

curl $CURLOPTIONS "$GETURL?q_exotic=%00"
curl $CURLOPTIONS "$GETURL?q_exotic=%01"
curl $CURLOPTIONS "$GETURL?q_exotic=%02"
curl $CURLOPTIONS "$GETURL?q_exotic=%03"
curl $CURLOPTIONS "$GETURL?q_exotic=%04"
curl $CURLOPTIONS "$GETURL?q_exotic=%05"
curl $CURLOPTIONS "$GETURL?q_exotic=%06"
curl $CURLOPTIONS "$GETURL?q_exotic=%07"
curl $CURLOPTIONS "$GETURL?q_exotic=%08"
curl $CURLOPTIONS "$GETURL?q_exotic=%09"
curl $CURLOPTIONS "$GETURL?q_exotic=%0A"
curl $CURLOPTIONS "$GETURL?q_exotic=%0B"
curl $CURLOPTIONS "$GETURL?q_exotic=%0C"
curl $CURLOPTIONS "$GETURL?q_exotic=%0D"
curl $CURLOPTIONS "$GETURL?q_exotic=%0E"
curl $CURLOPTIONS "$GETURL?q_exotic=%0F"
curl $CURLOPTIONS "$GETURL?q_exotic=%10"
curl $CURLOPTIONS "$GETURL?q_exotic=%11"
curl $CURLOPTIONS "$GETURL?q_exotic=%12"
curl $CURLOPTIONS "$GETURL?q_exotic=%13"
curl $CURLOPTIONS "$GETURL?q_exotic=%14"
curl $CURLOPTIONS "$GETURL?q_exotic=%15"
curl $CURLOPTIONS "$GETURL?q_exotic=%16"
curl $CURLOPTIONS "$GETURL?q_exotic=%17"
curl $CURLOPTIONS "$GETURL?q_exotic=%18"
curl $CURLOPTIONS "$GETURL?q_exotic=%19"
curl $CURLOPTIONS "$GETURL?q_exotic=%1A"
curl $CURLOPTIONS "$GETURL?q_exotic=%1B"
curl $CURLOPTIONS "$GETURL?q_exotic=%1C"
curl $CURLOPTIONS "$GETURL?q_exotic=%1D"
curl $CURLOPTIONS "$GETURL?q_exotic=%1E"
curl $CURLOPTIONS "$GETURL?q_exotic=%1F"
curl $CURLOPTIONS "$GETURL?q_exotic=%20"
curl $CURLOPTIONS "$GETURL?q_exotic=%21"
curl $CURLOPTIONS "$GETURL?q_exotic=\""
curl $CURLOPTIONS "$GETURL?q_exotic=%23"
curl $CURLOPTIONS "$GETURL?q_exotic=$"
curl $CURLOPTIONS "$GETURL?q_exotic=%"
curl $CURLOPTIONS "$GETURL?q_exotic=%26"
curl $CURLOPTIONS "$GETURL?q_exotic='"
curl $CURLOPTIONS "$GETURL?q_exotic=("
curl $CURLOPTIONS "$GETURL?q_exotic=)"
curl $CURLOPTIONS "$GETURL?q_exotic=*"
curl $CURLOPTIONS "$GETURL?q_exotic=%2B"
curl $CURLOPTIONS "$GETURL?q_exotic=,"
curl $CURLOPTIONS "$GETURL?q_exotic=-"
curl $CURLOPTIONS "$GETURL?q_exotic=."
curl $CURLOPTIONS "$GETURL?q_exotic=/"
curl $CURLOPTIONS "$GETURL?q_exotic=:"
curl $CURLOPTIONS "$GETURL?q_exotic=;"
curl $CURLOPTIONS "$GETURL?q_exotic=<"
curl $CURLOPTIONS "$GETURL?q_exotic=%3D"
curl $CURLOPTIONS "$GETURL?q_exotic=>"
curl $CURLOPTIONS "$GETURL?q_exotic=?"
curl $CURLOPTIONS "$GETURL?q_exotic=@"
curl $CURLOPTIONS "$GETURL?q_exotic=\["
curl $CURLOPTIONS "$GETURL?q_exotic=\\"
curl $CURLOPTIONS "$GETURL?q_exotic=\]"
curl $CURLOPTIONS "$GETURL?q_exotic=^"
curl $CURLOPTIONS "$GETURL?q_exotic=_"
curl $CURLOPTIONS "$GETURL?q_exotic=\`"
curl $CURLOPTIONS "$GETURL?q_exotic=\{"
curl $CURLOPTIONS "$GETURL?q_exotic=|"
curl $CURLOPTIONS "$GETURL?q_exotic=\}"
curl $CURLOPTIONS "$GETURL?q_exotic=~"
curl $CURLOPTIONS "$GETURL?q_exotic=%7F"
curl $CURLOPTIONS "$GETURL?q_single_integer=1&q_single_letter=a"
curl $CURLOPTIONS "$GETURL?q_single_integer=1&q_single_letter"
curl $CURLOPTIONS "$GETURL?q_single_integer=1&q_empty=1"
curl $CURLOPTIONS "$GETURL?q_single_integer=1&q_single_integer_or_empty"
curl $CURLOPTIONS "$GETURL?q_single_integer_or_empty&q_single_integer=1"
curl $CURLOPTIONS "$GETURL?q_string_long=test+string+and+more"
curl $CURLOPTIONS "$GETURL?q_string_long=test%20string%20and%20more"
curl $CURLOPTIONS -H "X-Unknown: xxx" "$GETURL"
curl $CURLOPTIONS -H "Cookie: xxx" "$GETURL"
