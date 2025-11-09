#!/usr/bin/env bash
set -euo pipefail

echo "=== Frankie Operating Theatre: Debian Workstation Setup ==="

# Detect model (informational only)
MODEL="$(tr -d '\0' </proc/device-tree/model 2>/dev/null || echo 'Unknown')"
echo "Detected: ${MODEL}"

echo "=== Update & Upgrade ==="
sudo apt update
sudo apt full-upgrade -y

echo "=== Desktop & Display Manager (XFCE + LightDM) ==="
sudo apt install -y xfce4 xfce4-goodies lightdm lightdm-gtk-greeter
# Force LightDM + XFCE as session (bypass Pi-specific sessions)
sudo mkdir -p /etc/lightdm/lightdm.conf.d
printf "[Seat:*]\nuser-session=xfce\n" | sudo tee /etc/lightdm/lightdm.conf.d/50-xfce.conf >/dev/null
sudo update-alternatives --set x-session-manager /usr/bin/xfce4-session || true
sudo update-alternatives --set x-window-manager /usr/bin/xfwm4 || true
sudo systemctl enable --now lightdm

echo "=== Core Dev Tooling & CLI QoL ==="
sudo apt install -y \
  build-essential cmake pkg-config git curl wget ca-certificates gnupg lsb-release \
  bc bison flex libssl-dev libncurses5-dev libelf-dev \
  python3 python3-venv python3-pip python3-setuptools \
  fastfetch htop ncdu duf dust tmux screen vim nano file jq ripgrep fd-find \
  aria2 rsync zip unzip xz-utils p7zip-full p7zip-rar pv \
  net-tools iproute2 dnsutils openssh-server \
  gparted gnome-disk-utility

echo "=== Multimedia / GPU bits (for Kodi builds later) ==="
sudo apt install -y \
  ffmpeg mesa-utils libdrm-dev libgbm-dev libegl1-mesa-dev libgles2-mesa-dev libinput-dev \
  alsa-utils pulseaudio pavucontrol

echo "=== Optional: Docker (handy later; logout required to take effect) ==="
sudo apt install -y docker.io docker-compose-plugin || true
sudo usermod -aG docker "$USER" || true

echo "=== Optional: Timeshift (easy system restore points) ==="
sudo apt install -y timeshift || true

echo "=== Theming (nice defaults) ==="
sudo apt install -y arc-theme papirus-icon-theme plank conky-all || true

echo "=== SSH enable (so you can hop in from phone/PC) ==="
sudo systemctl enable --now ssh

echo "=== Stop screen blanking (XFCE) ==="
# xset on login for the current user
if ! grep -q "xset -dpms" "${HOME}/.xprofile" 2>/dev/null; then
  {
    echo 'xset -dpms'
    echo 'xset s off'
    echo 'xset s noblank'
  } >> "${HOME}/.xprofile"
fi

echo "=== Optional: Argon One support (uncomment to enable) ==="
# curl -fsSL https://download.argon40.com/argon1.sh | bash

echo "=== Done. Reboot recommended. ==="
