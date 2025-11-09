#!/usr/bin/env bash
set -euo pipefail

# ---------- Detect user & env ----------
USER_NAME="${SUDO_USER:-$USER}"
HOME_DIR="$(getent passwd "$USER_NAME" | cut -d: -f6)"
ARCH="$(dpkg --print-architecture)"
CODENAME="$(. /etc/os-release && echo "${VERSION_CODENAME:-unknown}")"

echo ">> Running as: $USER_NAME ($HOME_DIR) on Ubuntu $CODENAME [$ARCH]"

# ---------- Preflight ----------
if ! command -v apt >/dev/null 2>&1; then
  echo "This script expects an apt-based system (Ubuntu/Debian). Aborting."
  exit 1
fi

sudo apt update
sudo apt install -y software-properties-common ca-certificates gnupg lsb-release

# Universe (needed for a few packages)
sudo add-apt-repository -y universe || true
sudo apt update

# ---------- Core workstation toolchain ----------
sudo apt install -y \
  build-essential gcc g++ make cmake pkg-config ninja-build meson \
  git curl wget unzip zip jq ripgrep fd-find fzf \
  python3 python3-pip python3-venv python3-dev \
  libssl-dev libffi-dev \
  tmux htop ncdu fastfetch neovim \
  rclone rsync pv \
  net-tools iproute2 nmap \
  xdg-utils

# symlink fd to fdfind if needed
if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
  sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
fi

# ---------- OpenSSH server ----------
sudo apt install -y openssh-server
sudo systemctl enable --now ssh

# ---------- Docker (official repo) ----------
if ! command -v docker >/dev/null 2>&1; then
  echo ">> Installing Docker CE..."
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo usermod -aG docker "$USER_NAME" || true
  echo ">> Docker installed. You must log out/in (or reboot) to use docker without sudo."
fi

# ---------- GNOME/Wayland: disable screen blank & lock ----------
maybe_set_gsettings() {
  # Use the target user's DBus session if available
  local uid; uid="$(id -u "$USER_NAME")"
  local bus="unix:path=/run/user/${uid}/bus"
  if sudo -u "$USER_NAME" DBUS_SESSION_BUS_ADDRESS="$bus" gsettings writable org.gnome.desktop.session idle-delay >/dev/null 2>&1; then
    sudo -u "$USER_NAME" DBUS_SESSION_BUS_ADDRESS="$bus" gsettings set org.gnome.desktop.session idle-delay 0 || true
    sudo -u "$USER_NAME" DBUS_SESSION_BUS_ADDRESS="$bus" gsettings set org.gnome.desktop.screensaver lock-enabled false || true
    echo ">> GNOME idle/lock disabled."
  else
    echo ">> Could not reach GNOME session bus (headless?). Skipping idle/lock tweaks."
  fi
}
maybe_set_gsettings

# ---------- Quality-of-life dotfiles ----------
# tmux
TMUX_CONF="${HOME_DIR}/.tmux.conf"
if [[ ! -f "$TMUX_CONF" ]]; then
  cat <<'TMUX' | sudo -u "$USER_NAME" tee "$TMUX_CONF" >/dev/null
set -g mouse on
setw -g mode-keys vi
set -g history-limit 100000
set -g status-bg colour236
set -g status-fg white
bind r source-file ~/.tmux.conf \; display "reloaded"
TMUX
fi

# fastfetch default
PROFILE_DIR="${HOME_DIR}/.config"
sudo -u "$USER_NAME" mkdir -p "${PROFILE_DIR}"
if command -v fastfetch >/dev/null 2>&1 && [[ ! -f "${PROFILE_DIR}/fastfetch/config.jsonc" ]]; then
  sudo -u "$USER_NAME" fastfetch --gen-config >/dev/null 2>&1 || true
fi

# ---------- Fin ----------
sudo apt upgrade -y
echo
echo "✅ Workstation setup complete."
echo "   - SSH is enabled."
echo "   - Docker installed (log out/in to use without sudo)."
echo "   - GNOME screen blanking disabled (if session detected)."

# ---- Fastfetch installer (Ubuntu ARM safe) ----
install_fastfetch() {
  if command -v fastfetch >/dev/null 2>&1; then
    echo "[✓] fastfetch already installed"
    return
  fi

  echo "[+] Installing fastfetch (Ubuntu ARM)"
  tmp=/tmp/fastfetch.tar.gz
  curl -fsSL -o "$tmp" \
    https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-aarch64-polyfilled.tar.gz || {
      echo "[-] Download failed"; return 1; }

  # Extract with correct /usr layout from the tar
  sudo tar -xzf "$tmp" -C / || { echo "[-] Extract failed"; return 1; }

  # Ensure it's on PATH
  if [ -x /usr/bin/fastfetch ]; then
    sudo ln -sf /usr/bin/fastfetch /usr/local/bin/fastfetch
  elif [ -x /usr/local/bin/fastfetch-linux-aarch64-polyfilled/usr/bin/fastfetch ]; then
    sudo ln -sf /usr/local/bin/fastfetch-linux-aarch64-polyfilled/usr/bin/fastfetch /usr/local/bin/fastfetch
  fi

  if ! command -v fastfetch >/dev/null 2>&1; then
    echo "[-] fastfetch not found on PATH after install"; return 1
  fi

  echo "[✓] fastfetch installed"
}
install_fastfetch
# ---- /Fastfetch installer ----------------------
