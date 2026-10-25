# THE WASM KEEPERS' SHARED FLOOR, sourced once `wasm_who` names the voice and `here`, `tree` and `avra`
# are set. A missing tool skips, spoken, with status 0; a skip never hides a failed build.
#
#   say <words>        a line from the keeper, on stderr
#   skip <words>       say them, ended "skipped", and leave with 0
#   needs <tool>…      skip unless every tool is on PATH, naming the package that carries it
#   needs_wasm_clang   skip unless clang targets wasm32
#   needs_compiler     skip unless `avra` is a compiler
#   wasm_ready         the archive and package objects, current (lib/wasm_ready.sh)
. "$here/lib/wasm_ready.sh"
say() { echo "$wasm_who: $*" >&2; }
skip() { say "$* — skipped"; exit 0; }
needs() {
    for wasm_tool in "$@"; do
        command -v "$wasm_tool" >/dev/null 2>&1 && continue
        case $wasm_tool in
            wasm-opt) skip "wasm-opt (binaryen) not on PATH" ;;
            wasm-objdump | wasm-validate) skip "$wasm_tool (wabt) not on PATH" ;;
            *) skip "$wasm_tool not on PATH" ;;
        esac
    done
}
needs_wasm_clang() { needs clang; clang --print-targets 2>/dev/null | grep -q wasm32 || skip "clang has no wasm32 target"; }
needs_compiler() { [ -x "$avra" ] || skip "no compiler at $avra"; }
