#!/bin/sh
# THREE BINARIES SHARING A STORE EACH BUILD WHAT THEY BUILD COLD. Three compilers whose queries
# differ build the cli on the program layer over one store: each once cold, its product kept; then
# each in turn edits a literal, builds, takes the edit back and builds again, and that last product
# must be the one its own cold build made, octet for octet. Every process's mappings are sampled while
# it runs, and none may map a pack another binary wrote. A store keeps its newest two binaries, so
# the third evicts the first, whose next build is cold again: its product must still be its own.
# Empties the cli's store first; restores the edited file on every exit.
#   sh tools/witness_store_builders.sh <compiler A> <compiler B> <compiler C>   (Linux: reads /proc)
set -eu
# a store is copied, counted or emptied here between builds, so each build saves its own before it answers
export AVRA_STORE_KEPT_HERE=1
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
[ $# = 3 ] || { echo "usage: witness_store_builders.sh <compiler A> <compiler B> <compiler C>"; exit 1; }
store="$root/packages/cli/.avra-cache"
tapes="$store/tapes"
product="$root/packages/cli/src/main"
edited="$root/packages/cli/src/commands/cache.av"
tmp=$(mktemp -d)
cp "$edited" "$tmp/edited.av"
trap 'cp "$tmp/edited.av" "$edited"; find "$tmp" -delete' EXIT
find "$store" -delete 2>/dev/null || :

prints() { ls "$tapes" 2>/dev/null | sed -n 's/^pack-\([^.]*\)\..*\.pack$/\1/p' | sort -u; }

# one build by `$1`, the packs it maps sampled into `$2`
built() {
    AVRA_PROGRAM=1 "$1" build packages/cli > "$tmp/out" 2>&1 &
    pid=$!
    while kill -0 "$pid" 2>/dev/null; do
        for p in $pid $(pgrep -P "$pid" || :); do
            grep -o 'pack-[^ ]*\.pack' "/proc/$p/maps" 2>/dev/null >> "$2" || :
        done
        sleep 1
    done
    wait "$pid" || { tail -5 "$tmp/out"; echo "witness_store_builders: $1 failed to build"; exit 1; }
}

# `$1`'s print: the one the store gained when it first built
fails=0
n=0
for c in "$@"; do
    before=$(prints)
    built "$c" "$tmp/maps$n"
    print=$(prints | grep -vxF -e "$before" | head -1 || :)
    [ -n "$print" ] || { echo "witness_store_builders: $c left no print of its own — the compilers' queries must differ"; exit 1; }
    echo "$print" > "$tmp/print$n"
    cp "$product" "$tmp/cold$n"
    n=$((n + 1))
done
n=0
for c in "$@"; do
    sed -i.bak 's/shared store kept/shared store holds/' "$edited"
    built "$c" "$tmp/maps$n"
    cp "$tmp/edited.av" "$edited"
    built "$c" "$tmp/maps$n"
    if cmp -s "$product" "$tmp/cold$n"; then
        echo "witness_store_builders: $c — warm after edit and take-back == its cold build"
    else
        echo "witness_store_builders: $c — warm after edit and take-back DIFFERS from its cold build"; fails=1
    fi
    n=$((n + 1))
done
find "$root/packages/cli/src/commands" -name 'cache.av.bak' -delete
for i in 0 1 2; do
    own=$(cat "$tmp/print$i")
    others=$(sort -u "$tmp/maps$i" | grep -v "^pack-$own\." || :)
    if [ -n "$others" ]; then echo "witness_store_builders: compiler $((i + 1)) mapped another binary's pack: $(echo "$others" | head -1)"; fails=1; fi
done
[ "$(prints | wc -l)" -le 2 ] || { echo "witness_store_builders: the store holds $(prints | wc -l) binaries' packs"; fails=1; }
[ $fails = 0 ] || exit 1
echo "witness_store_builders: three binaries, each mapped only its own packs and built warm what it built cold"
