#!/bin/sh
# THE TOOLCHAIN'S STD ANSWERS SERVE A PROGRAM'S FIRST CHECK, AND NEVER WRONGLY. A toolchain is laid
# out as `make install` lays one (bin/avra, lib/avra/std, lib/avra/answers), shipping the answers its
# compiler keeps over @std/text, and a program over @std/text is checked against it:
#   (1) on a fresh machine, the shipped packs are laid in, and the check says what a check with no
#       machine store says, its own store holding less than half of what that one's does;
#   (2) two first checks at once on one fresh machine both say it, and leave every pack whole and
#       no draft behind;
#   (3) a compiler of another print lays nothing in;
#   (4) a machine store that can't stand, or a disk too small for the packs (where this machine can
#       mount one), costs one line on stderr and nothing else: the check says what it says without;
#   (5) the install's verdict stands only for the std it judged: an installed std file edited to a
#       type error is judged again, and the program's check refuses it.
#   sh tools/std_answers_attack.sh [compiler]     (default build/avra-try)
. "$(dirname "$0")/lib/scratch.sh"
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
avra=$(cd "$(dirname "${1:-$root/build/avra-try}")" && pwd)/$(basename "${1:-$root/build/avra-try}")
scratch_dir w
mounted=""
scratch_also '[ -n "$mounted" ] && umount "$mounted" 2>/dev/null; find "$w" -delete 2>/dev/null || :'
export AVRA_PROGRAM_NET=0
unset AVRA_MACHINE_STORE AVRA_MACHINE_STORE_DIR
fail() { echo "std_answers_attack: $*"; exit 1; }
held() { echo "std_answers_attack: $*"; }

tc="$w/tc"
mkdir -p "$tc/bin" "$tc/lib/avra"
cp "$avra" "$tc/bin/avra"
# the toolchain's std: the tree's, its @std/text a copy of its own, which (5) edits
mkdir -p "$tc/lib/avra/std"
for d in "$root"/packages/std-*; do ln -s "$d" "$tc/lib/avra/std/$(basename "$d")"; done
text_std="$tc/lib/avra/std/std-text"
find "$text_std" -maxdepth 0 -type l -delete
cp -R "$root/packages/std-text" "$text_std"
find "$text_std" -name .avra-cache -prune -exec find {} -delete \;
sh "$root/tools/std_answers.sh" "$tc/bin/avra" "$tc/lib/avra/std" "$tc/lib/avra/answers" std-text std-prelude std-meta >/dev/null ||
    fail "the toolchain's answers were not made"
shipped=$(ls "$tc/lib/avra/answers" | grep -c '^pack-')
[ "$shipped" -gt 0 ] || fail "the toolchain ships no pack"

mkdir -p "$w/p/src"
printf '[package]\nname = "texted"\nversion = "0.0.1"\n' > "$w/p/avra.toml"
printf 'use @std.text.{parse_int}\n\nfn n() -> int { parse_int("41") ?? 0 }\nn()\n' > "$w/p/src/main.av"
# `checked <compiler> <cache> <said> [env…]`: the program (`$at`, else `$w/p`) checked cold in its
# own store, under the machine cache `<cache>`; stdout to `<said>`, stderr to `<said>.err`, the exit
# after stdout, its path said as `<p>`
checked() {
    c=$1; cache=$2; said=$3; shift 3
    dir=${at:-$w/p}
    find "$dir" -name .avra-cache -prune -exec find {} -delete \;
    env AVRA_CACHE_DIR="$cache" "$@" "$c" check "$dir" > "$said.raw" 2> "$said.err"
    code=$?
    sed "s#$dir#<p>#g" "$said.raw" > "$said"
    echo "exit $code" >> "$said"
}

checked "$tc/bin/avra" "$w/none" "$w/cold" AVRA_MACHINE_STORE=0
# what a fresh machine store gains when the toolchain ships nothing
mkdir -p "$w/bare/bin" "$w/bare/lib/avra"
cp "$avra" "$w/bare/bin/avra"
ln -s "$root/packages" "$w/bare/lib/avra/std"
checked "$w/bare/bin/avra" "$w/m0" "$w/unshipped"
cmp -s "$w/cold" "$w/unshipped" || fail "a check with nothing shipped says otherwise: $(cat "$w/unshipped")"
unshipped_kb=$(du -sk "$w/m0/tapes" | cut -f1)

