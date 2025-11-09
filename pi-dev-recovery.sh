#!/usr/bin/env bash
set -euo pipefail
echo "=== Dev + Recovery Toolbox ==="

sudo apt update
sudo apt install -y \
  gddrescue ddrescueview \
  genimage mtools dosfstools parted e2fsprogs exfatprogs exfat-fuse \
  kpartx udisks2 lshw usbutils pciutils \
  squashfs-tools squashfuse \
  ccache ninja-build meson qemu-user-static \
  rclone git-lfs

# Fun/handy aliases in /etc/profile.d
sudo bash -c 'cat >/etc/profile.d/mash-aliases.sh' <<'EOF'
# M*A*S*H field tools
alias vitals='top -o %MEM'
alias scalpel='sudo'
alias revive='sudo shutdown -r now'
alias timeofdeath='sudo shutdown now'
EOF

echo "=== rclone present: use `rclone config` for Google Drive if needed ==="
echo "=== Done. ==="
