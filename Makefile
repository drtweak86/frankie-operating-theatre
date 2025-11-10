# Frankie Operating Theatre — Master Makefile
# One command = One surgery step

# -------- Variables (override at runtime) -------------------------------------
DISK        ?= /dev/sda                     # make flash DISK=/dev/sdX
DEST        ?= $(HOME)/Backups              # make backup DEST=/path
ARCHIVE     ?=                               # make restore ARCHIVE=...
REMOTE      ?= drive:                        # rclone remote if you use it

# Kernel build knobs (used by scripts/build-kernel.sh)
KERNEL_DIR  ?= $(HOME)/raspberrypi-linux
FW_DIR      ?= $(HOME)/rpi-firmware
OUT_DIR     ?= $(HOME)/kernel-out
DEFCONFIG   ?= bcm2711_defconfig
JOBS        ?= $(shell nproc)
MODULES_OUT ?=                               # e.g. $(OUT_DIR)/rootfs

SCRIPTS_DIR := scripts

# -------- Meta ----------------------------------------------------------------
.PHONY: all help \
        workstation dev ssh backup restore flash motd \
        pretty-matrix pretty-xfce matrix-theme noblank \
        kernel fetch-firmware fetch-kernel clean-tmp

all: help

help:
	@echo ""
	@echo "======= FRANKIE OPERATING THEATRE ======="
	@echo "Setup:"
	@echo "  make workstation           → Desktop + tools + niceties"
	@echo "  make dev                   → Recovery/build utilities"
	@echo "  make ssh                   → GitHub SSH + git config"
	@echo ""
	@echo "Backup / Restore:"
	@echo "  make backup DEST=…         → Backup /home/<user> → DEST"
	@echo "  make restore ARCHIVE=…     → Restore from tgz archive"
	@echo ""
	@echo "Bootable media:"
	@echo "  make flash DISK=/dev/sdX   → Flash Debian (DANGER: wipes disk)"
	@echo ""
	@echo "Look & Feel:"
	@echo "  make pretty-matrix         → Fastfetch + matrix CLI vibes"
	@echo "  make pretty-xfce           → XFCE matrix skin + wallpaper"
	@echo "  make matrix-theme          → Install Matrix GTK + icons"
	@echo "  make noblank               → Disable screen blank/DPMS"
	@echo ""
	@echo "Kernel workflow:"
	@echo "  make fetch-firmware        → Shallow/sparse rpi-firmware"
	@echo "  make fetch-kernel          → Shallow kernel clone (arm64)"
	@echo "  make kernel                → Build & stage kernel/DTBs/modules"
	@echo ""
	@echo "Utils:"
	@echo "  make motd                  → M*A*S*H welcome"
	@echo "  make clean-tmp             → Prune ./tmp and misc caches"
	@echo ""

# -------- Core scripts --------------------------------------------------------
workstation:
	@echo "=== Running workstation setup ==="
	@chmod +x $(SCRIPTS_DIR)/pi-workstation.sh
	@$(SCRIPTS_DIR)/pi-workstation.sh

dev:
	@echo "=== Installing dev + recovery tools ==="
	@chmod +x $(SCRIPTS_DIR)/pi-dev-recovery.sh
	@$(SCRIPTS_DIR)/pi-dev-recovery.sh

ssh:
	@echo "=== GitHub SSH setup ==="
	@chmod +x $(SCRIPTS_DIR)/setup-ssh-github.sh
	@$(SCRIPTS_DIR)/setup-ssh-github.sh

backup:
	@echo "=== Backing up HOME to $(DEST) ==="
	@chmod +x $(SCRIPTS_DIR)/pi-backup.sh
	@$(SCRIPTS_DIR)/pi-backup.sh "$(DEST)"

restore:
	@if [ -z "$(ARCHIVE)" ]; then \
		echo "Missing ARCHIVE. Usage: make restore ARCHIVE=/path/file.tgz"; \
		exit 1; \
	fi
	@echo "=== Restoring $(ARCHIVE) ==="
	@chmod +x $(SCRIPTS_DIR)/pi-restore.sh
	@$(SCRIPTS_DIR)/pi-restore.sh "$(ARCHIVE)"

flash:
	@echo "=== FLASHING DEBIAN TO $(DISK) ==="
	@echo "WARNING: THIS WILL ERASE $(DISK)"
	@printf "Type YES to continue: "; \
	read OK; if [ "$$OK" != "YES" ]; then echo "Abort."; exit 1; fi
	@chmod +x $(SCRIPTS_DIR)/flash-debian-to-disk.sh
	@$(SCRIPTS_DIR)/flash-debian-to-disk.sh "" "$(DISK)"

