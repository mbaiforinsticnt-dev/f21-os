#!/usr/bin/env bash
# Builds the pinned Traditional T9 APK (English-only dictionaries) for image injection.
# Pin lives in rom/UPSTREAMS.lock (tt9.url / tt9.commit). Requires JDK 21 and network.
# The full flavor bundles 50+ dictionaries (~255MB); we ship English only, which is
# the same trim the t9-comparison CI validated in the emulator (9.8MB APK).
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT=${1:-$ROOT/../out/tt9}
LOCK=$ROOT/UPSTREAMS.lock
url=$(sed -n 's/^tt9.url=//p' "$LOCK")
commit=$(sed -n 's/^tt9.commit=//p' "$LOCK")
[[ -n "$url" && -n "$commit" ]] || { echo 'tt9 pin missing from UPSTREAMS.lock' >&2; exit 2; }
mkdir -p "$OUT"
if [[ ! -d "$OUT/src/.git" ]]; then git clone "$url" "$OUT/src"; fi
git -C "$OUT/src" fetch origin
git -C "$OUT/src" checkout --detach "$commit"
find "$OUT/src/app/languages/definitions" -name '*.yml' ! -name 'English.yml' -delete
cd "$OUT/src"
chmod +x gradlew
./gradlew --no-daemon generateDocs validateLanguages buildDefinition buildDictionaryDownloads copyDownloadsToAssets assembleFullDebug
apk=$(find app/build/outputs/apk -name '*.apk' | head -n 1)
[[ -f "$apk" ]] || { echo 'tt9 build produced no APK' >&2; exit 1; }
cp "$apk" "$OUT/TraditionalT9.apk"
sha256sum "$OUT/TraditionalT9.apk"
echo "$OUT/TraditionalT9.apk"
