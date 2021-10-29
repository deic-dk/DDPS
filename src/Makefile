# NTH
install:
ifeq (0, $(shell grep -q vagrant /etc/passwd; echo $$?))
	touch ~/.ssh/known_hosts
	ssh-keygen -R localhost
	ssh-keygen -R 127.0.0.1
	ssh-keygen -R ww1
	ssh-keygen -R 192.168.33.12
	ssh-keyscan -H 127.0.0.1,localhost >> ~/.ssh/known_hosts
	ssh-keyscan -H localhost >> ~/.ssh/known_hosts
	ssh-keyscan -H 127.0.0.1 >> ~/.ssh/known_hosts
	ssh-keyscan -H ww1 >> ~/.ssh/known_hosts
	ssh-keyscan -H 192.168.33.12 >> ~/.ssh/known_hosts
endif

ifeq (, $(shell which go))
	bash install_golang_on_ubuntu_2004.sh
endif
	@cd DDOS_app && make install
	@cd db2bgp && make install
	@cd ddps_api && make install
	@test -d /opt/ddps_ui/web/images || mkdir /opt/ddps_ui/web/images
	@test -f /opt/ddps_ui/web/images/favicon.png || cp images/favicon.png /opt/ddps_ui/web/images/favicon.ico

uninstall:
	@cd DDOS_app && make uinstall
	@cd db2bgp && make uinstall
	@cd ddps_api && make install