motd:
	@echo "=== Installing M*A*S*H MOTD ==="
	@chmod +x $(SCRIPTS_DIR)/mash-motd.sh
	@$(SCRIPTS_DIR)/mash-motd.sh

# -------- Look & Feel ---------------------------------------------------------
pretty-matrix:
	@echo "=== Matrix CLI cosmetics (fastfetch, bars, PS1) ==="
	@chmod +x $(SCRIPTS_DIR)/pretty-matrix.sh
	@$(SCRIPTS_DIR)/pretty-matrix.sh

pretty-xfce:
	@echo "=== Matrix XFCE theme + wallpaper ==="
	@chmod +x $(SCRIPTS_DIR)/pretty-xfce.sh
	@$(SCRIPTS_DIR)/pretty-xfce.sh

# Optional: GTK theme/icons via the Matrix theme repo you pulled
matrix-theme:
	@echo "=== Installing Matrix GTK theme + icons (user scope) ==="
	@mkdir -p $(HOME)/.themes $(HOME)/.icons
	@# expects you already cloned/downloaded theme assets under ~/.themes/Matrix-GTK-Theme
	@# copies \"themes/src/main\" as an installed theme directory
	@if [ -d "$(HOME)/.themes/Matrix-GTK-Theme/themes/src/main" ]; then \
	  rm -rf "$(HOME)/.themes/Matrix2.0" && \
	  cp -a "$(HOME)/.themes/Matrix-GTK-Theme/themes/src/main" "$(HOME)/.themes/Matrix2.0"; \
	  echo "[✓] GTK theme installed at ~/.themes/Matrix2.0"; \
	else \
	  echo "[!] Missing ~/.themes/Matrix-GTK-Theme (run: git clone https://github.com/Fausto-Korpsvart/Matrix-GTK-Theme ~/.themes/Matrix-GTK-Theme)"; \
	fi

# Disable DPMS/blanking for Xorg + LightDM/XFCE (safe to re-run)
noblank:
	@echo "=== Disabling screen blank/DPMS ==="
	@sudo install -d /etc/X11/xorg.conf.d
	@printf "%s\n" \
'Section "Monitor"' \
'  Identifier "HDMI-0"' \
'  Option "DPMS" "false"' \
'EndSection' \
'Section "ServerFlags"' \
'  Option "BlankTime" "0"' \
'  Option "StandbyTime" "0"' \
'  Option "SuspendTime" "0"' \
'  Option "OffTime" "0"' \
'EndSection' \
	| sudo tee /etc/X11/xorg.conf.d/10-dpms.conf >/dev/null
	@sudo mkdir -p /etc/xdg/autostart
	@printf "%s\n" \
"[Desktop Entry]" \
"Type=Application" \
"Name=Disable DPMS" \
"Exec=/bin/sh -c 'xset -dpms; xset s off; xset s noblank'" \
"X-GNOME-Autostart-enabled=true" \
	| sudo tee /etc/xdg/autostart/disable-dpms.desktop >/dev/null
	@echo "[i] Reboot or log out/in for desktop session autostart to take effect."

# -------- Kernel workflow -----------------------------------------------------
fetch-firmware:
	@echo "=== Sparse+shallow fetch of rpi-firmware (boot only) ==="
	@if [ ! -d "$(FW_DIR)" ]; then \
	  git clone --filter=tree:0 --depth=1 https://github.com/raspberrypi/firmware "$(FW_DIR)"; \
	else \
	  git -C "$(FW_DIR)" pull --ff-only; \
	fi

fetch-kernel:
	@echo "=== Shallow fetch of raspberrypi/linux (arm64) ==="
	@if [ ! -d "$(KERNEL_DIR)" ]; then \
	  git clone --depth=1 --branch rpi-6.6.y https://github.com/raspberrypi/linux "$(KERNEL_DIR)"; \
	else \
	  git -C "$(KERNEL_DIR)" fetch --depth=1 origin rpi-6.6.y && \
	  git -C "$(KERNEL_DIR)" checkout -qf FETCH_HEAD; \
	fi

kernel:
	@echo "=== Building & staging kernel/DTBs/modules ==="
	@chmod +x $(SCRIPTS_DIR)/build-kernel.sh
	@KERNEL_DIR="$(KERNEL_DIR)" \
	 FW_DIR="$(FW_DIR)" \
	 OUT_DIR="$(OUT_DIR)" \
	 DEFCONFIG="$(DEFCONFIG)" \
	 JOBS="$(JOBS)" \
	 MODULES_OUT="$(MODULES_OUT)" \
	 $(SCRIPTS_DIR)/build-kernel.sh

# -------- Housekeeping --------------------------------------------------------
clean-tmp:
	@echo "=== Cleaning local temp artifacts ==="
	@rm -rf ./tmp ./.cache 2>/dev/null || true
	@echo "[✓] Done."
