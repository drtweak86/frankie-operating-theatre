#!/usr/bin/env bash
set -e

echo "=== Updating system ==="
sudo apt update -y
sudo apt full-upgrade -y

echo "=== Installing Full Workstation Toolset ==="
sudo apt install -y \
  build-essential bc bison flex libssl-dev libncurses5-dev libelf-dev \
  libusb-dev libudev-dev libtool meson ninja-build cmake pkg-config gperf \
  qemu-user-static genimage mtools dosfstools parted gddrescue \
  e2fsprogs exfatprogs exfat-fuse kodi ffmpeg libdrm-dev libgbm-dev \
  libegl1-mesa-dev libgles2-mesa-dev libinput-dev mesa-utils alsa-utils \
  pulseaudio pavucontrol python3 python3-dev python3-pip python3-setuptools \
  python3-venv python3-ctypes python3-pkgutil git curl wget openssh-server \
  net-tools iproute2 network-manager firmware-brcm80211 htop neofetch ncdu \
  gparted thunar zip unzip xz-utils tar file jq tmux screen vim nano \
  usbutils pciutils ufw fail2ban xfce4 xfce4-goodies arc-theme \
  papirus-icon-theme plank conky-all vlc lsb-release

echo "=== Installing Argon ONE Fan Driver ==="
curl -s https://download.argon40.com/argon1.sh | bash

echo "=== Setting XFCE Dark Theme + Papirus Icons ==="
xfconf-query -c xsettings -p /Net/ThemeName -s "Arc-Dark" || true
xfconf-query -c xsettings -p /Net/IconThemeName -s "Papirus" || true

echo "=== Enabling Plank at Startup ==="
mkdir -p ~/.config/autostart
cp /usr/share/applications/plank.desktop ~/.config/autostart/ || true

echo "=== Done! Reboot recommended. ==="
