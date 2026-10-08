#!/bin/sh
# A TRACE HAS ONE SHAPE IN BOTH ENGINES. Each program is run compiled
# and evaluated under `AVRA_FLOW_TRACE`, and what `avra trace` prints as
# each trace's shape — a task's events in order, with nothing an engine
# owns — must be the text committed beside the program, from both: a
# join of a spawned task, a join of a timer's task, a join of a task
# nothing runs answered by another, a wait on a descriptor, a task
# spawned in a generic fn another file uses. The program's directory
# is its package: the other `.av` files there go with it.
#
# A program is a package of its own under build/, so each engine reads
# one small file and a spawn's site reads the same wherever the tree
# stands. The check proves itself on fixtures first: a trace of the
# right shape is held, one with no join and one with no line at all are
# refused.
#
# The evaluated leg runs the compiler's binary itself: the `avra` shim
# gives a program no standard input, and one program here waits on it.
#
# THE EVALUATED LEG TRACES THE COMPILER'S OWN PROCESS, so a task the
# compiler itself spawned while evaluating would write into the
# program's trace under a compiled task's id. It spawns none; a
# compiled `spawn` line in an evaluated trace is refused by name.
set -e
cd "$(dirname "$0")/.."
: "${LLVM_PREFIX:=/opt/homebrew/opt/llvm}"
export LLVM_PREFIX

TESTS=packages/std-avrac/src/features/tasks/tests
PROGRAMS="$TESTS/traced_join/traced_join $TESTS/traced_timer/traced_timer $TESTS/traced_answer/traced_answer $TESTS/traced_generic/traced_generic tools/flow_trace/traced_fd"
ROOT=build/flow-trace
mkdir -p "$ROOT"

fails=0

# One trace held to a committed shape; 1 when it is not.
held() {
    engine="$1"; trace="$2"; want="$3"
    if [ "$engine" = evaluated ] && grep -q '^ts=[0-9-]* spawn id=' "$trace"; then
        echo "flow-trace: the compiler spawned a task of its own while it evaluated $want"
        return 1
    fi
    case "$trace" in /*) whole_path=$trace ;; *) whole_path=$PWD/$trace ;; esac
    if ! build/avra trace "$whole_path" --shape > "$trace.shape" 2> "$trace.strays"; then
        echo "flow-trace: the $engine trace of $want holds a line that is no event"; sed -n '1p' "$trace.strays"
        return 1
    fi
    cmp -s "$trace.shape" "$want" && return 0
    echo "flow-trace: the $engine trace's shape is not $want"
    diff "$want" "$trace.shape" || true
    return 1
}

# The fixtures: a compiled trace of the join program as the runtime
# writes it, the same with its joins left out, nothing, and an evaluated
# trace a compiled spawn wrote into.
fixtures() {
    self="$ROOT/self"; want="$TESTS/traced_join/traced_join.shape"
    mkdir -p "$self"
    cat > "$self/whole.trace" <<'TRACE'
ts=1 spawn id=1 0
ts=1 site id=1 zz-traced_join/main.av:10
ts=2 spawn id=2 0
ts=2 site id=2 zz-traced_join/main.av:11
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
    held compiled "$self/whole.trace" "$want" > /dev/null || broken="$broken [a whole trace is refused]"
    held compiled "$self/joinless.trace" "$want" > /dev/null && broken="$broken [a trace with no join is held]"
    held compiled "$self/empty.trace" "$want" > /dev/null && broken="$broken [an empty trace is held]"
    held evaluated "$self/whole.trace" "$want" > /dev/null && broken="$broken [a compiled spawn in an evaluated trace is held]"
    [ -z "$broken" ] && return 0
    echo "flow-trace: the check fails its own fixtures —$broken"
    return 1
}

fixtures || exit 1

events=0
programs=0
for program in $PROGRAMS; do
    name=$(basename "$program"); dir="$ROOT/$name"
    programs=$((programs + 1))
    mkdir -p "$dir/src"
    printf '[package]\nname    = "zz-%s"\nversion = "0.0.1"\n' "$name" > "$dir/avra.toml"
    for other in "$(dirname "$program")"/*.av; do
        [ "$other" = "$program.av" ] || cp "$other" "$dir/src/"
    done
    cp "$program.av" "$dir/src/main.av"
    if ! ./avra build "$dir" > "$dir/build.out" 2>&1; then
        echo "flow-trace: $name did not COMPILE"; sed -n '1,6p' "$dir/build.out"
        fails=$((fails + 1)); continue
    fi
    echo x | AVRA_FLOW_TRACE="$dir/compiled.trace" "$dir/src/main" > "$dir/compiled.out" 2>&1 || true
    echo x | AVRA_FLOW_TRACE="$dir/evaluated.trace" build/avra run "$dir" > "$dir/evaluated.out" 2>&1 || true
    for engine in compiled evaluated; do
        held "$engine" "$dir/$engine.trace" "$program.shape" || fails=$((fails + 1))
        events=$((events + $(grep -c '^ts=' "$dir/$engine.trace" 2>/dev/null || echo 0)))
    done
done
# A LIVE PROCESS'S LISTING IS A TRACE: the runtime's own scene of a task
# in every state, listed, and read back by the same graph — addresses and
# descriptor numbers left out, since they are the machine's.
dump=$ROOT/listed.trace
if build/runtime-tests/tasks_door_test listed -1 > "$dump" 2>&1 \
    && build/avra trace "$PWD/$dump" --graph | sed 's/0x[0-9a-f]*/0x/g; s/descriptor [0-9]*/descriptor N/' > "$dump.graph" \
    && cmp -s "$dump.graph" tools/flow_trace/listed.graph; then
    events=$((events + $(grep -c '^ts=' "$dump")))
else
    echo "flow-trace: a live listing's graph is not tools/flow_trace/listed.graph"
    diff tools/flow_trace/listed.graph "$dump.graph" || true
    fails=$((fails + 1))
fi
echo "flow-trace: 4 fixtures, $programs programs in 2 engines and a live listing, $events events read, $fails refused"
[ "$fails" -eq 0 ]
