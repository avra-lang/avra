#!/bin/sh
# THE HOST SEAM'S PROOF, END TO END: the board (tools/ui-board) is built
# as a wasm reactor and run over the real page glue by tools/ui-board/demo.mjs,
# which checks each claim and exits 1 on the first that fails. This is the one
# run that holds `mount`, the `avra_main` entry, the web module's exports and
# the names the host calls them by to a real module.
#
# It needs node and a wasm toolchain — the compiler finds one or says what is
# missing (`avra build --target wasm` exits 2). Where one is absent this
# SKIPS, spoken, in the compiler's own words — a machine without them is not
# falsely green. UI_BOARD_TARGET names one wasm triple (default `wasm`: the
# one this machine's toolchain links).
set -eu

. "$(dirname "$0")/lib/tree.sh"
target=${UI_BOARD_TARGET:-wasm}
work=$(mktemp -d "${TMPDIR:-/tmp}/avra-ui-board.XXXXXX")

skip() { echo "ui-board: SKIPPED — $* ; the board did not run on a page"; exit 0; }

[ -x "$avra" ] || skip "no compiler at $avra"
command -v node >/dev/null 2>&1 || skip "no \`node\` on this machine"
. "$here/lib/wasm_ready.sh"
wasm_ready || skip "the wasm runtime archive did not build"

# A COPY is built, so the tree's own object cache never holds a wasm object.
mkdir -p "$work/tools"
cp -R "$tree/tools/ui-board" "$work/tools/ui-board"
"$avra" build --time --target "$target" --wasm_reactor "$work/tools/ui-board" >"$work/build.out" 2>"$work/build.err" || built=$?
[ "${built:-0}" -ne 2 ] || skip "$(sed 's/^avra: //' "$work/build.err" | head -1)"
if [ "${built:-0}" -ne 0 ]; then
    echo "ui-board: the board did not build for $target"; cat "$work/build.err"; tail -20 "$work/build.out"; exit 1
fi
wasm=$(tail -1 "$work/build.out")
[ -f "$wasm" ] || { echo "ui-board: the build named no module ($wasm)"; exit 1; }

# A PAGE THAT NEITHER SPAWNS NOR WAITS LINKS NO SCHEDULER: the module imports
# none of its port (`avra_host`) and none of the file calls its trace file
# makes. The scheduler stays in the archive and is dropped by the linker's GC
# unless a reachable fn parks, so a count above zero is a root that holds it.
carried=$(node -e 'const m = new WebAssembly.Module(require("fs").readFileSync(process.argv[1])); console.log(WebAssembly.Module.imports(m).map((i) => i.module + "." + i.name).filter((n) => n.startsWith("avra_host.") || n === "wasi_snapshot_preview1.path_open").join(" "))' "$wasm")
[ -z "$carried" ] || { echo "ui-board: the board runs no task and carries a scheduler: $carried"; exit 1; }

shrunk="unshrunk (no wasm-opt on PATH)"
command -v "${WASM_OPT:-wasm-opt}" >/dev/null 2>&1 && shrunk="shrunk by ${WASM_OPT:-wasm-opt}"

# THE SAME BOARD WITH ONE WORD EDITED: the module a page swaps to on a view edit.
mkdir -p "$work/edited"
cp -R "$tree/tools/ui-board" "$work/edited/ui-board"
sed 's/fn title() -> string { "Tasks" }/fn title() -> string { "Tasks today" }/' "$tree/tools/ui-board/src/board.av" > "$work/edited/ui-board/src/board.av"
cmp -s "$tree/tools/ui-board/src/board.av" "$work/edited/ui-board/src/board.av" && { echo "ui-board: the edit found no heading to change"; exit 1; }
"$avra" build --target "$target" --wasm_reactor "$work/edited/ui-board" >"$work/edited.out" 2>"$work/edited.err" || { cat "$work/edited.err"; echo "ui-board: the edited board did not build"; exit 1; }
edited=$(tail -1 "$work/edited.out")

# THE SERVER'S FIRST PAGE, drawn natively from the same view: the print the
# module is held to and the bytes of HTML a page carries.
mkdir -p "$work/server/tools"
cp -R "$tree/tools/ui-board" "$work/server/tools/ui-board"
cp "$tree/tools/ui-board/hydrate/main.av" "$work/server/tools/ui-board/src/main.av"
if ! sent=$("$avra" run "$work/server/tools/ui-board" 2>"$work/hydrate.err"); then
    cat "$work/hydrate.err"; echo "ui-board: the server's page did not draw"; exit 1
fi

if ! out=$(node "$tree/tools/ui-board/demo.mjs" "$wasm" "$(echo "$sent" | sed -n 1p)" "$(echo "$sent" | sed -n 2p)" "$edited" "$(echo "$sent" | sed -n 3p)" 2>&1); then
    echo "$out" | grep -v '^ok ' ; echo "ui-board: the board failed on the page"; exit 1
fi
# WHAT THE HOST MAY CALL, and whose word each is: the module's host fns.
sed -n 's/^host fn: /ui-board: host fn /p' "$work/build.err"
echo "ui-board: $(echo "$out" | grep -c '^ok ') claims hold over a $(wc -c < "$wasm" | tr -d ' ')-byte module, $shrunk"
