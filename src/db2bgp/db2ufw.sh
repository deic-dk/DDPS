#!/bin/bash
#
# Replaced with tables in OpenBSD firewall, do not use in production
#

TMPFILE=$( mktemp )
NETWORKS="$( cd /tmp; echo 'SELECT net FROM ddps.networks;'|sudo -u postgres psql -d flows --csv 2>$TMPFILE| sed '/net/d' )"

# Detect if running on vagrant and apply specific non-production rules
if [ -d /vagrant ]; then
	VAGRANT_NOT_ON_ROOT=$( df -l /vagrant/ /|awk '$NF ~/\// { print $NF }'|uniq|wc -l|tr -d ' ' )
else
	VAGRANT_NOT_ON_ROOT=0
fi
case $VAGRANT_NOT_ON_ROOT in
	2)	AVR="true"
		;;
	*)	AVR="false"
		;;
esac
echo "Apply specific vagrant rules: $AVR"

VANILLA_HEAD='
*filter
:ufw-user-input - [0:0]
:ufw-user-output - [0:0]
:ufw-user-forward - [0:0]
:ufw-before-logging-input - [0:0]
:ufw-before-logging-output - [0:0]
:ufw-before-logging-forward - [0:0]
:ufw-user-logging-input - [0:0]
:ufw-user-logging-output - [0:0]
:ufw-user-logging-forward - [0:0]
:ufw-after-logging-input - [0:0]
:ufw-after-logging-output - [0:0]
:ufw-after-logging-forward - [0:0]
:ufw-logging-deny - [0:0]
:ufw-logging-allow - [0:0]
:ufw-user-limit - [0:0]
:ufw-user-limit-accept - [0:0]
### RULES ###
'

VANILLA_TAIL='
### END RULES ###

### LOGGING ###
-A ufw-after-logging-input -j LOG --log-prefix "[UFW BLOCK] " -m limit --limit 3/min --limit-burst 10
-A ufw-after-logging-forward -j LOG --log-prefix "[UFW BLOCK] " -m limit --limit 3/min --limit-burst 10
-I ufw-logging-deny -m conntrack --ctstate INVALID -j RETURN -m limit --limit 3/min --limit-burst 10
-A ufw-logging-deny -j LOG --log-prefix "[UFW BLOCK] " -m limit --limit 3/min --limit-burst 10
-A ufw-logging-allow -j LOG --log-prefix "[UFW ALLOW] " -m limit --limit 3/min --limit-burst 10
### END LOGGING ###

### RATE LIMITING ###
-A ufw-user-limit -m limit --limit 3/minute -j LOG --log-prefix "[UFW LIMIT BLOCK] "
-A ufw-user-limit -j REJECT
-A ufw-user-limit-accept -j ACCEPT
### END RATE LIMITING ###
COMMIT
'

# sanity check
if [ -s $TMPFILE ]; then
	echo ERROR while extracting networks from database:
	echo "---"
	cat $TMPFILE
	echo "---"
	rm -f $TMPFILE
	exit 127
fi
if [ -z "${NETWORKS}" ]; then
	echo ERROR
	echo "no networks found: NETWORKS='${NETWORKS}'"
	exit 127
fi

# ifconfig -a|sed '/inet/!d; /inet6/d; /127.0.0/d; s/.*inet //; s/ netmask.*//'
# MY_IP=$( netstat -rn|awk '$1 == "0.0.0.0" { print $2 }' )
MY_IP=$( ifconfig -a|sed '/inet/!d;/inet6/d; /127.0.0.1/d; s/.*inet //; s/ .*$//' )
if [ -z "${MY_IP}" ]; then
	echo ERROR
	echo no networks
	exit 127
fi
rm -f $TMPFILE

echo "my primary ip address...: $MY_IP"
echo "networks in database....: ${NETWORKS}"
set -o noglob
INI_NETWORKS=$( sed '/ufw_ipv4_extra_addresses/!d; s/.*=//; s/[ \t]*//' /opt/db2bgp/etc/ddps.ini )
echo "networks in ini file....: ${INI_NETWORKS}"

# Working with files + reload is faster and more reliable than issuing a set of
# ufw commands

ufw --force enable

# preserve existing config
CONFIG=/etc/ufw/user.rules
PREV_CONFIG=${CONFIG}.prev
mv ${CONFIG} ${PREV_CONFIG}

# If we are on a new system with an nearly empty users.rules make a new one
touch ${CONFIG}
LINES=$( ufw status numbered|wc -l|tr -d ' ' )
case $LINES in 
	1)	echo ${VANILLA_HEAD} >  ${CONFIG}
		echo ${VANILLA_TAIL} >> ${CONFIG}
		echo new system initiated
		;;
	*)	:
		;;
esac

(
	echo "# made on $( date )"
	echo "# by $0"
	sed '/### RULES ###/q' ${PREV_CONFIG}

	echo "#"
	echo "# UFW rules for http,https to DDOS_app and API"
	echo "#"

	echo ""

	# default rules
	echo "### tuple ### allow tcp 22 0.0.0.0/0 any 0.0.0.0/0 in"
	echo ' -A ufw-user-input -p tcp --dport 22 -j ACCEPT'

	# Extra addresses from ufw_ipv4_extra_addresses in /opt/db2bgp/etc/ddps.ini 
	for NET in $INI_NETWORKS
	do
		echo "############ $NET "
		echo "### tuple ### allow tcp 80,443  ${MY_IP} any ${NET} in"
		echo "-A ufw-user-input -p tcp -m multiport --dports 80,443 -d ${MY_IP} -s ${NET} -j ACCEPT"
	done

	# Vagrant mounted on /vagrant - add rule for postgres access
	case $VAGRANT_NOT_ON_ROOT in
		2)	echo "### Vagrant rules"
			# MY_IP_ADDRS=$( ip a|awk '$1 == "inet" && $2 !~ /127.0.0.1/ { gsub(/\/.*$/, ""); print $2 }' ) 
			ip a|awk '$1 == "inet" && $2 !~ /127.0.0.1/ { print $2 }'|awk -F. '{ gsub(/.*\//, "", $4); print $1 "." $2 "." $3 ".0/" $4 }' | while read NET
			do
				for IPA in ${MY_IP}
				do
					echo "### tuple ### allow tcp 5432 ${IPA} any ${NET} in"
					echo " -A ufw-user-input -p tcp --dport 5432 -d ${IPA} -s  ${NET} -j ACCEPT"
					echo "### tuple ### allow tcp 80,443 ${IPA} any ${NET} in"
					echo "-A ufw-user-input -p tcp -m multiport --dports 80,443 -d ${IPA} -s ${NET} -j ACCEPT"
				done
			done
			;;
		*)	echo "# not applying vagrant rules"
	esac

	for NET in $NETWORKS
	do
		echo "# Networks: $NETWORKS"
		echo "### tuple ### allow tcp 80,443 ${MY_IP} any ${NET} in"
		echo "-A ufw-user-input -p tcp -m multiport --dports 80,443 -d ${MY_IP} -s ${NET} -j ACCEPT"
	done

	# tail:
	sed -n '/### END RULES ###/,$p'  ${PREV_CONFIG}
) > ${CONFIG}

ufw reload
ufw status >/dev/null
ERR=$?

case $ERR  in
	0) echo successfully applied rules
		;;
	*)
		echo "reload failed reversing to prev. rules ..."
		mv ${CONFIG} ${CONFIG}.bad
		cp ${PREV_CONFIG} ${CONFIG}
		ufw reload
		;;
esac

ufw status numbered verbose

exit 0

# /etc/default/ufw should be handled by ansible

