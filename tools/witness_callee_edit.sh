#!/bin/sh
# `MEMCAP=<memcap.sh> sh tools/witness_callee_edit.sh`
#
# A CALLER'S OBJECT FOLLOWS ITS CALLEE'S BODY. `main` settles a constant from `f`, a
# fn in another module: the constant's value is a function of `f`'s body, and lands in
# `main`'s object. Build the package cold, edit ONLY `f`'s body (no signature moves),
# and build again over the warm store: the program must print the new value. A stale
# object prints the old one with nothing failing, so the check is the program's answer.
#
# The witness examined something only if the first build left kept objects behind for the
# second to reuse, so that is counted and asserted before the answer is.
#
# A standalone witness, never a gate step: two small package builds. MEMCAP names the
# memory-cap wrapper each build runs under (cap 4000 MB).
set -u

memcap="${MEMCAP:?MEMCAP must name the memory-cap wrapper, memcap.sh}"
tree="$(cd "$(dirname "$0")/.." && pwd)"
logs="$(mktemp -d "${TMPDIR:-/tmp}/avra-witness-callee.XXXXXX")"
pkg="$logs/pkg"

export LLVM_PREFIX="${LLVM_PREFIX:-/opt/homebrew/opt/llvm}"
avra="$tree/build/avra"

mkdir -p "$pkg/src/util"
cat > "$pkg/avra.toml" <<'TOML'
[package]
name        = "callee"
version     = "0.0.1"
description = "A caller's constant settled from a callee in another module"
TOML
printf 'export fn f() -> int {\n    41\n}\n' > "$pkg/src/util/b.av"
printf 'use util.{f}\n\nconst x: int = f()\n\nprintln("x=${x}")\n' > "$pkg/src/main.av"

build() { # build <label>
    (cd "$pkg" && sh "$memcap" 4000 "$avra" build . > "$logs/$1.log" 2>&1)
    echo $? > "$logs/$1.exit"
}

answer() { "$pkg/src/main" 2> /dev/null; }

build cold
if [ "$(cat "$logs/cold.exit")" != 0 ]; then echo "witness_callee_edit: the cold build failed ($logs/cold.log)"; exit 1; fi
first="$(answer)"

kept="$(find "$pkg" -name .avra-cache -type d -exec find {} -type f \; | wc -l | tr -d ' ')"
if [ "$kept" = 0 ]; then echo "witness_callee_edit: the cold build kept nothing, so the warm build reuses nothing ($logs)"; exit 1; fi

# one fn's body moves; no signature does
printf 'export fn f() -> int {\n    42\n}\n' > "$pkg/src/util/b.av"
build warm
if [ "$(cat "$logs/warm.exit")" != 0 ]; then echo "witness_callee_edit: the warm build failed ($logs/warm.log)"; exit 1; fi
second="$(answer)"

echo "witness_callee_edit: cold '$first', warm '$second', $kept kept files ($logs)"
if [ "$first" = "x=41" ] && [ "$second" = "x=42" ]; then
    echo "witness_callee_edit: the caller's object followed its callee's body"
    exit 0
fi
echo "witness_callee_edit: the warm build answered '$second' where '$first' became x=42 — a stale caller"
exit 1
