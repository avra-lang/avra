#!/bin/sh
# A TRACE HAS ONE SHAPE IN BOTH ENGINES. One program is run compiled
# and evaluated under `AVRA_FLOW_TRACE`, and what the reader prints as
# each trace's shape — a task's events in order, with nothing an engine
# owns — must be the committed text, from both.
#
# The program is a program test too; here it is a package of its own
# under build/, so each engine reads one small file. The check proves
# itself on fixtures first: a trace of the right shape is held, one
# with no join and one with no line at all are refused.
set -e
cd "$(dirname "$0")/.."
: "${LLVM_PREFIX:=/opt/homebrew/opt/llvm}"
export LLVM_PREFIX

PROGRAM=packages/std-avrac/src/features/tasks/tests/traced_join/traced_join
ROOT=build/flow-trace
mkdir -p "$ROOT/src"
printf '[package]\nname    = "zz-flow-trace"\nversion = "0.0.1"\n' > "$ROOT/avra.toml"
cp "$PROGRAM.av" "$ROOT/src/main.av"

fails=0

# One engine's trace held to the committed shape; 1 when it is not.
held() {
    engine="$1"; trace="$2"
    if ! python3 tools/flow_trace.py "$trace" --shape > "$trace.shape" 2> "$trace.strays"; then
        echo "flow-trace: the $engine trace holds a line that is no event"; sed -n '1p' "$trace.strays"
        return 1
    fi
    cmp -s "$trace.shape" "$PROGRAM.shape" && return 0
    echo "flow-trace: the $engine trace's shape is not the committed one"
    diff "$PROGRAM.shape" "$trace.shape" || true
    return 1
}

# The fixtures: a compiled trace of the program as the runtime writes it,
# the same with its joins left out, and nothing.
fixtures() {
    self="$ROOT/self"
    mkdir -p "$self"
    cat > "$self/whole.trace" <<'TRACE'
ts=1 spawn id=1 0
ts=2 spawn id=2 0
ts=3 join id=0 on=2
ts=4 park id=0 src=gate:0x7f00 arm=0:0
ts=5 park id=1 src=at arm=0:0
ts=6 join id=2 on=1
ts=7 park id=2 src=gate:0x7f40 arm=0:0
ts=8 claim id=1 by=timer arm=0:0
ts=9 claim id=2 by=1 arm=0:0
ts=10 end id=1 0
ts=11 claim id=0 by=2 arm=0:0
ts=12 end id=2 0
TRACE
    grep -v ' join \| by=[12] ' "$self/whole.trace" > "$self/joinless.trace"
    : > "$self/empty.trace"
    broken=""
    held fixture "$self/whole.trace" > /dev/null || broken="$broken [a whole trace is refused]"
    held fixture "$self/joinless.trace" > /dev/null && broken="$broken [a trace with no join is held]"
    held fixture "$self/empty.trace" > /dev/null && broken="$broken [an empty trace is held]"
    [ -z "$broken" ] && return 0
    echo "flow-trace: the check fails its own fixtures —$broken"
    return 1
}

fixtures || exit 1

if ! ./avra build "$ROOT" > "$ROOT/build.out" 2>&1; then
    echo "flow-trace: the program did not COMPILE"; sed -n '1,6p' "$ROOT/build.out"
    exit 1
fi
AVRA_FLOW_TRACE="$ROOT/compiled.trace" "$ROOT/src/main" > "$ROOT/compiled.out" 2>&1 || true
AVRA_FLOW_TRACE="$ROOT/evaluated.trace" ./avra run "$ROOT" > "$ROOT/evaluated.out" 2>&1 || true

events=0
for engine in compiled evaluated; do
    held "$engine" "$ROOT/$engine.trace" || fails=$((fails + 1))
    events=$((events + $(grep -c '^ts=' "$ROOT/$engine.trace" 2>/dev/null || echo 0)))
done
echo "flow-trace: 3 fixtures, 2 engines, $events events read, $fails refused"
[ "$fails" -eq 0 ]
