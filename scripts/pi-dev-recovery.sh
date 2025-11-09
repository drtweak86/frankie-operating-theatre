#!/usr/bin/env bash
set -euo pipefail

USER_NAME="${SUDO_USER:-$USER}"
HOME_DIR="$(getent passwd "$USER_NAME" | cut -d: -f6)"
CODENAME="$(. /etc/os-release && echo "${VERSION_CODENAME:-unknown}")"

echo ">> Dev/Recovery setup for $USER_NAME on Ubuntu $CODENAME"

sudo apt update

# Filesystems, imaging, partitioning, diagnostics
sudo apt install -y \
  gparted gnome-disk-utility \
  parted dosfstools exfatprogs ntfs-3g btrfs-progs xfsprogs \
  e2fsprogs mtools \
  usbutils pciutils smartmontools lshw hdparm \
  ddrescue util-linux udisks2 \
  rpi-imager \
  rsync pv unzip zip \
  gvfs-backends

# Network & troubleshooting
sudo apt install -y \
  netcat-openbsd socat iperf3 traceroute \
  tcpdump tshark nmap whois dnsutils \
  openssh-client curl wget

# Editors & terminals
sudo apt install -y neovim tmux screen

# Optional: Argon fan script (Pi cases)
# (harmless on non-Argon systems; comment out if you don’t want it)
if curl -fsSL https://download.argon40.com/argon1.sh -o /tmp/argon.sh; then
  bash /tmp/argon.sh || true
  rm -f /tmp/argon.sh
fi

# Handy aliases
BASHRC="${HOME_DIR}/.bashrc"
if ! grep -q "# recovery-aliases" "$BASHRC"; then
  cat <<'ALIASES' | sudo -u "$USER_NAME" tee -a "$BASHRC" >/dev/null
# recovery-aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias dfh='df -h'
alias duh='du -h --max-depth=1'
ALIASES
fi

# Simple helpers: mount an image, make a raw clone (with progress)
BIN_DIR="/usr/local/bin"
sudo install -d -m 0755 "$BIN_DIR"

# mount-img: mount a partitioned image to /mnt/img{boot,root}
if [[ ! -x "${BIN_DIR}/mount-img" ]]; then
  sudo tee "${BIN_DIR}/mount-img" >/dev/null <<'SH'
#!/usr/bin/env bash
set -euo pipefail
IMG="${1:-}"
[[ -z "$IMG" ]] && { echo "Usage: mount-img <image.img>"; exit 1; }
LOOP="$(sudo losetup --show -fP "$IMG")"
echo "Loop: $LOOP"
sudo mkdir -p /mnt/imgboot /mnt/imgroot
# Try common RPi layouts: p1=boot (vfat), p2=root
sudo mount "${LOOP}p1" /mnt/imgboot 2>/dev/null || true
sudo mount "${LOOP}p2" /mnt/imgroot 2>/dev/null || true
lsblk "$LOOP"
echo "Mounted to /mnt/imgboot and /mnt/imgroot (if present)."
echo "Use: sudo umount /mnt/imgboot /mnt/imgroot && sudo losetup -d $LOOP"
SH
  sudo chmod +x "${BIN_DIR}/mount-img"
fi

# raw-clone: dd with pv progress (src -> dst)
if [[ ! -x "${BIN_DIR}/raw-clone" ]]; then
  sudo tee "${BIN_DIR}/raw-clone" >/dev/null <<'SH'
#!/usr/bin/env bash
set -euo pipefail
SRC="${1:-}"; DST="${2:-}"
[[ -z "$SRC" || -z "$DST" ]] && { echo "Usage: raw-clone </dev/src> </dev/dst>"; exit 1; }
[[ ! -b "$SRC" || ! -b "$DST" ]] && { echo "SRC and DST must be block devices"; exit 1; }
SIZE=$(blockdev --getsize64 "$SRC")
pv -s "$SIZE" "$SRC" | sudo dd of="$DST" bs=4M conv=fsync status=none
sync
echo "Clone complete."
SH
  sudo chmod +x "${BIN_DIR}/raw-clone"
fi

echo "✅ Dev/Recovery tools installed."
