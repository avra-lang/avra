#!/bin/sh
# THE CPU BACKSTOP. Reads what the jobs already print and writes a table; wall seconds warn over
# 25% (a shared runner's I/O stalls swing them), CPU seconds (`speed cpu-<step>`, user+sys from the
# step's rusage) FAIL over 2x main's baseline AND 30 s more (a baseline that is missing says so, never passes
# silently), unless the PR body carries `SPEED_ACCEPT: <reason>`. Counts are the primary
# ratchet (tools/census_ratchet.py); this catches what they miss. Two modes:
#   sh tools/speed_note.sh collect <log>...         name seconds lines on stdout
#   sh tools/speed_note.sh compare <current> <main>  a markdown table; ::warning:: over 25%
# A metric is `keeper.<name>` from `keepers: <name> Ns`, `suite.<pkg>` from
# `<pkg> Ns` (the suites step), or `speed <name> <seconds>` written around a step.
set -u
FAIL=0
ACCEPT=$(sh "$(dirname "$0")/pr_body.sh" | sed -n 's/^SPEED_ACCEPT: *//p' | head -n 1)
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

# value <file> <metric>: the metric's number — the MEDIAN when the file keeps several samples (a baseline
# keeps its last three), so one slow or fast run never sets the bar.
value() {
    [ -f "$1" ] || return 0
    awk -v n="$2" '$1 == n { v[++k] = $2 + 0 }
        END { if (k == 0) exit; for (i = 2; i <= k; i++) { x = v[i]; j = i - 1; while (j > 0 && v[j] > x) { v[j+1] = v[j]; j-- } v[j+1] = x }
              print v[int((k + 1) / 2)] }' "$1"
}

# state_other <metric> <baseline file>: when the metric names a cache state (-warm or -cold) and the baseline holds
# the OTHER state of the same stem, `<other metric> <seconds>`; else status 1.
state_other() {
    case "$1" in
        *-cold) other="${1%-cold}-warm" ;;
        *-warm) other="${1%-warm}-cold" ;;
        *) return 1 ;;
    esac
    v=$(value "$2" "$other")
    [ -n "$v" ] || return 1
    echo "$other $v"
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
        elif [ -z "$b" ] && state_other "$m" "$base" >/dev/null; then
            # LIKE WITH LIKE: a suite's CPU rides its cache state in its name (warm/cold); main's number
            # in the OTHER state is a different quantity (2-100x apart for one tree), so it is said and
            # skipped, never compared and never passed over in silence.
            o=$(state_other "$m" "$base")
            echo "| $m | main: ${o%% *} (${o#* }s) | this run (${c}s) | not compared: another cache state |" >> "$out"
            echo "::notice::speed: $m not compared — main's baseline is ${o%% *} (${o#* }s) and this run is the other cache state"
        elif [ -z "$b" ]; then
            echo "| $m | no baseline | ${c}s | — |" >> "$out"
        else
            pct=$(awk -v c="$c" -v b="$b" 'BEGIN { if (b == 0) print 0; else printf "%.0f", (c - b) * 100 / b }')
            echo "| $m | ${b}s | ${c}s | ${pct}% |" >> "$out"
            # Runners swing a small step past 2x with nothing changed (std-path 6s -> 13s, sqlite 10s -> 23s,
            # in one run where nearly every cold step ran 30-130% over its baseline), so the backstop wants
            # the step to have grown by 30s as well as doubled; the counters are the ratchet for the rest.
            grew=$(awk -v c="$c" -v b="$b" 'BEGIN { print (c - b >= 30) ? 1 : 0 }')
            if [ "$pct" -gt 100 ] 2>/dev/null && [ "$grew" = 1 ] && case "$m" in speed.cpu-*) true ;; *) false ;; esac; then
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

# merge <now> <base>: the baseline a main run keeps — this run's numbers, then earlier samples of each name
# up to three in all (the median of the last three is the bar), and every earlier number whose name this
# run did not measure (a suite measured cold today keeps its warm number from before), so both cache
# states stay comparable.
merge() {
    cat "${1:-/dev/null}"
    [ -f "${2:-}" ] && awk 'NR==FNR { seen[$1]++; next } { if (!($1 in seen)) print; else if (seen[$1] < 3) { print; seen[$1]++ } }' "${1:-/dev/null}" "$2"
    return 0
}

