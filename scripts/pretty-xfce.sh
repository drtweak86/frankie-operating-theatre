#!/usr/bin/env bash
set -euo pipefail

log(){ printf "\n[+] %s\n" "$*"; }

# --- Minimal XFCE bits (skip if you already have a desktop) ---
if ! command -v xfconf-query >/dev/null 2>&1; then
  log "Installing minimal XFCE session (xfce4 + greeter)"
  sudo apt-get update -y
  sudo apt-get install -y xfce4 xfconf xfce4-goodies lightdm slick-greeter
fi

log "Installing fonts and goodies"
sudo apt-get install -y fonts-jetbrains-mono fonts-hack fonts-terminus cool-retro-term papirus-icon-theme || true

THEMES="$HOME/.themes"
ICONS="$HOME/.icons"
WALL="$HOME/Pictures/Wallpapers"
mkdir -p "$THEMES" "$ICONS" "$WALL"

# --- robust download helper (tries each URL until one works) ---
dl(){
  local out="$1"; shift
  for url in "$@"; do
    if curl -fsSL -L "$url" -o "$out"; then
      return 0
    fi
  done
  return 1
}

# --- Try to get Gruvbox GTK theme & icons (Green/Dark) ---
GTK_TXZ="$THEMES/gruvbox-gtk.txz"
ICO_TXZ="$ICONS/gruvbox-icons.txz"

log "Fetching Gruvbox GTK theme (Green/Dark)…"
if dl "$GTK_TXZ" \
  "https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme/releases/latest/download/Gruvbox-Green-Dark.tar.xz" \
  "https://raw.githubusercontent.com/Fausto-Korpsvart/Gruvbox-GTK-Theme/master/pkgs/Gruvbox-Green-Dark.tar.xz"; then
  tar -C "$THEMES" -xf "$GTK_TXZ" && rm -f "$GTK_TXZ"
  GTK_NAME="Gruvbox-Green-Dark"
else
  log "GTK Gruvbox not found, falling back to Adwaita-dark"
  GTK_NAME="Adwaita-dark"
fi

log "Fetching Gruvbox icon theme (Dark/Green)…"
if dl "$ICO_TXZ" \
  "https://github.com/Fausto-Korpsvart/Gruvbox-Icons/releases/latest/download/Gruvbox-Dark-Green.tar.xz" \
  "https://raw.githubusercontent.com/Fausto-Korpsvart/Gruvbox-Icons/master/pkgs/Gruvbox-Dark-Green.tar.xz"; then
  tar -C "$ICONS" -xf "$ICO_TXZ" && rm -f "$ICO_TXZ"
  ICON_NAME="Gruvbox-Dark-Green"
else
  log "Icon Gruvbox not found, falling back to Papirus-Dark"
  ICON_NAME="Papirus-Dark"
fi

# --- Wallpaper ---
log "Setting wallpaper"
WALL_IMG="$WALL/matrix-crt.png"
dl "$WALL_IMG" \
  "https://i.imgur.com/6Cp3C0R.png" \
  "https://raw.githubusercontent.com/adi1090x/wallpapers/master/minimalist/0018.png" || true

# --- Apply theme/wallpaper if XFCE is running (no error if not) ---
log "Applying XFCE theme and icons (if session is active)"
xfconf-query -c xsettings -p /Net/ThemeName     -s "$GTK_NAME"      2>/dev/null || true
xfconf-query -c xsettings -p /Net/IconThemeName -s "$ICON_NAME"     2>/dev/null || true
xfconf-query -c xfwm4     -p /general/theme     -s "$GTK_NAME"      2>/dev/null || true

for p in \
  /backdrop/screen0/monitor0/workspace0/last-image \
  /backdrop/screen0/monitor0/image-path \
  /backdrop/screen0/monitorDP-1/workspace0/last-image \
  /backdrop/screen0/monitorHDMI-1/workspace0/last-image \
; do
  xfconf-query -c xfce4-desktop -p "$p" -s "$WALL_IMG" 2>/dev/null || true
done

# --- Terminal: neon-green on black ---
log "Configuring XFCE Terminal profile"
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

# --- CRT alias ---
grep -q "alias crt=" "$HOME/.bashrc" || echo "alias crt='cool-retro-term >/dev/null 2>&1 & disown'" >> "$HOME/.bashrc"

log "Done. If you just installed XFCE, reboot; otherwise log out/in to see the theme."
