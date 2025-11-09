#!/usr/bin/env bash
set -euo pipefail

DEST="${1:-$HOME/Backups}"
TS="$(date +%F_%H-%M-%S)"
mkdir -p "$DEST"

ARCHIVE="${DEST}/pi_home_backup_${TS}.tgz"
echo "=== Backing up /home/pi to ${ARCHIVE} ==="

EXCLUDES=(
  --exclude="$HOME/.cache"
  --exclude="$HOME/.local/share/Trash"
  --exclude="$HOME/.npm/_cacache"
  --exclude="$HOME/.cargo/.package-cache"
  --exclude="$HOME/.config/Code/Cache"
)
if command -v pv >/dev/null 2>&1; then
  tar -czf - -C / home/pi "${EXCLUDES[@]}" | pv > "${ARCHIVE}"
else
  tar -czf "${ARCHIVE}" -C / home/pi "${EXCLUDES[@]}"
fi

echo "=== Done:"
ls -lh "${ARCHIVE}"
