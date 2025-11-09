# Frankie Operating Theatre — Master Makefile
# One command = One surgery step

# Default disk to flash Debian onto (override with: make flash DISK=/dev/sdb)
DISK ?= /dev/sda
# Backup destination (override with: make backup DEST=/mnt/hddroot/PI_BACKUP)
DEST ?= $(HOME)/Backups
# Restore archive (override with: make restore ARCHIVE=/path/to/pi_home_backup_XXXX.tgz)
ARCHIVE ?=

.PHONY: all workstation dev backup restore flash ssh motd help

all: help

help:
	@echo ""
	@echo "======= FRANKIE OPERATING THEATRE ======="
	@echo "make workstation        → Install full desktop, dev tools, theming"
	@echo "make dev                → Install recovery & build utilities"
	@echo "make ssh                → Configure SSH key + GitHub identity"
	@echo "make backup             → Backup /home/pi → $(DEST)"
	@echo "make restore ARCHIVE=…  → Restore /home/pi from backup"
	@echo "make flash DISK=/dev/sdX→ Flash Debian image to disk (WARNING!)"
	@echo "make motd               → Install the M*A*S*H MOTD"
	@echo ""

workstation:
	@echo "=== Running workstation setup ==="
	@chmod +x pi-workstation.sh
	@./pi-workstation.sh

dev:
	@echo "=== Installing dev + recovery tools ==="
	@chmod +x pi-dev-recovery.sh
	@./pi-dev-recovery.sh

ssh:
	@echo "=== GitHub SSH setup ==="
	@chmod +x setup-ssh-github.sh
	@./setup-ssh-github.sh

backup:
	@echo "=== Backing up /home/pi to $(DEST) ==="
	@chmod +x pi-backup.sh
	@./pi-backup.sh $(DEST)

restore:
	@if [ -z "$(ARCHIVE)" ]; then \
		echo "Missing ARCHIVE. Usage: make restore ARCHIVE=/path/file.tgz"; \
		exit 1; \
	fi
	@echo "=== Restoring $(ARCHIVE) ==="
	@chmod +x pi-restore.sh
	@./pi-restore.sh $(ARCHIVE)

flash:
	@echo "=== FLASHING DEBIAN TO $(DISK) ==="
	@echo "WARNING: THIS WILL ERASE $(DISK)"
	@echo "Type YES to continue:"
	@read OK; if [ "$$OK" != "YES" ]; then echo "Abort."; exit 1; fi
	@chmod +x flash-debian-to-disk.sh
	@./flash-debian-to-disk.sh "" $(DISK)

motd:
	@echo "=== Installing M*A*S*H MOTD ==="
	@chmod +x mash-motd.sh
	@./mash-motd.sh

.PHONY: pretty-matrix
pretty-matrix:
\tbash scripts/pretty-matrix.sh
