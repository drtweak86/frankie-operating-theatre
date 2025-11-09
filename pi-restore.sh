#!/usr/bin/env bash
set -euo pipefail

USER_NAME="${SUDO_USER:-$USER}"
HOME_DIR="$(getent passwd "$USER_NAME" | cut -d: -f6)"

ARCHIVE="${1:-}"
[[ -z "${ARCHIVE}" ]] && { echo "Usage: $0 /path/to/home_<user>_backup_YYYY-MM-DD_HH-MM-SS.tgz"; exit 1; }
[[ -f "${ARCHIVE}" ]] || { echo "Archive not found: ${ARCHIVE}"; exit 2; }

echo ">> Restoring archive: ${ARCHIVE}"
echo ">> Target HOME     : ${HOME_DIR}"
read -rp "Proceed? (y/N) " yn
[[ "${yn,,}" == "y" ]] || { echo "Aborted."; exit 0; }

# Extract into HOME; use sudo to preserve original perms/owner where present,
# then enforce ownership to the target user to be safe.
sudo tar -xzvf "${ARCHIVE}" -C "${HOME_DIR}"
sudo chown -R "${USER_NAME}:${USER_NAME}" "${HOME_DIR}"

echo "✅ Restore complete. A reboot/logout is recommended."
