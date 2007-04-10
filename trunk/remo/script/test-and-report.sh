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
REV=`svn info | grep Revision\: | cut -d " " -f2`
TEST=`ruby script/overall-testsuite.rb >/tmp/test.log; cat /tmp/test.log | tail -1`

cd

rm -rf $TMPDIR
echo "Test Results for Revision $REV (`date +'%Y-%m-%d %H:%M %Z'`): $TEST" 

