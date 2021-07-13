#! /bin/bash
#
# vim: set nonu ts=8 sw=8 tw=0:
#
#	$Revision: 1.1 $
#

#
# Backup a files on local machine using gnu tar. The
# archive should go on a nfs filesystem, or be picked
# up by a remote server e.g. using rsync
#

##################################################################
#
# Vars - Please change default settings in the config file(s)
#
##################################################################

PATH=/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/sbin:/usr/local/bin:/var/opt/UNItools/bin
export PATH

CONFIGFILE=/usr/local/etc/daily_backup.cfg
FILELIST=/usr/local/etc/daily_backup.files

SLOG="/usr/local/bin/log2slack "

# Use GNU tar (compression and exclude flags) 
case `uname` in
	Linux)		GTAR=tar
	;;
	OpenBSD|SunOS)	GTAR=gtar
		if ! type $GTAR >/dev/null 2>&1; then
			# part of base in FreeBSD, OpenBSD, OSX and solaris. 
			echo $GTAR not found please install
			echo OpenBSD: pkg_find gtar
			exit 1
		fi
	;;
	*)		GTAR=tar	# wild guess
	;;
esac

# Use mailx to send mail in case of errors. It is installed as part of the base
# os in FreeBSD, OpenBSD, OSX and Solaris - but not Ubuntu, as it comes without
# postfix or sendmail in base. Which is nice.
#if ! type mailx >/dev/null 2>&1; then
#	echo mailx not found install with
#	echo ubuntu: apt-get install heirloom-mailx
#	exit 1
#fi

ME=`basename $0`
MY_LOGFILE=/var/log/backup.log		# logfile send by mail in case of errors

GZRATE=9				# compression rate for gtar
NOW=`date '+%Y%m%d-%H%M%S'`		# date as YYYYmmdd-HHMMSS
HOSTNAME=`/bin/hostname`		# caliban.ssi.uni-c.dk / scan / ...
DOMAINNAME=`/bin/domainname`		# sik / ssi.uni-c.dk / ...

case $DOMAINNAME in
	""|\(none\))
		DNSDOMAIN=""		# fqdn is identical to hostname on FreeBSD
	;;				# else append domainname
	*)	DNSDOMAIN=".${DOMAINNAME}"
	;;
esac

FQDN="${HOSTNAME}${DNSDOMAIN}"

OS=`uname -s`				# FreeBSD
VERSION=`uname -r`			# 5.2.1-RELEASE

# Prefer tar with compression to two step (tar/gzip) or pipe
ZIPFILE=${FQDN}.${OS}.${VERSION}.${NOW}.tgz

# Save backup same place as on the Check Point firealls and (mis)use existing
# backup collector for retreival
BACKUP_HOME="/var/CPbackup/"

ERRORS=0				# default: no errors on start
export ERRORS				# required

##################################################################
#
# Functions
#
##################################################################

function pre_backup() {
	: # I am a dummy function
}

function post_backup() {
	: # I am a dummy function
}

function logit() {
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

usage() {
# purpose     : Script usage
# arguments   : none
# return value: none
# see also    :
cat << EOF

	ERROR: $*

	Usage: `basename $0` [-v] [-c configfile] [-f filelist]

	Usage: `basename $0`

EOF
	exit 2
}

clean_f () {
# purpose     : Clean-up on trapping (signal)
# arguments   : None
# return value: None
# see also    :
	$echo trapped
	exit 1
}

################################################################################
# Main
################################################################################
#
# clean up on trap(s)
#
trap clean_f 1 2 3 13 15

#
# Suppressing newline
#
echo="builtin echo "
case ${N}$C in
	"") if $echo "\c" | grep c >/dev/null 2>&1; then
		N='-n'
	else
		C='\c'
	fi ;;
esac

MY_ARGV=$*

#
# Upon first run check for missing config file
#
if [ ! -f $CONFIGFILE ]; then
	logit "creating default $CONFIGFILE"
	cp ${CONFIGFILE}.tmpl $CONFIGFILE
fi
if [ ! -f $FILELIST ]; then
	logit "creating default $FILELIST"
	cp ${FILELIST}.tmpl $FILELIST
fi

#
# Process arguments
#
while getopts vc:f:hiu opt
do
case $opt in
	v)	VERBOSE=TRUE
	;;
	c)	CONFIGFILE=$OPTARG
	;;
	f)	FILELIST=$OPTARG
	;;
	h)	usage
	;;
	i)
		echo installing crontab ...
		cat <<-EOF > /etc/cron.d/daily_backup
		# Periodic backup on a daily basis to the local filesystem. Archives will be consolidated with rsync
		59 23 * * * root [ -x /usr/local/bin/daily_backup.sh ] && /usr/local/bin/daily_backup.sh
