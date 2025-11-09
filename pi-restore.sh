#!/usr/bin/env bash
set -euo pipefail

ARCHIVE="${1:-}"
[[ -z "$ARCHIVE" ]] && { echo "Usage: $0 /path/to/pi_home_backup_YYYY-MM-DD_HH-MM-SS.tgz"; exit 1; }
[[ -f "$ARCHIVE" ]] || { echo "Archive not found: $ARCHIVE"; exit 2; }

echo "=== Restoring ${ARCHIVE} to / (will place files under /home/pi) ==="
sudo tar -xzvf "$ARCHIVE" -C /
sudo chown -R pi:pi /home/pi || true
echo "=== Restore complete. Consider rebooting. ==="
