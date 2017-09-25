all:
	@echo "Run 'make install' as root to install this script."

SHELL:=/bin/bash
BASE=tun2socks-manager
BIN_DIR:=/usr/local/bin
BIN:=$(BASE)

.PHONY: install reconfigure uninstall purge

install:
	[ $$(whoami) == "root" ]
	cp $(BIN) $(BIN_DIR)/$(BIN)
	mkdir -p /etc/NetworkManager/dispatcher.d
	cp 02tun2socks /etc/NetworkManager/dispatcher.d/
	mkdir -p /etc/$(BASE).d
	cp -r sample /etc/$(BASE).d/
	cp $(BASE).conf.sample /etc/
	[ -e /etc/$(BASE).conf ] || mv /etc/$(BASE).conf.sample /etc/$(BASE).conf
	$(BIN_DIR)/$(BIN) install

reconfigure:
	$(BIN_DIR)/$(BIN) uninstall
	$(BIN_DIR)/$(BIN) install

uninstall:
	[ $$(whoami) == "root" ]
	[ -x $(BIN_DIR)/$(BIN) ] && $(BIN_DIR)/$(BIN) uninstall || true
	rm -f $(BIN_DIR)/$(BIN)
	rm -f /etc/NetworkManager/dispatcher.d/02tun2socks

purge: uninstall
	[ $$(whoami) == "root" ]
	rm -rf /etc/$(BASE).d
	rm -f /etc/$(BASE).conf.sample /etc/$(BASE).conf

