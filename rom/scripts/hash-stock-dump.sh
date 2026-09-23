#!/usr/bin/env bash
set -euo pipefail
DUMP=${1:?usage: hash-stock-dump.sh STOCK_DUMP_DIRECTORY}
# Exclude SHA256SUMS itself: a re-run must not hash its own earlier output.
find "$DUMP" -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > "$DUMP/SHA256SUMS"
sha256sum -c "$DUMP/SHA256SUMS"