case "${1:-}" in
    merge) shift; merge "${1:-}" "${2:-}" ;;
    collect) shift; collect "$@" ;;
    compare) shift; compare "${1:-}" "${2:-}"; exit $? ;;
    --self-test)
        # hermetic: the fixtures name their own PR_BODY, never the run's PR
        PR_NUMBER=; export PR_NUMBER
        d=$(mktemp -d)
        printf 'speed.cpu-cli 100\nspeed.compiler 50\n' > "$d/cur"
        printf 'speed.cpu-cli 40\nspeed.compiler 49\n' > "$d/base"
        [ "$(PR_BODY= GITHUB_STEP_SUMMARY=/dev/null sh "$0" compare "$d/cur" "$d/base" >/dev/null 2>&1; echo $?)" = 1 ] || { echo "speed_note: a 2.5x slowdown did not fail"; exit 1; }
        [ "$(PR_BODY='SPEED_ACCEPT: why' GITHUB_STEP_SUMMARY=/dev/null sh "$0" compare "$d/cur" "$d/base" >/dev/null 2>&1; echo $?)" = 0 ] || { echo "speed_note: a waived slowdown failed"; exit 1; }
        [ "$(GITHUB_STEP_SUMMARY=/dev/null sh "$0" compare "$d/base" "$d/base" >/dev/null 2>&1; echo $?)" = 0 ] || { echo "speed_note: a no-op failed"; exit 1; }
        printf 'suite.cli 100\n' > "$d/curw"
        printf 'suite.cli 40\n' > "$d/basew"
        [ "$(PR_BODY= GITHUB_STEP_SUMMARY=/dev/null sh "$0" compare "$d/curw" "$d/basew" >/dev/null 2>&1; echo $?)" = 0 ] || { echo "speed_note: a wall-clock swing failed (only CPU gates)"; exit 1; }
        # LIKE WITH LIKE: a cold PR against a warm main is NOT compared (and says so); matched states are judged
        printf 'speed.cpu-std-action-cold 14\n' > "$d/curc"
        printf 'speed.cpu-std-action-warm 0\n' > "$d/basew2"
        out=$(PR_BODY= GITHUB_STEP_SUMMARY=/dev/stdout sh "$0" compare "$d/curc" "$d/basew2" 2>&1); st=$?
        [ "$st" = 0 ] && printf '%s\n' "$out" | grep -q "not compared" || { echo "speed_note: a cold run against a warm baseline failed or was passed silently ($st): $out"; exit 1; }
        printf 'speed.cpu-std-action-cold 33\n' > "$d/basec"
        [ "$(PR_BODY= GITHUB_STEP_SUMMARY=/dev/null sh "$0" compare "$d/curc" "$d/basec" >/dev/null 2>&1; echo $?)" = 0 ] || { echo "speed_note: matched cold states within 2x failed"; exit 1; }
        printf 'speed.cpu-std-action-cold 100\n' > "$d/curc2"
        [ "$(PR_BODY= GITHUB_STEP_SUMMARY=/dev/null sh "$0" compare "$d/curc2" "$d/basec" >/dev/null 2>&1; echo $?)" = 1 ] || { echo "speed_note: a real 3x on matched cold states did not fail"; exit 1; }
        printf 'speed.cpu-small 13\n' > "$d/curs"
        printf 'speed.cpu-small 6\n' > "$d/bases"
        [ "$(PR_BODY= GITHUB_STEP_SUMMARY=/dev/null sh "$0" compare "$d/curs" "$d/bases" >/dev/null 2>&1; echo $?)" = 0 ] || { echo "speed_note: a doubled 6s step (+7s) failed — the backstop owes a 30s floor"; exit 1; }
        printf 'speed.cpu-small 37\n' > "$d/curs2"
        [ "$(PR_BODY= GITHUB_STEP_SUMMARY=/dev/null sh "$0" compare "$d/curs2" "$d/bases" >/dev/null 2>&1; echo $?)" = 1 ] || { echo "speed_note: a 6s step grown by 31s did not fail"; exit 1; }
        printf 'speed.cpu-w 10\nspeed.cpu-w 90\nspeed.cpu-w 12\n' > "$d/med"
        [ "$(value "$d/med" speed.cpu-w)" = 12 ] || { echo "speed_note: the median of 10, 90, 12 is not 12"; exit 1; }
        printf 'speed.cpu-w 20\n' > "$d/m0"
        [ "$(sh "$0" merge "$d/m0" "$d/med" | wc -l | tr -d ' ')" = 3 ] || { echo "speed_note: merge kept more or fewer than three samples"; exit 1; }
        printf 'speed.cpu-w 11\nspeed.cpu-w 95\nspeed.cpu-w 12\n' > "$d/curm"
        printf 'speed.cpu-w 40\n' > "$d/noise"
        [ "$(PR_BODY= GITHUB_STEP_SUMMARY=/dev/null sh "$0" compare "$d/noise" "$d/med" >/dev/null 2>&1; echo $?)" = 0 ] || { echo "speed_note: 40s against a median of 12s (+28s, under the floor) failed"; exit 1; }
        printf 'speed.cpu-a-cold 5\nspeed.cpu-b 7\n' > "$d/m1"
        printf 'speed.cpu-a-warm 1\nspeed.cpu-a-cold 9\n' > "$d/m2"
        [ "$(sh "$0" merge "$d/m1" "$d/m2" | sort | tr '\n' ' ')" = "speed.cpu-a-cold 5 speed.cpu-a-cold 9 speed.cpu-a-warm 1 speed.cpu-b 7 " ] || { echo "speed_note: merge did not keep the other state's baseline and the earlier sample"; exit 1; }
        echo "speed_note: self-test passed — 13 fixtures"
        exit 0 ;;
    *) echo "usage: speed_note.sh collect <log>... | compare <current> <main>" ;;
esac
exit 0