EOF
		chmod 644 /etc/cron.d/daily_backup
		/etc/init.d/cron restart
		exit 0
	;;
	u)	echo uninstalling crontab ...
		/bin/rm -f /etc/cron.d/daily_backup
		/etc/init.d/cron restart
		exit 0
	;;
	*)	usage
		exit 1
	;;
esac
done
shift `expr $OPTIND - 1`

/bin/rm -f ${MY_LOGFILE}

logit "Starting ${ME} ${MY_ARGV}"
logit "Old logfile '${MY_LOGFILE}' removed. Processing 'dot' files ... "

for RC in /etc/profile /etc/bashrc ${HOME}/.profile ${HOME}/.bash_login ${HOME}/.bashrc
do
	if [ -f "${RC}" ]; then
		logit "processing '${RC}' ... "
		. "${RC}" 2>&1 | logit
	else
		logit "file '${RC}' not found on `hostname`"
	fi
done


ARCHIVE_LIST=${BACKUP_HOME}/archive_list # list of archives for cleaning
STATUS_FILE=${BACKUP_HOME}/status	# print result of last backup here in the format
					# $NOW:ok | $NOW:failed
					# The document will be checked by something else
					# The document will be checked by something else

test -d ${BACKUP_HOME}	|| mkdir -p ${BACKUP_HOME}

test -n "${CONFIGFILE}"	|| usage "No default config file and none supplied"
test -n "${FILELIST}"	|| usage "No default file list (file) and none supplied"
test -f "${CONFIGFILE}"	|| usage "Sorry the config file '${CONFIGFILE}' is not readable"
test -f "${FILELIST}"	|| usage "Sorry the file list file '${FILELIST}' is not readable "

/bin/rm -f ${BACKUP_HOME}/${ZIPFILE}

logit "Reading the configuration file  ${CONFIGFILE} ... "
.	${CONFIGFILE}
GENERIC="`cat ${FILELIST} | sed '/^#/d; /^$/d;'`"

#
# FILES holds list of all files to backup. Use GENERIC
# and EXTRA from config-file
#
FILES="${GENERIC} ${EXTRA}"

#
# Exclude files
#
ALL_EXCLUDE="${EXCLUDE}"


logit "List of files to back up:"
echo "------------------------------------------------------------------" | logit
echo ${FILES} | tr '
' ' ' | fmt  | logit
echo "------------------------------------------------------------------" | logit

#
# Things to do, before executing backup.
# Set it in the config file
#
logit "Executing pre_backup commands ... "
pre_backup 

logit "preparing for OS backup ... "
logit "Keeping archives in '${BACKUP_HOME}'"

logit "backup archive is ${ZIPFILE}"
logit "Removing leading / from filenames ... "
cd /
${GTAR} -cpz --exclude "${ALL_EXCLUDE}" -f ${BACKUP_HOME}/${ZIPFILE} ${FILES} 2>/tmp/.tar_errors
EXIT_STATUS=$?
wait
logit "exit status from $GTAR is $EXIT_STATUS "

case $EXIT_STATUS in
	0)	:
	;;
	*)	ERRORS=$EXIT_STATUS
		logit "Errors from $TAR below:"
		cat /tmp/.tar_errors | logit
	;;
esac

/bin/rm -f /tmp/.tar_errors

sync; sync; sync

#
# Things to do after backup. Set it also in the config file
#

logit "Executing post_backup commands ... "
post_backup

# Allways delete the tar file
du -k ${BACKUP_HOME}/${ZIPFILE} | awk '{ print "removing temporary file saving " $1 " Kb ..."}' | logit

#
# If backup failled (EXIT != 0) stop here and send a mail
#
case ${ERRORS} in
	0)	logit "No errors found, removing oldest archives ... "

		# Add new archive name to the button of the list
		echo ${ZIPFILE}	>> ${ARCHIVE_LIST}

		# Keep $BACKLOG archives
		BACKLOG=${BACKLOG:=10}

		logit "Removing all but the last ${BACKLOG} archives ... "

		while :;
		do
			LINES=`wc -l < ${ARCHIVE_LIST} | tr -d ' '`

			if [ ${LINES} -gt ${BACKLOG} ]; then
				#DELE=`sed "s/.* //g; q" ${ARCHIVE_LIST}`
				DELE=`head -1 ${ARCHIVE_LIST}`
				logit "removing old archive '${BACKUP_HOME}/${DELE}'"
				/bin/rm -f ${BACKUP_HOME}/${DELE}
				grep -v "${DELE}" ${ARCHIVE_LIST} > ${ARCHIVE_LIST}.tmp
				/bin/mv ${ARCHIVE_LIST}.tmp ${ARCHIVE_LIST}
			else
				break
			fi
		done

		logit "Archive house keeping done"

		#
		# Set mode for backup
		#
		chmod 444		${BACKUP_HOME}/$ZIPFILE

		logger -p mail.crit "backup ok"
		echo "$NOW:ok" > "${STATUS_FILE}"

		logit "backup done"
		exit 0
	;;
	*)	
	logit "backup failed, old archives not deleted"
	echo "$NOW:failed" > "${STATUS_FILE}"
	logger -p mail.crit "The backup of ${HOSTNAME}.${DOMAINNAME} failed"
	cat ${MY_LOGFILE}   | logger -p mail.crit 
	${SLOG} backup failed
	;;
