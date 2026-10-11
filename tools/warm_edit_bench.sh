#!/bin/sh
# THE WARM-EDIT GATE — the script the DB 07 ticket names
# (avra-8sb5.57.176), and the gap it describes, made refutable.
#
# Its acceptance: an UNCHANGED `check packages/cli` at <= 60 ms and a ONE
# BODY EDIT `check` at <= 300 ms (goal 150), cold process, no daemon, on a
# warm store. Nothing ran it before — `grep -rn warm_edit Makefile
# .github/` answered nothing and no keeper held it — so 374-635 ms
# unchanged and 21 819 ms for one edit stood with nothing to fail.
#
# TWO EXISTING DEFINITIONS, never a second copy:
#   - the MECHANISM is `tools/db_measure/warm_edit.sh`'s: a `check --time`,
#     ONE string literal in ONE body moved to fresh text per round so a
#     round is never a store hit, the wall read from the clock.
#   - the CEILINGS are `tools/speed_ratchet.py`'s budget
#     (`tools/speed.budget`): this script measures and hands its raw stream
#     to `speed_ratchet.py --warm --raw`, the ONE reader of that file, which
#     REFUSES past a ceiling and names each by how much.
#
# stdout is the raw measurement the judge reads (`host <key>`,
# `warm unchanged <ms>`, `warm edit <ms>`); every word of its own goes to
# stderr. A warm store is REQUIRED: a cold one makes the first rounds the
# whole program's price, so it SKIPS with a word (never a silent pass).
# On macOS the measurement goes to the lane's Sprite (`tools/work run`),
# as `speed-ratchet` does — a loaded Mac supplies no number.
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
avra=${AVRA_SPEED_BIN:-build/avra}
rounds=${SPEED_ROUNDS:-3}
target=${SPEED_TARGET:-packages/cli}
file=${SPEED_EDIT_FILE:-packages/cli/src/commands/shared.av}
lit=${SPEED_EDIT_LIT:-· memo}
case "$rounds" in ''|*[!0-9]*) rounds=3 ;; esac

# A Mac has no number of its own: this lane's Sprite has. Re-run there, and
# answer its status. A worktree with no Sprite is not measured here.
if [ "$(uname -s)" = "Darwin" ] && [ "${SPEED_LOCAL:-0}" != "1" ]; then
    sprite=$(cat "$(git rev-parse --absolute-git-dir)/avra-sprite" 2>/dev/null || :)
    if [ -z "$sprite" ]; then
        echo "warm_edit_bench: no Sprite bound to this worktree — not measured here" >&2
        exit 0
    fi
    exec sh tools/work run "sh tools/warm_edit_bench.sh"
fi

# A CEILING IS READ FROM A WARM STORE.
if [ ! -d .avra-cache ] && [ "${SPEED_ALLOW_COLD:-0}" != "1" ]; then
    echo "warm_edit_bench: no warm store at .avra-cache — run \`make try\` once, then re-run; not measured" >&2
    echo "skip cold-store"
    exit 0
fi
[ -x "$avra" ] || { echo "warm_edit_bench: no compiler at $avra — build it first" >&2; exit 1; }
[ -f "$file" ] || { echo "warm_edit_bench: no edit target at $file" >&2; exit 1; }
grep -qF "$lit" "$file" || { echo "warm_edit_bench: \`$lit\` is gone from $file — the edit target moved" >&2; exit 1; }
# The program links the tree's own runtime library; a fresh Sprite may not
# have built it. Built here, on the machine that measures, never a loaded Mac.
if [ ! -f build/libavra_runtime.a ]; then
    echo "warm_edit_bench: build/libavra_runtime.a missing — building objects and libs" >&2
    make -s -o avra objects libs >&2 || { echo "warm_edit_bench: objects and libs did not build" >&2; exit 1; }
fi

# The host the number is keyed by, in the budget's own spelling — the CPU is
# in the key because two x86_64 Linux machines are not one machine.
token() { printf '%s' "$1" | tr 'A-Z' 'a-z' | tr -cs 'a-z0-9' '-' | sed 's/^-*//;s/-*$//'; }
cpu() {
    if [ -r /proc/cpuinfo ]; then
        awk -F: '/model name/ { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2; exit }' /proc/cpuinfo
    else
        sysctl -n machdep.cpu.brand_string 2>/dev/null || uname -p
    fi
}
host=${SPEED_HOST:-$(token "$(uname -s)")-$(token "$(uname -m)")-$(token "$(cpu)")}

# Nanoseconds from GNU date; a BSD date that does not answer falls back to
# Python's clock (the measurement itself runs on the Sprite, where date is GNU).
now() {
    n=$(date +%s%N 2>/dev/null)
    case "$n" in ''|*[!0-9]*) python3 -c 'import time; print(time.time_ns())' ;; *) printf '%s' "$n" ;; esac
}
wall() { # -> "<ms> <status>"
    s=$(now)
    "$avra" check "$target" >/dev/null 2>&1
    st=$?
    e=$(now)
    printf '%s %s' "$(((e - s) / 1000000))" "$st"
}

orig=$(mktemp)
cp "$file" "$orig"
restore() { cp "$orig" "$file"; rm -f "$orig"; }
trap restore EXIT INT TERM

# A FRESH EDIT per round: the appended word carries a run nonce and the
# round's own name, so no round lands on a store hit.
nonce=${SPEED_NONCE:-$(date +%s)-$$}
edit() { # <word>
    cp "$orig" "$file"
    python3 - "$file" "$lit" "$1$nonce" <<'PY'
import sys
path, lit, word = sys.argv[1:4]
text = open(path, encoding="utf-8").read()
open(path, "w", encoding="utf-8").write(text.replace(lit, lit + " " + word, 1))
PY
}

raw=$(mktemp)
printf 'host %s\n' "$host" > "$raw"

# UNCHANGED rounds first and contiguous: the store is already holding this
# exact file from the warm-up, so the LEAST of the rounds is a hit's price.
least=0
i=0
while [ "$i" -lt "$rounds" ]; do
    i=$((i + 1))
    set -- $(wall)
    ms=$1; st=$2
    [ "$st" = 0 ] || { echo "warm_edit_bench: an unchanged check exited $st — not measured" >&2; cat "$raw"; rm -f "$raw"; exit 1; }
    if [ "$least" -eq 0 ] || [ "$ms" -lt "$least" ]; then least=$ms; fi
done
printf 'warm unchanged %s\n' "$least" >> "$raw"

# ONE BODY EDIT per round, each a miss; the LEAST is the edit's price.
least=0
i=0
while [ "$i" -lt "$rounds" ]; do
    i=$((i + 1))
    edit "warm$i"
    set -- $(wall)
    ms=$1; st=$2
    [ "$st" = 0 ] || { echo "warm_edit_bench: an edited check exited $st — not measured" >&2; cat "$raw"; rm -f "$raw"; exit 1; }
    if [ "$least" -eq 0 ] || [ "$ms" -lt "$least" ]; then least=$ms; fi
done
printf 'warm edit %s\n' "$least" >> "$raw"

cat "$raw"
python3 tools/speed_ratchet.py --warm --raw "$raw"
st=$?
rm -f "$raw"
exit $st
