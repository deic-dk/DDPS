# The vagrant image does not contain a go installation. To install go. see
# install_golang_on_ubuntu_2004.sh
# It may also be useful to apt install -y jq

target = ddpsapid
ddpsusr = ddpsusr
ddpsgrp = ddpsusr
reload = /opt/db2bgp/tmp/.reload

gofiles = $(wildcard *.go)

export PATH := /usr/local/go/bin:$(PATH)

all: 
ifeq (, $(shell which go))
	$(error "No go in PATH, install latest with install_golang_on_ubuntu_2004.sh (check LATEST= first, then logout/in to update environment))
endif
	$(MAKE) $(target)
	$(MAKE) stop
	$(MAKE) install
	$(MAKE) start_service
	bash test-client-api.sh

install: /lib/systemd/system/ddps_api.service #$(target)
	service ddps_api stop
	cp $(target) /opt/db2bgp/bin/
	chmod 555 /opt/db2bgp/bin/$(target)
	# cp ddps.ini /opt/db2bgp/etc/ddps.ini
	service ddps_api start

/lib/systemd/system/ddps_api.service: ddps_api.service.tmpl
	sed "	\
		s/_ddpsusr_/${ddpsusr}/g;	\
		s/_ddpsgrp_/${ddpsgrp}/g;	\
		s/_reload_/${ddpsgrp}/g;	\
		" < ddps_api.service.tmpl >	/lib/systemd/system/ddps_api.service

		chmod 0644				/lib/systemd/system/ddps_api.service
		chown root:root			/lib/systemd/system/ddps_api.service
		systemctl daemon-reload
		systemctl enable ddps_api

start_service: /lib/systemd/system/ddps_api.service /opt/db2bgp/bin/$(target)
	systemctl start ddps_api
	systemctl --no-pager status -l ddps_api

stop:
	echo stopping $(target) ...
	killall ${target} ||true

start:
	echo starting $(target) ...
	./${target}  -d &
	sleep 4
	echo $(target) started

$(target): $(gofiles)
	# automatic
	# env GOOS=$(shell uname|tr 'A-Z' 'a-z' ) GOARCH=amd64 go build -o $(target) $(gofiles) && echo compiled $(target)
	# fixed darwin|linux
	env GOOS=linux GOARCH=amd64 go build -o $(target) $(gofiles) && echo compiled $(target)

# go get github.com/lib/pq
# go get gopkg.in/go-playground/validator.v9
# go get github.com/dgrijalva/jwt-go

version.go: Makefile
	bash make-version.sh g

backup:
	bash bu.sh

# .IGNORE:

ifndef VERBOSE
.SILENT:
endif

.SUFFIXES:

.PHONY:

