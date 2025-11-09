#!/usr/bin/env bash
set -euo pipefail

ARCHIVE="${1:-}"
TARGET="${HOME}"

if [ -z "${ARCHIVE}" ] || [ ! -f "${ARCHIVE}" ]; then
  echo "Usage: $0 /path/to/pi_home_backup_YYYY-MM-DD_HH-MM-SS.tgz"
  exit 1
fi

echo "==> Restoring ${ARCHIVE} to ${TARGET}"
# Safety: create target if missing
mkdir -p "${TARGET}"

# Extract to root (archive paths contain /home/pi/…)
sudo tar -xzf "${ARCHIVE}" -C / \
  --same-owner --preserve-permissions

echo "==> Restore complete."
