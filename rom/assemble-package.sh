#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
GSI=${1:?usage: rom/assemble-package.sh LINEAGE_VNDKLITE_SYSTEM_IMAGE}
OUT=${2:-$ROOT/out/f21-os-hardware-ready}
[[ -f "$GSI" ]] || { echo "missing GSI: $GSI" >&2; exit 2; }
mkdir -p "$OUT/images" "$OUT/tools" "$OUT/docs"
cp "$GSI" "$OUT/images/system-lineage18.1-vndklite.img"
cp "$ROOT/app/build/outputs/apk/debug/app-debug.apk" "$OUT/f21-os-launcher.apk"
cp "$ROOT/rom/debloat-packages.txt" "$ROOT/rom/PACKAGE-MANIFEST.md" "$OUT/"
cp "$ROOT/rom/scripts/"*.sh "$OUT/tools/"
cp "$ROOT/docs/UNLOCK-FLASH-RESTORE.md" "$ROOT/docs/BUYING-GUIDE.md" "$OUT/docs/"
(
 cd "$OUT"
 find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS
)
tar -C "$(dirname "$OUT")" -czf "$OUT.tar.gz" "$(basename "$OUT")"
sha256sum "$OUT.tar.gz" > "$OUT.tar.gz.sha256"
echo "$OUT.tar.gz"
