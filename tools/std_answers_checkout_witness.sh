#!/bin/sh
# A CHECKOUT READS ITS STD AS AN INSTALL DOES, AND NEVER STALE. A checkout is laid out as one stands
# (build/avra, packages/std-*), its std answers made as `make avra` makes them (tools/std_answers.sh
# into build/answers), and a program over @std/text is checked with its binary:
#   (1) on a fresh machine the checkout's answers are laid in, and the check says what a check with
#       no machine store says, working out less than half of what a checkout shipping none does;
#   (2) a body edited inside a std file is worked out again: the check says what a check with no
#       store says, and works out less than half of what (1) skipped;
#   (3) a std signature edited so the program no longer types: the program's item is faced again
#       and the check refuses it, as a check with no store does;
#   (4) a std file edited so another std file it serves no longer resolves: the verdict stands for
#       neither, and the check refuses the dependent, as a check with no store does;
#   (5) the packs the machine store evicted are laid in again, their mark notwithstanding;
#   (6) the answers are complete by construction: written three times, the store compacted at no
#       moment, after the last package and after the first and last, the check over each works out
#       the same;
#   (7) a store that compacts once they're laid in keeps them: the check after it works out what
#       the check with none does;
#   (8) on the volume the answers stand on, each is laid in by a second name, never a copy: every
#       pack and kept file the store holds of them is the shipped file itself;
#   (9) the answers are the same however the writer's jobs meet: written with its jobs one at a time
#       and all at once, the check over each works out the same.
#   sh tools/std_answers_checkout_witness.sh [compiler]     (default build/avra)
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
avra=$(cd "$(dirname "${1:-$root/build/avra}")" && pwd)/$(basename "${1:-$root/build/avra}")
w=$(mktemp -d "${TMPDIR:-/tmp}/avra-checkout-answers.XXXXXX")
trap 'find "$w" -delete 2>/dev/null || :' EXIT
export AVRA_PROGRAM_NET=0
unset AVRA_MACHINE_STORE AVRA_MACHINE_STORE_DIR
fail() { echo "std_answers_checkout_witness: $*"; exit 1; }
held() { echo "std_answers_checkout_witness: $*"; }

# `checkout <dir>`: a checkout at <dir> whose @std/text and @std/meta are copies of the tree's, which
# the cases edit, its other std the tree's own
checkout() {
    mkdir -p "$1/build" "$1/packages"
    cp "$avra" "$1/build/avra"
    for d in "$root"/packages/std-*; do ln -s "$d" "$1/packages/$(basename "$d")"; done
    for p in std-text std-meta; do
        find "$1/packages/$p" -maxdepth 0 -type l -delete
        cp -R "$root/packages/$p" "$1/packages/$p"
        find "$1/packages/$p" -name .avra-cache -prune -exec find {} -delete \;
    done
}
tree="$w/tree"
checkout "$tree"
sh "$root/tools/std_answers.sh" "$tree/build/avra" "$tree/packages" "$tree/build/answers" std-text std-prelude std-meta >/dev/null ||
    fail "the checkout's answers were not made"
[ "$(ls "$tree/build/answers" | grep -c '^pack-')" -gt 0 ] || fail "the checkout ships no pack"
bare="$w/bare"
checkout "$bare"

mkdir -p "$w/p/src"
printf '[package]\nname = "texted"\nversion = "0.0.1"\n' > "$w/p/avra.toml"
printf 'use @std.text.{parse_int}\n\nfn n() -> int { parse_int("41") ?? 0 }\nn()\n' > "$w/p/src/main.av"
# `checked <compiler> <cache> <said> [env…]`: the program checked cold in its own store, under the
# machine cache `<cache>`; stdout to `<said>`, stderr to `<said>.err`, the exit after stdout, its
# path said as `<p>` and the checkout's as `<tree>`
checked() {
    c=$1; cache=$2; said=$3; shift 3
    find "$w/p" -name .avra-cache -prune -exec find {} -delete \;
    env AVRA_CACHE_DIR="$cache" "$@" "$c" check "$w/p" > "$said.raw" 2> "$said.err"
    code=$?
    sed -e "s#$w/p#<p>#g" -e "s#$tree#<tree>#g" -e "s#$bare#<tree>#g" "$said.raw" > "$said"
    echo "exit $code" >> "$said"
}
# `counted <compiler> <cache>`: how many answers the program's check works out, cold in its own
# store, under the machine cache `<cache>` — what a store serves, whatever its files' bytes
counted() {
    find "$w/p" -name .avra-cache -prune -exec find {} -delete \;
    env AVRA_CACHE_DIR="$2" "$1" check --counts "$w/p" 2>&1 >/dev/null | grep -o ' queries_computed=[0-9]*' | cut -d= -f2
}
# `edited <file> <sed script>`: the same file in both checkouts, edited alike
edited() {
    for t in "$tree" "$bare"; do sed -i.was "$2" "$t/packages/$1" && find "$t/packages/$1.was" -delete; done
}
# `as_unstored <case> <said>`: the checkout's check over the machine store m1 says what the bare
# checkout's says with no machine store
as_unstored() {
    checked "$bare/build/avra" "$w/none" "$w/$2.bare" AVRA_MACHINE_STORE=0
    checked "$tree/build/avra" "$w/m1" "$w/$2"
    cmp -s "$w/$2.bare" "$w/$2" || fail "$1 the checkout says otherwise than a check with no store: $(cat "$w/$2" "$w/$2.err") against $(cat "$w/$2.bare")"
}

