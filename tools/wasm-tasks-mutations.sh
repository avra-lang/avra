#!/bin/sh
# THE HOSTED SCHEDULER, TESTED: one piece of its wasm port broken at a time,
# and a fixture must stop agreeing with its oracle for each. The C runtime
# tests cannot see this half — it exists only in a wasm build and in the JS
# host — so the fixtures (`tasks`, `cancel`) are the oracle, and a break they
# survive is a gap in them. Each kill names the numbered claims of the
# `cancel` fixture that moved, so a claim no break reaches is visible.
#
# A break is either a replacement in runtime/avra_fiber.c (built for wasm and
# swapped into the archive for the length of one build) or one in the JS host
# (runtime/dom/tasks.js, run from a copy). A break that does not apply is
# reported: the source moved and this table did not.
#
# NOT HERE, AND WHY (the canary): the check at a handover that a task's stack
# block still reads as it was written (`canary_held`) is not killed by any
# fixture. A hosted stack overflows only through frames that live in linear
# memory, which Avra source does not produce — a call's depth is bounded first
# by the engine, and the host speaks that limit as the same overflow (the
# `stack_overflow` fixture and its break below). THE DEADLINE: the first
# construct whose frames sit in memory is the day a fixture can overrun the
# canary, and its break joins this table.
#
# NOT HERE, AND WHY: dropping the stack-pointer restore after a resume
# (`shadow_set(mine)` in `fiber_switched`) is not killed by any fixture, and
# the case that would kill it cannot be built from Avra source: a function
# epilogue writes the global back from its own saved copy, so a wrong value
# heals at the next return, and it bites only when a NEW framed call parks
# inside its frame while another task allocates in the same region. The
# restore stays on the strength of that trace. THE DEADLINE: a program
# construct that parks inside a memory-resident frame (an escaping local) is
# the day to add the break here. The scheduler's own cancel and `within`
# logic is shared with native and mutation-tested by the C runtime tests
# (`make runtime-mutations`); what these breaks reach is the port under it.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
tree=$(cd "$here/.." && pwd)
avra=${AVRA:-$tree/build/avra}
work=${WASM_WORK:-$(mktemp -d "${TMPDIR:-/tmp}/avra-wmut.XXXXXX")}
lib=$tree/build/wasm32/libavra_runtime.a
say() { echo "wasm-tasks-mutations: $*" >&2; }
skip() { say "$* — skipped"; exit 0; }
. "$here/jspi_node.sh"

[ -x "$avra" ] || skip "no compiler at $avra"
command -v "$node" >/dev/null 2>&1 || skip "node not on PATH"
command -v clang >/dev/null 2>&1 || skip "clang not on PATH"
clang --print-targets 2>/dev/null | grep -q wasm32 || skip "clang has no wasm32 target"
( cd "$tree" && make -s wasm-runtime ) >/dev/null 2>&1 || skip "the wasm runtime archive did not build"
if "$node" --experimental-wasm-jspi -e 0 >/dev/null 2>&1; then jspi="--experimental-wasm-jspi"; else skip "this Node has no JSPI"; fi

cp "$lib" "$work/clean.a"
restore() { cp "$work/clean.a" "$lib"; ( cd "$tree" && make -s wasm-runtime ) >/dev/null 2>&1 || true; }
trap restore EXIT

# Build and run every fixture with the archive as it stands, under the host
# in `$1` (a directory holding tools/wasm-node.mjs and runtime/dom/tasks.js).
# Answers each fixture's stdout and stderr, after its name.
observe() {
    host=$1
    tag=$2
    for f in tasks cancel stack_overflow; do
        cp -R "$here/wasm-fixtures/$f" "$work/$tag-$f"
        out=$("$avra" build --target wasm32 "$work/$tag-$f" 2>/dev/null | tail -1)
        if [ -f "$out" ]; then
            res=$(timeout 30 "$node" --no-warnings $jspi "$host/tools/wasm-node.mjs" "$out" 2>&1) || true
        else
            res="(build failed)"
        fi
        printf '== %s\n%s\n' "$f" "$res"
    done
}

