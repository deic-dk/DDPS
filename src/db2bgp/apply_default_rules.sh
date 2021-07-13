#! /usr/bin/env bash

function usage() {

	case $# in
		0)
			cat << EOF
usage: $0
Apply at set of default rules based on data in
https://www.akamai.com/de/de/multimedia/documents/state-of-the-internet/q2-2017-state-of-the-internet-security-report.pdf"
page 8 figure 2-1: DDoS Attack Vector Frequency

EOF
			exit
		;;
		*)
			echo $*
			exit
		;;
	esac
}

function check_var()
{
	var=$1
	shift
	value=$*
	if [ -z "${value}" ]; then
		logit "program error: env var $var empty";
		exit
	else
		logit "ok: $var=$value"
	fi
}


function logit() {
	LOGIT_NOW="`date '+%H:%M:%S (%d/%m)'`"
	STRING="$*"

	VERBOSE="TRUE"
    log2syslog="logger -t world -p mail.crit "

	if [ -n "${STRING}" ]; then
		$log2syslog "${STRING}"
		if [ "${VERBOSE}" = "TRUE" ]; then
			$echo "${LOGIT_NOW} ${STRING}"
		fi
	else
		while read LINE
		do
			if [ -n "${LINE}" ]; then
				$log2syslog "${line}"
				if [ "${VERBOSE}" = "TRUE" ]; then
					$echo "${LOGIT_NOW} ${LINE}"
				fi
			fi
		done
	fi
}

