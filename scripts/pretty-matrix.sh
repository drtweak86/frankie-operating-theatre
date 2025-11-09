#!/usr/bin/env bash
set -euo pipefail

# 1) Fastfetch (prefer repo; fallback to upstream tar)
if ! command -v fastfetch >/dev/null 2>&1; then
  if apt-cache show fastfetch >/dev/null 2>&1; then
    sudo apt update && sudo apt install -y fastfetch
  else
    tmp=/tmp/fastfetch.tar.gz
    curl -fsSL -o "$tmp" \
      https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-aarch64-polyfilled.tar.gz
    sudo tar -xzf "$tmp" -C /   # contains /usr/… paths
    sudo ln -sf /usr/bin/fastfetch /usr/local/bin/fastfetch || true
  fi
fi

# 2) Minimal “nice dashboard” preset
mkdir -p "$HOME/.config/fastfetch"
cat > "$HOME/.config/fastfetch/config.jsonc" <<'JSON'
{
  // clean, readable, green dashboard
  "logo": { "type": "small" },
  "display": { "separator": "  ", "brightColor": true, "color": "green" },
  "modules": [
    { "type": "title",   "key": "System" },
    { "type": "os",      "key": "OS" },
    { "type": "kernel",  "key": "Kernel" },
    { "type": "uptime",  "key": "Uptime" },

    { "type": "cpu",     "key": "CPU",  "format": "{name} — {usage:bar:24:█░:true:false} {usage}%" },
    { "type": "memory",  "key": "RAM",  "format": "{used:bar:24:█░:true:false} {used} / {total}" },
    { "type": "disk",    "key": "Root", "folders": [ "/" ], "format": "{used:bar:24:█░:true:false} {used} / {total}" },

    { "type": "gpu",     "key": "GPU",  "format": "{name}" },
    { "type": "temperature", "key": "Temp", "format": "{temperature}°C" },

    { "type": "packages","key": "Pkgs", "format": "{count}" },
    { "type": "localip", "key": "LAN" },
    { "type": "publicip","key": "WAN" }
  ]
}
JSON

# 3) Tiny convenience alias (no autorun)
grep -q 'alias dash=' "$HOME/.bashrc" || echo "alias dash='fastfetch'" >> "$HOME/.bashrc"

echo "[✓] Dashboard ready. Run: fastfetch   (or: dash)"
