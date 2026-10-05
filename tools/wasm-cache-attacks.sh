#!/bin/sh
# THE BUILD CACHE, ATTACKED ACROSS TARGETS. One program is built for the host
# and for wasm32 through ONE tree's stores; every step asks that a module is
# its own target's code and that what a build keeps is what it published.
#
# The wasm toolchain is a BUILD dependency: where `clang` has no wasm32 target
# the attacks SKIP with a spoken reason. `wasm-opt` is stood in for, so the
# shrunk module is told from the link's own answer by one appended byte.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
tree=$(cd "$here/.." && pwd)
avra=${AVRA:-$tree/build/avra}
target=${WASM_TARGET:-wasm32}
work=${WASM_WORK:-$(mktemp -d "${TMPDIR:-/tmp}/avra-wasm-cache.XXXXXX")}
pkg=$work/app
wasm=$pkg/src/main.wasm

say() { echo "wasm-cache-attacks: $*" >&2; }
skip() { say "$* — skipped"; exit 0; }

[ -x "$avra" ] || skip "no compiler at $avra"
command -v clang >/dev/null 2>&1 || skip "clang not on PATH"
clang --print-targets 2>/dev/null | grep -q wasm32 || skip "clang has no wasm32 target"
[ -f "$tree/build/wasm32/libavra_runtime.a" ] || ( cd "$tree" && make -s wasm-runtime ) || skip "the wasm runtime archive did not build"
# the host half links the host's own runtime, which a gate job may not hold yet
[ -f "$tree/build/libavra_runtime.a" ] || ( cd "$tree" && make -s build/libavra_runtime.a ) || { say "the host runtime archive did not build"; exit 1; }

mkdir -p "$pkg/src/words"
printf '[package]\nname    = "app"\nversion = "0.1.0"\n\n[bin]\nname = "app"\npath = "src/main.av"\n' > "$pkg/avra.toml"
printf 'use words.{word, first}\n\nprintln(word(first([2, 3]) ?? 0))\n' > "$pkg/src/main.av"
words() { printf 'export fn word(n: int) -> string { "%s ${n}" }\n\nexport fn first<T>(xs: List<T>) -> T? { xs.first() }\n\n%s\n' "$1" "$2" > "$pkg/src/words/mod.av"; }
words word ""
# the stand-in reads the optimizer's own shape — `… <module> -o <answer>` —
# never a position, so a flag the compiler adds moves nothing here
cat > "$work/mark-opt" <<'OPT'
#!/bin/sh
prev= module= answer=
for word; do
    [ "$word" = -o ] && module=$prev
    [ "$prev" = -o ] && answer=$word
    prev=$word
done
[ -n "$module" ] && [ -n "$answer" ] || exit 2
cp "$module" "$answer" && printf X >> "$answer"
OPT
chmod +x "$work/mark-opt"
export WASM_OPT=$work/mark-opt

fails=0
attacks=0
held() { attacks=$((attacks+1)); if "$@"; then echo "ok    $what"; else fails=$((fails+1)); echo "FAIL  $what"; fi; }
native() { "$avra" build "$pkg" > "$work/native.out" 2> "$work/native.err"; }
module() { "$avra" build --target "$target" "$@" "$pkg" > "$work/wasm.out" 2> "$work/wasm.err"; }
is_wasm() { [ "$(head -c 4 "$wasm" | od -An -c | tr -d ' ')" = '\0asm' ]; }
# the stand-in's byte ends a shrunk module, and only one
shrunk() { [ "$(tail -c 1 "$wasm")" = X ]; }
unstaged() { ! ls "$pkg/src" | grep -q '\.staged$'; }

native || { say "the host build failed"; cat "$work/native.err" >&2; exit 1; }
module || { say "the wasm build failed"; cat "$work/wasm.err" >&2; exit 1; }

what="a wasm build beside a host build's store is wasm";                     held is_wasm
what="a fresh module is the shrunk one";                                       held shrunk
cp "$wasm" "$work/fresh.wasm"
what="a module built again links";                                             held module
what="a reused module is the bytes the fresh build published";                 held cmp -s "$wasm" "$work/fresh.wasm"
what="a build leaves no staged file beside its module";                        held unstaged

# AN EDIT TO A GENERIC'S HOME RESTARTS THE DERIVATION, and the host builds it
# first: the restart must read the wasm store, never the host's objects
words "the word" ""
native || { say "the host build failed after an edit"; cat "$work/native.err" >&2; exit 1; }
what="a wasm build after a home's edit the host built first links";              held module
what="and is wasm";                                                            held is_wasm
words "the word" "export fn other() -> int { 1 }"
native || { say "the host build failed after a second edit"; cat "$work/native.err" >&2; exit 1; }
what="a wasm build after a new export the host built first links";             held module
what="and is wasm";                                                            held is_wasm

cp "$wasm" "$work/stripped.wasm"
what="a debug link builds";                                                    held module --wasm_debug
what="a debug link is not handed the stripped module";                         held test "$(wc -c < "$wasm")" -gt "$(wc -c < "$work/stripped.wasm")"
what="a reactor builds";                                                       held module --wasm_reactor
what="a reactor is not handed the command module";                             held sh -c "! cmp -s '$wasm' '$work/stripped.wasm'"
what="the command module, asked again, is the one first built";                held sh -c "'$avra' build --target '$target' '$pkg' >/dev/null 2>&1 && cmp -s '$wasm' '$work/stripped.wasm'"
what="the host's program still runs";                                          held sh -c "'$avra' build '$pkg' >/dev/null 2>&1 && [ \"\$('$pkg/src/main')\" = 'the word 2' ]"

echo "wasm-cache-attacks: $attacks attack(s), $fails failed"
[ "$fails" -eq 0 ]
