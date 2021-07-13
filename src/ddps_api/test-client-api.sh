#! /bin/bash
#
# test view log run in other window
# tail -f /var/log/syslog|grep ddps_api
# tac /var/log/syslog|sed  '/ddps_api/!d; /program starting/q'|tac

# vars

# Notes to anyone who will use this in vagrant:
# - api_ddps_deic_dkname(s) should be in /etc/api_ddps_deic_dks:
#	192.168.33.12	api.ddps.deic.dk
#	192.168.33.12	ww1.ddps.deic.dk
# Note that http headers are case insensitive, while methods like POST are not
# see ${proto}://www.w3.org/Protocols/rfc2616/rfc2616-sec5.html

# Fix /etc/hosts in vagrant
FOUNDIP=$( ifconfig |sed '/192.168.33.12/!d; s/^.*inet //; s/ net.*$//; s/ *//g' )
case $FOUNDIP in
	192.168.33.12)
		(
			cat /etc/hosts|grep -v 192.168.33.12
			cat << EOF
192.168.33.12	api.ddps.deic.dk
192.168.33.12	www.ddps.deic.dk
EOF
		) > /tmp/hosts
		mv /tmp/hosts /etc/hosts
		chmod 0644 /etc/hosts
		chown root:root /etc/hosts
		;;
	*)	:
		;;
esac

# port=443
# proto=https
port=80
proto=http
api_ddps_deic_dk="api.ddps.deic.dk"

USERNAME="administrator"
PASSWORD="1qazxsw2"

ROUTER_SIGNIN="${proto}://${api_ddps_deic_dk}:${port}/signin"
ROUTER_ADDRULE="${proto}://${api_ddps_deic_dk}:${port}/addrule"
ROUTER_REFRESH="${proto}://${api_ddps_deic_dk}:${port}/refresh"

LINES=$(tput lines)
COLUMNS=$(tput cols)
dastline=$( seq -s- $COLUMNS|tr -d '[:digit:]' )

function test_invalid_credentials()
{
	UNKNOWNUSERNAME="notfound"
	WRONGPASSWORD="invalid"

	# check invalid login
	TOKEN=$( curl -c - -s -k -X POST								\
		-H 'Accept: application/json'								\
		-H 'Content-Type: application/json'							\
		--data "{\"username\":\"${UNKNOWNUSERNAME}\",\"password\":\"${WRONGPASSWORD}\"}" "${ROUTER_SIGNIN}" |
		sed '/token/!d; s/.*token//g; s/[[:space:]]*//g'
	)

	assert_empty $TOKEN
	case $? in
		0)	log_success "Testing INVALID credentials SUCCESS: TOKEN = '$( echo ${TOKEN:0:41})'"
			;;
		*) log_failure "Testing INVALID credentials FAILED: TOKEN = '$( echo ${TOKEN:0:41})'"
			;;
	esac
}

function test_valid_credentials()
{
	# Get a valid JWT token
	TOKEN=$( curl -c - -s -k -X POST								\
		-H 'Accept: application/json'								\
		-H 'Content-Type: application/json'							\
		--data "{\"username\":\"${USERNAME}\",\"password\":\"${PASSWORD}\"}" "${ROUTER_SIGNIN}" |
		sed '/token/!d; s/.*token//g; s/[[:space:]]*//g'
	)

	assert_not_empty $TOKEN
	case $? in
		0)	log_success "Testing VALID credentials SUCCESS: TOKEN = '$( echo ${TOKEN:0:41})'"
			;;
		*) log_failure "Testing VALID credentials FAILED: TOKEN = '$( echo ${TOKEN:0:41})'"
	curl -c - -k -X POST								\
		-H 'Accept: application/json'								\
		-H 'Content-Type: application/json'							\
		--data "{\"username\":\"${USERNAME}\",\"password\":\"${PASSWORD}\"}" "${ROUTER_SIGNIN}"


			exit 127
			;;
	esac
}

function test_add_rule()
{
	case $1 in
		fail)	PATTERN="*fail*"
			;;
		success)	PATTERN="*success*"
			;;
			*)	echo "use fail|success"; exit 0
			;;
	esac

	find testrules.d -type f -name "${PATTERN}" | while read JSONFILE
	do
		ADD_STATUS=$( curl -s -k -c /dev/null -H 'Accept: application/json' -H 'Content-Type: application/json'  \
			--header "Cookie: token=${TOKEN}" -d @${JSONFILE} -X POST "${ROUTER_ADDRULE}" )

		case $1 in
				fail)
					case $ADD_STATUS in
						"rule accepted") log_failure "Testing add invalid rule FAILED: $ADD_STATUS"
							;;
						*) 		log_success "Testing add invalid rule SUCCESS: $ADD_STATUS"
							;;
					esac
					;;
				success)	
					case $ADD_STATUS in
						"rule accepted") log_success "Testing add valid rule SUCCESS: $ADD_STATUS"
							;;
						*) 		log_failure "Testing add valid rule FAILED: $ADD_STATUS"
							;;
					esac
					;;
				*)	echo bummer
			esac
	done
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

	.  assert.sh

	echo $dastline
	echo "$0 starting, TOKEN truncated to the first 42 chars in output ... "

	case $1 in 
		""|all)
			test_invalid_credentials
			test_valid_credentials
			test_add_rule fail
			test_add_rule success
			;;
		fail)
			test_invalid_credentials
			test_valid_credentials
			test_add_rule fail
			;;
		success)
			test_valid_credentials
			test_add_rule success
			;;
	esac


}

main $*

exit 0

