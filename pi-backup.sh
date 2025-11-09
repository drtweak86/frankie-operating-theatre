#!/usr/bin/env bash
set -euo pipefail

USER_HOME="${HOME}"
SRC="${USER_HOME}"
DEST="${1:-${USER_HOME}}"
STAMP="$(date +%Y-%m-%d_%H-%M-%S)"
OUT="${DEST}/pi_home_backup_${STAMP}.tgz"

REQUIRED_MB=2048

echo "📦  Backing up ${SRC} → ${OUT}"

mkdir -p "${DEST}"
test -w "${DEST}" || { echo "❌ ERROR: Cannot write to ${DEST}"; exit 1; }

AVAIL_MB=$(df -Pm "${DEST}" | awk 'NR==2{print $4}')
if [ "${AVAIL_MB}" -lt "${REQUIRED_MB}" ]; then
  echo "❌ ERROR: Not enough space (${AVAIL_MB} MiB free, need ${REQUIRED_MB})"
  exit 1
fi

EXCLUDES=(
  "--exclude=${SRC}/Downloads/*.img"
  "--exclude=${SRC}/**/*.img"
  "--exclude=${SRC}/**/*.iso"
  "--exclude=${SRC}/**/*.vfat"
  "--exclude=${SRC}/**/*.zip"
  "--exclude=${SRC}/**/*.7z"
  "--exclude=${SRC}/**/*.xz"
  "--exclude=${SRC}/**/*.tar"
  "--exclude=${SRC}/**/*.tgz"
  "--exclude=${SRC}/.cache"
  "--exclude=${SRC}/.local/share/Trash"
  "--exclude=${SRC}/.thumbnails"
  "--exclude=${SRC}/**/node_modules"
  "--exclude=${SRC}/buildroot/output"
  "--exclude=${SRC}/**/output"
  "--exclude=${SRC}/**/cache"
  "--exclude=${SRC}/**/.gradle"
  "--exclude=${SRC}/**/.venv"
)

echo "➡️  Creating archive..."
tar -czf "${OUT}" "${EXCLUDES[@]}" \
  --warning=no-file-changed \
  -C "${SRC%/*}" "${SRC##*/}"

echo "✅ Backup complete:"
ls -lh "${OUT}"
