#!/bin/sh
# WHAT A CHANGE COSTS TO PROVE, AS A SHARE OF WHAT THE STORE HOLDS. One literal in one body of the cli
# edited and built warm: the changed input reaches most of the program's answers by reading, and each
# reached answer this build asks is proved — its reads read — before it is taken as it stands. The
# warm build's `cutoff:` line (`AVRA_QUERY_TIMES`) says how many answers the frontier held, how many
# the change reached past the cuts that stood, how many were proved and how many reads that read. The
# ceilings in tools/cutoff.ceiling are shares of what the frontier held, never counts, so they hold
# as the program grows: per ten thousand answers held, at most `proved` proved and at most `reads`
# reads checked. They pin what a cut-off costs now, and are lowered as it tightens.
#
#   sh tools/cutoff_witness.sh [compiler]   (default build/avra)
set -u
. "$(dirname "$0")/lib/attack.sh"
A=${1:-build/avra}
CEILING=tools/cutoff.ceiling
R=build/cutoff-witness
rm -rf "$R" && mkdir -p "$R"
unset AVRA_PROGRAM AVRA_PROGRAM_MODE AVRA_WORK_AHEAD_OFF AVRA_QUERY_TIMES
export AVRA_PROGRAM_NET=0 AVRA_STORE_KEPT_HERE=1
F=packages/cli/src/commands/cache.av
before='println("avra cache log: no pack")'
after='println("avra cache log: no packs")'
cp "$F" "$R/orig.av"
trap 'cp "$R/orig.av" "$F"' EXIT

# The cli built cold over a store of its own, then warm.
for d in $(find packages -name .avra-cache -type d -prune); do find "$d" -mindepth 1 -delete; done
find "$AVRA_CACHE_DIR" -mindepth 1 -delete 2>/dev/null
steps=$((steps + 1))
"$A" build packages/cli > "$R/cold.log" 2>&1 || fail "the cold build failed: $(tail -3 "$R/cold.log")"
[ "$(grep -cF "$before" "$F")" = 1 ] || fail "the literal edited is not one line of $F"
python3 -c "import sys; p,a,b=sys.argv[1:]; s=open(p).read(); open(p,'w').write(s.replace(a,b,1))" "$F" "$before" "$after"
steps=$((steps + 1))
AVRA_QUERY_TIMES=1 "$A" build packages/cli > "$R/warm.log" 2>&1 || fail "the warm build failed: $(tail -3 "$R/warm.log")"
cp "$R/orig.av" "$F"

said=$(grep '^cutoff: ' "$R/warm.log" | tail -1)
held=$(echo "$said" | sed -n 's/^cutoff: \([0-9]*\) answers held, .*/\1/p')
proved=$(echo "$said" | sed -n 's/.* reached, \([0-9]*\) proved, .*/\1/p')
reads=$(echo "$said" | sed -n 's/.* proved, \([0-9]*\) reads checked$/\1/p')
steps=$((steps + 1))
if [ -z "$held" ] || [ -z "$proved" ] || [ -z "$reads" ]; then
    fail "the warm build said no cutoff line: '$said'"
else
    per_proved=$(sed -n 's/^proved \([0-9]*\)$/\1/p' "$CEILING")
    per_reads=$(sed -n 's/^reads \([0-9]*\)$/\1/p' "$CEILING")
    [ "$held" -gt 0 ] || fail "the frontier held no answer: '$said'"
    [ $((proved * 10000)) -le $((held * per_proved)) ] || fail "$proved proved of $held answers held: past $per_proved in ten thousand"
    [ $((reads * 10000)) -le $((held * per_reads)) ] || fail "$reads reads checked for $held answers held: past $per_reads in ten thousand"
fi
verdict "cutoff-witness: $said" "one literal edited"
