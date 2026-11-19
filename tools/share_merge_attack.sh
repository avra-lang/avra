#!/bin/sh
# A WAVE'S PACKS MERGED BY SHARES ARE THE PACKS MERGED HERE. The cores of a wave publish a pack
# each, and as many processes merge them, each one share of the keys, while the asking process
# takes the cores' answers. One package, built cold three ways: merged in the asking process
# (`AVRA_MERGED_HERE`), merged by shares however small the store (`AVRA_MERGED_APART_FROM`), and by
# shares with one share left unpublished (`AVRA_SHARE_UNMERGED`), which the asking process must
# then merge itself. Each binary must be the first one's, and a build after each must stand on
# the store it left, working out nothing. Merged by shares, a process said it published a share and
# another read an answer from one (`AVRA_QTRACE`'s store lines); merged here, none did.
#
#   sh tools/share_merge_attack.sh
set -u
. "$(dirname "$0")/lib/attack.sh"
A=${SHARE_ATTACK_AVRA:-$(pwd)/avra}
R=build/share-merge-attack
find "$R" -delete 2>/dev/null; mkdir -p "$R"
unset AVRA_PROGRAM AVRA_PROGRAM_NET AVRA_MERGED_HERE AVRA_MERGED_APART_FROM AVRA_SHARE_UNMERGED

# The package at `$R/$1`: an entry printing the sum of enough files that every wave forks.
package() {
    p=$R/$1
    find "$p" -delete 2>/dev/null; mkdir -p "$p/src"
    printf '[package]\nname = "share"\nversion = "0.1.0"\n' > "$p/avra.toml"
    uses=""; sum="0"
    for k in $(seq 0 39); do
        printf 'export fn f%s() -> int { %s }\n' "$k" "$k" > "$p/src/f$k.av"
        uses="${uses}use f$k.{f$k}\n"; sum="$sum + f$k()"
    done
    printf "${uses}\nprintln(\"\${$sum}\")\n" > "$p/src/main.av"
    own_store "$p"
}

# The package built cold, in one place whatever the settings `$@`, then built again: its binary's
# digest, how many shares the first build said were published and how many answers read from one,
# and whether the second stood.
built() {
    package pkg
    env AVRA_QTRACE=1 "$@" "$A" build "$R/pkg" > "$R/pkg.build" 2>&1 || { echo "BUILD FAILED"; return; }
    published=$(grep -c '^store: share [0-9]* of [0-9]* published$' "$R/pkg.build")
    read=$(grep -c '^store: an answer read from a share another process published: ' "$R/pkg.build")
    stood=$(env "$@" "$A" build "$R/pkg" --time 2>&1 >/dev/null | grep -c 'cache hit')
    echo "$(cksum < "$R/pkg/src/main") published=$published read=$read stood=$stood said=$("$R/pkg/src/main")"
}
binary() { echo "$1" | sed 's/ published=.*//'; }
field() { echo "$1" | tr ' ' '\n' | grep "^$2=" | cut -d= -f2; }

steps=$((steps + 1)); here=$(built AVRA_MERGED_HERE=1)
[ "$(field "$here" said)" = 780 ] || fail "merged here, the build says: $here"
[ "$(field "$here" stood)" = 1 ] || fail "merged here, the build after did not stand"
[ "$(field "$here" published)" = 0 ] || fail "merged here, a process said it published a share: $here"
steps=$((steps + 1)); shares=$(built AVRA_MERGED_APART_FROM=10)
[ "$(binary "$shares")" = "$(binary "$here")" ] || fail "merged by shares, the binary is not the one merged here: $shares"
[ "$(field "$shares" stood)" = 1 ] || fail "merged by shares, the build after did not stand"
[ "$(field "$shares" published)" -gt 0 ] || fail "merged by shares, no process said it published a share: $shares"
[ "$(field "$shares" read)" -gt 0 ] || fail "merged by shares, no process read an answer from a share: $shares"
steps=$((steps + 1)); short=$(built AVRA_MERGED_APART_FROM=10 AVRA_SHARE_UNMERGED=2)
[ "$(binary "$short")" = "$(binary "$here")" ] || fail "with a share unpublished, the binary is not the one merged here: $short"
[ "$(field "$short" stood)" = 1 ] || fail "with a share unpublished, the build after did not stand"
verdict "share-merge-attack: $steps step(s)" "merged here, by shares, a share unpublished"
