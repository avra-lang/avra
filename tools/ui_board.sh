#!/bin/sh
# THE HOST SEAM'S PROOF, END TO END: the board (tools/ui-board/web) is built
# as a wasm reactor and run over the real page glue by tools/ui-board/demo.mjs,
# which checks each claim and exits 1 on the first that fails. This is the one
# run that holds `mount`, the `avra_main` entry, the web module's exports and
# the names the host calls them by to a real module.
#
# It needs node, a clang that links wasm32 against a WASI sysroot, and the wasm
# runtime archive. Where one is absent this SKIPS, spoken, naming what is
# missing — a machine without them is not falsely green. `wasm-opt` is used
# when it is on PATH and the line that reports success says whether it was.
# UI_BOARD_TARGET names another wasm triple (default `wasm`).
set -eu

here=$(cd "$(dirname "$0")" && pwd)
tree=$(cd "$here/.." && pwd)
avra=${AVRA:-$tree/build/avra}
target=${UI_BOARD_TARGET:-wasm}
work=$(mktemp -d "${TMPDIR:-/tmp}/avra-ui-board.XXXXXX")

skip() { echo "ui-board: SKIPPED — $* ; the board did not run on a page"; exit 0; }

[ -x "$avra" ] || skip "no compiler at $avra"
command -v node >/dev/null 2>&1 || skip "no \`node\` on this machine"
command -v clang >/dev/null 2>&1 || skip "no \`clang\` on PATH"
clang --print-targets 2>/dev/null | grep -q wasm32 || skip "clang has no wasm32 target"
triple=$target
case "$target" in wasm|wasm32|wasm32-wasi) triple=wasm32-unknown-wasi ;; esac
echo 'int main(void) { return 0; }' > "$work/probe.c"
clang --target="$triple" "$work/probe.c" -o "$work/probe.wasm" >/dev/null 2>&1 || skip "clang cannot link a $triple program (no WASI sysroot for it)"
if [ ! -f "$tree/build/wasm32/libavra_runtime.a" ]; then
    ( cd "$tree" && make -s wasm-runtime ) >/dev/null 2>&1 || skip "the wasm runtime archive did not build"
fi

# A COPY is built, so the tree's own object cache never holds a wasm object.
mkdir -p "$work/tools"
cp -R "$tree/tools/ui-board" "$work/tools/ui-board"
if ! "$avra" build --target "$target" --wasm_reactor "$work/tools/ui-board/web" >"$work/build.out" 2>"$work/build.err"; then
    echo "ui-board: the board did not build for $target"; cat "$work/build.err"; tail -20 "$work/build.out"; exit 1
fi
wasm=$(tail -1 "$work/build.out")
[ -f "$wasm" ] || { echo "ui-board: the build named no module ($wasm)"; exit 1; }

shrunk="unshrunk (no wasm-opt on PATH)"
command -v "${WASM_OPT:-wasm-opt}" >/dev/null 2>&1 && shrunk="shrunk by ${WASM_OPT:-wasm-opt}"

if ! out=$(node "$tree/tools/ui-board/demo.mjs" "$wasm" 2>&1); then
    echo "$out" | grep -v '^ok ' ; echo "ui-board: the board failed on the page"; exit 1
fi
echo "ui-board: $(echo "$out" | grep -c '^ok ') claims hold over a $(wc -c < "$wasm" | tr -d ' ')-byte module, $shrunk"
