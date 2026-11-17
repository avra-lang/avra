#!/bin/sh
# tool-witness: run
# A PROJECT BUILT OVER A WARM MACHINE STORE BUILDS WHAT A FULLY COLD BUILD BUILDS. The machine store
# (`AVRA_MACHINE_STORE=1`, under `AVRA_CACHE_DIR`) keeps once the answers every package this binary
# builds shares; a project reuses one only where its record still holds. Each case below builds a
# product two ways and the two must be one file:
#   (a) the cli with every store empty, machine store on, against the machine store off;
#   (b) a copy of the cli in a fresh directory over the warm machine store, against (a); the copy's
#       own store holds less than half what a cold one does, so the machine store answered;
#   (c) a second program, over std alone, cold and over the warm machine store;
#   (d) that program under a copy of the toolchain whose std has one file changed, over the warm
#       machine store, against the same toolchain fully cold;
#   (e) two copies of that program built at once over one empty machine store, and a third after,
#       against cold;
#   (f) that program pinning a std package to a path, machine store on and off.
#
#   sh tools/witness_machine_store.sh [compiler]     (default build/avra-try)
set -eu
# a store is copied, counted or emptied here between builds, so each build saves its own before it answers
export AVRA_STORE_KEPT_HERE=1
root=$(cd "$(dirname "$0")/.." && pwd)
avra=$(cd "$(dirname "${1:-$root/build/avra-try}")" && pwd)/$(basename "${1:-$root/build/avra-try}")
w=$(mktemp -d "${TMPDIR:-/tmp}/avra-machine-store.XXXXXX")
trap 'find "$w" -delete 2>/dev/null || :' EXIT
export AVRA_PROGRAM=1
# A PRODUCT COMPARED BYTE FOR BYTE IS THE RELEASE ONE: a dev build's binary is an overlay linked
# beside the world it last linked, so no two stores' dev products share their bytes.
export AVRA_PROGRAM_MODE=release
fail() { echo "witness_machine_store: $*"; exit 1; }
# every store a build reads emptied: the packages', and the machine store at `$1`
stores_emptied() {
    for d in "$root"/packages/*/.avra-cache "$root"/.avra-cache "$w"/*/.avra-cache; do [ -e "$d" ] && find "$d" -delete; done
    [ -e "$1" ] && find "$1" -delete
    :
}
# `built <compiler> <package dir> <machine dir> <on|off> <product copy>`: the package built, its binary kept
built() {
    if [ "$4" = on ]; then on=1; else on=0; fi
    began=$(date +%s)
    (cd "$2" && AVRA_CACHE_DIR="$3" AVRA_MACHINE_STORE=$on "$1" build . > "$5.log" 2>&1) || { cat "$5.log"; fail "building $2 failed"; }
    [ -n "${AVRA_WITNESS_TIMES:-}" ] && echo "  built $(basename "$5") in $(($(date +%s) - began)) s"
    cp "$2/src/main" "$5"
}
same() { cmp -s "$1" "$2" || fail "$3: the products differ ($1, $2)"; echo "witness_machine_store: $3 — one product"; }
octets() { du -sk "$1" | cut -f1; }

# a program over std alone
mkdir -p "$w/small/src"
printf '[package]\nname = "@w/machine-small"\nversion = "0.0.1"\n\n[bin]\npath = "src/main.av"\n' > "$w/small/avra.toml"
cat > "$w/small/src/main.av" <<'AV'
use @std.text.{parse_int}
let n = parse_int("41") ?? 0
println("${n + 1} ${["a", "b"].join("-")}")
AV

