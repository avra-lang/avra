#!/bin/sh
# THE CPU BACKSTOP. Reads what the jobs already print and writes a table; wall seconds warn over
# 25% (a shared runner's I/O stalls swing them), CPU seconds (`speed cpu-<step>`, user+sys from the
# step's rusage) FAIL over 2x main's baseline AND 30 s more AND twice the run's own median growth (a
# baseline that is missing says so, never passes silently), unless the PR body carries
# `SPEED_ACCEPT: <reason>`. Counts are the primary ratchet (tools/census_ratchet.py); this catches
# what they miss. THE RUN'S MEDIAN IS THE RUNNER'S CLOCK: one absolute floor cannot tell a step that
# grew from a run that was slow, so every CPU row is judged against how far the run itself moved. Two modes:
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

# cpu_ratios <current> <baseline>: the growth of every CPU step this run can compare like with like —
# the rows the median below is made of. A step whose baseline is the other cache state is absent by name.
cpu_ratios() {
    [ -f "$1" ] && [ -f "$2" ] || return 0
    for m in $(awk '$1 ~ /^speed\.cpu-/ { print $1 }' "$1" | sort -u); do
        c=$(value "$1" "$m")
        b=$(value "$2" "$m")
        [ -n "$b" ] && awk -v c="$c" -v b="$b" 'BEGIN { if (b + 0 > 0) print c / b }'
    done
}

# median: the central growth of a list of ratios (sort -n feeds it). A runner inflates every row at
# once, so the middle row is the runner's factor where the mean would follow whichever row leaked.
median() {
    sort -n | awk '{ v[NR] = $1 } END {
        if (NR == 0) exit 1
        if (NR % 2) print v[(NR + 1) / 2]
        else printf "%.6f\n", (v[NR / 2] + v[NR / 2 + 1]) / 2
    }'
}

