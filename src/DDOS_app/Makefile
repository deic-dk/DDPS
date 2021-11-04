#
# stub for creating package in the future, Makefile is primarily for internal use
#
# NTH

project				= ddos
# <project>_<major version>.<minor version>-<package revision>

postgres_pw 		= 1qazxsw2

prefix				= /opt/ddps_ui

major_version=1
minor_version=0
package_revision=0

git_sha				= $(shell git rev-parse HEAD 2>/dev/null)
build_date			= $(shell date +"%Y-%m-%d %H:%M")

VERSION				= $(shell git tag 2>/dev/null | sort -n -t'-' -k2,2 | tail -1 )

PREV_VERSION		= $(shell if [ -f ${prefix}/.version ]; then cat ${prefix}/.version; else echo 'just older or not found'; fi )

# may/may not solve first run with no git tag
ifeq ($(strip $(VERSION)),)
VERSION = "1.0-1"
endif

# here be dragons:
#	seems like $NF, $1 etc is not acceptable in $(shell ... which exclude awk and reduces sed match capab.
# not sure, though
package_revision    = $(shell echo ${VERSION} | sed 's/^.*-//' )
major_version       = $(shell echo ${VERSION} | sed 's/\..*//')
minor_version       = $(shell echo ${VERSION} | sed 's/^.*\.//; s/-.*//')

package				= ${project}_${major_version}.${minor_version}-${package_revision}

# do minor changes to
footer_file			= "$(prefix)/web/smarty/templates/footer.tpl"

ifneq "$(shell uname )" "Linux"
install:
	@echo you are on the wrong OS ..
else
ifneq "$(shell whoami )" "root"
install:
	@echo please run as root
else
ifeq "$(PREV_VERSION)" "$(VERSION)"
install:
else
install: install_smarty install_web_ui fixfooter
	@if test `whoami` != "root"; then echo "please run as root"; exit 127; fi
	@echo Installing version $(VERSION)
	@echo Old version....... $(PREV_VERSION)
	@echo  $(VERSION) > ${prefix}/.version
	@systemctl --no-pager restart nginx.service
	@systemctl --no-pager status nginx.service
endif
endif
endif

reinstall: install_smarty install_web_ui fixfooter

# Only install if file doesn't exists
dbConfig.php		= $(prefix)/web/www/conf/dbConfig.php
install_web_ui:   $(dbConfig.php)
	@rsync --delete --archive --compress --hard-links --exclude=.git --exclude=.DS_Store ddos/ $(prefix)
	@find $(prefix) -type d -print0 | xargs -0 chmod 555
	@find $(prefix) -type f -print0 | xargs -0 chmod 444
	@chown -R root:root  $(prefix)
	# fix smarty, it requires bloody write access
	test -d $(prefix)/web/smarty/templates_c || mkdir $(prefix)/web/smarty/templates_c
	test -d $(prefix)/web/smarty/cache || mkdir $(prefix)/web/smarty/cache
	chmod 755 $(prefix)/web/smarty/templates_c
	chown -R www-data:www-data  $(prefix)//web/smarty/templates_c \
								$(prefix)//web/smarty/cache

SMARTY_README		=  "/usr/local/lib/php/smarty/README"
install_smarty: $(SMARTY_README)

$(SMARTY_README):
	@tar xfpz smarty.tgz -C /usr/local/lib/php/
	@chmod 555 $(shell find /usr/local/lib/php/smarty -type d )
	@chmod 444 $(shell find /usr/local/lib/php/smarty -type f )

$(dbConfig.php):
	@rsync --delete --archive --compress --hard-links --exclude=.git --exclude=.DS_Store ddos/ $(prefix)

fixfooter:
	@if [ ! -f $(footer_file).org ]; then cp $(footer_file) $(footer_file).org; fi
	@sed 's%<div id="support" class="content right" style="padding-top: 23px">DDPS Support: <a href="mailto:ddps-info@deic.dk">ddps-info@deic.dk</a> </div>%<div id="support" class="content right" style="padding-top: 10px">Version: _VERSION_</br>DDPS Support: <a href="mailto:ddps-info@deic.dk">ddps-info@deic.dk</a> </div>%' $(footer_file).org > $(footer_file)
	@sed -i "s/_VERSION_/${VERSION}/g" $(footer_file)

uninstall:
	@rm -fr $(prefix) /usr/local/lib/php/smarty

.SUFFIXES:
