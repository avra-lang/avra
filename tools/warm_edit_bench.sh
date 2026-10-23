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
# stderr. THE STORE MEASURED IS THE COMPILER'S OWN (the tree's is set aside and
# put back) and a run that cannot judge is a
# FAILURE, never a silent pass: a named reason and status 1, with the
# `skip warm-edit` marker on stdout. The ONLY skip is a hand-set
# `WARM_EDIT_SKIP` (the workflow's `warm_skip` input), and even then it says
# so loudly. On macOS the measurement goes to the lane's Sprite
# (`tools/work run`), as `speed-ratchet` does — a loaded Mac supplies no
# number, and a worktree with no Sprite refuses rather than passing.
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
avra=${AVRA_SPEED_BIN:-build/avra}
rounds=${SPEED_ROUNDS:-3}
target=${SPEED_TARGET:-packages/cli}
file=${SPEED_EDIT_FILE:-packages/cli/src/commands/shared.av}
lit=${SPEED_EDIT_LIT:-· memo}
case "$rounds" in ''|*[!0-9]*) rounds=3 ;; esac

# A SKIP IS A FAILURE. `WARM_EDIT_SKIP` is the ONE hand-set opt-out — the
# workflow's `warm_skip` input passes it, and a human sets it nowhere else.
# With it the reason goes out LOUDLY and the status is 0; without it a run
# that cannot judge REFUSES, with a named reason and the `skip warm-edit`
# marker on stdout.
refuse() { # <reason>
    echo "warm_edit_bench: $1" >&2
    if [ -n "${WARM_EDIT_SKIP:-}" ]; then
        echo "warm_edit_bench: SKIPPED BY REQUEST (WARM_EDIT_SKIP=${WARM_EDIT_SKIP}) — the warm gate is NOT judged" >&2
        echo "skip warm-edit"
        exit 0
    fi
    echo "warm_edit_bench: this is a FAILURE — the warm-edit gate cannot judge; set WARM_EDIT_SKIP=1 by hand only to skip" >&2
    echo "skip warm-edit"
    exit 1
}

# A Mac has no number of its own: this lane's Sprite has. Re-run there, and
# answer its status. A worktree with no Sprite cannot judge, so it refuses.
if [ "$(uname -s)" = "Darwin" ] && [ "${SPEED_LOCAL:-0}" != "1" ]; then
    sprite=$(cat "$(git rev-parse --absolute-git-dir)/avra-sprite" 2>/dev/null || :)
    [ -n "$sprite" ] || refuse "no Sprite bound to this worktree"
    exec sh tools/work run "sh tools/warm_edit_bench.sh"
fi

[ -x "$avra" ] || refuse "no compiler at $avra — build it first"
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
wall() { # -> "<ms> <status>"; an answer that never came reads as 0 ms and a failed check
    s=$(now)
    "$avra" check "$target" >/dev/null 2>&1
    st=$?
    e=$(now)
    printf '%s %s\n' "$(((e - s) / 1000000))" "$st"
}

# A CEILING IS READ FROM A STORE THE COMPILER UNDER TEST WROTE. A store restored from elsewhere
# (CI's cache, another compiler's run) holds answers this compiler did not make, and an edit over
# it prices their holds, not this compiler's edit path. The tree's own store is set aside, warmed
# here by one unchanged check, and put back when the run ends, so what follows still has it.
held=$(mktemp -d)
orig=$(mktemp)
cp "$file" "$orig"
restore() {
    cp "$orig" "$file"
    rm -f "$orig"
    [ ! -d .avra-cache ] || mv .avra-cache "$held/measured"
    [ ! -d "$held/kept" ] || mv "$held/kept" .avra-cache
    find "$held" -delete
}
trap restore EXIT INT TERM
[ ! -d .avra-cache ] || mv .avra-cache "$held/kept"
set -- $(wall)
[ "${2:-1}" = 0 ] || { echo "warm_edit_bench: the warming check exited ${2:-1} — not measured" >&2; exit 1; }

# A FRESH EDIT per round, of the same WIDTH every run (a count of bytes written is exact only
# if the edit's text is): the appended word carries a run nonce and the
# round's own name, so no round lands on a store hit.
nonce=${SPEED_NONCE:-$(date +%s)-$(printf '%07d' $$)}
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
    ms=${1:-0}; st=${2:-1}
    [ "$st" = 0 ] || { echo "warm_edit_bench: an unchanged check exited $st — not measured" >&2; cat "$raw"; rm -f "$raw"; exit 1; }
    if [ "$least" -eq 0 ] || [ "$ms" -lt "$least" ]; then least=$ms; fi
done
printf 'warm unchanged %s\n' "$least" >> "$raw"
# WHERE THE HIT'S MILLISECONDS GO, to stderr beside the number: the process's own
# start (an arg-less run, no check) and the check's `--time` phases, so a runner that
# is slower reads as a slower START, never as a slower compiler. Not judged.
s0=$(now); "$avra" rules >/dev/null 2>&1; e0=$(now)
echo "warm_edit_bench: startup $(((e0 - s0) / 1000000)) ms (\`avra rules\`, no check)" >&2
"$avra" check --time "$target" 2>&1 >/dev/null | grep '^time:' | sed 's/^/warm_edit_bench: unchanged /' >&2

# ONE BODY EDIT per round, each a miss; the LEAST is the edit's price.
least=0
i=0
while [ "$i" -lt "$rounds" ]; do
    i=$((i + 1))
    edit "warm$i"
    set -- $(wall)
    ms=${1:-0}; st=${2:-1}
    [ "$st" = 0 ] || { echo "warm_edit_bench: an edited check exited $st — not measured" >&2; cat "$raw"; rm -f "$raw"; exit 1; }
    if [ "$least" -eq 0 ] || [ "$ms" -lt "$least" ]; then least=$ms; fi
done
printf 'warm edit %s\n' "$least" >> "$raw"

# THE WORK, COUNTED: what the unchanged check and one more fresh edit DID, as the
# compiler counts it (`check --counts`, compiler/work.av) — exact on every machine,
# so tools/work_ratchet.py holds it with no slack. One round each, the edit never
# a store hit.
counted() { # <scenario>: `counts <scenario> <counter> <n>` rows from one check, its whole-read attribution to stderr
    out=$("$avra" check --counts "$target" 2>&1 >/dev/null)
    printf '%s\n' "$out" | grep -E '^(whole|why):' | sed "s/^/$1 /" >&2
    printf '%s\n' "$out" | grep '^counts:' | tail -n 1 | tr ' ' '\n' | grep = \
        | while IFS== read -r name n; do printf 'counts %s %s %s\n' "$1" "$name" "$n"; done
}
counted unchanged >> "$raw"
edit "counts"
counted edit >> "$raw"

cat "$raw"
# `WARM_EDIT_ACCEPT` lowers this host's warm ceilings to what was measured
# (never raises one); a human sets it when a real run landed under them.
[ -z "${WARM_EDIT_ACCEPT:-}" ] || echo "warm_edit_bench: --accept — the warm ceilings may only fall" >&2
python3 tools/speed_ratchet.py --warm ${WARM_EDIT_ACCEPT:+--accept} --raw "$raw"
st=$?
# `WORK_ACCEPT` lowers the work-count ceilings to what was counted (never raises one).
python3 tools/work_ratchet.py ${WORK_ACCEPT:+--accept} --raw "$raw" >&2 || st=1
rm -f "$raw"
exit $st
