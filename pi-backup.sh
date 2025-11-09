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

# Check space
AVAIL_MB=$(df -Pm "${DEST}" | awk 'NR==2{print $4}')
if [ "${AVAIL_MB}" -lt "${REQUIRED_MB}" ]; then
  echo "❌ ERROR: Not enough space (${AVAIL_MB} MiB free, need ${REQUIRED_MB})"
  exit 1
fi

# We need pv + pigz (parallel gzip)
sudo apt-get install -y pv pigz

# Exclude heavy and useless stuff
EXCLUDES=(
  "--exclude=${SRC}/Downloads/*.img"
  "--exclude=${SRC}/**/*.img"
  "--exclude=${SRC}/**/*.iso"
  "--exclude=${SRC}/**/*.zip"
  "--exclude=${SRC}/**/*.7z"
  "--exclude=${SRC}/**/*.xz"
  "--exclude=${SRC}/.cache"
  "--exclude=${SRC}/.local/share/Trash"
  "--exclude=${SRC}/.thumbnails"
  "--exclude=${SRC}/buildroot/output"
)

echo "⏳ Creating backup with progress bar (pv + pigz)…"

# tar -> pv -> pigz (parallel) -> file
tar -cf - "${EXCLUDES[@]}" \
  -C "${SRC%/*}" "${SRC##*/}" \
  | pv -s "$(du -sb "${SRC}" | awk '{print $1}')" \
  | pigz > "${OUT}"

echo "✅ Backup complete:"
ls -lh "${OUT}"
