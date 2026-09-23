#!/usr/bin/env bash
set -euo pipefail
# Debloat an unpacked system tree (rm -rf) or a raw ext4 system image (debugfs).
# Never point this at the stock phone.
TARGET=${1:?usage: debloat-image.sh UNPACKED_SYSTEM_ROOT|SYSTEM_IMAGE_FILE}
LIST=${2:-$(dirname "$0")/../debloat-packages.txt}
command -v aapt2 >/dev/null || { echo 'aapt2 not found; cannot identify packages, skipping debloat' >&2; exit 0; }

debloat_tree() { # ROOT
  local ROOT=$1 pkg apk
  case "$ROOT" in /|/system|/vendor) echo "refusing unsafe root: $ROOT" >&2; exit 2;; esac
  while IFS= read -r pkg; do
    [[ -z "$pkg" || "$pkg" == \#* ]] && continue
    while IFS= read -r -d '' apk; do
      if aapt2 dump badging "$apk" 2>/dev/null | grep -q "package: name='$pkg'"; then
        echo "remove $pkg: $(dirname "$apk")"
        rm -rf -- "$(dirname "$apk")"
      fi
    done < <(find "$ROOT" -type f -name '*.apk' -print0)
  done < "$LIST"
}

if [[ -d "$TARGET" ]]; then
  debloat_tree "$TARGET"
  exit 0
fi

# Image path: extract app dirs, debloat the copy, mirror the removals back in.
IMG=$TARGET
[[ -f "$IMG" ]] || { echo "missing target: $TARGET" >&2; exit 2; }
case "$IMG" in /dev/*) echo "refusing unsafe image: $IMG" >&2; exit 2;; esac
command -v debugfs >/dev/null
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
TREE=$WORK/tree; mkdir -p "$TREE"
for d in /system/app /system/priv-app /system/product/app /system/product/priv-app /system/system_ext/app /vendor/app; do
  if debugfs -R "stat $d" "$IMG" 2>/dev/null | grep -q 'Inode:'; then
    mkdir -p "$TREE$(dirname "$d")"
    debugfs -R "rdump $d $TREE$(dirname "$d")" "$IMG" >/dev/null 2>&1
  fi
done
snapshot() { ( cd "$TREE" && find . -mindepth 1 -printf '%y %p\n' | sort -k2 ); }
snapshot > "$WORK/before"
debloat_tree "$TREE"
snapshot > "$WORK/after"
# Files/symlinks that vanished: rm from the image.
comm -23 <(awk '$1!="d"' "$WORK/before") <(awk '$1!="d"' "$WORK/after") \
  | sed 's/^[a-z] \.//' \
  | while IFS= read -r p; do debugfs -w -R "rm $p" "$IMG" >/dev/null; done
# Directories that vanished: rmdir deepest first.
comm -23 <(awk '$1=="d" {print substr($0,4)}' "$WORK/before") <(awk '$1=="d" {print substr($0,4)}' "$WORK/after") \
  | awk '{print gsub(/\//,"/"), $0}' | sort -rn | cut -d' ' -f2- \
  | sed 's/^\.//' \
  | while IFS= read -r p; do debugfs -w -R "rmdir $p" "$IMG" >/dev/null 2>&1 || true; done
e2fsck -fy "$IMG" >/dev/null
echo "debloat mirrored into $IMG"
