#!/usr/bin/env bash
# import_primes.sh SRC_DIR [VMIN VMAX]
#
# Import plaintext CLERS prime files into primegen's data/prime layout.
# For each v in [VMIN, VMAX], looks for SRC_DIR/{v}.txt (one CLERS per
# line) and writes data/prime/{v}.txt.gz. Skips v's already present.
#
# Default VMIN=4, VMAX=80. The Makefile's recurrence (and verify_counts.sh)
# pick up the gzipped files automatically.
#
# Example:
#   scripts/import_primes.sh /home/doyle/neo/data/primes 4 60

set -eu
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

if [ $# -lt 1 ]; then
    echo "usage: $0 SRC_DIR [VMIN VMAX]" >&2
    exit 2
fi

SRC="$1"
VMIN="${2:-4}"
VMAX="${3:-80}"
DST="$ROOT/data/prime"
mkdir -p "$DST"

[ -d "$SRC" ] || { echo "error: $SRC not a directory" >&2; exit 1; }

imported=0
skipped=0
for v in $(seq "$VMIN" "$VMAX"); do
    out="$DST/${v}.txt.gz"
    if [ -f "$out" ]; then
        skipped=$((skipped + 1))
        continue
    fi
    src="$SRC/${v}.txt"
    if [ ! -f "$src" ]; then
        # Some v's may be missing from the source (e.g. v=5 has no primes
        # but the file should still be created as empty).
        if [ "$v" = 5 ]; then
            printf '' | gzip > "$out.tmp"
            mv "$out.tmp" "$out"
            echo "v=$v: 0 (empty placeholder)"
            imported=$((imported + 1))
        else
            echo "v=$v: SKIP, $src not found" >&2
        fi
        continue
    fi
    # Sort + uniq just in case the source isn't already in primegen's
    # canonical order; primegen always writes sort -u output.
    sort -u "$src" | gzip > "$out.tmp"
    mv "$out.tmp" "$out"
    n=$(gzip -dc "$out" | wc -l | tr -d ' ')
    echo "v=$v: $n (imported)"
    imported=$((imported + 1))
done

echo "[import_primes] imported=$imported  already_present=$skipped"
