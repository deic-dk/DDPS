#!/bin/bash
#
# $Header$
#
#--------------------------------------------------------------------------------------#
# TODO
#	add slack code to notify about upcoming patches. Include uname major/minor hostname
#	etc in payload
#	Faileures etc should also go to slack
#	Introduce some where to keep 'secrets' from prying eyes
#--------------------------------------------------------------------------------------#

# time:
# 	first time run: 50 seconds
# 	next run(s):     6 seconds
#
# Vars
#
MY_LOGFILE=/var/log/adhoc_update.log
VERBOSE=FALSE
CHECKONLY=FALSE
TMPFILE=$( mktemp )
SLOG="/usr/local/bin/log2slack "

export PATH=/bin:/etc:/sbin:/usr/bin:/usr/bin/X11:/usr/local/bin:/usr/local/etc:/usr/local/sbin:/usr/sbin:/usr/lib
export APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE="ignore"

# this may not allways work - seem to fail for vmware tools. Don't know any
# workaround for unattented installation though
export DEBIAN_FRONTEND=noninteractive

#
# Functions
#
function install_digup_if_not_found()
{
		if [ ! -e /usr/local/bin/digup ]; then
			logit "installing /usr/local/bin/digup ... "
			cd /tmp
			(
				git clone https://github.com/bingmann/digup.git 
				apt-get -y install autotools-dev automake 
				cd /tmp/digup
				bash autogen.sh 
				./configure
				make install
			) 2>&1 |logit
			cd /tmp
			rm -fr /tmp/digup
		else
			logit "found /usr/local/bin/digup"
		fi
}

function run_digup()
{
	install_digup_if_not_found

	# daily_backup and adhoc_update are part of the same package
	logit "Searching for DIGUPDIRS in /usr/local/etc/daily_backup.cfg ... "
	DIGUPDIRS=$( sed '/^DIGUPDIRS=/!d; s/.*=//;s/"//g' /usr/local/etc/daily_backup.cfg )
	case $DIGUPDIRS in
		*)	logit "found DIGUPDIRS=$DIGUPDIRS"
			;;
		"") DIGUPDIRS="/opt /etc /bin /usr /var/opt /var/www /var/snap"
			# this covers most of Debian/Ubuntu but also gives a lot of noice from gitlab and the like
			logit "no DIGUPDIRS, using $DIGUPDIRS"
			;;
	esac
	test -d /root/digup || mkdir /root/digup
	PREFIX=/root/digup
	TMPFILE=$( mktemp -p ${PREFIX} )

	logit "running file integrety check for files in each of the directories '$DIGUPDIRS'"
	for D in $DIGUPDIRS
	do
		if [ -d "$D" ]; then
			TMP=$( echo $D| sed 's%/%_%g' )
			SHAFILE=${PREFIX}/digup_root${TMP}.sha512
			LOGFILE=${PREFIX}/digup_root${TMP}.log
			# If  $SHAFILE $LOGFILE does not exist and we only have new. entries in the LOGFILE
			# ignore output: it is a first time run
			if [ ! -f $SHAFILE ]; then
				FIRSTRUN="TRUE"
			else
				FIRSTRUN="FALSE"
			fi
			# Prevent complainings 'file not found' from digup
			touch $SHAFILE $LOGFILE
			/usr/local/bin/digup --file=${SHAFILE} --modified --batch --update --verbose --type=sha512 --directory=${D} > ${LOGFILE} 2>/dev/null

			case $1 in
				"ignoreerrors")
					logit processed $D, ignoring chages
					;;
				*)	logit processed $D, reporting all changes
					case $FIRSTRUN in
						"TRUE")
							logit "no $SHAFILE, ignoring initial output"
						;;
						"FALSE")
							egrep 'new.$|CHANGED.$|DELETED.$' ${LOGFILE} > ${TMPFILE}
							case $? in
								1)	logit no changes in $D
								;;
								*)	logit "warning: changes in $D (only showing the first 100 lines)"
									head -100 ${TMPFILE}|logit
									log2slack WARNING: first 100 changes in $D: $( head -100 ${TMPFILE} )
								;;
							esac
						;;
					esac
					;;
			esac
		else
			logit "Not a directory: $D, ignored"
		fi
	done

	rm -f $TMPFILE
	logit done
}

function run_apt_get()
{
        do=$1
        tmpfile=/tmp/$$.tmp.$$.tmp

        if [ -z "${do}" ]; then
                logit "in function run_apt_get: called without argument, bye"
                exit
        fi
		logit "apt-get $do ... "
		# allow unauthenticated as well otherwise upgrade(s) may fail
		/usr/bin/apt-get -y --allow-unauthenticated $do > $tmpfile 2>&1
		if [[ $? > 0 ]]; then
				echo fatal: apt-get $do failed
                logit "apt-get $do failed:"
                logit  < $tmpfile
                /bin/rm -f $tmpfile
                exit 1
		else
				if egrep -q "^W: Failed to fetch|^Err http"  $tmpfile
				then
					logit "apt-get $do failed:"
                	logit  < $tmpfile
					${SLOG} apt-get $do failed
					exit 1
				else
                	logit apt-get $do done ok
				fi
		fi
        /bin/rm -f $tmpfile
}

