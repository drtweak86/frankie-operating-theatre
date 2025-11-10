#!/usr/bin/env bash
set -euo pipefail

# ────────────────────────────────────────────────────────────
# Prestage for Frankie (Pi HTPC) — minimal, shallow, sparse
# Sections covered:
# 1) pick best kernel (default rpi-6.6.y)
# 2) fix giant firmware clone (sparse, shallow)
# 3) clone kernel shallow
# 4) optional lean tools
# 5) install build deps (optional)
# 6) disk sanity checks
# 7) print next steps
# ────────────────────────────────────────────────────────────

# Defaults (override with flags)
KERNEL_BRANCH="${KERNEL_BRANCH:-rpi-6.6.y}"   # rpi-6.6.y is stable sweet spot
FW_DIR="${FW_DIR:-$HOME/rpi-firmware}"
KERNEL_DIR="${KERNEL_DIR:-$HOME/raspberrypi-linux}"
TOOLS_DIR="${TOOLS_DIR:-$HOME/rpi-tools}"
WITH_TOOLS="0"
INSTALL_DEPS="1"
PLATFORM="pi4"  # currently informational

usage() {
  cat <<EOF
Usage: $0 [--kernel <rpi-6.6.y|rpi-6.12.y|rpi-6.1.y>] [--with-tools] [--no-deps]
             [--fw-dir <path>] [--kernel-dir <path>] [--tools-dir <path>]

Examples:
  $0
  $0 --kernel rpi-6.12.y --with-tools
  KERNEL_BRANCH=rpi-6.1.y $0 --no-deps

EOF
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --kernel)       KERNEL_BRANCH="$2"; shift 2 ;;
    --with-tools)   WITH_TOOLS="1"; shift ;;
    --no-deps)      INSTALL_DEPS="0"; shift ;;
    --fw-dir)       FW_DIR="$2"; shift 2 ;;
    --kernel-dir)   KERNEL_DIR="$2"; shift 2 ;;
    --tools-dir)    TOOLS_DIR="$2"; shift 2 ;;
    -h|--help)      usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 1 ;;
  esac
done

echo "[1] Kernel branch: ${KERNEL_BRANCH}"
echo "[i] Target dirs: FW=${FW_DIR}  KERNEL=${KERNEL_DIR}  TOOLS=${TOOLS_DIR}"

# ── prereqs ─────────────────────────────────────────────────
command -v git >/dev/null || { echo "git is required"; exit 1; }

if [[ "$INSTALL_DEPS" == "1" ]]; then
  echo "[5] Installing build deps (Ubuntu/Debian)…"
  sudo apt-get update -y
  sudo apt-get install -y \
    build-essential bc bison flex libssl-dev libelf-dev \
    libncurses5-dev libncursesw5-dev dwarves \
    mtools dosfstools parted genimage xz-utils zstd squashfs-tools pigz \
    gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
    qemu-user-static
else
  echo "[5] Skipping deps install (--no-deps)"
fi

# ── helpers ─────────────────────────────────────────────────
safe_rm_git_dir () {
  local path="$1"
  if [[ -d "$path/.git" ]]; then
    echo "  - removing previous git dir: $path"
    rm -rf "$path"
  fi
}

human_du () {
  du -sh "$1" 2>/dev/null | awk '{print $1}'
}

# ── 2) Firmware: sparse+shallow ────────────────────────────
echo "[2] Preparing rpi-firmware (sparse+shallow: boot only)…"
safe_rm_git_dir "$FW_DIR"
git clone --depth=1 --filter=blob:none --sparse https://github.com/raspberrypi/firmware.git "$FW_DIR"
(
  cd "$FW_DIR"
  git sparse-checkout set boot
)
echo "    firmware size: $(human_du "$FW_DIR")  (expect << 100MB)"

# ── 3) Kernel: shallow on chosen branch ─────────────────────
echo "[3] Cloning kernel (branch ${KERNEL_BRANCH}, depth=1)…"
safe_rm_git_dir "$KERNEL_DIR"
git clone --depth=1 --branch "$KERNEL_BRANCH" https://github.com/raspberrypi/linux.git "$KERNEL_DIR"
echo "    kernel size:   $(human_du "$KERNEL_DIR")"

# ── 4) Optional tools: shallow/lean ─────────────────────────
if [[ "$WITH_TOOLS" == "1" ]]; then
  echo "[4] Cloning rpi-tools (lean)…"
  safe_rm_git_dir "$TOOLS_DIR"
  git clone --depth=1 --filter=blob:none https://github.com/raspberrypi/tools.git "$TOOLS_DIR"
  echo "    tools size:    $(human_du "$TOOLS_DIR")"
else
  echo "[4] Skipping rpi-tools (--with-tools to enable)"
fi

# ── 6) Disk sanity check ────────────────────────────────────
echo "[6] Disk sanity (top 10 in \$HOME)…"
du -hxd1 "$HOME" 2>/dev/null | sort -h | tail -n 10 || true

# ── 7) Next steps (for Pi 4) ────────────────────────────────
cat <<'NEXT'

[7] Next steps — build for Pi 4:
  cd ~/raspberrypi-linux
  make bcm2711_defconfig
  # Optional: make menuconfig
  make -j$(nproc) Image modules dtbs

Artifacts of interest:
  - arch/arm64/boot/Image
  - arch/arm64/boot/dts/broadcom/*.dtb     (e.g. bcm2711-rpi-4-b.dtb)
  - arch/arm64/boot/dts/overlays/*.dtbo
  - modules in:  modules_install → /lib/modules/<version>

Boot staging model:
  - /boot (from firmware repo: ~/rpi-firmware/boot/*)
  - Kernel image & DTBs from build above
  - overlays from build above (or keep firmware overlays if desired)

Tip:
  Keep firmware shallow+sparse. If you need extra files temporarily:
    cd ~/rpi-firmware && git sparse-checkout add boot/overlays
  (Then remove again to keep it lean.)

All set. No 50GB blobs were harmed. 🧪
NEXT
