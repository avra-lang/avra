#!/bin/sh
# THE FRAMERS FUZZED, IN BOUNDED TIME: `make fuzz-http`.
#
#   1. every checked-in input replayed — the corpus and every past
#      finding in packages/std-http-fuzz/crashes, so a finding is
#      permanent the moment it is saved;
#   2. libFuzzer over the C rows the framers stand on (a third of the
#      budget), each row held to a naive walk;
#   3. the Avra fuzzer in batches until the budget is spent: a batch
#      that traps or hangs is BISECTED to its one mutant, which is
#      written to crashes/, and so is every mutant an oracle refused.
#
# FUZZ_HTTP_SECONDS (default 180) bounds the whole run; FUZZ_HTTP_SEED
# (default: the day of the year) picks the mutants, and is printed so
# a run is repeatable. A status is a verdict: 0 clean, 1 anything found.
set -u
cd "$(dirname "$0")/.."
secs="${FUZZ_HTTP_SECONDS:-180}"
seed="${FUZZ_HTTP_SEED:-$(date +%j | sed 's/^0*//')}"
batch="${FUZZ_HTTP_BATCH:-20000}"
dir=packages/std-http-fuzz
bin="$dir/src/main"
out=build/fuzz-http
clang="${LLVM_PREFIX:-/opt/homebrew/opt/llvm}/bin/clang"
mkdir -p "$out" "$out/rows-corpus" "$dir/crashes" "$dir/rows-crashes"
found=0
kept_n=0

# A bounded child and its watchdog die with this driver, on any exit.
pid= dog=
trap 'for p in $pid $dog; do kill -9 "$p" 2> /dev/null; done' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# A command under a wall-clock bound; a kill answers 137.
bounded() {
    lim="$1"; log="$2"; shift 2
    "$@" > "$log" 2>&1 &
    pid=$!
    ( sleep "$lim"; kill -9 "$pid" 2>/dev/null ) &
    dog=$!
    wait "$pid"; st=$?
    kill "$dog" 2>/dev/null; wait "$dog" 2>/dev/null
    return "$st"
}

# The one mutant in FROM..FROM+N whose own batch traps or hangs.
culprit() {
    lo="$1"; n="$2"
    while [ "$n" -gt 1 ]; do
        h=$((n / 2))
        if bounded 30 "$out/bisect.log" env FUZZ_SEED="$seed" FUZZ_FROM="$lo" FUZZ_COUNT="$h" FUZZ_CORPUS="$dir/corpus" "$bin"; then
            lo=$((lo + h)); n=$((n - h))
        else
            n="$h"
        fi
    done
    echo "$lo"
}

# Mutant I written to crashes/ as KIND.
kept() {
    f="$dir/crashes/$1-$seed-$2.bin"
    env FUZZ_SEED="$seed" FUZZ_DUMP="$2" FUZZ_OUT="$f" FUZZ_CORPUS="$dir/corpus" "$bin" > /dev/null 2>&1
    echo "fuzz-http: kept $f"
}

build/avra build "$dir" > "$out/build.log" 2>&1 || { tail -20 "$out/build.log"; echo "fuzz-http: the fuzzer did not build"; exit 1; }
start=$(date +%s)

for d in corpus crashes; do
    bounded 120 "$out/replay.log" env FUZZ_SEED="$seed" FUZZ_REPLAY="$dir/$d" "$bin"; st=$?
    tail -1 "$out/replay.log"
    if [ "$st" -ne 0 ] || grep -q '^FAIL' "$out/replay.log"; then
        grep '^FAIL\|avra:' "$out/replay.log" | head -10
        found=$((found + 1))
    fi
done

rows_secs=$((secs / 3))
if "$clang" -O1 -g -fsanitize=fuzzer,undefined -fno-sanitize-recover=undefined -Iruntime \
    -o "$out/bytes_rows" "$dir/c/bytes_rows_fuzz.c" runtime/*.c > "$out/rows-build.log" 2>&1; then
    rows=$(ls "$dir/rows-crashes" | sed "s|^|$dir/rows-crashes/|")
    # shellcheck disable=SC2086
    [ -z "$rows" ] || "$out/bytes_rows" $rows > "$out/rows-replay.log" 2>&1 || { echo "fuzz-http: a kept rows input fails again"; found=$((found + 1)); }
    bounded $((rows_secs + 30)) "$out/rows.log" "$out/bytes_rows" -max_total_time="$rows_secs" -max_len=4096 \
        -artifact_prefix="$dir/rows-crashes/" "$out/rows-corpus"; st=$?
    runs=$(grep -o 'Done [0-9]* runs' "$out/rows.log" | grep -o '[0-9]*' | tail -1)
    if [ "$st" -ne 0 ]; then
        grep 'SUMMARY\|Test unit written' "$out/rows.log" | head -3
        found=$((found + 1))
    fi
    echo "fuzz-http: C rows — ${runs:-0} libFuzzer runs in ${rows_secs}s"
else
    echo "fuzz-http: no libFuzzer here ($clang) — the C rows were not fuzzed"
    tail -5 "$out/rows-build.log"
fi

end=$((start + secs))
from=0
checked=0
complete=0
while [ "$(date +%s)" -lt "$end" ]; do
    if bounded 60 "$out/batch.log" env FUZZ_SEED="$seed" FUZZ_FROM="$from" FUZZ_COUNT="$batch" FUZZ_CORPUS="$dir/corpus" "$bin"; then
        room=$((10 - kept_n))
        [ "$room" -gt 0 ] || room=1
        [ "$kept_n" -lt 10 ] && for i in $(grep '^FAIL' "$out/batch.log" | awk '{print $2}' | sort -un | head -"$room"); do
            grep "^FAIL $i " "$out/batch.log" | head -2
            kept breach "$i"
            kept_n=$((kept_n + 1))
        done
        n=$(grep -c '^FAIL' "$out/batch.log")
        found=$((found + n))
        c=$(sed -n 's/.*requests \([0-9]*\) complete.*/\1/p' "$out/batch.log")
        complete=$((complete + ${c:-0}))
    else
        i=$(culprit "$from" "$batch")
        echo "fuzz-http: mutant $i of seed $seed traps or hangs:"
        bounded 30 "$out/one.log" env FUZZ_SEED="$seed" FUZZ_FROM="$i" FUZZ_COUNT=1 FUZZ_CORPUS="$dir/corpus" "$bin"
        grep -v '^fuzz-http' "$out/one.log" | head -3
        kept trap "$i"
        found=$((found + 1))
    fi
    checked=$((checked + batch))
    from=$((from + batch))
done
took=$(( $(date +%s) - start ))
echo "fuzz-http: seed $seed — $checked mutants checked ($complete framed complete) in ${took}s, $found finding(s)"
[ "$found" -eq 0 ]
