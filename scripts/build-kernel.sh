#!/usr/bin/env bash
set -euo pipefail

# build-kernel.sh — compile & stage a Raspberry Pi 64-bit kernel for Pi 4
# - Builds Image/modules/DTBs
# - Stages a bootable tree alongside firmware/boot files
# - Leaves your system untouched (no sudo install unless you ask)

# Defaults (override with flags/env)
KDIR="${KERNEL_DIR:-$HOME/raspberrypi-linux}"
FWDIR="${FW_DIR:-$HOME/rpi-firmware}"           # from the sparse+shallow clone
OUT="${OUT_DIR:-$HOME/kernel-out}"              # staging root for artifacts
DEFCONFIG="${DEFCONFIG:-bcm2711_defconfig}"     # Pi 4
JOBS="${JOBS:-$(nproc)}"
INSTALL_MODPATH=""                               # if set, will run modules_install here (e.g. --modules-out /tmp/rootfs)

usage() {
  cat <<EOF
Usage: $0 [--kernel-dir <path>] [--firmware-dir <path>] [--out <path>]
          [--defconfig <bcm2711_defconfig>] [--jobs N]
          [--modules-out <path>]

Examples:
  $0
  $0 --defconfig bcm2711_defconfig --jobs 6
  $0 --modules-out \$HOME/kernel-out/rootfs

Notes:
- Expects a 64-bit kernel tree (arch/arm64) at --kernel-dir
- Uses firmware boot files from --firmware-dir/boot
- Stages:
    \$OUT/boot/    (boot partition content: start4.elf, fixup4.dat, cmdline.txt, config.txt, Image, DTBs, overlays)
    \$OUT/rootfs/  (optional modules if --modules-out given)
EOF
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --kernel-dir)     KDIR="$2"; shift 2 ;;
    --firmware-dir)   FWDIR="$2"; shift 2 ;;
    --out)            OUT="$2"; shift 2 ;;
    --defconfig)      DEFCONFIG="$2"; shift 2 ;;
    --jobs)           JOBS="$2"; shift 2 ;;
    --modules-out)    INSTALL_MODPATH="$2"; shift 2 ;;
    -h|--help)        usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 1 ;;
  esac
done

# Sanity
[[ -d "$KDIR" ]] || { echo "Kernel dir not found: $KDIR"; exit 1; }
[[ -d "$FWDIR/boot" ]] || { echo "Firmware boot dir not found: $FWDIR/boot"; exit 1; }

mkdir -p "$OUT/boot"
echo "[i] Kernel:   $KDIR"
echo "[i] Firmware: $FWDIR/boot"
echo "[i] Out:      $OUT"

pushd "$KDIR" >/dev/null

# 1) Configure
if [[ ! -f ".config" ]]; then
  echo "[+] make ${DEFCONFIG}"
  make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- "${DEFCONFIG}"
fi

# 2) Build
echo "[+] Building kernel Image, modules, dtbs (jobs: $JOBS)…"
make -j"$JOBS" ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image dtbs modules

# 3) Capture kernel release
KREL="$(make ARCH=arm64 kernelrelease)"
echo "[i] kernelrelease: $KREL"

# 4) Stage /boot
BOOT="$OUT/boot"
mkdir -p "$BOOT/overlays"
echo "[+] Staging /boot to $BOOT"

#   4a) Copy firmware "boot" files (lightweight sparse clone: start4.elf, fixup4.dat, overlays/*, etc.)
rsync -a --delete \
  "$FWDIR/boot/" "$BOOT/"

#   4b) Replace kernel+DTBs with our freshly built ones
install -Dm0644 "arch/arm64/boot/Image" "$BOOT/Image"
# Kernel alias for Pi firmware (kernel8.img)
ln -sf Image "$BOOT/kernel8.img"

# Pi 4 DTB(s)
for dtb in arch/arm64/boot/dts/broadcom/bcm2711-rpi-4-*.dtb; do
  install -Dm0644 "$dtb" "$BOOT/$(basename "$dtb")"
done

# Overlays (.dtbo)
rsync -a arch/arm64/boot/dts/overlays/*.dtbo "$BOOT/overlays/" 2>/dev/null || true
# Keep firmware overlays that aren’t in our build as a fallback
# (already present from firmware rsync)

#   4c) Ensure minimal cmdline.txt / config.txt exist if missing
if [[ ! -f "$BOOT/cmdline.txt" ]]; then
  echo "[+] Writing default cmdline.txt"
  cat > "$BOOT/cmdline.txt" <<'CMD'
console=serial0,115200 console=tty1 root=PARTUUID=XXXXXXXX-02 rootfstype=ext4 fsck.repair=yes rootwait
CMD
fi

if [[ ! -f "$BOOT/config.txt" ]]; then
  echo "[+] Writing default config.txt"
  cat > "$BOOT/config.txt" <<'CFG'
arm_64bit=1
kernel=kernel8.img
enable_uart=1
[pi4]
dtoverlay=vc4-kms-v3d
max_framebuffers=2
[all]
CFG
fi

# 5) Modules (optional)
if [[ -n "$INSTALL_MODPATH" ]]; then
  echo "[+] Installing modules to $INSTALL_MODPATH (no root needed)"
  mkdir -p "$INSTALL_MODPATH"
  make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- \
    INSTALL_MOD_PATH="$INSTALL_MODPATH" modules_install
  # Strip debug symbols for space (optional)
  find "$INSTALL_MODPATH/lib/modules/$KREL" -name '*.ko' -exec strip --strip-debug {} + 2>/dev/null || true
fi

popd >/dev/null

# 6) Manifest
MAN="$OUT/manifest.txt"
{
  echo "Kernel dir:   $KDIR"
  echo "Firmware dir: $FWDIR"
  echo "Out:          $OUT"
  echo "kernelrelease:$KREL"
  echo "Built:        $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo
  echo "[/boot contents]"
  (cd "$OUT/boot" && find . -maxdepth 2 -type f | sort)
  [[ -n "${INSTALL_MODPATH}" ]] && {
    echo
    echo "[modules]"
    find "$INSTALL_MODPATH/lib/modules/$KREL" -type f | sort
  }
} > "$MAN"

echo
echo "[✓] Done."
echo "    Boot tree : $OUT/boot"
[[ -n "$INSTALL_MODPATH" ]] && echo "    Modules   : $INSTALL_MODPATH/lib/modules/$KREL"
echo "    Manifest  : $MAN"

cat <<'TIP'

Next:
- To update a mounted /boot on the Pi’s boot partition:
    sudo rsync -a --delete $OUT/boot/ /boot/firmware/
  (or /boot on some distros)

- If you staged modules to a rootfs:
    sudo rsync -a $OUT/rootfs/ /       # merges /lib/modules/<ver>

- If you’re making an image: use genimage or your SD-card writer to put
  $OUT/boot into the boot partition, and include modules in your rootfs.

TIP