clean_host=$tree
clean_out=$(observe "$clean_host" clean)
# the oracle: every fixture's stdout is its expected.txt
for f in tasks cancel stack_overflow; do
    got=$(printf '%s\n' "$clean_out" | awk -v f="$f" '$0=="== " f{on=1; next} /^== /{on=0} on' | grep -v '^wasm-node:' || true)
    if [ -f "$here/wasm-fixtures/$f/refuses.txt" ]; then
        printf '%s\n' "$got" | grep -q "$(cat "$here/wasm-fixtures/$f/refuses.txt")" || { say "the clean $f fixture does not say its refuses.txt:"; printf '%s\n' "$got" >&2; exit 1; }
    else
        [ "$got" = "$(cat "$here/wasm-fixtures/$f/expected.txt")" ] || { say "the clean $f fixture does not answer its expected.txt:"; printf '%s\n' "$got" >&2; exit 1; }
    fi
done

fail=0
tried=0
verdict() { # name out
    if [ "$2" = "$clean_out" ]; then
        say "$1: SURVIVED — the fixtures still agree"
        fail=1
        return 0
    fi
    claims=""
    for n in 1 2 3 4 5 6 7; do
        a=$(printf '%s\n' "$clean_out" | grep -a "^$n " || true)
        b=$(printf '%s\n' "$2" | grep -a "^$n " || true)
        [ "$a" = "$b" ] || claims="$claims $n"
    done
    say "$1: killed${claims:+ (cancel claims moved:$claims)}"
}

c_break() { # name old new
    tried=$((tried + 1))
    python3 - "$tree/runtime/avra_fiber.c" "$work/mut.c" "$2" "$3" <<'PY' || { say "$1: its line is not in the source"; fail=1; return 0; }
import sys
src, out, old, new = sys.argv[1:5]
text = open(src).read()
if text.count(old) != 1:
    sys.exit(1)
open(out, "w").write(text.replace(old, new))
PY
    clang --target=wasm32-wasip1 -DAVRA_INSTRUMENTS=0 -I"$tree/runtime" -Oz -Wno-deprecated -ffunction-sections -fdata-sections \
        -D_WASI_EMULATED_MMAN -D_WASI_EMULATED_SIGNAL -D_WASI_EMULATED_GETPID -c -o "$work/avra_fiber.o" "$work/mut.c" 2>/dev/null \
        || { say "$1: does not build"; fail=1; return 0; }
    cp "$work/clean.a" "$lib"
    ( cd "$work" && ar r "$lib" avra_fiber.o ) >/dev/null 2>&1
    verdict "$1" "$(observe "$tree" "m$tried")"
    cp "$work/clean.a" "$lib"
}

js_break() { # name old new
    tried=$((tried + 1))
    h=$work/jshost$tried
    mkdir -p "$h/tools" "$h/runtime/dom"
    cp "$here/wasm-node.mjs" "$h/tools/"
    python3 - "$tree/runtime/dom/tasks.js" "$h/runtime/dom/tasks.js" "$2" "$3" <<'PY' || { say "$1: its line is not in the source"; fail=1; return 0; }
import sys
src, out, old, new = sys.argv[1:5]
text = open(src).read()
if text.count(old) != 1:
    sys.exit(1)
open(out, "w").write(text.replace(old, new))
PY
    verdict "$1" "$(observe "$h" "j$tried")"
}

c_break "a fresh task starts on its parent's shadow stack" \
    "    shadow_set(g_current->sp);
    fiber_start();" \
    "    fiber_start();"
c_break "a finished task is suspended for ever" \
    "avra_host_switch(self, next, self->state == FIBER_DONE, (void*)avra_task_entry, (void*)avra_asyncify_buffer);" \
    "avra_host_switch(self, next, 0, (void*)avra_task_entry, (void*)avra_asyncify_buffer);"
js_break "an ended task's slot answers the next task at its address" \
    "      if (ends) slots.delete(from);
      else slot(from).running = true;" \
    "      slot(from).running = true;"
js_break "a suspended task is never resumed" \
    "        next.resume();" \
    "        void next;"
js_break "an engine's stack overflow is spoken bare" \
    "  if (e instanceof RangeError && /call stack/i.test(e.message)) return \"avra: a task's stack overflowed\";
" \
    ""
js_break "the world waits for ever" \
    "        setTimeout(resolve, Number((ns + 999999n) / 1000000n));" \
    "        void ns;"


[ "$fail" -eq 0 ] || exit 1
say "$tried port breaks, each killed by the fixtures"
