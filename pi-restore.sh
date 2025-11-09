#!/usr/bin/env bash
set -euo pipefail

ARCHIVE="${1:-}"
TARGET="${HOME}"

if [ -z "${ARCHIVE}" ] || [ ! -f "${ARCHIVE}" ]; then
  echo "Usage: $0 /path/to/pi_home_backup_YYYY-MM-DD_HH-MM-SS.tgz"
  exit 1
fi

echo "📥 Restoring from: ${ARCHIVE}"
echo "→ Target: ${TARGET}"

# Ensure tools exist
sudo apt-get install -y pv pigz

# Safety: make sure no stupid extraction into wrong place
if [[ "${TARGET}" != "/home/pi" && "${TARGET}" != "$HOME" ]]; then
  echo "⚠️  WARNING: Target is not /home/pi"
  read -rp "Continue restore? (y/N) " confirm
  [[ "${confirm,,}" == "y" ]] || { echo "Aborted."; exit 1; }
fi

# Make sure home exists
sudo mkdir -p "${TARGET}"

# Show archive size before starting
ls -lh "${ARCHIVE}"

echo "⏳ Restoring with progress bar (pv + pigz)…"

# pigz -d decompresses, tar extracts, pv gives progress
pv "${ARCHIVE}" | pigz -d | sudo tar -xvf - -C / \
  --same-owner --preserve-permissions

echo
echo "✅ Restore complete!"
echo "You may want to reboot or log out/in to load restored configs."