m="$w/machine"
# (a)
stores_emptied "$m"
built "$avra" "$root/packages/cli" "$w/none" off "$w/cli-off"
cold_own=$(octets "$root/packages/cli/.avra-cache/tapes")
stores_emptied "$m"
built "$avra" "$root/packages/cli" "$m" on "$w/cli-on"
same "$w/cli-off" "$w/cli-on" "(a) the cli, machine store on and off"
[ -n "$(ls "$m/tapes" 2>/dev/null | grep '^pack-' || :)" ] || fail "(a) the machine store kept nothing"
# (b)
mkdir -p "$w/cli-copy" && cp -r "$root/packages/cli/avra.toml" "$root/packages/cli/src" "$w/cli-copy/"
find "$w/cli-copy/src" -name main -delete
built "$avra" "$w/cli-copy" "$m" on "$w/cli-copy-on"
same "$w/cli-on" "$w/cli-copy-on" "(b) a copy of the cli over the warm machine store"
copy_own=$(octets "$w/cli-copy/.avra-cache/tapes")
[ "$((copy_own * 2))" -lt "$cold_own" ] || fail "(b) the copy's own store holds ${copy_own} KB of a cold ${cold_own} KB: the machine store answered too little"
# (c)
built "$avra" "$w/small" "$w/none" off "$w/small-off"
find "$w/small/.avra-cache" -delete
built "$avra" "$w/small" "$m" on "$w/small-on"
same "$w/small-off" "$w/small-on" "(c) a second program, cold and over the warm machine store"
# (d) a toolchain whose std has one file changed: its binary, its objects, its std
t="$w/toolchain"
mkdir -p "$t/build" "$t/packages"
for f in "$(dirname "$avra")"/*.o "$(dirname "$avra")"/*.a "$(dirname "$avra")"/*.bc; do [ -e "$f" ] && cp "$f" "$t/build/"; done
cp "$avra" "$t/build/avra"
for p in "$root"/packages/std-*; do cp -r "$p" "$t/packages/"; done
find "$t/packages" -path '*/.avra-cache*' -delete
printf '\n/// One more fn, so this file reads otherwise.\nexport fn machine_store_witness() -> int { 7 }\n' >> "$t/packages/std-text/src/text.av"
find "$w/small/.avra-cache" -delete
built "$t/build/avra" "$w/small" "$m" on "$w/small-changed-on"
find "$w/small/.avra-cache" -delete
built "$t/build/avra" "$w/small" "$w/none-d" off "$w/small-changed-off"
same "$w/small-changed-off" "$w/small-changed-on" "(d) a changed std file, over the warm machine store and cold"
# (e)
m2="$w/machine-two"
for c in one two three; do mkdir -p "$w/small-$c" && cp -r "$w/small/avra.toml" "$w/small/src" "$w/small-$c/" && find "$w/small-$c/src" -name main -delete; done
built "$avra" "$w/small-one" "$m2" on "$w/small-e1" &
first=$!
built "$avra" "$w/small-two" "$m2" on "$w/small-e2" &
second=$!
wait "$first" || fail "(e) the first of two builds at once failed"
wait "$second" || fail "(e) the second of two builds at once failed"
built "$avra" "$w/small-three" "$m2" on "$w/small-e3"
same "$w/small-off" "$w/small-e1" "(e) the first of two builds at once"
same "$w/small-off" "$w/small-e2" "(e) the second of two builds at once"
same "$w/small-off" "$w/small-e3" "(e) a build after both"
# (f)
mkdir -p "$w/pinned/src" && cp -r "$root/packages/std-text" "$w/pinned-text"
find "$w/pinned-text" -path '*/.avra-cache*' -delete
printf '[package]\nname = "@w/machine-pinned"\nversion = "0.0.1"\n\n[bin]\npath = "src/main.av"\n\n[dependencies]\n"@std/text" = { path = "../pinned-text" }\n' > "$w/pinned/avra.toml"
cp "$w/small/src/main.av" "$w/pinned/src/main.av"
built "$avra" "$w/pinned" "$w/none-f" off "$w/pinned-off"
find "$w/pinned/.avra-cache" -delete
built "$avra" "$w/pinned" "$m" on "$w/pinned-on"
same "$w/pinned-off" "$w/pinned-on" "(f) a std package pinned to a path, machine store on and off"
echo "witness_machine_store: every case builds one product"
