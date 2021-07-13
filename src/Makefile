# NTH
install:
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
