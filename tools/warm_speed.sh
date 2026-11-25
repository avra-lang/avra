#!/bin/sh
# warm_speed.sh <base-bin> <cand-bin> — the warm one-line edit, timed for
# two compilers over ONE input (this tree; both binaries sit in build/,
# so both resolve this tree's std root): each warms its own store, then
# `check packages/cli` after a fresh edit to fmt.av's one diagnostic line,
# best of AVRA_WARM_TRIES (3). Each trial's edit is new text, so a trial is
# never a store hit. Fails when the candidate's best passes the base's
# best x AVRA_WARM_RATIO (1.25) + AVRA_WARM_SLACK_S (1), or AVRA_WARM_CAP_S (15).
set -u
B="$1"; C="$2"
tries=${AVRA_WARM_TRIES:-3}
ratio=${AVRA_WARM_RATIO:-1.25}
slack=${AVRA_WARM_SLACK_S:-1}
cap=${AVRA_WARM_CAP_S:-15}
f=packages/cli/src/commands/fmt.av
orig=$(mktemp)
cp "$f" "$orig"
trap 'cp "$orig" "$f"; rm -f "$orig"' EXIT

now_s() { python3 -c 'import time; print("%.3f" % time.time())'; }

# best <bin>: the fastest warm edit of `tries`, in seconds.
best() {
    bin=$1
    find . -name .avra-cache -type d -prune -exec rm -rf {} +
    cp "$orig" "$f"
    "$bin" check packages/cli > /dev/null 2>&1 || true
    fastest=""
    i=1
    while [ "$i" -le "$tries" ]; do
        sed "s/\"avra: \${path}: \${e.describe/\"avra $i- \${path}: \${e.describe/" "$orig" > "$f"
        if cmp -s "$orig" "$f"; then echo "warm_speed: the scripted edit did not change $f" >&2; exit 2; fi
        t0=$(now_s)
        "$bin" check packages/cli > /dev/null 2>&1 || true
        t1=$(now_s)
        s=$(python3 -c "print('%.2f' % ($t1 - $t0))")
        echo "warm_speed: $bin trial $i: ${s}s" >&2
        if [ -z "$fastest" ] || python3 -c "import sys; sys.exit(0 if $s < $fastest else 1)"; then fastest=$s; fi
        cp "$orig" "$f"
        "$bin" check packages/cli > /dev/null 2>&1 || true
        i=$((i + 1))
    done
    echo "$fastest"
}

base=$(best "$B")
cand=$(best "$C")
[ -n "$base" ] && [ -n "$cand" ] || { echo "warm_speed: a compiler gave no time" >&2; exit 2; }
limit=$(python3 -c "print('%.2f' % min($base * $ratio + $slack, $cap))")
echo "warm_speed: base ${base}s, candidate ${cand}s, limit ${limit}s (base x $ratio + ${slack}s, cap ${cap}s)"
python3 -c "import sys; sys.exit(0 if $cand <= $limit else 1)" || { echo "warm_speed: FAIL — the warm edit is slower than main's"; exit 1; }
echo "warm_speed: PASS"
