#!/bin/sh
# A TRACE HAS ONE SHAPE IN BOTH ENGINES. One program is run compiled
# and evaluated under `AVRA_FLOW_TRACE`, and what the reader prints as
# each trace's shape — a task's events in order, with nothing an engine
# owns — must be the committed text, from both.
#
# The program is a program test too; here it is a package of its own
# under build/, so each engine reads one small file.
set -e
cd "$(dirname "$0")/.."
: "${LLVM_PREFIX:=/opt/homebrew/opt/llvm}"
export LLVM_PREFIX

PROGRAM=packages/std-avrac/src/features/tasks/tests/traced_join/traced_join
ROOT=build/flow-trace
mkdir -p "$ROOT/src"
printf '[package]\nname    = "zz-flow-trace"\nversion = "0.0.1"\n' > "$ROOT/avra.toml"
cp "$PROGRAM.av" "$ROOT/src/main.av"

if ! ./avra build "$ROOT" > "$ROOT/build.out" 2>&1; then
    echo "flow-trace: the program did not COMPILE"; sed -n '1,6p' "$ROOT/build.out"
    exit 1
fi
AVRA_FLOW_TRACE="$ROOT/compiled.trace" "$ROOT/src/main" > "$ROOT/compiled.out" 2>&1
AVRA_FLOW_TRACE="$ROOT/evaluated.trace" ./avra run "$ROOT" > "$ROOT/evaluated.out" 2>&1

fails=0
for engine in compiled evaluated; do
    if ! python3 tools/flow_trace.py "$ROOT/$engine.trace" --shape > "$ROOT/$engine.shape"; then
        echo "flow-trace: the $engine trace holds a line that is no event"
        fails=$((fails + 1))
    elif ! cmp -s "$ROOT/$engine.shape" "$PROGRAM.shape"; then
        echo "flow-trace: the $engine trace's shape is not the committed one"
        diff "$PROGRAM.shape" "$ROOT/$engine.shape" || true
        fails=$((fails + 1))
    fi
done
echo "flow-trace: 2 engines, $(wc -l < "$PROGRAM.shape" | tr -d ' ') lines of shape, $fails refused"
[ "$fails" -eq 0 ]
