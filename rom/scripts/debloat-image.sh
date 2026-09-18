#!/usr/bin/env bash
set -euo pipefail
# Apply to an unpacked, writable system tree during image assembly, never to the stock phone.
ROOT=${1:?usage: debloat-image.sh UNPACKED_SYSTEM_ROOT}
LIST=${2:-$(dirname "$0")/../debloat-packages.txt}
case "$ROOT" in /|/system|/vendor) echo "refusing unsafe root: $ROOT" >&2; exit 2;; esac
while IFS= read -r pkg; do
  [[ -z "$pkg" || "$pkg" == \#* ]] && continue
  while IFS= read -r -d '' apk; do
    appdir=$(dirname "$apk")
    echo "remove $pkg: $appdir"
    rm -rf -- "$appdir"
  done < <(find "$ROOT" -type f -name '*.apk' -print0 | while IFS= read -r -d '' apk; do
    if command -v aapt2 >/dev/null && aapt2 dump badging "$apk" 2>/dev/null | grep -q "package: name='$pkg'"; then printf '%s\0' "$apk"; fi
  done)
done < "$LIST"
