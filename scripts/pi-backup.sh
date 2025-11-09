#!/usr/bin/env bash
set -euo pipefail

USER_NAME="${SUDO_USER:-$USER}"
HOME_DIR="$(getent passwd "$USER_NAME" | cut -d: -f6)"
DEST="${1:-${HOME_DIR}/Backups}"
TS="$(date +%F_%H-%M-%S)"
ARCHIVE="${DEST}/home_${USER_NAME}_backup_${TS}.tgz"

echo ">> Backing up home: ${HOME_DIR}"
echo ">> Destination dir: ${DEST}"
mkdir -p "${DEST}"

# Excludes to keep backups lean
EXCLUDES=(
  --exclude='.cache'
  --exclude='.local/share/Trash'
  --exclude='.npm/_cacache'
  --exclude='.cargo/.package-cache'
  --exclude='.config/Code/Cache'
  --exclude='Downloads/*.iso'
  --exclude='*.img'
  --exclude='*.img.xz'
)

# Estimate size (best effort) for friendly heads-up
EST=$(du -sh "${HOME_DIR}" 2>/dev/null | awk '{print $1}')
echo ">> Estimated source size (uncompressed): ${EST:-unknown}"

# Create archive with progress if pv is available
echo ">> Creating: ${ARCHIVE}"
if command -v pv >/dev/null 2>&1; then
  tar -C "${HOME_DIR}" -czf - "${EXCLUDES[@]}" . | pv > "${ARCHIVE}"
else
  tar -C "${HOME_DIR}" -czf "${ARCHIVE}" "${EXCLUDES[@]}" .
fi

chmod 600 "${ARCHIVE}"
echo "✅ Backup complete:"
ls -lh "${ARCHIVE}"
