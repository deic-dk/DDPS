#
# stub for creating package in the future, Makefile is primarily for internal use
#
SHELL 			:= /bin/bash
.ONESHELL:

project				= db2bgp
# <project>_<major version>.<minor version>-<package revision>

prefix				= /opt/${project}

major_version=1
minor_version=0
package_revision=0

git_sha				= $(shell git rev-parse HEAD 2>/dev/null)
build_date			= $(shell date +"%Y-%m-%d %H:%M")

VERSION				= $(shell git tag 2>/dev/null | sort -n -t'-' -k2,2 | tail -1 )
PREV_VERSION		= $(shell if [ -f ${prefix}/.version ]; then cat ${prefix}/.version; else echo 'just older or not found'; fi )

DAEMON				= db2bgp.pl
GCOS				= "DDPS user for db2bgp"

db2ufw				= db2ufw.sh

# may/may not solve first run with no git tag
ifeq ($(strip $(VERSION)),)
VERSION = "1.0-1"
endif

ddpsusr = ddpsusr
ddpsgrp = ddpsusr

# TODO for some reason doesn't work
#ifeq (,$(wildcard $(prefix)/etc/ddps.ini))
#	shutdown	= $(shell sed '/^shutdown.*=,*/!d; s/.*=//; s/[[:space:]]//g'  $(prefix)/etc/ddps.ini )
#	reload		= $(shell sed '/^reload.*=,*/!d; s/.*=//; s/[[:space:]]//g' $(prefix)/etc/ddps.ini )
#else
#	shutdown	= $(shell sed '/^shutdown.*=,*/!d; s/.*=//; s/[[:space:]]//g'  ddps.ini )
#	reload		= $(shell sed '/^reload.*=,*/!d; s/.*=//; s/[[:space:]]//g' ddps.ini )
#endif

shutdown	= $(shell sed '/^shutdown.*=,*/!d; s/.*=//; s/[[:space:]]//g'  ddps.ini )
reload		= $(shell sed '/^reload.*=,*/!d; s/.*=//; s/[[:space:]]//g' ddps.ini )

# here be dragons:
#	seems like $NF, $1 etc is not acceptable in $(shell ... which exclude awk and reduces sed match capab.
# not sure, though
package_revision    = $(shell echo ${VERSION} | sed 's/^.*-//' )
major_version       = $(shell echo ${VERSION} | sed 's/\..*//')
minor_version       = $(shell echo ${VERSION} | sed 's/^.*\.//; s/-.*//')

package				= ${project}_${major_version}.${minor_version}-${package_revision}

ifneq "$(shell uname )" "Linux"
install:
	echo you are on the wrong OS ..
else
ifneq "$(shell whoami )" "root"
install:
	echo please run as root
else
ifeq "$(PREV_VERSION)" "$(VERSION)"
install:
	echo "same version detected $(PREV_VERSION) == $(VERSION)"
	echo "did you mean this: "
	echo "make install_db2bgp create_systemd_unit_file start_service"
else
install: install_db2bgp create_systemd_unit_file update_sql_functions start_service
	echo  $(VERSION) > ${prefix}/.version
endif
endif
endif

update_sql_functions:
	bash  update_database_functions.sh

install_db2bgp: db2bgp_prerequisite
	echo creating directories in ${prefix}/{bin,etc,lib,data,tmp}

	mkdir -p ${prefix}/{bin,etc,lib,data,tmp}/
	chown -R $(ddpsusr):$(ddpsgrp) ${prefix}
	chmod 1777 ${prefix}/tmp

	install -m 555 -o $(ddpsusr) -g $(ddpsgrp) $(DAEMON)    ${prefix}/bin
	install -m 555 -o $(ddpsusr) -g $(ddpsgrp)  ddpsctl apply_default_rules.sh reactivate_not_expired_rules.sh ${prefix}/bin
	install -m 444 -o $(ddpsusr) -g $(ddpsgrp) sqlstr.pm    ${prefix}/lib/sqlstr.pm

	install -m 555 -o $(ddpsusr) -g $(ddpsgrp) $(db2ufw)    ${prefix}/bin

	# check if an upgrade then preserve ini file
	if [ -f ${prefix}/etc/ddps.init ]; then echo "preserving existing ddps.ini ..." \
		cp /opt/db2bgp/etc/ddps.ini /root ; \
	else \
		install -m 444 -o $(ddpsusr) -g $(ddpsgrp) ddps.ini     ${prefix}/etc/; \
	fi

