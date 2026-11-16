#!/bin/sh
# EVERY DOOR TAKES THE PROGRAM LAYER UNDER AVRA_PROGRAM=1, OR REFUSES NAMING WHAT IS MISSING.
# Over tools/program-doors/ — `lone/probe.av`, a file in no package; `app`, a package with an entry
# and a program test; `specs`, a library whose suite holds a spec — each copied cold, each door run
# on the old path and on the program layer:
#   run of the lone file and of the package, test of the package and of its test's file, check of
#     the package, of its entry's file and of the lone file: the same exit and stdout, the program
#     layer's store left by its run alone; the lone file built on each path printing the same;
#   build of a library: the old path's "declares no entry point", exit 1;
#   test of a spec suite: the same exit and stdout;
#   build for another target: the same exit on both paths — where the target's toolchain stands, a
#     module written by each; where it does not, the toolchain's refusal in the same words;
#   a package pinning @std/text to a copy of its own: run against the copy on both paths, and a
#     second pin of it, to another directory, refused in the same words on both.
#   sh tools/witness_program_doors.sh [compiler]   (default build/avra-try)
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
avra=${1:-build/avra-try}
case $avra in /*) ;; *) avra="$root/$avra" ;; esac
[ -x "$avra" ] || { echo "witness_program_doors: no compiler at $avra" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'find "$tmp" -delete' EXIT
failed=0

# a fresh copy of the fixtures at $tmp/$1
fresh() { find "$tmp" -mindepth 1 -maxdepth 1 -name "$1" -exec find {} -delete \; ; mkdir -p "$tmp/$1"; cp -R "$root/tools/program-doors/." "$tmp/$1/"; }
# the door `$2…` run under AVRA_PROGRAM=$1 in a fresh copy, its stdout, stderr and exit at $tmp/out.$1
door() {
    p=$1; shift
    fresh "w$p"
    (cd "$tmp/w$p" && AVRA_PROGRAM=$p "$avra" "$@" >"$tmp/out.$p" 2>"$tmp/err.$p"; echo $? >"$tmp/code.$p")
    sed "s#$tmp/w$p#<w>#g" "$tmp/out.$p" >"$tmp/said.$p"
    sed "s#$tmp/w$p#<w>#g" "$tmp/err.$p" >"$tmp/told.$p"
}
missed() { echo "witness_program_doors: $1" >&2; failed=$((failed + 1)); }

# the door `$2…` the same on both paths, exit and stdout, the program layer's store standing at
# `$1` after its run and none there after the old path's
same() {
    store=$1; shift
    door 0 "$@"
    [ -d "$tmp/w0/$store/.avra-cache/tapes" ] && missed "\`$*\`: the old path ran the program layer"
    door 1 "$@"
    [ -d "$tmp/w1/$store/.avra-cache/tapes" ] || missed "\`$*\`: the program layer did not run it"
    [ "$(cat "$tmp/code.0")" = "$(cat "$tmp/code.1")" ] || missed "\`$*\`: exit $(cat "$tmp/code.0") on the old path, $(cat "$tmp/code.1") on the program layer"
    cmp -s "$tmp/said.0" "$tmp/said.1" || { missed "\`$*\`: stdout differs"; diff "$tmp/said.0" "$tmp/said.1" >&2; }
}

same lone run lone/probe.av
same app run app
same app test app
same app test app/src/tests/doubled/doubled.av
same app check app
same app check app/src/main.av
same lone check lone/probe.av
door 0 build specs
door 1 build specs
cmp -s "$tmp/told.0" "$tmp/told.1" && [ "$(cat "$tmp/code.1")" = 1 ] ||
    missed "\`build specs\`: a library's build is not refused in the old path's words"
for p in 0 1; do
    door $p build lone/probe.av
    out=$("$tmp/w$p/lone/probe" 2>&1)
    [ "$out" = "lone 42" ] || missed "the lone file built on the path AVRA_PROGRAM=$p prints \"$out\""
done
# each file of lone-equals-package/ built on the program layer alone in a directory of its own, alone
# under a package's root but outside its src/ (a lone file still, whatever manifest stands above),
# and as the src/main.av of a package: the same exit, a binary wherever the exit is 0 and none where
# it isn't, and the binaries, run under the guard, leave the same way printing the same
for src in "$root"/tools/program-doors/lone-equals-package/*.av; do
    name=$(basename "$src" .av)
    mkdir -p "$tmp/eq/$name/lone" "$tmp/eq/$name/pkg/src" "$tmp/eq/$name/above/src" "$tmp/eq/$name/above/out/x"
    cp "$src" "$tmp/eq/$name/lone/"
    cp "$src" "$tmp/eq/$name/above/out/x/"
    printf '[package]\nname = "above"\nversion = "0.0.1"\n' >"$tmp/eq/$name/above/avra.toml"
    AVRA_PROGRAM=1 "$avra" build "$tmp/eq/$name/above/out/x/$name.av" >/dev/null 2>"$tmp/eq/$name/above.err"
    above=$?
    cp "$src" "$tmp/eq/$name/pkg/src/main.av"
    printf '[package]\nname = "%s"\nversion = "0.0.1"\n' "$name" >"$tmp/eq/$name/pkg/avra.toml"
    AVRA_PROGRAM=1 "$avra" build "$tmp/eq/$name/lone/$name.av" >/dev/null 2>"$tmp/eq/$name/lone.err"
    lone=$?
    AVRA_PROGRAM=1 "$avra" build "$tmp/eq/$name/pkg" >/dev/null 2>"$tmp/eq/$name/pkg.err"
    pkg=$?
    [ "$lone" = "$pkg" ] || missed "$name: built alone it exits $lone, as a package $pkg"
    [ "$above" = "$lone" ] || missed "$name: built under a package's root, outside its src/, it exits $above, alone $lone"
    for shape in lone pkg above; do
        binary=$tmp/eq/$name/lone/$name
        [ "$shape" = pkg ] && binary=$tmp/eq/$name/pkg/src/main
        [ "$shape" = above ] && binary=$tmp/eq/$name/above/out/x/$name
        code=$lone
        [ "$shape" = pkg ] && code=$pkg
        [ "$shape" = above ] && code=$above
        if [ "$code" = 0 ] && [ ! -x "$binary" ]; then missed "$name ($shape): the build exited 0 and wrote no binary"; fi
        if [ "$code" != 0 ] && [ -x "$binary" ]; then missed "$name ($shape): the build exited $code and wrote a binary"; fi
        if [ -x "$binary" ]; then
            AVRA_RC_GUARD=1 "$binary" >"$tmp/eq/$name/$shape.out" 2>/dev/null
            echo $? >"$tmp/eq/$name/$shape.code"
        fi
    done
    if [ -e "$tmp/eq/$name/lone.code" ] || [ -e "$tmp/eq/$name/pkg.code" ]; then
        cmp -s "$tmp/eq/$name/lone.out" "$tmp/eq/$name/pkg.out" && cmp -s "$tmp/eq/$name/lone.code" "$tmp/eq/$name/pkg.code" ||
            missed "$name: run alone and as a package, it leaves otherwise"
        cmp -s "$tmp/eq/$name/lone.out" "$tmp/eq/$name/above.out" && cmp -s "$tmp/eq/$name/lone.code" "$tmp/eq/$name/above.code" ||
            missed "$name: run alone and under a package's root outside its src/, it leaves otherwise"
    fi
done
same specs test specs
door 0 build app --target wasm
door 1 build app --target wasm
if [ "$(cat "$tmp/code.0")" != "$(cat "$tmp/code.1")" ]; then
    missed "\`build app --target wasm\`: exit $(cat "$tmp/code.0") on the old path, $(cat "$tmp/code.1") on the program layer"
elif [ "$(cat "$tmp/code.1")" = 0 ]; then
    for p in 0 1; do
        built=$(tail -1 "$tmp/out.$p")
        case $built in *.wasm) [ -f "$built" ] || missed "\`build app --target wasm\` on the path AVRA_PROGRAM=$p wrote no module at $built" ;;
        *) missed "\`build app --target wasm\` on the path AVRA_PROGRAM=$p names no module: $built" ;; esac
    done
else
    cmp -s "$tmp/told.0" "$tmp/told.1" || { missed "\`build app --target wasm\`: the toolchain's refusal differs"; diff "$tmp/told.0" "$tmp/told.1" >&2; }
fi

# a package pinning @std/text to a copy of its own, its `repeat` writing one turn more: run against
# the copy on both paths; then a package it depends on pinning the toolchain's own copy, which is one
# name at two directories: refused alike on both
mkdir -p "$tmp/pin/app/src" "$tmp/pin/other/src"
cp -R "$root/packages/std-text" "$tmp/pin/text-copy"
find "$tmp/pin/text-copy" \( -name .avra-cache -o -name build \) -prune -exec find {} -delete \;
sed '/^export fn repeat(/,/^}/s/while i < n {/while i <= n {/' "$root/packages/std-text/src/text.av" >"$tmp/pin/text-copy/src/text.av"
printf '[package]\nname = "app"\nversion = "0.0.1"\n\n[dependencies]\n"@std/text" = { path = "../text-copy" }\n' >"$tmp/pin/app/avra.toml"
printf 'use @std.text.{repeat}\n\nrepeat("ab", 2)\n' >"$tmp/pin/app/src/main.av"
for p in 0 1; do
    out=$(cd "$tmp/pin/app" && AVRA_PROGRAM=$p "$avra" run . 2>&1)
    [ "$out" = "ababab" ] || missed "a pinned @std/text on the path AVRA_PROGRAM=$p prints \"$out\", not the copy's \"ababab\""
done
printf '[package]\nname = "@x/other"\nversion = "0.0.1"\n\n[lib]\nname = "x-other"\npath = "src/other.av"\n\n[dependencies]\n"@std/text" = { path = "%s" }\n' "$root/packages/std-text" >"$tmp/pin/other/avra.toml"
printf 'export fn one() -> int { 1 }\n' >"$tmp/pin/other/src/other.av"
printf '"@x/other" = { path = "../other" }\n' >>"$tmp/pin/app/avra.toml"
for p in 0 1; do
    find "$tmp/pin" -name .avra-cache -prune -exec find {} -delete \;
    (cd "$tmp/pin/app" && AVRA_PROGRAM=$p "$avra" build . >"$tmp/pin/said.$p" 2>&1; echo $? >"$tmp/pin/code.$p")
done
[ "$(cat "$tmp/pin/code.0")" = 1 ] && [ "$(cat "$tmp/pin/code.1")" = 1 ] ||
    missed "two pins of @std/text: exit $(cat "$tmp/pin/code.0") on the old path, $(cat "$tmp/pin/code.1") on the program layer"
grep -q "manifest.duplicate_package" "$tmp/pin/said.0" || missed "two pins of @std/text: the old path doesn't refuse them as one name at two directories"
cmp -s "$tmp/pin/said.0" "$tmp/pin/said.1" || { missed "two pins of @std/text: said otherwise"; diff "$tmp/pin/said.0" "$tmp/pin/said.1" >&2; }

[ "$failed" = 0 ] && echo "witness_program_doors: run, test (a spec suite too), check and build agree on both paths; another target builds where its toolchain stands and refuses alike where it does not; a std pin wins for the whole graph on both, and two pins refuse alike"
[ "$failed" = 0 ]
