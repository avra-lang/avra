#!/bin/sh
# EVERY DOOR TAKES THE PROGRAM LAYER, OR REFUSES NAMING WHAT IS MISSING, AS THE OLD PATH DID.
# Over tools/program-doors/ — `lone/probe.av`, a file in no package; `app`, a package with an entry
# and a program test; `specs`, a library whose suite holds a spec — each copied cold, each door run
# on the program layer and held to what the old path said of it, its last word frozen at cbc437f4
# before its deletion, in tools/program-doors.expected/:
#   run of the lone file and of the package, test of the package and of its test's file, check of
#     the package, of its entry's file and of the lone file: the old path's exit and stdout, the
#     program layer's store left by its run; the lone file built printing `lone 42`;
#   build of a library: the old path's "declares no entry point", exit 1;
#   test of a spec suite: the old path's exit and stdout;
#   build for another target: where the target's toolchain stands, a module written; where it does
#     not, the build refuses (exit 2), said untooled;
#   a package pinning @std/text to a copy of its own: run against the copy, and a second pin of it,
#     to another directory, refused in the old path's words.
#   sh tools/witness_program_doors.sh [compiler [case…]]   (default build/avra-try; every case)
#   sh tools/witness_program_doors.sh --cases               its cases, one a line, for the gate to deal
set -u
# a store is copied, counted or emptied here between builds, so each build saves its own before it answers
export AVRA_STORE_KEPT_HERE=1
# a test's words depend on whether every suite runs on past a failure: every one does, as the gate runs
# them, and tools/program-doors.expected/ says the doors' words under it
export AVRA_SUITE_ALL=1
root=$(cd "$(dirname "$0")/.." && pwd)
# THE CASES, each a door or a group of them that stands alone: named after the compiler, those run
# alone; named none, every one
cases() {
    printf '%s\n' lone-run app-run app-test app-test-file app-check app-check-file lone-check build-specs build-lone
    for src in "$root"/tools/program-doors/lone-equals-package/*.av; do echo "equals-$(basename "$src" .av)"; done
    printf '%s\n' specs-test target pin
}
if [ "${1:-}" = --cases ]; then cases; exit 0; fi
avra=${1:-build/avra-try}
[ $# -eq 0 ] || shift
only="$*"
for c in $only; do cases | grep -qx "$c" || { echo "witness_program_doors: no case $c — --cases lists them" >&2; exit 2; }; done
wanted() { [ -z "$only" ] || case " $only " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }
case $avra in /*) ;; *) avra="$root/$avra" ;; esac
[ -x "$avra" ] || { echo "witness_program_doors: no compiler at $avra" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'find "$tmp" -delete' EXIT
# a machine store of the witness's own, whatever store the caller names
export AVRA_CACHE_DIR="$tmp/machine"
failed=0

# a fresh copy of the fixtures at $tmp/$1
fresh() { find "$tmp" -mindepth 1 -maxdepth 1 -name "$1" -exec find {} -delete \; ; mkdir -p "$tmp/$1"; cp -R "$root/tools/program-doors/." "$tmp/$1/"; }
# the door `$2…` run in a fresh copy `w$1`, its stdout, stderr and exit at $tmp/out.$1
door() {
    p=$1; shift
    fresh "w$p"
    find "$tmp" -mindepth 1 -maxdepth 1 -name "m$p" -exec find {} -delete \; ; mkdir -p "$tmp/m$p"
    (cd "$tmp/w$p" && AVRA_CACHE_DIR="$tmp/m$p" "$avra" "$@" >"$tmp/out.$p" 2>"$tmp/err.$p"; echo $? >"$tmp/code.$p")
    sed "s#$tmp/w$p#<w>#g" "$tmp/out.$p" >"$tmp/said.$p"
    sed "s#$tmp/w$p#<w>#g" "$tmp/err.$p" >"$tmp/told.$p"
}
missed() { echo "witness_program_doors: $1" >&2; failed=$((failed + 1)); }

# what the old path said of the door named `$1`, frozen
expected="$root/tools/program-doors.expected"
# the door `$3…`, named `$1`, as the old path said it, exit and stdout, the program layer's store
# standing at `$2` after its run
same() {
    name=$1; store=$2; shift 2
    door 1 "$@"
    [ -d "$tmp/w1/$store/.avra-cache/tapes" ] || missed "\`$*\`: the program layer did not run it"
    [ "$(cat "$expected/$name.code")" = "$(cat "$tmp/code.1")" ] || missed "\`$*\`: exit $(cat "$expected/$name.code") on the old path, $(cat "$tmp/code.1") on the program layer"
    cmp -s "$expected/$name.out" "$tmp/said.1" || { missed "\`$*\`: stdout differs from the old path's"; diff "$expected/$name.out" "$tmp/said.1" >&2; }
}

! wanted lone-run || same lone-run lone run lone/probe.av
! wanted app-run || same app-run app run app
! wanted app-test || same app-test app test app
! wanted app-test-file || same app-test-file app test app/src/tests/doubled/doubled.av
! wanted app-check || same app-check app check app
! wanted app-check-file || same app-check-file app check app/src/main.av
! wanted lone-check || same lone-check lone check lone/probe.av
if wanted build-specs; then
    door 1 build specs
    cmp -s "$expected/build-specs.err" "$tmp/told.1" && [ "$(cat "$tmp/code.1")" = 1 ] ||
        missed "\`build specs\`: a library's build is not refused in the old path's words"
fi
if wanted build-lone; then
    door 1 build lone/probe.av
    out=$("$tmp/w1/lone/probe" 2>&1)
    [ "$out" = "lone 42" ] || missed "the lone file built prints \"$out\""
fi
# each file of lone-equals-package/ built on the program layer alone in a directory of its own, alone
# under a package's root but outside its src/ (a lone file still, whatever manifest stands above),
# and as the src/main.av of a package: the same exit, a binary wherever the exit is 0 and none where
# it isn't, and the binaries, run under the guard, leave the same way printing the same
for src in "$root"/tools/program-doors/lone-equals-package/*.av; do
    name=$(basename "$src" .av)
    wanted "equals-$name" || continue
    mkdir -p "$tmp/eq/$name/lone" "$tmp/eq/$name/pkg/src" "$tmp/eq/$name/above/src" "$tmp/eq/$name/above/out/x"
    cp "$src" "$tmp/eq/$name/lone/"
    cp "$src" "$tmp/eq/$name/above/out/x/"
    printf '[package]\nname = "above"\nversion = "0.0.1"\n' >"$tmp/eq/$name/above/avra.toml"
    "$avra" build "$tmp/eq/$name/above/out/x/$name.av" >/dev/null 2>"$tmp/eq/$name/above.err"
    above=$?
    cp "$src" "$tmp/eq/$name/pkg/src/main.av"
    printf '[package]\nname = "%s"\nversion = "0.0.1"\n' "$name" >"$tmp/eq/$name/pkg/avra.toml"
    "$avra" build "$tmp/eq/$name/lone/$name.av" >/dev/null 2>"$tmp/eq/$name/lone.err"
    lone=$?
    "$avra" build "$tmp/eq/$name/pkg" >/dev/null 2>"$tmp/eq/$name/pkg.err"
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
! wanted specs-test || same specs-test specs test specs
if wanted target; then
    door 1 build app --target wasm
    case $(cat "$tmp/code.1") in
        0)  built=$(tail -1 "$tmp/out.1")
            case $built in *.wasm) [ -f "$built" ] || missed "\`build app --target wasm\` wrote no module at $built" ;;
            *) missed "\`build app --target wasm\` names no module: $built" ;; esac ;;
        2)  echo "witness_program_doors: \`build app --target wasm\`: untooled — $(head -1 "$tmp/told.1")" ;;
        *)  missed "\`build app --target wasm\`: exit $(cat "$tmp/code.1")"; cat "$tmp/told.1" >&2 ;;
    esac
fi

# a package pinning @std/text to a copy of its own, its `repeat` writing one turn more: run against
# the copy; then a package it depends on pinning the toolchain's own copy, which is one name at two
# directories: refused in the old path's words
if wanted pin; then
    mkdir -p "$tmp/pin/app/src" "$tmp/pin/other/src"
    cp -R "$root/packages/std-text" "$tmp/pin/text-copy"
    find "$tmp/pin/text-copy" \( -name .avra-cache -o -name build \) -prune -exec find {} -delete \;
    sed '/^export fn repeat(/,/^}/s/while i < n {/while i <= n {/' "$root/packages/std-text/src/text.av" >"$tmp/pin/text-copy/src/text.av"
    printf '[package]\nname = "app"\nversion = "0.0.1"\n\n[dependencies]\n"@std/text" = { path = "../text-copy" }\n' >"$tmp/pin/app/avra.toml"
    printf 'use @std.text.{repeat}\n\nrepeat("ab", 2)\n' >"$tmp/pin/app/src/main.av"
    out=$(cd "$tmp/pin/app" && "$avra" run . 2>&1)
    [ "$out" = "ababab" ] || missed "a pinned @std/text prints \"$out\", not the copy's \"ababab\""
    printf '[package]\nname = "@x/other"\nversion = "0.0.1"\n\n[lib]\nname = "x-other"\npath = "src/other.av"\n\n[dependencies]\n"@std/text" = { path = "%s" }\n' "$root/packages/std-text" >"$tmp/pin/other/avra.toml"
    printf 'export fn one() -> int { 1 }\n' >"$tmp/pin/other/src/other.av"
    printf '"@x/other" = { path = "../other" }\n' >>"$tmp/pin/app/avra.toml"
    find "$tmp/pin" -name .avra-cache -prune -exec find {} -delete \;
    (cd "$tmp/pin/app" && "$avra" build . >"$tmp/pin/said.1" 2>&1; echo $? >"$tmp/pin/code.1")
    sed "s#$tmp/pin#<pin>#g; s#$root#<root>#g" "$tmp/pin/said.1" >"$tmp/pin/told.1"
    [ "$(cat "$tmp/pin/code.1")" = "$(cat "$expected/pin-twice.code")" ] ||
        missed "two pins of @std/text: exit $(cat "$expected/pin-twice.code") on the old path, $(cat "$tmp/pin/code.1") on the program layer"
    cmp -s "$expected/pin-twice.said" "$tmp/pin/told.1" || { missed "two pins of @std/text: said otherwise than the old path did"; diff "$expected/pin-twice.said" "$tmp/pin/told.1" >&2; }
fi

[ "$failed" = 0 ] && [ -n "$only" ] && echo "witness_program_doors: $only — as the whole witness holds them"
[ "$failed" = 0 ] && [ -z "$only" ] && echo "witness_program_doors: run, test (a spec suite too), check and build say what the old path said; another target builds where its toolchain stands; a std pin wins for the whole graph, and two pins refuse in the old path's words"
[ "$failed" = 0 ]
