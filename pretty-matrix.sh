#!/usr/bin/env bash
set -e

# --- ensure fastfetch is installed (Ubuntu ARM safe) ---
if ! command -v fastfetch >/dev/null 2>&1; then
  echo "[+] Installing fastfetch (Ubuntu ARM)"
  tmp=/tmp/fastfetch.tar.gz
  curl -fsSL -o "$tmp" \
    https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-aarch64-polyfilled.tar.gz
  sudo tar -xzf "$tmp" -C /
  if [ -x /usr/bin/fastfetch ]; then
    sudo ln -sf /usr/bin/fastfetch /usr/local/bin/fastfetch
  elif [ -x /usr/local/bin/fastfetch-linux-aarch64-polyfilled/usr/bin/fastfetch ]; then
    sudo ln -sf /usr/local/bin/fastfetch-linux-aarch64-polyfilled/usr/bin/fastfetch /usr/local/bin/fastfetch
  fi
fi

# --- Fastfetch Matrix preset ---
mkdir -p "$HOME/.config/fastfetch"
cat > "$HOME/.config/fastfetch/config.jsonc" <<'JSON'
{
  "logo": { "type": "small" },
  "display": { "separator": "  ", "brightColor": true, "color": "green" },
  "modules": [
    { "type": "title",   "key": "⟟  System" },
    { "type": "os",      "key": "⟟  OS" },
    { "type": "kernel",  "key": "⟟  Kernel" },
    { "type": "uptime",  "key": "⟟  Uptime" },
    { "type": "packages","key": "⟟  Pkgs", "format": "{count} (apt)" },
    { "type": "memory",  "key": "⟟  RAM",  "format": "{used:bar:28:█░:true:false} {used} / {total}" },
    { "type": "disk",    "key": "⟟  Disk", "format": "{used:bar:28:█░:true:false} {used} / {total}" },
    { "type": "cpu",     "key": "⟟  CPU",  "format": "{usage:bar:28:█░:true:false} {usage}%" },
    { "type": "gpu",     "key": "⟟  GPU",  "format": "{usage:bar:28:█░:true:false} {usage:%?}" },
    { "type": "temperature", "key": "⟟  Temp", "format": "{temperature}°C" },
    { "type": "publicip","key": "⟟  WAN" },
    { "type": "localip", "key": "⟟  LAN" }
  ]
}
JSON

# --- autorun fastfetch on new shells (idempotent) ---
grep -q 'fastfetch' "$HOME/.bashrc" || echo 'command -v fastfetch >/dev/null && fastfetch' >> "$HOME/.bashrc"

# --- Matrix-green PS1 prompt (idempotent) ---
if ! grep -q 'Matrix PS1' "$HOME/.bashrc"; then
  cat >> "$HOME/.bashrc" <<'BRC'
# --- Matrix PS1 ---
if [ -n "$PS1" ]; then
  GREEN='\[\e[0;32m\]'
  DIM='\[\e[2m\]'
  RESET='\[\e[0m\]'
  PS1="${GREEN}\u@\h${RESET}${DIM} [\A] ${RESET}\w\n${GREEN}❯ ${RESET}"
fi
# -------------------
BRC
fi

# --- nice font + matrix rain ---
sudo apt-get update -y
sudo apt-get install -y fonts-firacode cmatrix lm-sensors sysstat || true
sudo sensors-detect --auto || true

# handy alias (idempotent)
grep -q 'alias matrix=' "$HOME/.bashrc" || echo "alias matrix='cmatrix -b -u 4 -C green'" >> "$HOME/.bashrc"

echo "[✓] Matrix mode installed. Open a new terminal or run: source ~/.bashrc && fastfetch"
