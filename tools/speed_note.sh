#!/bin/sh
# THE CPU BACKSTOP. Reads what the jobs already print and writes a table; wall seconds warn over
# 25% (a shared runner's I/O stalls swing them), CPU seconds (`speed cpu-<step>`, user+sys from the
# step's rusage) FAIL over 2x main's baseline (a baseline that is missing says so, never passes
# silently), unless the PR body carries `SPEED_ACCEPT: <reason>`. Counts are the primary
# ratchet (tools/census_ratchet.py); this catches what they miss. Two modes:
#   sh tools/speed_note.sh collect <log>...         name seconds lines on stdout
#   sh tools/speed_note.sh compare <current> <main>  a markdown table; ::warning:: over 25%
# A metric is `keeper.<name>` from `keepers: <name> Ns`, `suite.<pkg>` from
# `<pkg> Ns` (the suites step), or `speed <name> <seconds>` written around a step.
set -u
FAIL=0
ACCEPT=$(printf '%s\n' "${PR_BODY:-}" | sed -n 's/^SPEED_ACCEPT: *//p' | head -n 1)
METRICS="speed.static speed.compiler speed.cache-attacks speed.keepers-a speed.keepers-b keeper.attack suite.cli suite.std-avrac"

collect() {
    for log in "$@"; do
        [ -f "$log" ] || continue
        grep -E '^keepers: [a-z-]+ [0-9]+s$|^speed [a-z0-9-]+ [0-9]+$|^[a-z0-9_./-]+ [0-9]+s$' "$log" |
            sed -e 's/^keepers: \([a-z-]*\) \([0-9]*\)s$/keeper.\1 \2/' \
                -e 's/^speed \([a-z0-9-]*\) \([0-9]*\)$/speed.\1 \2/' \
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
        echo "### Speed (warns over 25%, fails over 2x main)"
        echo ""
        echo "| metric | main | this run | change |"
        echo "| --- | --- | --- | --- |"
    } >> "$out"
    cpus=$(awk '$1 ~ /^speed\.cpu-/ { print $1 }' "$cur" 2>/dev/null)
    for m in $METRICS $cpus; do
        c=$(value "$cur" "$m")
        b=$(value "$base" "$m")
        if [ -z "$c" ]; then
            echo "| $m | ${b:-—} | not measured | — |" >> "$out"
        elif [ -z "$b" ]; then
            echo "| $m | no baseline | ${c}s | — |" >> "$out"
        else
            pct=$(awk -v c="$c" -v b="$b" 'BEGIN { if (b == 0) print 0; else printf "%.0f", (c - b) * 100 / b }')
            echo "| $m | ${b}s | ${c}s | ${pct}% |" >> "$out"
            if [ "$pct" -gt 100 ] 2>/dev/null && case "$m" in speed.cpu-*) true ;; *) false ;; esac; then
                if [ -n "$ACCEPT" ]; then
                    echo "::warning::speed: $m is ${pct}% slower than main (${b}s -> ${c}s) — ACCEPTED by SPEED_ACCEPT: $ACCEPT"
                else
                    echo "::error::speed: $m is ${pct}% slower than main (${b}s -> ${c}s), over the 2x backstop; a PR that must cost more says \`SPEED_ACCEPT: <reason>\` in its body"
                    FAIL=1
                fi
            elif [ "$pct" -gt 25 ] 2>/dev/null; then
                echo "::warning::speed: $m is ${pct}% slower than main (${b}s -> ${c}s); the runner's noise is about ±20%"
            fi
        fi
    done
    return $FAIL
}

case "${1:-}" in
    collect) shift; collect "$@" ;;
    compare) shift; compare "${1:-}" "${2:-}"; exit $? ;;
    --self-test)
        d=$(mktemp -d)
        printf 'speed.cpu-cli 100\nspeed.compiler 50\n' > "$d/cur"
        printf 'speed.cpu-cli 40\nspeed.compiler 49\n' > "$d/base"
        [ "$(PR_BODY= GITHUB_STEP_SUMMARY=/dev/null sh "$0" compare "$d/cur" "$d/base" >/dev/null 2>&1; echo $?)" = 1 ] || { echo "speed_note: a 2.5x slowdown did not fail"; exit 1; }
        [ "$(PR_BODY='SPEED_ACCEPT: why' GITHUB_STEP_SUMMARY=/dev/null sh "$0" compare "$d/cur" "$d/base" >/dev/null 2>&1; echo $?)" = 0 ] || { echo "speed_note: a waived slowdown failed"; exit 1; }
        [ "$(GITHUB_STEP_SUMMARY=/dev/null sh "$0" compare "$d/base" "$d/base" >/dev/null 2>&1; echo $?)" = 0 ] || { echo "speed_note: a no-op failed"; exit 1; }
        printf 'suite.cli 100\n' > "$d/curw"
        printf 'suite.cli 40\n' > "$d/basew"
        [ "$(PR_BODY= GITHUB_STEP_SUMMARY=/dev/null sh "$0" compare "$d/curw" "$d/basew" >/dev/null 2>&1; echo $?)" = 0 ] || { echo "speed_note: a wall-clock swing failed (only CPU gates)"; exit 1; }
        echo "speed_note: self-test passed — 4 fixtures"
        exit 0 ;;
    *) echo "usage: speed_note.sh collect <log>... | compare <current> <main>" ;;
esac
exit 0
