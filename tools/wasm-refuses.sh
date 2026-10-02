#!/bin/sh
# A non-host target has no body for a fiber, a core, or a package's C. A
# program that reaches one is refused BY NAME — never a linker's
# "undefined symbol", which accuses the innocent. Each fixture below is such a
# program, and the voice it must speak is data here.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
tree=$(cd "$here/.." && pwd)
avra=${AVRA:-$tree/build/avra}
work=${WASM_WORK:-$(mktemp -d "${TMPDIR:-/tmp}/avra-refuses.XXXXXX")}

say() { echo "wasm-refuses: $*" >&2; }
[ -x "$avra" ] || { say "no compiler at $avra"; exit 1; }

# fixture name -> the symbol the refusal must name
check() {
    name=$1
    want=$2
    rm -rf "$work/$name"
    cp -R "$here/wasm-refuses/$name" "$work/$name"
    if "$avra" build --target wasm "$work/$name" >"$work/$name.out" 2>"$work/$name.err"; then
        say "$name: the build succeeded, and it must refuse"
        return 1
    fi
    if ! cat "$work/$name.out" "$work/$name.err" | grep -q "a wasm module has no body for .*${want}"; then
        say "$name: the refusal does not name ${want}"
        cat "$work/$name.out" "$work/$name.err" | tail -3 >&2
        return 1
    fi
    say "$name: refused, naming ${want}"
}

fail=0
check fiber 'avra_task_spawn' || fail=1
check package '@std/io' || fail=1
[ "$fail" -eq 0 ] || exit 1
say "both refusals speak"
