#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
GSI=${1:?usage: rom/assemble-package.sh LINEAGE_VNDKLITE_SYSTEM_IMAGE[.xz]}
OUT=${2:-$ROOT/out/f21-os-hardware-ready}
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
LOCK="$ROOT/rom/UPSTREAMS.lock"
[[ -f "$GSI" ]] || { echo "missing GSI: $GSI" >&2; exit 2; }
command -v debugfs >/dev/null

# 1. Verify the locked upstream hash, then decompress.
case "$GSI" in
  *.xz)
    want=$(sed -n 's/^lineage_gsi.xz_sha256=//p' "$LOCK")
    [[ -n "$want" ]] || { echo "lock file has no lineage_gsi.xz_sha256" >&2; exit 2; }
    got=$(sha256sum "$GSI" | awk '{print $1}')
    [[ "$got" == "$want" ]] || { echo "GSI hash mismatch: got $got, locked $want" >&2; exit 1; }
    xz -dc "$GSI" > "$WORK/system.img"
    ;;
  *) cp "$GSI" "$WORK/system.img" ;;
esac
IMG=$WORK/system.img

# 2. A sparse image cannot be written with debugfs; convert to raw first.
if [[ "$(od -An -tx1 -N4 "$IMG" | tr -d ' \n')" == "ed26ff3a" ]]; then
  command -v simg2img >/dev/null || { echo "sparse GSI but simg2img not found" >&2; exit 2; }
  simg2img "$IMG" "$WORK/system.raw.img"
  IMG=$WORK/system.raw.img
fi

# 3. Fetch the pinned F21 treble patch APKs.
PATCH=$WORK/patches; mkdir -p "$PATCH"
commit=$(sed -n 's/^f21_treble_patches.commit=//p' "$LOCK")
pdir=$(sed -n 's/^f21_treble_patches.path=//p' "$LOCK")
[[ -n "$commit" && -n "$pdir" ]] || { echo "lock file is missing f21_treble_patches pins" >&2; exit 2; }
for apk in bluetooth devinputjack; do
  curl -fsSL "https://raw.githubusercontent.com/AshiVered/Android-custom-ROMs/$commit/$pdir/$apk.apk" -o "$PATCH/$apk.apk"
done

# 4. Build the pinned T9 keyboard APK (default IME).
bash "$ROOT/rom/scripts/fetch-tt9.sh" "$ROOT/out/tt9"

# 5. Mutate the image: F21 overlays, debloat, then app injection.
bash "$ROOT/rom/scripts/apply-f21-patches.sh" "$IMG" "$PATCH"
bash "$ROOT/rom/scripts/debloat-image.sh" "$IMG"
bash "$ROOT/rom/scripts/inject-f21-apps.sh" "$IMG" \
  "$ROOT/out/tt9/TraditionalT9.apk" \
  "$ROOT/app/build/outputs/apk/debug/app-debug.apk" \
  "$ROOT/rom/prebuilts/privapp-permissions-f21os.xml"

# 6. Refuse to package an unpatched image: every payload must verify in-image.
for p in \
  /vendor/overlay/bluetooth/bluetooth.apk \
  /vendor/overlay/devinputjack/devinputjack.apk \
  /system/app/TraditionalT9/TraditionalT9.apk \
  /system/priv-app/F21Launcher/F21Launcher.apk \
  /system/etc/permissions/privapp-permissions-f21os.xml
do
  debugfs -R "stat $p" "$IMG" 2>/dev/null | grep -q 'Inode:' \
    || { echo "VERIFY FAIL: $p missing from the patched image" >&2; exit 1; }
done

# 7. Package the PATCHED image.
mkdir -p "$OUT/images" "$OUT/tools" "$OUT/docs"
cp "$IMG" "$OUT/images/f21-os-patched-lineage18.1-vndklite.img"
cp "$ROOT/rom/scripts/"*.sh "$OUT/tools/"
cp "$ROOT/docs/UNLOCK-FLASH-RESTORE.md" "$ROOT/docs/BUYING-GUIDE.md" "$OUT/docs/"
cp "$ROOT/rom/debloat-packages.txt" "$ROOT/rom/PACKAGE-MANIFEST.md" "$OUT/"
(
 cd "$OUT"
 find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS
)
tar -C "$(dirname "$OUT")" -czf "$OUT.tar.gz" "$(basename "$OUT")"
sha256sum "$OUT.tar.gz" > "$OUT.tar.gz.sha256"
echo "$OUT.tar.gz"
