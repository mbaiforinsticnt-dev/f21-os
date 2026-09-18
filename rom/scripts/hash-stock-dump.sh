#!/usr/bin/env bash
set -euo pipefail
DUMP=${1:?usage: hash-stock-dump.sh STOCK_DUMP_DIRECTORY}
find "$DUMP" -type f -print0 | sort -z | xargs -0 sha256sum | tee "$DUMP/SHA256SUMS"
sha256sum -c "$DUMP/SHA256SUMS"