esac

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
#++
# NAME
#	daily_backup.sh 1
# SUMMARY
#	Simple \fCtar(1)\fR basd backup to the local filesystem
# PACKAGE
#	UNIbackup
# SYNOPSIS
#	daily_backup.sh [-v] [-c \fIconfigfile\fR] [-f \fIfilelist\fR]
# DESCRIPTION
#	\fCdaily_backup.sh(1)\fR preserves a \fCtar(1)\fR archive of configuration
#	files the same way \fCbackup_util\fR saves a copy on a Check Point SPLAT
#	firewall. The script is intented for internal use only, and runs on
#	most Unix systems. The script is intented to run periodic from \fCcron(1)\fR.
#
#	Old archives are pruned. Archives should be fetched using \fCrsync(1)\fR
#	from an internal backup host.
# OPTIONS
# .TP
#	\fC-v\fR
#	Verbose: print to stdout and a logfile.
# .TP
#	\fC-c\ \fCconfiguration file\fR
#	The configuration file describes what has to be done ahead of backup, and
#	after the backup. It may contain aditional files for backup and the 
#	retention period. Creating restore information may be wise; information on
#	what software was installed (and how) and the hardware information is
#	valuable information during a recovery.
#
#	A short example is printed below:
# .PP
# .nf
#	\fC
    1   #
    2   # THIS FILE IS BEEING SOURCED BY /bin/sh
    3   #
    4   # Additional files to be put on backup - this host only
    5   EXTRA="/root"
    6
    7   #
    8   # Keep this number of old backup files locally
    9   BACKLOG=10
   10
   11   #
   12   # On errors, send mail to RCPT
   13   RCPT="fwsupport@uni-c.dk"
   14
   15   # Things to do before backup, i.e stopping ace-database
   16   pre_backup() {
   17       echo "stopping aceserver ..."
   18       /usr/ace/aceserver stop 2>&1 >/dev/null
   19       echo "stopping sdconnect ..."
   20       /usr/ace/sdconnect stop 2>&1 >/dev/null
   21   }
   22
   23   # Things to do after backup, i.e starting ace-database
   24   post_backup() {
   25       echo "restarts aceserver ..." >&2
   26       /usr/ace/aceserver start  2>&1
   27       echo "restarts sdconnect ..." >&2
   28       /usr/ace/sdconnect start  2>&1
   31   }
# .fi
#	\fR
# .TP
#	\fC-f\ \fIfile list\fR
#	An \fCglob(1)\fR list of filenames for backup. Example below:
# .PP
# .nf
#	\fC
    1   #
    2   # mail.ssi.uni-c.dk
    3   #
    4   # Nameserver
    5   #
    6   ./var/namedb
    7   #
    8   # OS
    9   #
   10   ./etc/*
   11   ./usr/local/etc/*
# .fi
#	\fR
#	\fBNotice\fR that the script and both config files uses \fCbash(1)\fR
#	so it is possible to substitute the script's default values in the
#	config files.
# FILES
# .TP
#	\fC/usr/local/etc/daily_backup.cfg\fR
#	Default configuration file.
# .TP
#	\fC/usr/local/etc/daily_backup.cfg.example\fR
#	A more comprehensive configuration example.
# .TP
#	\fC/usr/local/etc/daily_backup.files\fR
#	Detault \fCglob(1)\fR file list.
# .TP
#	\fC/var/log/backup.log\fR
#	Temporary backup log. Will be sent to an smtp address in case of
#	errors, or else deleted after success full execution of the backup.
# COMMANDS
#	\fCsh(1)\fR, \fCsed(1)\fR og \fCawk(1)\fR.
# SEE ALSO
#	Documentation for UNIbackup.
# DIAGNOSTICS
#	Errors from the program will be sent as email.
# BUGS
#	Please fix any errors.
# VERSION
#	$Date: 2016/04/09 09:02:42 $
# .br
#	$Revision: 1.1 $
# .br
#	$Source: /usr/local/src/ubuntu/packages/backup-and-patch/RCS/daily_backup.sh,v $
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
