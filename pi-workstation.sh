#!/usr/bin/env bash
set -euo pipefail

echo "=== Frankie Operating Theatre: Workstation Rebuild ==="

# Detect model and warn unless Pi 4 or Pi 5
MODEL="$(tr -d '\0' </proc/device-tree/model 2>/dev/null || echo 'Unknown')"
echo "Detected: ${MODEL}"
if ! echo "$MODEL" | grep -Eq 'Raspberry Pi (4|5)'; then
  echo "⚠️  This script is tuned for Raspberry Pi 4/5."
  read -rp "Continue anyway? (y/N) " yn
  [[ "${yn,,}" == "y" ]] || { echo "Aborting."; exit 1; }
fi

echo "=== Updating system ==="
sudo apt update -y
sudo apt full-upgrade -y

echo "=== Installing Full Workstation Toolset ==="
sudo apt install -y \
  build-essential bc bison flex libssl-dev libncurses5-dev libelf-dev \
  libusb-dev libudev-dev libtool meson ninja-build cmake pkg-config gperf \
  qemu-user-static genimage mtools dosfstools parted gddrescue \
  e2fsprogs exfatprogs exfat-fuse \
  kodi ffmpeg libdrm-dev libgbm-dev libegl1-mesa-dev libgles2-mesa-dev \
  libinput-dev mesa-utils alsa-utils pulseaudio pavucontrol \
  python3 python3-dev python3-pip python3-setuptools python3-venv \
  git curl wget openssh-server net-tools iproute2 network-manager \
  firmware-brcm80211 \
  htop fastfetch ncdu gparted thunar zip unzip xz-utils tar file jq \
  tmux screen vim nano usbutils pciutils \
  ufw fail2ban \
  xfce4 xfce4-goodies \
  arc-theme papirus-icon-theme \
  plank conky-all \
  vlc lsb-release

echo "=== Installing Argon ONE Fan Driver ==="
curl -s https://download.argon40.com/argon1.sh | bash || true

echo "=== XFCE theming (Arc-Dark + Papirus) ==="
xfconf-query -c xsettings -p /Net/ThemeName -s "Arc-Dark" || true
xfconf-query -c xsettings -p /Net/IconThemeName -s "Papirus" || true

echo "=== Enable Plank dock at startup ==="
mkdir -p "${HOME}/.config/autostart"
cp /usr/share/applications/plank.desktop "${HOME}/.config/autostart/" 2>/dev/null || true

echo "=== Disabling screen blanking & power saving ==="

# 1) Runtime (immediate)
xset -dpms || true
xset s off || true
xset s noblank || true

# 2) Permanent desktop config for XFCE
mkdir -p "${HOME}/.config/autostart"
cat <<EOF > "${HOME}/.config/autostart/nosleep.desktop"
[Desktop Entry]
Type=Application
Name=NoSleep
Exec=xset s off -dpms
EOF

# 3) System-wide LightDM config (prevents blank before login)
sudo mkdir -p /etc/lightdm/lightdm.conf.d
echo "[Seat:*]" | sudo tee /etc/lightdm/lightdm.conf.d/50-no-blanking.conf > /dev/null
echo "xserver-command=X -s 0 -dpms" | sudo tee -a /etc/lightdm/lightdm.conf.d/50-no-blanking.conf > /dev/null

echo "=== ✅ Screen will NEVER turn off, blank, or dim. ==="
echo "=== ✅ Build complete. Reboot recommended. ==="
