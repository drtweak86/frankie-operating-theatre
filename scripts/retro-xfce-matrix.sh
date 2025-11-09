#!/usr/bin/env bash
set -euo pipefail

echo "[+] Matrix XFCE: packages"
export DEBIAN_FRONTEND=noninteractive

# Desktop if missing (leaner than xubuntu-desktop)
if ! command -v startxfce4 >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y xfce4 xfce4-terminal xfce4-goodies lightdm
fi

# Fonts & extras (skip if already present)
sudo apt install -y wget curl fonts-jetbrains-mono fonts-hack fonts-terminus cool-retro-term || true

echo "[+] Matrix XFCE: themes"
mkdir -p "$HOME/.themes" "$HOME/.icons" "$HOME/Pictures/Wallpapers"

# Gruvbox GTK theme
if [ ! -d "$HOME/.themes/Gruvbox-Green-Dark" ]; then
  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/ggtk.txz" \
    https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme/releases/download/v2023-09-20/Gruvbox-Green-Dark.tar.xz
  tar -xf "$tmp/ggtk.txz" -C "$HOME/.themes"
fi

# Gruvbox icon theme
if [ ! -d "$HOME/.icons/Gruvbox-Dark-Green" ]; then
  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/gicons.txz" \
    https://github.com/Fausto-Korpsvart/Gruvbox-Icons/releases/download/v2023-09-20/Gruvbox-Dark-Green.tar.xz
  tar -xf "$tmp/gicons.txz" -C "$HOME/.icons"
fi

echo "[+] Matrix XFCE: wallpaper"
WALL="$HOME/Pictures/Wallpapers/matrix-crt.png"
[ -f "$WALL" ] || curl -fsSL -o "$WALL" "https://i.imgur.com/6Cp3C0R.png" || true

# Apply theme via xfconf (no-op if not in XFCE session)
THEME="Gruvbox-Green-Dark"
ICONS="Gruvbox-Dark-Green"
echo "[+] Applying themes (if XFCE session active)"
xfconf-query -c xsettings -p /Net/ThemeName     -s "$THEME"  2>/dev/null || true
xfconf-query -c xsettings -p /Net/IconThemeName -s "$ICONS"  2>/dev/null || true
xfconf-query -c xfwm4     -p /general/theme     -s "$THEME"  2>/dev/null || true

# Set wallpaper on any known path (different XFCE versions use different keys)
for p in \
  /backdrop/screen0/monitor0/workspace0/last-image \
  /backdrop/screen0/monitor0/image-path \
  /backdrop/screen0/monitorHDMI-1/workspace0/last-image \
  /backdrop/screen0/monitorHDMI-1/image-path \
  /backdrop/screen0/monitorLVDS-1/workspace0/last-image \
  /backdrop/screen0/monitorLVDS-1/image-path ; do
  xfconf-query -c xfce4-desktop -p "$p" -s "$WALL" 2>/dev/null || true
done

# Ensure wallpaper style is scaled nicely if the key exists
xfconf-query -c xfce4-desktop -p /backdrop/single-workspace-mode -s true 2>/dev/null || true

echo "[+] Matrix XFCE: terminal profile"
mkdir -p "$HOME/.config/xfce4/terminal"
cat > "$HOME/.config/xfce4/terminal/terminalrc" <<'RC'
[Configuration]
FontName=Terminus 12
ColorPalette=#000000;#00aa00;#00ff00;#00ff00;#00ff00;#00ff00;#00ff00;#00ff00;#003300;#00aa00;#00ff00;#00ff00;#00ff00;#00ff00;#00ff00;#00ff00
ColorForeground=#00ff00
ColorBackground=#000000
ColorCursor=#00ff00
ScrollingBar=TERMINAL_SCROLLBAR_NONE
MiscAlwaysShowTabs=FALSE
MiscBell=FALSE
RC

# Handy alias for CRT-look terminal (idempotent)
grep -q "alias crt=" "$HOME/.bashrc" || echo "alias crt='cool-retro-term >/dev/null 2>&1 & disown'" >> "$HOME/.bashrc"

echo "[✓] Matrix XFCE ready. If you just installed XFCE/LightDM, reboot."