# (1)
checked "$tc/bin/avra" "$w/m1" "$w/laid"
cmp -s "$w/cold" "$w/laid" || fail "(1) the check over the laid-in answers says otherwise: $(cat "$w/laid" "$w/laid.err")"
[ ! -s "$w/laid.err" ] || fail "(1) a first check said: $(cat "$w/laid.err")"
shipped_kb=$(du -sk "$tc/lib/avra/answers" | cut -f1)
gained_kb=$(($(du -sk "$w/m1/tapes" | cut -f1) - shipped_kb))
[ $((gained_kb * 2)) -lt "$unshipped_kb" ] ||
    fail "(1) the machine store gained ${gained_kb} KB past the ${shipped_kb} KB laid in, against ${unshipped_kb} KB with nothing shipped: the shipped answers didn't serve"
held "(1) laid in on a fresh machine: the same words, ${gained_kb} KB worked out past the ${shipped_kb} KB laid in, against ${unshipped_kb} KB with nothing shipped"

# (2)
for k in 1 2; do cp -R "$w/p" "$w/p$k"; done
for k in 1 2; do (at="$w/p$k" checked "$tc/bin/avra" "$w/m2" "$w/race$k") & done
wait
for k in 1 2; do cmp -s "$w/cold" "$w/race$k" || fail "(2) racer $k says otherwise: $(cat "$w/race$k" "$w/race$k.err")"; done
ls "$w/m2/tapes" | grep -q 'draft$' && fail "(2) a draft is left: $(ls "$w/m2/tapes")"
for n in $(ls "$tc/lib/avra/answers"); do cmp -s "$tc/lib/avra/answers/$n" "$w/m2/tapes/$n" || [ ! -e "$w/m2/tapes/$n" ] || fail "(2) pack $n lies torn"; done
held "(2) two first checks at once: the same words, no draft, every pack whole"

# (3)
cp "$avra" "$w/other-avra"
printf 'another print' >> "$w/other-avra"
mkdir -p "$w/tc2/bin" "$w/tc2/lib/avra"
cp "$w/other-avra" "$w/tc2/bin/avra"
ln -s "$root/packages" "$w/tc2/lib/avra/std"
ln -s "$tc/lib/avra/answers" "$w/tc2/lib/avra/answers"
checked "$w/tc2/bin/avra" "$w/m3" "$w/other"
cmp -s "$w/cold" "$w/other" || fail "(3) the other compiler says otherwise: $(cat "$w/other" "$w/other.err")"
for n in $(ls "$tc/lib/avra/answers"); do [ ! -e "$w/m3/tapes/$n" ] || fail "(3) a compiler of another print laid in $n"; done
held "(3) a compiler of another print laid nothing in"

# (4)
touch "$w/a-file"
checked "$tc/bin/avra" "$w/m4" "$w/unstood" AVRA_MACHINE_STORE_DIR="$w/a-file/tapes"
cmp -s "$w/cold" "$w/unstood" || fail "(4) a check whose machine store can't stand says otherwise: $(cat "$w/unstood")"
[ "$(wc -l < "$w/unstood.err")" -eq 1 ] && grep -q "can't stand" "$w/unstood.err" ||
    fail "(4) a machine store that can't stand is said otherwise: $(cat "$w/unstood.err")"
held "(4) a machine store that can't stand: one line, the same words"
mkdir -p "$w/tiny"
if mount -t tmpfs -o size=64k tmpfs "$w/tiny" 2>/dev/null; then
    mounted="$w/tiny"
    checked "$tc/bin/avra" "$w/m5" "$w/full" AVRA_MACHINE_STORE_DIR="$w/tiny/tapes"
    cmp -s "$w/cold" "$w/full" || fail "(4) a check on a full disk says otherwise: $(cat "$w/full")"
    [ "$(grep -c "couldn't be laid" "$w/full.err")" -eq 1 ] || fail "(4) a full disk is said otherwise: $(cat "$w/full.err")"
    held "(4) a disk too small for the packs: one line, the same words"
else
    held "(4) a full disk: not attacked, this machine mounts no small disk"
fi
# (5)
src=$(ls "$tc/lib/avra/std/std-text/src"/*.av | head -1)
printf '\nexport fn broken_by_the_attack() -> int { "text" }\n' >> "$src"
checked "$tc/bin/avra" "$w/m1" "$w/edited"
grep -q '^exit 1$' "$w/edited" && grep -q 'type.mismatch' "$w/edited" ||
    fail "(5) an edited std file standing on the install's verdict: $(cat "$w/edited" "$w/edited.err")"
held "(5) an installed std file edited to a type error: judged again, the check refuses it"
echo "std_answers_attack: held"
