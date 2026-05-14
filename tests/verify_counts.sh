#!/usr/bin/env bash
# verify_counts.sh -- compare data/prime/{v}.txt.gz line counts to
# tests/expected_counts.tsv. Fails (exit 1) on any mismatch in the
# range [VMIN, VMAX] (defaults: 4, the largest v in the expected file).
#
# Usage:
#   tests/verify_counts.sh                 # check all expected v
#   tests/verify_counts.sh 4 20            # check v=4..20

set -eu
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
EXP="$HERE/expected_counts.tsv"
PRIME="$ROOT/data/prime"

VMIN="${1:-4}"
VMAX="${2:-$(awk 'NR>1 {print $1}' "$EXP" | sort -n | tail -1)}"

fail=0
while IFS=$'\t' read -r v expected; do
    [ "$v" = v ] && continue
    [ "$v" -lt "$VMIN" ] && continue
    [ "$v" -gt "$VMAX" ] && continue
    gz="$PRIME/${v}.txt.gz"
    if [ ! -f "$gz" ]; then
        echo "v=$v: MISSING $gz"
        fail=1
        continue
    fi
    got=$(gzip -dc "$gz" | wc -l | tr -d ' ')
    if [ "$got" -ne "$expected" ]; then
        echo "v=$v: FAIL got=$got expected=$expected"
        fail=1
    else
        echo "v=$v: ok ($got)"
    fi
done < "$EXP"

if [ "$fail" -eq 0 ]; then
    echo "[verify_counts] PASS v=$VMIN..$VMAX"
else
    echo "[verify_counts] FAIL" >&2
    exit 1
fi
