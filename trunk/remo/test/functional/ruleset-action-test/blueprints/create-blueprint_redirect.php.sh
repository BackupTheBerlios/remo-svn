#!/bin/bash
export REDIRECTURL="http://localhost:16005/redirect.php"
export CURLOPTIONS=""

curl $CURLOPTIONS "$REDIRECTURL"
curl $CURLOPTIONS -H "Cookie: c_session=12345678" "$REDIRECTURL"
curl $CURLOPTIONS -H "Cookie: c_session=12345678" "$REDIRECTURL?q_unknown=1"
curl $CURLOPTIONS -H "Cookie: c_session=12345678" "$REDIRECTURL?q_single_integer=1"

