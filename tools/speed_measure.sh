#!/bin/sh
# THE WARM ONE-EDIT MEASUREMENT: one file of `packages/cli` edited, the
# `--time` phases of a build and a check read off, each round a FRESH
# edit so a round is never a store hit. The least of SPEED_ROUNDS (3)
# per phase is that phase's price — the spread's lower edge, which a
# competing process can only raise.
#
# Prints one `<command> <phase> <ms>` per phase per round on stdout; the
# gate (tools/speed_ratchet.py) folds the rounds to the least and judges
# them. Every word of its own goes to stderr, so the stream stays raw.
#
# The store is warmed first: a cold first round is the whole program's
# price, not the phase's, and a budget must read the phase.
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
avra=${AVRA_SPEED_BIN:-build/avra}
rounds=${SPEED_ROUNDS:-3}
target=${SPEED_TARGET:-packages/cli}
file=${SPEED_EDIT:-packages/cli/src/commands/fmt.av}
case "$rounds" in ''|*[!0-9]*) rounds=3 ;; esac

# The host the measurement is keyed by (tools/host_key.sh: a Mac delegating to its Sprite keys the Sprite's).
printf 'host %s\n' "$(sh tools/host_key.sh)"

# A CEILING IS READ FROM A WARM STORE. A cold one makes the first rounds
# the whole program's price, not the phase's, and measuring it here would
# cost the rebuild the store exists to save (and on a runner, differ from
# the machine the ceiling was recorded on). So a cold store SKIPS: the
# lane warms it with `make try` or `sh tools/work test`, then re-runs.
if [ ! -d .avra-cache ] && [ "${SPEED_ALLOW_COLD:-0}" != "1" ]; then
    echo "speed_measure: no warm store at .avra-cache — run \`make try\` once, then re-run; not measured" >&2
    echo "skip cold-store"
    exit 0
fi

[ -x "$avra" ] || { echo "speed_measure: no compiler at $avra — build it first" >&2; exit 1; }
[ -f "$file" ] || { echo "speed_measure: no edit target at $file" >&2; exit 1; }
# The program links the tree's runtime library; a fresh Sprite may not have
# built it yet. Built here rather than as a Makefile prerequisite so the
# work lands on the machine that measures, never on a loaded Mac.
if [ ! -f build/libavra_runtime.a ]; then
    echo "speed_measure: build/libavra_runtime.a missing — building objects and libs" >&2
    make -s -o avra objects libs >&2 || { echo "speed_measure: objects and libs did not build" >&2; exit 1; }
fi

orig=$(mktemp)
cp "$file" "$orig"
restore() { cp "$orig" "$file"; rm -f "$orig"; }
trap restore EXIT INT TERM

# A FRESH EDIT per round: the appended line carries a run nonce and the
# round's own name, so no round ever lands on a store hit — a repeat of an
# earlier run's exact bytes would read the answer back, not pay for it.
nonce=${SPEED_NONCE:-$(date +%s)-$$}
edit() {
    cp "$orig" "$file"
    printf '  // speed-ratchet %s %s\n' "$1" "$nonce" >> "$file"
}

# The timed command's phase line, phases split one per line, filtered to
# the phases the ratchet holds. `emit`/`place`/`link` are the build's;
# a check answers analyze/lower/keep alone and the filter just finds none.
phases() {
    cmd=$1
    line=$2
    printf '%s\n' "$line" |
        tr ',' '\n' |
        sed 's/^[[:space:]]*//;s/[[:space:]]*$//' |
        while IFS= read -r part; do
            name=${part%% *}
            value=${part#* }
            case "$name" in analyze|lower|keep|emit|link) ;; *) continue ;; esac
            case "$value" in *ms) ;; *) continue ;; esac
            printf '%s %s %s\n' "$cmd" "$name" "${value%ms}"
        done
}

timed() {
    cmd=$1
    "$avra" "$cmd" "$target" --time 2>&1 >/dev/null | grep '^time:' | tail -1
}

run_rounds() {
    cmd=$1
    i=0
    while [ "$i" -lt "$rounds" ]; do
        i=$((i + 1))
        edit "$cmd-$i"
        line=$(timed "$cmd")
        [ -n "$line" ] || { echo "speed_measure: $cmd answered no time line" >&2; continue; }
        phases "$cmd" "${line#time: }"
    done
}

# The warm-up is not measured: its only job is to leave the store holding
# every phase's reads, so the rounds below price the work, not the first
# sight of it.
edit warm-build
"$avra" build "$target" --time >/dev/null 2>&1 || true
edit warm-check
"$avra" check "$target" --time >/dev/null 2>&1 || true

echo "speed_measure: warm store, $rounds round(s) of build and check" >&2
run_rounds build
run_rounds check
