#!/usr/bin/env bash
#
# Regenerate the self-hosted JetBrains Mono subset shipped in public/fonts/.
# Each weight is cut down to Latin + punctuation + arrows and re-packed as WOFF2,
# taking the family from ~270 KB/weight (TTF) to ~13 KB/weight.
#
# Requires: python3, fonttools, brotli
#   pip install fonttools brotli
#
# Usage:
#   bash scripts/optimize-fonts.sh           # uses JetBrains Mono @ master
#   JBM_VERSION=v2.304 bash scripts/optimize-fonts.sh

set -euo pipefail

VERSION="${JBM_VERSION:-master}"
BASE="https://raw.githubusercontent.com/JetBrains/JetBrainsMono/${VERSION}/fonts/ttf"

# ASCII + Latin-1 (© ·), dashes/quotes/ellipsis/bullet, arrows (→ ↗)
RANGE="U+0020-00FF,U+2010-2014,U+2018-201A,U+201C-201E,U+2022,U+2026,U+2190-2199"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/public/fonts"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$OUT"

declare -A WEIGHT=( [Regular]=400 [Medium]=500 [Bold]=700 )

for name in Regular Medium Bold; do
  w="${WEIGHT[$name]}"
  echo "→ JetBrainsMono-$name ($w)"
  curl -fsSL "$BASE/JetBrainsMono-$name.ttf" -o "$TMP/$name.ttf"
  python3 -m fontTools.subset "$TMP/$name.ttf" \
    --unicodes="$RANGE" \
    --layout-features='' \
    --name-IDs='' \
    --flavor=woff2 \
    --output-file="$OUT/jetbrains-mono-$w.woff2"
  printf "   jetbrains-mono-%s.woff2  %s bytes\n" "$w" "$(stat -c%s "$OUT/jetbrains-mono-$w.woff2")"
done

echo "Done → $OUT"
