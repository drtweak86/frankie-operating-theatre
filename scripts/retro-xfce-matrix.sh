#!/usr/bin/env bash
set -e

echo "[+] Matrix XFCE: packages"
sudo apt update
# Desktop if missing
command -v startxfce4 >/dev/null 2>&1 || sudo apt install -y xubuntu-desktop
# Fonts & goodies
sudo apt install -y fonts-jetbrains-mono fonts-hack fonts-terminus cool-retro-term

echo "[+] Matrix XFCE: themes"
mkdir -p "$HOME/.themes" "$HOME/.icons" "$HOME/Pictures/Wallpapers"
cd "$HOME/.themes"
wget -q https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme/releases/download/v2023-09-20/Gruvbox-Green-Dark.tar.xz -O ggtk.txz
tar -xf ggtk.txz && rm -f ggtk.txz
cd "$HOME/.icons"
wget -q https://github.com/Fausto-Korpsvart/Gruvbox-Icons/releases/download/v2023-09-20/Gruvbox-Dark-Green.tar.xz -O gicons.txz
tar -xf gicons.txz && rm -f gicons.txz

echo "[+] Matrix XFCE: wallpaper"
wget -q -O "$HOME/Pictures/Wallpapers/matrix-crt.png" "https://i.imgur.com/6Cp3C0R.png" || true

# Apply theme via xfconf (harmless if run outside X)
THEME="Gruvbox-Green-Dark"
ICONS="Gruvbox-Dark-Green"
echo "[+] Applying themes (if XFCE session active)"
xfconf-query -c xsettings -p /Net/ThemeName      -s "$THEME"           2>/dev/null || true
xfconf-query -c xsettings -p /Net/IconThemeName  -s "$ICONS"           2>/dev/null || true
xfconf-query -c xfwm4     -p /general/theme      -s "$THEME"           2>/dev/null || true

# Set wallpaper on primary display (common path); safe if property exists
for p in /backdrop/screen0/monitor0/workspace0/last-image \
         /backdrop/screen0/monitor0/image-path; do
  xfconf-query -c xfce4-desktop -p "$p" -s "$HOME/Pictures/Wallpapers/matrix-crt.png" 2>/dev/null || true
done

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

# Cool tip: alias for CRT-look terminal
grep -q "alias crt=" "$HOME/.bashrc" || echo "alias crt='cool-retro-term >/dev/null 2>&1 & disown'" >> "$HOME/.bashrc"

echo "[✓] Matrix XFCE ready. If you just installed the desktop, reboot."