function main()
{
	# check on how to suppress newline (found in an Oracle installation script ca 1992)
	echo="/bin/echo"
	case ${N}$C in
		"") if $echo "\c" | grep c >/dev/null 2>&1; then
			N='-n'
		else
			C='\c'
		fi ;;
	esac

	VALID_YEARS=100
	case $1 in
		"")	:
			;;
		*)	VALID_YEARS=$1
			;;
	esac

	db2bgp=/opt/db2bgp/bin/db2bgp.pl
	if [ -x ${db2bgp} ]; then
		ADD="${db2bgp} -a "
	else
		echo "error: ${db2bgp} not found, bye"
		exit
	fi

	# Read some configuration parameters and check all read parameters ok
	INI=/opt/db2bgp/etc/ddps.ini
	if [ ! -f ${INI} ]; then
		usage ini file ${INI} not found, bye
	else
		logit "Reading parameters from ${INI} ... "
	fi
	export dbuser=$( sed '/^dbuser/!d; s/^.*=//; s/[[:blank:]]//g' ${INI} )
	check_var dbuser $dbuser
	export dbpassword=$( sed '/^dbpassword/!d; s/^.*=//; s/[[:blank:]]//g' ${INI} )
	check_var dbpassword $dbpassword
	export dbname=$( sed '/^dbname/!d; s/^.*=//; s/[[:blank:]]//g' ${INI} )
	check_var dbname $dbname

	# read more configuration parameters
	export ournetworks=$( echo "SELECT net from ddps.networks; "|PGPASSWORD="${dbpassword}" psql -t -F' ' -h 127.0.0.1 -A -U ${dbuser} -v ON_ERROR_STOP=1 -w -d ${dbname} )
	check_var ournetworks $ournetworks

	export createdon=$( echo "SELECT current_date"|PGPASSWORD="${dbpassword}" psql -t -F' ' -h 127.0.0.1 -A -U ${dbuser} -v ON_ERROR_STOP=1 -w -d ${dbname} )
	check_var createdon $createdon
	export validfrom=$( echo "SELECT current_date"|PGPASSWORD="${dbpassword}" psql -t -F' ' -h 127.0.0.1 -A -U ${dbuser} -v ON_ERROR_STOP=1 -w -d ${dbname} )
	check_var validfrom $validfrom
	export customeradminid=$( echo "select adminid from ddps.admins where adminroleid = 1; "|PGPASSWORD="${dbpassword}" psql -t -F' ' -h 127.0.0.1 -A -U ${dbuser} -v ON_ERROR_STOP=1 -w -d ${dbname} )
	check_var customeradminid $customeradminid
	export createdon=$( echo "SELECT now() "|PGPASSWORD="${dbpassword}" psql -t -F' ' -h 127.0.0.1 -A -U ${dbuser} -v ON_ERROR_STOP=1 -w -d ${dbname} )
	check_var createdon $createdon

	# Set default expire / valid to 100 years in the future
	validto="52560000"	# 60*24*365*100 minutes
	check_var validto $validto

	for dst in $ournetworks
	do
  		FRAG_TYPE="dont-fragment is-fragment first-fragment last-fragment"
  		${ADD} "direction [in] destinationprefix [$dst] expireafter [${validto}] fragmentencoding [${FRAG_TYPE}] action [discard] description [block UDP ${FRAG_TYPE} type ]" &&
			logit "block all fragments"
		${ADD} "direction [in] destinationprefix [$dst] expireafter [${validto}] protocol [=17] sourceport [=123] length [=468] action [discard] description [Discard NTP amplification]" &&
			logit "Discard NTP amplification"
		${ADD} "direction [in] destinationprefix [$dst] expireafter [${validto}] protocol [=17] sourceport [=53] length [=512] action [discard] description [Discard DNS amplification]" &&
			logit "Discard DNS amplification"
		${ADD} "direction [in] destinationprefix [$dst] expireafter [${validto}] protocol [=6 =17] sourceport [=19] action [discard] description [Discard TCP and UDP chargen]" &&
			logit "Discard TCP and UDP chargen"
		${ADD} "direction [in] destinationprefix [$dst] expireafter [${validto}] protocol [=6 =17] sourceport [=17] action [discard] description [Discard TCP and UDP QOTD]" &&
			logit "Discard TCP and UDP QOTD"
		${ADD} "direction [in] destinationprefix [$dst] expireafter [${validto}] protocol [=47] action [discard] description [Discard IP protocol 47, GRE]" &&
			logit "Discard IP protocol 47, GRE"
		${ADD} "direction [in] destinationprefix [$dst] expireafter [${validto}] protocol [=17] sourceport [=1900] action [rate-limit 9600] description [ratelimit SSDP]" &&
			logit "ratelimit SSDP"
		${ADD} "direction [in] destinationprefix [$dst] expireafter [${validto}] protocol [=17] sourceport [=161 =162] action [rate-limit 9600] description [ratelimit SNMP]" &&
			logit "ratelimit SNMP"
		${ADD} "direction [in] destinationprefix [$dst] expireafter [${validto}] protocol [=17] sourceport [=11211] action [discard] description [Discard memcached amplification]" &&
			logit "Discard memcached amplification"
	done

	cat <<-EOF
Please check applied rules from the GUI or with
	$db2bgp -p
BGP status with
	gobgp neighbor
And announcements with
	gobgp global rib -a ipv4-flowspec
EOF
	logger -p mail.crit "`whoami` on `hostname` applied default rules"


	exit 0
}

function clean_f()
{
	echo "trapped; but some rules may already have been applied"
	exit 127
}

################################################################################
# Main
################################################################################

trap clean_f 1 2 3 13 15
main $*

exit 0

# Based on idea from http://nabcop.org/index.php/DDoS-DoS-attack-BCOP, conversation with Nordunet and
# https://www.akamai.com/us/en/multimedia/documents/state-of-the-internet/q4-2016-state-of-the-internet-security-report.pdf

# Modified BSD License
# ====================
# 
# Copyright © 2019, Niels Thomas Haugård
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright
#	 notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#	 notice, this list of conditions and the following disclaimer in the
#	 documentation and/or other materials provided with the distribution.
# 3. Neither the name of the  haugaard.net inc nor the
#	 names of its contributors may be used to endorse or promote products
#	 derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS” AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL Niels Thomas Haugård BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
