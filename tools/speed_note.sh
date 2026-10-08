#!/bin/sh
# THE SOFT SPEED RATCHET. Reads what the jobs already print and writes a table;
# never fails a run (exit 0 always). Two modes:
#   sh tools/speed_note.sh collect <log>...         name seconds lines on stdout
#   sh tools/speed_note.sh compare <current> <main>  a markdown table; ::warning:: over 25%
# A metric is `keeper.<name>` from `keepers: <name> Ns`, `suite.<pkg>` from
# `<pkg> Ns` (the suites step), or `speed <name> <seconds>` written around a step.
set -u
METRICS="speed.static speed.compiler speed.cache-attacks speed.keepers-a speed.keepers-b keeper.attack suite.cli suite.std-avrac"

collect() {
    for log in "$@"; do
        [ -f "$log" ] || continue
        grep -E '^keepers: [a-z-]+ [0-9]+s$|^speed [a-z-]+ [0-9]+$|^[a-z0-9_./-]+ [0-9]+s$' "$log" |
            sed -e 's/^keepers: \([a-z-]*\) \([0-9]*\)s$/keeper.\1 \2/' \
                -e 's/^speed \([a-z-]*\) \([0-9]*\)$/speed.\1 \2/' \
                -e 's/^\([a-z0-9_./-]*\)\/\([a-z0-9_-]*\) \([0-9]*\)s$/suite.\2 \3/' \
                -e 's/^\([a-z0-9_-]*\) \([0-9]*\)s$/suite.\1 \2/'
    done
}

value() {
    [ -f "$1" ] || return 0
    awk -v n="$2" '$1 == n { print $2; exit }' "$1"
}

compare() {
    cur=$1
    base=$2
    out=${GITHUB_STEP_SUMMARY:-/dev/stdout}
    {
        echo "### Speed (soft: never fails the run)"
        echo ""
        echo "| metric | main | this run | change |"
        echo "| --- | --- | --- | --- |"
    } >> "$out"
    for m in $METRICS; do
        c=$(value "$cur" "$m")
        b=$(value "$base" "$m")
        if [ -z "$c" ]; then
            echo "| $m | ${b:-—} | not measured | — |" >> "$out"
        elif [ -z "$b" ]; then
            echo "| $m | no baseline | ${c}s | — |" >> "$out"
        else
            pct=$(awk -v c="$c" -v b="$b" 'BEGIN { if (b == 0) print 0; else printf "%.0f", (c - b) * 100 / b }')
            echo "| $m | ${b}s | ${c}s | ${pct}% |" >> "$out"
            if [ "$pct" -gt 25 ] 2>/dev/null; then
                echo "::warning::speed: $m is ${pct}% slower than main (${b}s -> ${c}s); the runner's noise is about ±20%"
            fi
        fi
    done
    return 0
}

case "${1:-}" in
    collect) shift; collect "$@" ;;
    compare) shift; compare "${1:-}" "${2:-}" ;;
    *) echo "usage: speed_note.sh collect <log>... | compare <current> <main>" ;;
esac
exit 0