logit() {
# purpose     : Timestamp output
# arguments   : Line og stream
# return value: None
# see also    :
	LOGIT_NOW="`date '+%H:%M:%S (%d/%m)'`"
	STRING="$*"

	if [ -n "${STRING}" ]; then
		$echo "${LOGIT_NOW} ${STRING}" >> ${MY_LOGFILE}
		if [ "${VERBOSE}" = "TRUE" ]; then
			$echo "${LOGIT_NOW} ${STRING}"
		fi
	else
		while read LINE
		do
			if [ -n "${LINE}" ]; then
				$echo "${LOGIT_NOW} ${LINE}" >> ${MY_LOGFILE}
				if [ "${VERBOSE}" = "TRUE" ]; then
					$echo "${LOGIT_NOW} ${LINE}"
				fi
			else
				$echo "" >> ${MY_LOGFILE}
			fi
		done
	fi
}

clean_f () {
# purpose     : Clean-up on trapping (signal)
# arguments   : None
# return value: None
# see also    :
	$echo trapped
	/bin/rm -f $TMPFILE ${TMPFILE2} $MAILFILE
	exit 1
}

#
# clean up on trap(s)
#
trap clean_f 1 2 3 13 15

################################################################################
# Main
################################################################################

echo=/bin/echo
case ${N}$C in
	"") if $echo "\c" | grep c >/dev/null 2>&1; then
		N='-n'
	else
		C='\c'
	fi ;;
esac

#
# Process arguments
#
while getopts cv opt
do
case $opt in
	v)	VERBOSE=TRUE
	;;
	c)	CHECKONLY=TRUE
	;;
	*)	echo "usage: `basename $0` [-cv]"
		echo "     -c: check only"
		echo "     -v: verbose"
		exit
	;;
esac
done
shift `expr $OPTIND - 1`

logit "starting $0 $*"

# Linux Ubuntu specific output
EXIF=`netstat -rn|awk '$1 == "0.0.0.0" { print $NF }'`
MYIP=`ifconfig $EXIF|sed '/inet/!d; /inet6/d; s/.*inet //; s/[\t ].*$//'`
SYSINFO="`hostname -f` [${MYIP}] `lsb_release -d|sed 's/.*://; s/^[\t ]*//g'`"

logit "$SYSINFO"

# Run digup before any changes -- here must be no outut indicating changes
run_digup printerrors

# Try to fix any expired keys
(
	for K in $(apt-key list | grep expired | cut -d'/' -f2 | cut -d' ' -f1); do sudo apt-key adv --recv-keys --keyserver keys.gnupg.net $K; done
	for K in $(apt-key list | grep expired | cut -d'/' -f2 | cut -d' ' -f1); do sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 $K; done
) 2>&1 | logit

run_apt_get update

# List packages which can be upgraded and ignore 'WARNING: apt does not have a stable CLI interface'
apt list --upgradable -a 2>/dev/null|logit

case $CHECKONLY in
	"TRUE")	logit upgrade check done
			exit
	;;
	"FALSE")	logit done. Proceding with upgrade and dist-upgrade and autoremove
	;;
esac

# sometimes upgrade fails so run this:
dpkg --configure -a

run_apt_get upgrade
run_apt_get dist-upgrade
run_apt_get autoremove
run_apt_get clean

# Ignore any changes that will be due to the upgrade
run_digup ignoreerrors

if [ -f /var/run/reboot-required ]; then
	echo "Reboot required, will do so" > $TMPFILE
	${SLOG} "Applied $LINES patches, will do required reboot now"
	logit reboot required - reboot in 60 seconds
	sleep 60
	rm -f ${TMPFILE}
	reboot
else
	echo reboot not required normal exit > $TMPFILE
	logit reboot not required normal exit
fi
rm -f ${TMPFILE}
exit 0

#
# Documentation and  standard disclaimar
#
# Copyright (C) 2001 Niels Thomas Haugård
# UNI-C
# http://www.uni-c.dk/
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the 
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License 
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# Please notice this script uses a set of other commands to do the
# actual work. These commands has their own licences and are not made by me
#++
# NAME
#	adhoc_update.sh 1
# SUMMARY
#	Ad-hoc based software updating of modern Debian and Ubuntu with simple
#	file system integrity checks and advising of required reboot and integrity
#	failures on Slack
# PACKAGE
#	backup-and-patch
# SYNOPSIS
#	adhoc_update.sh [-v][c]
# DESCRIPTION
#	\fCadhoc_update.sh(1)\fR is a script which does the following:
# .IP o
#	Check if any files in a set of directories has changed since last run and
#	complain if files have been added, changed or deleted.
# .IP o
#	\fCapt-get update\fR
# .IP o
#	\fCapt-get upgrade\fR
# .IP o
#	\fCapt-get dist-upgrade\fR
# .IP o
#	Update the file digest with new values.
#
#	If a reboot is required it will be done as well.
#
#	If the integrity check software is not found, it will be compiled and installed from git.
#
# OPTIONS
#	Kaldes \fCadhoc_update.sh\fR med flaget
# .TP
#	\fC-c\fR
#	Print a list of software which can be updated and exit (use -v)
# .TP
#	\fC-v\fR
#	Print what is being done to stdout
# SE OGSÅ
#	Documentation for UNIbackup.
# DIAGNOSTICS
#	None.
# BUGS
#	Sure. Please report any found to the author.
# VERSION
#	$Date: 2003/08/13 13:40:31 $
# .br
#	$Revision: 1.17 $
# .br
#	$Source: /lan/ssi/projects/adhoc_update/src/RCS/adhoc_update.sh,v $
# .br
#	$State: Exp $
# HISTORY
#	See \fCrlog\fR $Id$
# AUTHOR(S)
#	Niels Thomas Haugård
# .br
#	E-mail: thomas@haugaard.net
# .br
#	UNI\(buC
# .br
#	DTU, Building 304
# .br
#	DK-2800 Kgs. Lyngby
#--
