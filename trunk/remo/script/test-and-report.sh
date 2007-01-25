#!/bin/sh
#
# This downloads the subversion tree of the project and calls a test function
# The result of the test is appended to a logfile 
#
#

SVNTREE="http://svn.berlios.de/svnroot/repos/remo/trunk"
TRUNKDIR="trunk/remo"
TMPDIR=`mktemp -d`

TMPFILE=D`tempfile`

cd $TMPDIR

svn checkout --quiet $SVNTREE
cd $TRUNKDIR
REV=`svn log 2>/dev/null | head -2 | tail -1 | cut -d" " -f1`	# clumsy way of getting the last revision number
TEST=`ruby test/functional/main_controller_test.rb | tail -1`

cd

rm -rf $TMPDIR
echo "Test Results for Revision $REV (`date +'%Y-%m-%d %H:%M %Z'`): $TEST" 

