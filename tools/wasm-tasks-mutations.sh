#!/bin/sh
# THE HOSTED SCHEDULER, TESTED: one line of its wasm port broken at a time,
# and the `tasks` fixture must stop agreeing with native for each. The C
# runtime tests cannot see this half — it exists only in a wasm build — so the
# fixture is the oracle, and a break it survives is a gap in it.
#
# NOT HERE, AND WHY: dropping the stack-pointer restore after a resume
# (`shadow_set(mine)` in `fiber_switched`) is not killed by any fixture, and
# the case that would kill it cannot be built from Avra source: a function
# epilogue writes the global back from its own saved copy, so a wrong value
# heals at the next return, and it bites only when a NEW framed call parks
# inside its frame while another task allocates in the same region. The
# restore stays on the strength of that trace. THE DEADLINE: a program
# construct that parks inside a memory-resident frame (an escaping local) is
# the day to add the break here.
#
# Each break replaces ONE piece of runtime/avra_fiber.c, builds that object for
# wasm, swaps it into the archive for the length of one build, and runs the
# fixture under the host. A break that does not apply is reported: it means
# the source moved and this table did not.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
tree=$(cd "$here/.." && pwd)
avra=${AVRA:-$tree/build/avra}
node=${NODE:-node}
work=${WASM_WORK:-$(mktemp -d "${TMPDIR:-/tmp}/avra-wmut.XXXXXX")}
lib=$tree/build/wasm32/libavra_runtime.a
say() { echo "wasm-tasks-mutations: $*" >&2; }
skip() { say "$* — skipped"; exit 0; }

[ -x "$avra" ] || skip "no compiler at $avra"
command -v "$node" >/dev/null 2>&1 || skip "node not on PATH"
command -v clang >/dev/null 2>&1 || skip "clang not on PATH"
clang --print-targets 2>/dev/null | grep -q wasm32 || skip "clang has no wasm32 target"
( cd "$tree" && make -s wasm-runtime ) >/dev/null 2>&1 || skip "the wasm runtime archive did not build"
jspi=""
if "$node" --experimental-wasm-jspi -e 0 >/dev/null 2>&1; then jspi="--experimental-wasm-jspi"; else skip "this Node has no JSPI"; fi

cp -R "$here/wasm-fixtures/tasks" "$work/pkg"
cp "$lib" "$work/clean.a"
restore() { cp "$work/clean.a" "$lib"; ( cd "$tree" && make -s wasm-runtime ) >/dev/null 2>&1 || true; }
trap restore EXIT

# the fixture's answer under the clean archive is the oracle
want=$("$avra" build --target wasm32 "$work/pkg" 2>/dev/null | tail -1)
[ -f "$want" ] || { say "the clean fixture did not build"; exit 1; }
clean_out=$("$node" --no-warnings $jspi "$here/wasm-node.mjs" "$want" 2>&1) || true
case "$clean_out" in spawned*) : ;; *) say "the clean fixture does not answer: $clean_out"; exit 1 ;; esac

fail=0
tried=0
try() { # name old new
    name=$1
    tried=$((tried + 1))
    python3 - "$tree/runtime/avra_fiber.c" "$work/mut.c" "$2" "$3" <<'PY' || { say "$name: its line is not in the source"; fail=1; return 0; }
import sys
src, out, old, new = sys.argv[1:5]
text = open(src).read()
if text.count(old) != 1:
    sys.exit(1)
open(out, "w").write(text.replace(old, new))
PY
    clang --target=wasm32-wasip1 -DAVRA_INSTRUMENTS=0 -I"$tree/runtime" -Oz -Wno-deprecated -ffunction-sections -fdata-sections \
        -D_WASI_EMULATED_MMAN -D_WASI_EMULATED_SIGNAL -D_WASI_EMULATED_GETPID -c -o "$work/avra_fiber.o" "$work/mut.c" 2>/dev/null \
        || { say "$name: does not build"; fail=1; return 0; }
    cp "$work/clean.a" "$lib"
    ( cd "$work" && ar r "$lib" avra_fiber.o ) >/dev/null 2>&1
    # a package of its own each time: a kept binary must not answer for the archive that changed
    cp -R "$here/wasm-fixtures/tasks" "$work/pkg$tried"
    got=$("$avra" build --target wasm32 "$work/pkg$tried" 2>/dev/null | tail -1)
    if [ -f "$got" ]; then
        out=$(timeout 20 "$node" --no-warnings $jspi "$here/wasm-node.mjs" "$got" 2>&1) || true
    else
        out="(build failed)"
    fi
    if [ "$out" = "$clean_out" ]; then
        say "$name: SURVIVED — the fixture still agrees"
        fail=1
    else
        say "$name: killed"
    fi
}

try "a fresh task starts on its parent's shadow stack" \
    "    shadow_set(g_current->sp);
    fiber_start();" \
    "    fiber_start();"
try "a finished task is suspended for ever" \
    "avra_host_switch(self, next, self->state == FIBER_DONE);" \
    "avra_host_switch(self, next, 0);"

[ "$fail" -eq 0 ] || exit 1
say "$tried hosted breaks, each killed by the tasks fixture"
