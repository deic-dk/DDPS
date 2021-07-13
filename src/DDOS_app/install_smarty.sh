#! /bin/bash
#
#  Install php template engine smarty, see https://www.smarty.net
#
# Make script fail on error(s)
set -e

# According to www.smarty.net the source is on github, find the latest
# download it and extract the files where php expects them to be.
# The github path github.com/smarty-php/smarty/releases/latest contain
# a link for extraction
#
# Going from 
# <a href="/smarty-php/smarty/archive/v3.1.33.tar.gz" rel="nofollow" class="d-flex flex-items-center">
# to
# /smarty-php/smarty/archive/v3.1.33.tar.gz
# with sed:
PATH_TO_LATEST_ARCHIVE=$(  wget -q https://github.com/smarty-php/smarty/releases/latest -O -|sed '
	/\/smarty-php\/smarty\/archive/!d;
	s/.*"\//\//;
	/zip/d;
	s/" rel.*//
	')

# Save output from wget in case of error(s)
TMPFILE=$( mktemp )

# download to /tmp
cd /tmp

# basename: from /smarty-php/smarty/archive/v3.1.33.tar.gz to v3.1.33.tar.gz
if [ -z ${PATH_TO_LATEST_ARCHIVE} ]; then
	echo are you connected to the internet?
	echo PATH_TO_LATEST_ARCHIVE empty, bye
	exit 127
fi

LATEST_ARCHIVE=$( basename ${PATH_TO_LATEST_ARCHIVE} )

# sed: from v3.1.33.tar.gz to 3.1.33
LATEST_VERSION=$( echo $LATEST_ARCHIVE | sed 's/[^0-9.]*//g; s/\(\.\)\1/\1/g; s/\.$//' )

# echo "The latest version of smarty-php seems to be $LATEST_VERSION"

# If $LATEST_VERSION is empty we have an error and stops

if [ -z "$LATEST_VERSION" ]; then
	echo "\$LATEST_VERSION is empty, somthing is wrong with the script" 
	exit 1
fi

# get it
wget https://github.com/${PATH_TO_LATEST_ARCHIVE} 2> ${TMPFILE}
case $? in
	0)	#  echo "download ok" 
		rm -f $TMPFILE
		;;
	*)	echo "Errors: `cat $TMPFILE`" 
		exit 1
		;;
esac

# install it
if [ ! -d /usr/local/lib/php ]; then
	mkdir -p /usr/local/lib/php
	chmod -R 555 /usr/local/lib/php
fi

# remove any existing versions
cd /usr/local/lib/php
if [ -d smarty ]; then
	rm -fr smarty
fi

# extract the archive and move in place
mv /tmp/$LATEST_ARCHIVE .
tar xfpz $LATEST_ARCHIVE

mv smarty-${LATEST_VERSION} smarty

# echo "Installed php-smarty version ${LATEST_VERSION} in /usr/local/lib/php" 

exit 0

#  Copyright © 2020, Niels Thomas Haugård, www.deic.dk, wwww.i2.dk.dk
#  
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#  
#       http://www.apache.org/licenses/LICENSE-2.0
#  
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#  

