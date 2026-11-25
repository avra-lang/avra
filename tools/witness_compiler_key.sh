#!/bin/sh
# tool-witness: run by the gate's witness-b slice (tools/gate.sh), never twice
# A KEPT ARTIFACT IS ITS COMPILER'S, EMITTED AS IT ASKED: an object or a binary another compiler
# made, or this one made emitting otherwise, is never taken for this one's. A package is built by compiler A, then by B — A's bytes and one more, the least a
# compiler can differ by, its code and every answer it works out the same — and B must emit every
# object and link its binary anew, as any change to the compiler, in its C, its LLVM or its
# sources, must make it; then A, built again, takes its own objects again and links the binary
# its first build linked, so a key that only ever misses proves nothing.
#   sh tools/witness_compiler_key.sh [compiler]   (default build/avra)
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
src=${1:-$root/build/avra}
a="$root/build/avra-witness-key-a"
b="$root/build/avra-witness-key-b"
w=$(mktemp -d)
cleared() { find "$w" "$a" "$b" "$root/build/.avra-witness-key-a.print" "$root/build/.avra-witness-key-b.print" -delete 2>/dev/null; }
fail() { echo "witness_compiler_key: $*"; cleared; exit 1; }
cp "$src" "$a" && cp "$src" "$b" && printf '\n' >> "$b" || fail "the two compilers were not made"
mkdir -p "$w/p/src"
printf '[package]\nname = "key-witness"\nversion = "0.1.0"\n' > "$w/p/avra.toml"
printf 'fn twice(n: int) -> int { n * 2 }\nprintln("${twice(21)}")\n' > "$w/p/src/main.av"
kept="$w/p/.avra-cache/tapes-build"
built() { # <compiler>: the package built by it, its binary run
    AVRA_CACHE_DIR="$w/machine" "$1" build "$w/p" > "$w/out" 2>&1 || { cat "$w/out"; fail "$(basename "$1") did not build"; }
    [ "$("$w/p/src/main")" = 42 ] || fail "$(basename "$1")'s binary did not print 42"
}
kept_named() { find "$kept" -name "*.$1" | sed 's|.*/||' | sort; } # <ext>: the kept files of that kind
built "$a"; objects_a=$(kept_named o); binary_a=$(kept_named bin)
[ -n "$objects_a" ] || fail "A kept no object"
built "$a"
[ "$(kept_named o)" = "$objects_a" ] || fail "A, built again over nothing moved, emitted anew — the key never holds"
built "$b"
taken=$(kept_named o | grep -cxF "$objects_a")
owned=$(printf '%s\n' "$objects_a" | grep -c .)
fresh=$(kept_named o | grep -vxF "$objects_a" | grep -c .)
[ "$fresh" -ge "$owned" ] || fail "B emitted $fresh objects of its own beside A's $owned: it took A's as its"
kept_named bin | grep -qxF "$binary_a" && fail "B's binary is the one A linked"
built "$a"
[ "$(kept_named o | grep -cxF "$objects_a")" = "$owned" ] || fail "A, built after B, lost objects of its own"
[ "$(kept_named o | grep -c .)" = "$((owned + fresh))" ] || fail "A, built after B, emitted anew — its own objects did not stand"
[ "$(kept_named bin)" = "$binary_a" ] || fail "A, built after B, linked another binary than its first"
echo "witness_compiler_key: B emitted $fresh objects and its binary anew, taking none of A's $owned; A, again, took its own and linked its first binary"
# THE SAME COMPILER, ITS ENVIRONMENT ASKING ANOTHER EMISSION: frame pointers kept is another object of
# the same code, so A asked for them emits anew, and A asked for none takes its own again.
before=$(kept_named o | grep -c .)
AVRA_FRAME_POINTERS=1 built "$a"
framed=$(kept_named o | grep -vxF "$objects_a" | grep -c .)
[ "$framed" -ge "$((fresh + owned))" ] || fail "A with frame pointers emitted $((framed - fresh)) objects of its own beside its $owned: it took the ones without as its"
built "$a"
[ "$(kept_named o | grep -cxF "$objects_a")" = "$owned" ] || fail "A without frame pointers lost objects of its own"
[ "$(kept_named o | grep -c .)" = "$((before + framed - fresh))" ] || fail "A without frame pointers emitted anew — the objects it made without them did not stand"
echo "witness_compiler_key: A asked for frame pointers emitted $((framed - fresh)) objects anew; asked for none, it took its own"
cleared
exit 0