# state_other <metric> <baseline file>: when the metric names a cache state (-warm, -part or -cold) and the
# baseline holds ANOTHER state of the same stem, `<other metric> <seconds>`; else status 1.
state_other() {
    case "$1" in
        *-cold) stem="${1%-cold}" ;;
        *-warm) stem="${1%-warm}" ;;
        *-part) stem="${1%-part}" ;;
        *) return 1 ;;
    esac
    for other in "$stem-warm" "$stem-cold" "$stem-part"; do
        [ "$other" != "$1" ] || continue
        v=$(value "$2" "$other")
        [ -z "$v" ] || { echo "$other $v"; return 0; }
    done
    return 1
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
    # THE RUN'S OWN CLOCK: the median growth of its comparable CPU rows. Fewer than three rows is no
    # distribution to judge a row against, so those runs keep the absolute backstop alone and say so.
    ratios=$(cpu_ratios "$cur" "$base")
    n=0
    med=
    medpct=
    if [ -n "$ratios" ]; then
        n=$(printf '%s\n' "$ratios" | grep -c .)
        med=$(printf '%s\n' "$ratios" | median)
        medpct=$(awk -v m="$med" 'BEGIN { printf "%.0f", (m - 1) * 100 }')
    fi
    runner=0
    cpus=$(awk '$1 ~ /^speed\.cpu-/ { print $1 }' "$cur" 2>/dev/null)
    for m in $METRICS $cpus; do
        c=$(value "$cur" "$m")
        b=$(value "$base" "$m")
        # A PART-WARM ROW IS HELD AGAINST MAIN'S COLD ONE when main has no part-warm row of its own: the
        # run held some of what the cold run built, so cold is an upper bound, and growth past it is real.
        vs=
        case "$m" in
            *-part) if [ -z "$b" ]; then
                b=$(value "$base" "${m%-part}-cold")
                [ -z "$b" ] || vs=" (main's cold row, an upper bound)"
            fi ;;
        esac
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
            echo "| $m | ${b}s$vs | ${c}s | ${pct}% |" >> "$out"
            [ -z "$vs" ] || echo "::notice::speed: $m is part-warm and main has no part-warm row, so it is compared with main's cold row (${b}s), an upper bound"
            # Runners swing a small step past 2x with nothing changed (std-path 6s -> 13s, sqlite 10s -> 23s),
            # so the 30 s floor stays as MATERIALITY — a step too small for its growth to mean anything is
            # not worth a gate — and the counters are the ratchet for the rest. It is no longer the judge:
            # whether the growth belongs to the row or to the runner is the median's question.
            grew=$(awk -v c="$c" -v b="$b" 'BEGIN { print (c - b >= 30) ? 1 : 0 }')
            if [ "$pct" -gt 100 ] 2>/dev/null && [ "$grew" = 1 ] && case "$m" in speed.cpu-*) true ;; *) false ;; esac; then
                # BEYOND TWICE THE RUN: a row earns a gate only by growing twice as much as the run's
                # middle row did. A uniform +120% run has median 2.2, and its rows sit at 2.2, not 4.4.
                if [ "$n" -lt 3 ] || [ -z "$med" ] || awk -v c="$c" -v b="$b" -v m="$med" 'BEGIN { exit !(c / b >= 2 * m) }'; then
                    if [ "$n" -lt 3 ] || [ -z "$med" ]; then
                        echo "::notice::speed: fewer than three comparable CPU rows, so $m is judged by the absolute backstop alone"
                    fi
                    if [ -n "$ACCEPT" ]; then
                        echo "::warning::speed: $m is ${pct}% slower than main (${b}s -> ${c}s) — ACCEPTED by SPEED_ACCEPT: $ACCEPT"
                    else
                        echo "::error::speed: $m is ${pct}% slower than main (${b}s -> ${c}s), over the 2x backstop; a PR that must cost more says \`SPEED_ACCEPT: <reason>\` in its body"
                        FAIL=1
                    fi
                else
                    runner=1
                    echo "::notice::speed: $m is ${pct}% slower than main (${b}s -> ${c}s), but the run's median CPU step grew ${medpct}% (${n} compared) — this is the runner, not the row"
                fi
            elif [ "$pct" -gt 25 ] 2>/dev/null; then
                echo "::warning::speed: $m is ${pct}% slower than main (${b}s -> ${c}s); the runner's noise is about ±20%"
            fi
        fi
    done
    if [ "$runner" = 1 ] && [ "$FAIL" = 0 ]; then
        echo "::notice::speed: this run was uniformly inflated — its median CPU step grew ${medpct}% over main (${n} rows compared), so no row's growth is beyond twice the run's; a slow runner gates nothing"
    fi
    if [ "$n" -ge 3 ] && [ -n "$med" ]; then
        echo "" >> "$out"
        echo "Run baseline: the median CPU step grew ${medpct}% (${n} compared); a row gates only beyond twice that." >> "$out"
    fi
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
        # A UNIFORMLY INFLATED RUN GATES NOTHING: every row is 2.2x main, which the absolute backstop
        # would fail five times over; the median says the run itself was 2.2x slower, so this is a runner.
        printf 'speed.cpu-a 220\nspeed.cpu-b 110\nspeed.cpu-c 440\nspeed.cpu-d 88\nspeed.cpu-e 264\n' > "$d/curu"
        printf 'speed.cpu-a 100\nspeed.cpu-b 50\nspeed.cpu-c 200\nspeed.cpu-d 40\nspeed.cpu-e 120\n' > "$d/baseu"
        outu=$(PR_BODY= GITHUB_STEP_SUMMARY=/dev/stdout sh "$0" compare "$d/curu" "$d/baseu" 2>&1); stu=$?
        [ "$stu" = 0 ] || { echo "speed_note: a uniformly inflated run failed ($stu): $outu"; exit 1; }
        printf '%s\n' "$outu" | grep -q "uniformly inflated" || { echo "speed_note: an inflated run did not say it was the runner: $outu"; exit 1; }
        printf '%s\n' "$outu" | grep -q "::error::speed" && { echo "speed_note: an inflated run gated a row: $outu"; exit 1; }
        # ONE ROW THAT GREW WHILE ITS SIBLINGS DID NOT STILL GATES, and names itself: the run's median is +3%.
        printf 'speed.cpu-a 105\nspeed.cpu-b 103\nspeed.cpu-c 101\nspeed.cpu-rogue 250\nspeed.cpu-d 102\n' > "$d/curr"
        printf 'speed.cpu-a 100\nspeed.cpu-b 100\nspeed.cpu-c 100\nspeed.cpu-rogue 100\nspeed.cpu-d 100\n' > "$d/baser"
        outr=$(PR_BODY= GITHUB_STEP_SUMMARY=/dev/stdout sh "$0" compare "$d/curr" "$d/baser" 2>&1); str=$?
        [ "$str" = 1 ] || { echo "speed_note: one anomalous row among normal ones did not fail ($str): $outr"; exit 1; }
        printf '%s\n' "$outr" | grep -q "::error::speed: speed.cpu-rogue" || { echo "speed_note: the anomalous row was not named: $outr"; exit 1; }
        # THE CAMPAIGN'S REAL NUMBERS: features-b-cold 216 -> 466 (+116%) with every sibling cold row
        # inflated (core-warm +67%, diagnostics +36%, io +30%, ui-http +31%, assets +38%). Median +37%,
        # so features-b's 2.16x is not twice the run's growth — a slow runner, not that row's regression.
        printf 'speed.cpu-core-warm 167\nspeed.cpu-diagnostics 136\nspeed.cpu-io 130\nspeed.cpu-ui-http 131\nspeed.cpu-assets 138\nspeed.cpu-features-b-cold 466\n' > "$d/curb"
        printf 'speed.cpu-core-warm 100\nspeed.cpu-diagnostics 100\nspeed.cpu-io 100\nspeed.cpu-ui-http 100\nspeed.cpu-assets 100\nspeed.cpu-features-b-cold 216\n' > "$d/baseb"
        outb=$(PR_BODY= GITHUB_STEP_SUMMARY=/dev/stdout sh "$0" compare "$d/curb" "$d/baseb" 2>&1); stb=$?
        [ "$stb" = 0 ] || { echo "speed_note: the features-b-cold replay gated ($stb): $outb"; exit 1; }
        printf '%s\n' "$outb" | grep -q "median CPU step grew 37%" || { echo "speed_note: the features-b-cold replay did not report the run's median: $outb"; exit 1; }
        printf '%s\n' "$outb" | grep -q "::error::speed" && { echo "speed_note: the features-b-cold replay gated a row: $outb"; exit 1; }
        # PART-WARM: never compared with a warm row (said); against main's cold row when that is all main has
        printf 'speed.cpu-std-db-part 64\n' > "$d/curp"
        printf 'speed.cpu-std-db-warm 32\n' > "$d/basepw"
        outp=$(PR_BODY= GITHUB_STEP_SUMMARY=/dev/stdout sh "$0" compare "$d/curp" "$d/basepw" 2>&1); stp=$?
        { [ "$stp" = 0 ] && printf '%s\n' "$outp" | grep -q "not compared: another cache state"; } || { echo "speed_note: a part-warm row against a warm baseline was compared or failed ($stp): $outp"; exit 1; }
        printf 'speed.cpu-std-db-cold 60\nspeed.cpu-std-db-warm 32\n' > "$d/basepc"
        outpc=$(PR_BODY= GITHUB_STEP_SUMMARY=/dev/stdout sh "$0" compare "$d/curp" "$d/basepc" 2>&1); stpc=$?
        { [ "$stpc" = 0 ] && printf '%s\n' "$outpc" | grep -q "main's cold row, an upper bound"; } || { echo "speed_note: a part-warm row was not held against main's cold row ($stpc): $outpc"; exit 1; }
        printf 'speed.cpu-std-db-part 190\n' > "$d/curp2"
        printf 'speed.cpu-std-db-cold 60\n' > "$d/basepc2"
        [ "$(PR_BODY= GITHUB_STEP_SUMMARY=/dev/null sh "$0" compare "$d/curp2" "$d/basepc2" >/dev/null 2>&1; echo $?)" = 1 ] || { echo "speed_note: a part-warm row 3x past main's cold row did not fail"; exit 1; }
        echo "speed_note: self-test passed — 24 fixtures"
        exit 0 ;;
    *) echo "usage: speed_note.sh collect <log>... | compare <current> <main>" ;;
esac
exit 0
