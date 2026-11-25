#!/bin/sh
# TWO BINARIES SHARING A STORE NEVER READ EACH OTHER'S ANSWERS, and the store stays the size of
# their two segments. Two compilers whose queries differ build the cli on the program layer over one
# store, in turn: each once cold, then each again. Every process's mappings are sampled while it
# runs, and no process may map a pack the other binary wrote; after the first round the store may
# not grow past what the two cold builds left (5% slack). Empties the cli's store first, and leaves
# it holding the two segments.
#   sh tools/witness_store_prints.sh <compiler A> <compiler B>   (Linux: reads /proc)
set -eu
# a store is copied, counted or emptied here between builds, so each build saves its own before it answers
export AVRA_STORE_KEPT_HERE=1
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
a=${1:?usage: witness_store_prints.sh <compiler A> <compiler B>}
b=${2:?usage: witness_store_prints.sh <compiler A> <compiler B>}
store="$root/packages/cli/.avra-cache"
tapes="$store/tapes"
find "$store" -delete 2>/dev/null || :
tmp=$(mktemp -d)
trap 'find "$tmp" -delete' EXIT

# the pack files of one binary, by the print its names carry, as a list of names
packs_of() { ls "$tapes" 2>/dev/null | grep "^pack-$1\." || :; }

# every print the store's packs carry
prints() { ls "$tapes" 2>/dev/null | sed -n 's/^pack-\([^.]*\)\..*\.pack$/\1/p' | sort -u; }

# one build by `$1`; every pack it maps, sampled, into `$2`
built() {
    "$1" build packages/cli > "$tmp/out" 2>&1 &
    pid=$!
    : > "$2"
    while kill -0 "$pid" 2>/dev/null; do
        for p in $pid $(pgrep -P "$pid" || :); do
            grep -o 'pack-[^ ]*\.pack' "/proc/$p/maps" 2>/dev/null >> "$2" || :
        done
        sleep 1
    done
    wait "$pid" || { tail -5 "$tmp/out"; echo "witness_store_prints: $1 failed to build"; exit 1; }
    sort -u "$2" -o "$2"
}

built "$a" "$tmp/a0"
print_a=$(prints)
[ "$(echo "$print_a" | wc -l)" = 1 ] || { echo "witness_store_prints: the first build left $(echo "$print_a" | wc -l) prints"; exit 1; }
built "$b" "$tmp/b0"
print_b=$(prints | grep -v "^$print_a$" || :)
[ -n "$print_b" ] || { echo "witness_store_prints: the two compilers share a print — their queries must differ"; exit 1; }
cold=$(du -sk "$tapes" | cut -f1)
echo "witness_store_prints: two cold builds left $((cold / 1024)) MB"
fails=0
for round in 1 2; do
    built "$a" "$tmp/a$round"
    built "$b" "$tmp/b$round"
done
for f in "$tmp"/a*; do
    if grep -q "^pack-$print_b\." "$f"; then echo "witness_store_prints: $a mapped a pack of the other binary: $(grep "^pack-$print_b\." "$f" | head -1)"; fails=1; fi
done
for f in "$tmp"/b*; do
    if grep -q "^pack-$print_a\." "$f"; then echo "witness_store_prints: $b mapped a pack of the other binary: $(grep "^pack-$print_a\." "$f" | head -1)"; fails=1; fi
done
now=$(du -sk "$tapes" | cut -f1)
if [ "$now" -gt $((cold + cold / 20)) ]; then echo "witness_store_prints: the store grew from $((cold / 1024)) MB to $((now / 1024)) MB"; fails=1; fi
[ "$(prints | wc -l)" = 2 ] || { echo "witness_store_prints: the store holds $(prints | wc -l) binaries' packs"; fails=1; }
[ $fails = 0 ] || exit 1
echo "witness_store_prints: each binary mapped only its own packs; the store held at $((now / 1024)) MB"
