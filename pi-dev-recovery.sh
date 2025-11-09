#!/usr/bin/env bash
set -euo pipefail

echo "=== Frankie Operating Theatre: Recovery/Dev Enhancements ==="

# --- Fast downloads & compressions ---
sudo apt update
sudo apt install -y \
  pigz pbzip2 p7zip-full aria2 pv \
  ccache zram-tools \
  ripgrep fd-find fzf bat eza colordiff \
  git-lfs gh \
  nmap iperf3 \
  btop glances \
  etckeeper \
  unattended-upgrades apt-listchanges \
  ufw fail2ban \
  nfs-common cifs-utils \
  rpi-imager

# Nice aliases (bat/eza names differ on Debian)
mkdir -p "${HOME}/.config"
grep -q "# FRANKIE-OT" ~/.bashrc 2>/dev/null || cat >> ~/.bashrc <<'EOF'
# FRANKIE-OT
alias ll='eza -lah --group-directories-first 2>/dev/null || ls -lah'
alias cat='batcat --paging=never 2>/dev/null || cat'
alias grep='grep --color=auto'
alias dfh='df -h'
alias duh='du -sh * | sort -h'
alias gs='git status'
alias gp='git pull --rebase'
alias ..='cd ..'
EOF

# Work dirs
sudo mkdir -p /work /images /backups
sudo chown -R "$USER":"$USER" /work /images /backups

# ccache (speed up rebuilds)
mkdir -p "${HOME}/.ccache"
grep -q CCACHE_DIR ~/.bashrc 2>/dev/null || cat >> ~/.bashrc <<'EOF'
export CCACHE_DIR="${HOME}/.ccache"
export CCACHE_MAXSIZE=15G
export PATH="/usr/lib/ccache:$PATH"
EOF

# zram (more breathing room when compiling)
sudo sed -i 's/^ALGO=.*/ALGO=zstd/' /etc/default/zramswap || true
sudo systemctl enable --now zramswap || true

# journald size cap (avoid log explosions)
sudo mkdir -p /etc/systemd/journald.conf.d
echo -e "[Journal]\nSystemMaxUse=200M" | sudo tee /etc/systemd/journald.conf.d/size.conf >/dev/null
sudo systemctl restart systemd-journald

# SSH hardening starter (keep simple)
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
yes | sudo ufw enable

# Fail2ban basic SSH jail
sudo mkdir -p /etc/fail2ban/jail.d
cat | sudo tee /etc/fail2ban/jail.d/ssh.local >/dev/null <<'EOF'
[sshd]
enabled = true
port    = ssh
filter  = sshd
logpath = /var/log/auth.log
maxretry = 6
bantime = 1h
EOF
sudo systemctl enable --now fail2ban

# Unattended upgrades (security)
sudo dpkg-reconfigure -f noninteractive unattended-upgrades || true
sudo systemctl enable --now unattended-upgrades

# Track /etc changes (lifesaver)
sudo etckeeper init || true
sudo etckeeper commit "Initial /etc snapshot (frankie OT)" || true

echo "=== Done. Open a new terminal to load aliases/ccache. ==="
echo "Tip: store giant builds under /work; images under /images; tarballs/backups under /backups."
