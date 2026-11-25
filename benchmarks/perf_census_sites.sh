#!/bin/sh
# One census run of the drain with the per-caller tables on, then the
# top copy / push / retain sites resolved to symbols. Linux uses
# addr2line, macOS atos; the program binary is still standing here.
set -eu
cd "$(dirname "$0")/.."
prog=benchmarks/tasks/drain/avra/src/main
n=${N:-10000}
cap=${CAP:-64}

make -s libs
out=$(AVRA_CENSUS_SITES=1 AVRA_ALIAS_LOG=1 \
    BENCH_SMALL=1 BENCH_N="$n" BENCH_ROUNDS=1 BENCH_CAP="$cap" \
    make census-types PROGRAM="$prog.av" 2>&1) || true
printf '%s\n' "$out"
echo '===== RESOLVED SITES (n='"$n"' cap='"$cap"') ====='
printf '%s\n' "$out" | awk '/^(copy|push|retain): site /{print $3}' | sort -u | while read -r a; do
    if command -v atos > /dev/null 2>&1; then
        name=$(atos -o "$prog" "$a" 2>/dev/null | head -1)
    else
        name=$(addr2line -f -e "$prog" "$a" 2>/dev/null | head -1)
    fi
    echo "$a $name"
done
