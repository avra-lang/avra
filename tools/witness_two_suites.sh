#!/bin/sh
# ONE `test` PROCESS OVER SEVERAL SUITES READS EACH SUITE THROUGH ITS OWN DISK. A package holds two
# test packages of its own, each a suite: the first embeds a file of its package and is given a kind
# from another through `provided`; the second only prints. The process makes every suite's disk
# before it runs any, so the embedded file must be read beneath the first suite's root while the
# second suite's disk is the last one made. Each must print its `.expected`, cold, in one run over
# both, as it does alone.
#   sh tools/witness_two_suites.sh [compiler]   (default build/avra-try)
. "$(dirname "$0")/lib/scratch.sh"
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
avra=${1:-build/avra-try}
case $avra in /*) ;; *) avra="$root/$avra" ;; esac
[ -x "$avra" ] || { echo "witness_two_suites: no compiler at $avra" >&2; exit 1; }
scratch_dir tmp
export AVRA_CACHE_DIR="$tmp/machine"
# a store is copied, counted or emptied here between builds, so each build saves its own before it answers
export AVRA_STORE_KEPT_HERE=1
mkdir -p "$AVRA_CACHE_DIR"
home="$tmp/home"

# a test package: its directory, its name, its entry, what it prints
suite() {
    mkdir -p "$1/src"
    printf '[package]\nname = "%s"\nversion = "0.0.1"\n' "$2" >"$1/avra.toml"
    printf '%b' "$3" >"$1/src/main.av"
    printf '%s\n' "$4" >"$1/src/main.expected"
}

mkdir -p "$home/src"
printf '[package]\nname = "home"\nversion = "0.0.1"\n' >"$home/avra.toml"
printf 'export fn unused() -> int { 0 }\n' >"$home/src/lib.av"
suite "$home/src/embeds/tests/reader" reader 'use @std.meta.{embed, provided, Provider}\ntype K = { n: int }\nimpl Provider for K {\n    static fn provide(path: string, octets: Bytes, digest: string) -> K? { K { n: octets.length } }\n}\nconst A: K = provided<K>("art/note.txt")\nconst T: string = embed("../art/note.txt")\nprintln("${A.n} ${T}")\n' "5 note!"
mkdir -p "$home/src/embeds/tests/reader/art"
printf 'note!' >"$home/src/embeds/tests/reader/art/note.txt"
suite "$home/src/plain/tests/printer" printer 'println("printed")\n' "printed"

(cd "$home" && env -u AVRA_PROGRAM "$avra" test src/embeds src/plain >"$tmp/both.log" 2>&1) || {
    cat "$tmp/both.log" >&2
    echo "witness_two_suites: one process over both suites failed" >&2
    exit 1
}
for t in embeds/tests/reader plain/tests/printer; do
    grep -q "$t/src/main: eval == native == expected" "$tmp/both.log" || {
        cat "$tmp/both.log" >&2
        echo "witness_two_suites: $t did not print its .expected in one process over both" >&2
        exit 1
    }
done
echo "witness_two_suites: one process over two suites — each read through its own disk, both print their .expected"