db2bgp_prerequisite:
	#
	# Install software requistes
	apt-get -yq	install libdbi-perl libpq-dev libdbd-pg-perl	\
				libfile-flock-perl libnet-subnet-perl           	\
				libnet-netmask-perl libproc-daemon-perl         	\
				libnet-openssh-perl libdata-validate-ip-perl		\
				libtext-lorem-perl >/dev/null 2>&1
	echo "added software prerequisite"
	#
	# Add user who will run the service
	adduser --home /home/$(ddpsusr)									\
			--gecos ""												\
			--disabled-password										\
			--shell /bin/bash										\
			--disabled-login 										\
			--quiet \
			$(ddpsusr) &>/dev/null || true
	$(MAKE) /home/$(ddpsusr)/.ssh/config
	echo "added user $(ddpsusr)"
	#
	# initial setup ssh for the user, later controlled by ansible
	# This should be everything for ddpsctl etc to work
	test -d /home/$(ddpsusr)/.ssh/multiplex || mkdir -p /home/$(ddpsusr)/.ssh/multiplex
	chmod 0700 /home/$(ddpsusr)/.ssh
	test -s /home/$(ddpsusr)/.ssh/id_ed25519 || ssh-keygen -t ED25519 -q -N "" -f /home/$(ddpsusr)/.ssh/id_ed25519 -C "$(ddpsusr)@`hostname -f `"
	test -f /home/$(ddpsusr)/.ssh/authorized_keys || cp /home/$(ddpsusr)/.ssh/id_ed25519.pub /home/$(ddpsusr)/.ssh/authorized_keys
	test -f /home/$(ddpsusr)/.ssh/authorized_keys || cat /root/.ssh/authorized_keys /root/.ssh/id_ed25519.pub >> /home/$(ddpsusr)/.ssh/authorized_key
	#
	# pollute known hosts
	ssh-keyscan `sed '/^hostlist.*=/!d; s/.*=//' ddps.ini` > /home/$(ddpsusr)/.ssh/known_hosts 2>/dev/null
	#
	# set owner and mode
	chown -R $(ddpsusr):$(ddpsgrp) /home/$(ddpsusr)
	find  /home/$(ddpsusr)/.ssh  -type d -print0 | xargs -0 chmod 700
	find  /home/$(ddpsusr)/.ssh  -type f -print0 | xargs -0 chmod 600

uninstall:
	systemctl --no-pager stop db2bgp

	kill -9 $(shell ps h -o pid -u $(ddpsusr) 2>/dev/null ) &>/dev/null || true
	userdel -r $(ddpsusr) || true
	/bin/rm -fr $(prefix) || true

/lib/systemd/system/db2bgp.service: create_systemd_unit_file
create_systemd_unit_file:
	sed "	\
		s/_ddpsusr_/${ddpsusr}/g;	\
		s/_ddpsgrp_/${ddpsgrp}/g;	\
		s%_shutdown_%${shutdown}%g;	\
		s%_reload_%${reload}%g;		\
		" < db2bgp.service.tmpl >	/lib/systemd/system/db2bgp.service

		chmod 0644				/lib/systemd/system/db2bgp.service
		chown root:root			/lib/systemd/system/db2bgp.service
		systemctl daemon-reload
		systemctl enable db2bgp

start_service: /lib/systemd/system/db2bgp.service
	systemctl start db2bgp
	systemctl --no-pager status -l db2bgp
	/opt/db2bgp/bin/ddpsctl status

dbtest: tests/assert.sh
	cd tests && sudo bash test_db_functions_and_constraints.sh

tests/assert.sh:
	cd tests && wget https://raw.githubusercontent.com/torokmark/assert.sh/master/assert.sh
	# https://github.com/torokmark/assert.sh
	# wget https://raw.githubusercontent.com/lehmannro/assert.sh/master/assert.sh

ifndef VERBOSE
.SILENT:
endif

#TODO:
#pkg:
# apt install ./ddps*.deb -- for both GUI and db2bgp

# This an ugly hack full of dragons
/home/$(ddpsusr)/.ssh/config = "\
\#\n\
\# ssh config for DDPS\n\
\#\n\
Host *\n\
\tKeepAlive yes\n\
\tConnectTimeout 10\n\
\tServerAliveInterval 60\n\
\tServerAliveCountMax 10\n\
\tControlPath ~/.ssh/multiplex/%r@%h:%p\n\
\tControlMaster auto\n\
\tControlPersist 10m\n\
\tUserKnownHostsFile /dev/null\n\
\tStrictHostKeyChecking no\n\
\tBatchMode yes\n"

/home/$(ddpsusr)/.ssh/config: Makefile
	/bin/echo -e $($(@)) | sed -e 's/^[ ]//' >$(@)

.SUFFIXES:

