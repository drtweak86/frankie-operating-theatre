# Frankie Operating Theatre — Master Makefile
# One command = One surgery step

# Paths
SCRIPT_DIR := scripts

# Defaults (override like: make flash DISK=/dev/sdb)
DISK    ?= /dev/sda
DEST    ?= $(HOME)/Backups
ARCHIVE ?=

.PHONY: all help workstation dev ssh backup restore flash motd \
        pretty-matrix pretty-ui pretty-dashboard

all: help

help:
	@echo ""
	@echo "======= FRANKIE OPERATING THEATRE ======="
	@echo "make workstation            → Install full desktop, dev tools, theming"
	@echo "make dev                    → Install recovery & build utilities"
	@echo "make ssh                    → Configure SSH key + GitHub identity"
	@echo "make backup                 → Backup /home/pi → $(DEST)"
	@echo "make restore ARCHIVE=…      → Restore /home/pi from backup"
	@echo "make flash DISK=/dev/sdX    → Flash Debian image to disk (WARNING!)"
	@echo "make motd                   → Install the M*A*S*H MOTD"
	@echo "make pretty-matrix          → Matrix fastfetch + prompt"
	@echo "make pretty-ui              → XFCE polish (icons, compositor, dock)"
	@echo "make pretty-dashboard       → Lean fastfetch dashboard"
	@echo ""

workstation:
	@echo "=== Running workstation setup ==="
	@chmod +x $(SCRIPT_DIR)/pi-workstation.sh
	@bash $(SCRIPT_DIR)/pi-workstation.sh

dev:
	@echo "=== Installing dev + recovery tools ==="
	@chmod +x $(SCRIPT_DIR)/pi-dev-recovery.sh
	@bash $(SCRIPT_DIR)/pi-dev-recovery.sh

ssh:
	@echo "=== GitHub SSH setup ==="
	@chmod +x $(SCRIPT_DIR)/setup-ssh-github.sh
	@bash $(SCRIPT_DIR)/setup-ssh-github.sh

backup:
	@echo "=== Backing up /home/pi to $(DEST) ==="
	@chmod +x $(SCRIPT_DIR)/pi-backup.sh
	@bash $(SCRIPT_DIR)/pi-backup.sh $(DEST)

restore:
	@if [ -z "$(ARCHIVE)" ]; then \
		echo "Missing ARCHIVE. Usage: make restore ARCHIVE=/path/file.tgz"; \
		exit 1; \
	fi
	@echo "=== Restoring $(ARCHIVE) ==="
	@chmod +x $(SCRIPT_DIR)/pi-restore.sh
	@bash $(SCRIPT_DIR)/pi-restore.sh $(ARCHIVE)

flash:
	@echo "=== FLASHING DEBIAN TO $(DISK) ==="
	@echo "WARNING: THIS WILL ERASE $(DISK)"
	@echo "Type YES to continue:"
	@read OK; if [ "$$OK" != "YES" ]; then echo "Abort."; exit 1; fi
	@chmod +x $(SCRIPT_DIR)/flash-debian-to-disk.sh
	@bash $(SCRIPT_DIR)/flash-debian-to-disk.sh "" $(DISK)

motd:
	@echo "=== Installing M*A*S*H MOTD ==="
	@chmod +x $(SCRIPT_DIR)/mash-motd.sh
	@bash $(SCRIPT_DIR)/mash-motd.sh

pretty-matrix:
	@echo "=== Applying Matrix look ==="
	@chmod +x $(SCRIPT_DIR)/pretty-matrix.sh
	@bash $(SCRIPT_DIR)/pretty-matrix.sh

pretty-ui:
	@echo "=== Applying XFCE polish ==="
	@chmod +x $(SCRIPT_DIR)/pretty-ui.sh
	@bash $(SCRIPT_DIR)/pretty-ui.sh

pretty-dashboard:
	@echo "=== Applying lean dashboard ==="
	@chmod +x $(SCRIPT_DIR)/pretty-dashboard.sh
	@bash $(SCRIPT_DIR)/pretty-dashboard.sh