# (1)
unshipped=$(counted "$bare/build/avra" "$w/m0")
as_unstored "(1)" laid
[ ! -s "$w/laid.err" ] || fail "(1) a first check said: $(cat "$w/laid.err")"
laid=$(counted "$tree/build/avra" "$w/m1a")
[ $((laid * 2)) -lt "$unshipped" ] ||
    fail "(1) over the checkout's answers the check worked out ${laid} answers, against ${unshipped} with nothing shipped: they didn't serve"
held "(1) a checkout's first check: the same words, ${laid} answers worked out, against ${unshipped} with nothing shipped"

# (2)
edited std-text/src/text.av 's|^    if !avra_str_parses_int(s) { return null }$|    if !avra_str_parses_int(s) { return null }\n    let _edited = 0|'
grep -q '_edited' "$tree/packages/std-text/src/text.av" || fail "(2) the body edit missed"
as_unstored "(2)" body
grep -q '^exit 0$' "$w/body" || fail "(2) a body edit is refused: $(cat "$w/body")"
again=$(counted "$tree/build/avra" "$w/m1a")
[ $(((again - laid) * 2)) -lt $((unshipped - laid)) ] ||
    fail "(2) a body edit worked out ${again} answers, against ${laid} before it and ${unshipped} with nothing shipped"
held "(2) a std body edited: the same words, $((again - laid)) answers more worked out again"

# (3)
edited std-text/src/text.av 's|^export fn parse_int(s: string) -> int? {$|export fn parse_int(s: string) -> string? {|'
as_unstored "(3)" typed
grep -q '^exit 1$' "$w/typed" || fail "(3) a std signature the program no longer types with is let through: $(cat "$w/typed")"
held "(3) a std signature edited: the program's item faced again, refused as with no store"
edited std-text/src/text.av 's|^export fn parse_int(s: string) -> string? {$|export fn parse_int(s: string) -> int? {|'

# (4)
edited std-meta/src/meta.av 's|^export fn identity(_t: Type) {}$|export fn identity_moved(_t: Type) {}|'
as_unstored "(4)" served
grep -q '^exit 1$' "$w/served" && grep -q 'std-text' "$w/served" ||
    fail "(4) a std file whose dependency moved is let through: $(cat "$w/served")"
held "(4) a std dependency edited: the dependent judged again, refused as with no store"

# (5)
whole=$(counted "$tree/build/avra" "$w/m5")
find "$w/m5/tapes" -name 'pack-*' -delete
evicted=$(counted "$tree/build/avra" "$w/m5")
[ "$evicted" = "$whole" ] || fail "(5) after the store evicted the answers, the check worked out ${evicted:-none}, against ${whole:-none} when they first stood"
held "(5) answers the store evicted: laid in again, ${evicted} answers worked out as when they first stood"

# `worked <cache>`: how many answers the fresh checkout's check of the program works out, cold in its
# own store, under the machine cache `<cache>`
fresh="$w/fresh"
checkout "$fresh"
worked() { counted "$fresh/build/avra" "$1"; }
# (6)
k=0
for moment in "" "std-text" "std-meta std-text"; do
    # each write made whole: answers of the same key would stand as they are, written once
    find "$fresh/build/answers" -delete 2>/dev/null
    STD_ANSWERS_COMPACT_AFTER="$moment" sh "$root/tools/std_answers.sh" "$fresh/build/avra" "$fresh/packages" "$fresh/build/answers" std-text std-prelude std-meta >/dev/null ||
        fail "(6) the answers were not made, compacted after '$moment'"
    eval "work$k=\$(worked \"\$w/m6-$k\")"
    k=$((k + 1))
done
[ -n "$work0" ] && [ "$work0" = "$work1" ] && [ "$work0" = "$work2" ] ||
    fail "(6) the shipped answers hang on when the store compacted: ${work0:-none}, ${work1:-none} and ${work2:-none} worked out"
held "(6) written three times, compacted at three moments: ${work0} answers worked out over each"

# (7)
(cd "$w" && AVRA_CACHE_DIR="$w/m7" "$fresh/build/avra" cache clean >/dev/null 2>&1) || fail "(7) the store was not compacted"
compacted=$(worked "$w/m7")
[ "$compacted" = "$work2" ] || fail "(7) a store compacted once the answers were laid in worked out ${compacted:-none}, against ${work2}"
held "(7) the store compacted once they're laid in: ${compacted} answers worked out, as without"

# (8)
worked "$w/m8" >/dev/null
for n in $(ls "$fresh/build/answers" | grep -E '^(pack|kept)-'); do
    [ "$(stat -c %i "$fresh/build/answers/$n")" = "$(stat -c %i "$w/m8/tapes/$n" 2>/dev/null)" ] ||
        fail "(8) $n was laid in as a copy, or not at all, on the volume its answers stand on"
done
held "(8) laid in by a second name: $(ls "$fresh/build/answers" | grep -cE '^(pack|kept)-') files, no copy"

# (9)
k=0
for jobs in 1 3; do
    find "$fresh/build/answers" -delete 2>/dev/null
    STD_ANSWERS_JOBS=$jobs sh "$root/tools/std_answers.sh" "$fresh/build/avra" "$fresh/packages" "$fresh/build/answers" std-text std-prelude std-meta >/dev/null ||
        fail "(9) the answers were not made, $jobs job(s) at a time"
    eval "met$k=\$(worked \"\$w/m9-$k\")"
    k=$((k + 1))
done
[ -n "$met0" ] && [ "$met0" = "$met1" ] ||
    fail "(9) the shipped answers hang on how the writer's jobs met: ${met0:-none} one at a time, ${met1:-none} at once"
held "(9) written one job at a time and all at once: ${met0} answers worked out over each"
echo "std_answers_checkout_witness: held"
