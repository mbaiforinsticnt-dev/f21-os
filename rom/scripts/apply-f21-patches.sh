#!/usr/bin/env bash
set -euo pipefail
IMG=${1:?usage: apply-f21-patches.sh SYSTEM_EXT_IMAGE PATCH_DIR}
PATCH=${2:?usage: apply-f21-patches.sh SYSTEM_EXT_IMAGE PATCH_DIR}
[[ -f "$IMG" && -f "$PATCH/bluetooth.apk" && -f "$PATCH/devinputjack.apk" ]] || { echo 'missing image or patch APKs' >&2; exit 2; }
command -v debugfs >/dev/null
# The GSI system image mounts as /; F21 overlays therefore land at /vendor/overlay when that compatibility path exists.
for d in /vendor /vendor/overlay /vendor/overlay/bluetooth /vendor/overlay/devinputjack; do
  debugfs -w -R "mkdir $d" "$IMG" >/dev/null 2>&1 || true
done
debugfs -w -R "rm /vendor/overlay/bluetooth/bluetooth.apk" "$IMG" >/dev/null 2>&1 || true
debugfs -w -R "rm /vendor/overlay/devinputjack/devinputjack.apk" "$IMG" >/dev/null 2>&1 || true
debugfs -w -R "write $PATCH/bluetooth.apk /vendor/overlay/bluetooth/bluetooth.apk" "$IMG"
debugfs -w -R "write $PATCH/devinputjack.apk /vendor/overlay/devinputjack/devinputjack.apk" "$IMG"
for x in /vendor/overlay/bluetooth/bluetooth.apk /vendor/overlay/devinputjack/devinputjack.apk; do debugfs -w -R "set_inode_field $x mode 0100644" "$IMG" >/dev/null; done
# Build properties are appended only when absent.
tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
debugfs -R 'cat /system/build.prop' "$IMG" 2>/dev/null > "$tmp" || debugfs -R 'cat /build.prop' "$IMG" 2>/dev/null > "$tmp"
grep -q '^persist.sys.overlay.devinputjack=true$' "$tmp" || printf '\npersist.sys.overlay.devinputjack=true\n' >> "$tmp"
grep -q '^persist.sys.phh.disable_a2dp_offload=true$' "$tmp" || printf 'persist.sys.phh.disable_a2dp_offload=true\n' >> "$tmp"
if debugfs -R 'stat /system/build.prop' "$IMG" 2>/dev/null | grep -q Inode; then bp=/system/build.prop; else bp=/build.prop; fi
debugfs -w -R "rm $bp" "$IMG" >/dev/null
debugfs -w -R "write $tmp $bp" "$IMG" >/dev/null
e2fsck -fy "$IMG"
