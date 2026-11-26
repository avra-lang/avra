#!/bin/sh
# THE TOOLCHAIN'S STD ANSWERS: the compiler `avra` checks every std package under `std` with the
# machine's store placed at `out`, so `out` holds the packs that compiler keeps over that std — what a
# program's first build reads instead of working std out (cli's std_answers.av lays them in), and the
# verdict each package's clean check leaves: its files by digest, which a program's build and check
# then ask no law of (std_answers.av's `vouched_files`). The answers are what a program over each
# package reads of it (`avra cache dependents`), never what only the package's own check asks. Run by
# the INSTALLED compiler over the INSTALLED std, so the packs are made at the paths and the print a
# program is built with. Each package's own store is left behind nowhere: it is made under a scratch
# cache and emptied. The compiler's own packages ship no answers: std-avrac is the compiler, and the
# fuzz, soak and gallery packages are its harnesses, never a program's import — but in a checkout the
# compiler is a program's import (cli's), so STD_ANSWERS_COMPILER=1 judges std-avrac too. Prints one
# line: how many packages, how many packs, how many kilobytes.
# THE ANSWERS ARE KEYED BY WHAT MADE THEM: the compiler's bytes, this writer's, where std and `out`
# stand, and every file of the packages judged. Where `out` holds answers of that key, they stand as they are and
# nothing is worked out; any of it moved, and every package is judged again, since a package's
# verdict reads the packages it uses.
# A PACKAGE ITS OWN COMPILER REFUSES fails an install; STD_ANSWERS_REFUSED=skip (a checkout, whose std
# may be mid-edit) keeps its answers, which are held to what they read, and leaves it no verdict, so a
# program judges its files.
# THE ANSWERS ARE THE SAME EVERY RUN, however the jobs are scheduled: a job that takes up an answer
# another job published keeps other records than one that works it out, so no job reads what another
# job of its wave writes. The packages are worked out in WAVES — each wave the packages whose std
# imports are all in earlier waves, the prelude the first — one job a core (STD_ANSWERS_JOBS), each in
# a scratch cache of its own over a private store linked from what the waves before it made (a pack
# is immutable, so a link is a copy); a wave's stores are folded in and compacted before the next
# begins. A build lowers its bodies in this process alone (AVRA_WORK_AHEAD_OFF): forked lowerers
# publish into the store as they finish. Each job's verdict is its own file until all are in. The
# packs are compacted into one at the end: the kept files name every question in them, so the
# compaction drops nothing, and a reader maps one pack.
#   sh tools/std_answers.sh <avra> <std> <out> [package…]   (default every std package but those)
set -u
export AVRA_WORK_AHEAD_OFF=1
# one package's verdict and answers, a job of the run below: `--one <avra> <package> <out> <scratch>`
if [ "${1:-}" = --one ]; then
    avra=$2; p=$3; out=$4; job="$5/$(basename "$3")"
    mkdir -p "$job/verdict"
    # the verdict: the package's own check, its answers kept apart and let go
    if ! AVRA_CACHE_DIR="$job" AVRA_MACHINE_STORE_DIR="$job/judged" AVRA_VERDICT_DIR="$job/verdict" AVRA_PROGRAM_NET=0 "$avra" check "$p" >"$job/said" 2>&1; then
        { echo "std_answers: $(basename "$p") is refused by its own compiler:"; head -40 "$job/said"; } >&2
        [ "${STD_ANSWERS_REFUSED:-fail}" = skip ] || exit 1
        echo "std_answers: $(basename "$p") ships its answers and no verdict: a program judges its files" >&2
        find "$job/verdict" -mindepth 1 -delete
    fi
    # the answers: what a program over the package reads of it
    AVRA_CACHE_DIR="$job" AVRA_MACHINE_STORE_DIR="$out" AVRA_PROGRAM_NET=0 "$avra" cache dependents "$p" >/dev/null 2>"$job/said" ||
        { echo "std_answers: what a program reads of $(basename "$p") was not worked out:" >&2; cat "$job/said" >&2; exit 1; }
    find "$p" -name .avra-cache -type d -prune -exec find {} -delete \;
    # a witness's moment: the store compacted after the packages STD_ANSWERS_COMPACT_AFTER names
    case " ${STD_ANSWERS_COMPACT_AFTER:-} " in
        *" $(basename "$p") "*) (cd "$job" && AVRA_CACHE_DIR="$job" AVRA_MACHINE_STORE_DIR="$out" "$avra" cache clean >/dev/null 2>&1) ;;
    esac
    exit 0
fi
[ $# -ge 3 ] || { sed -n 2,10p "$0"; exit 2; }
avra=$1; std=$2; out=$3
shift 3
named="$*"
# the compiler's own packages, never a program's import
COMPILERS=" std-avrac std-http-fuzz std-http-soak std-ui_gallery "
[ -x "$avra" ] || { echo "std_answers: no compiler at $avra" >&2; exit 1; }
[ -d "$std" ] || { echo "std_answers: no std at $std" >&2; exit 1; }
[ "${STD_ANSWERS_COMPILER:-0}" = 1 ] && COMPILERS=" std-http-fuzz std-http-soak std-ui_gallery "
# the packages judged, one a line
judged() {
    for p in "$std"/std-*; do
        [ -f "$p/avra.toml" ] || continue
        if [ -n "$named" ]; then
            case " $named " in *" $(basename "$p") "*) ;; *) continue ;; esac
        else
            case "$COMPILERS" in *" $(basename "$p") "*) continue ;; esac
        fi
        echo "$p"
    done
}
# the key of what the answers are made from: the compiler's bytes, this writer's, the paths, every judged file
keyed() {
    {
        sha256sum < "$avra"
        sha256sum < "$0"
        echo "$std $out"
        for p in $(judged); do find "$p/" -name .avra-cache -prune -o -type f -print; done | LC_ALL=C sort | xargs sha256sum
    } | sha256sum | cut -c1-64
}
key=$(keyed)
if [ "$(cat "$out/inputs" 2> /dev/null)" = "$key" ]; then
    echo "std answers: unchanged, $(ls "$out" | grep -c '^pack-') packs, $(du -sk "$out" | cut -f1) KB in $out"
    exit 0
fi
scratch=$(mktemp -d)
trap 'find "$scratch" -delete' EXIT
mkdir -p "$out"
find "$out" -mindepth 1 -delete
jobs=${STD_ANSWERS_JOBS:-$(nproc 2> /dev/null || echo 2)}
# the judged std packages the package at `$1` imports, one a line: the prelude is every package's
imports() {
    { [ "$(basename "$1")" = std-prelude ] || echo std-prelude
      grep -rhoE '@std\.[a-z_]+' "$1/src" --include='*.av' 2> /dev/null | sed 's/@std\./std-/'; } |
        LC_ALL=C sort -u | while read -r n; do [ "$n" != "$(basename "$1")" ] && judged | grep -qx "$std/$n" && echo "$n"; done
}
# the next wave: every package left whose imports are all made, sorted, on one line; an import
# cycle's members, none of which can wait for another, are one wave
wave() {
    for p in $left; do
        ready=1
        for i in $(imports "$p"); do case " $made " in *" $i "*) ;; *) ready=0 ;; esac; done
        [ "$ready" = 0 ] || printf '%s ' "$p"
    done
}
# every file of the store `$1` not yet in the store `$2`, linked there: a pack, a kept file and a
# frontier are each named by what they hold and never written again, so a link is a copy
linked() {
    for f in "$1"/*; do
        [ -f "$f" ] || continue
        [ -e "$2/${f##*/}" ] || ln "$f" "$2/${f##*/}" || return 1
    done
}
# what a wave's jobs made, folded into `out` and compacted
folded() {
    for p in "$@"; do linked "$scratch/stores/$(basename "$p")" "$out" || return 1; done
    (cd "$scratch" && AVRA_CACHE_DIR="$scratch/fold" AVRA_MACHINE_STORE_DIR="$out" "$avra" cache clean >/dev/null 2>&1)
}
left=$(judged | LC_ALL=C sort | tr '\n' ' ')
made=""
while [ -n "$(printf '%s' "$left" | tr -d ' ')" ]; do
    now=$(wave)
    [ -n "$now" ] || now=$left
    for p in $now; do mkdir -p "$scratch/stores/$(basename "$p")" && linked "$out" "$scratch/stores/$(basename "$p")" || exit 1; done
    # shellcheck disable=SC2086
    printf '%s\n' $now | xargs -r -P "$jobs" -I{} sh -c 'sh "$0" --one "$1" "$2" "$3/stores/$(basename "$2")" "$3"' "$0" "$avra" {} "$scratch" || exit 1
    # shellcheck disable=SC2086
    folded $now || { echo "std_answers: a wave's answers were not folded" >&2; exit 1; }
    for p in $now; do made="$made $(basename "$p")"; done
    rest=$(for p in $left; do case " $now " in (*" $p "*) ;; (*) printf '%s ' "$p" ;; esac; done)
    [ "$rest" != "$left" ] || { echo "std_answers: a wave made nothing of $left" >&2; exit 1; }
    left=$rest
done
n=$(judged | wc -l | tr -d ' ')
for v in "$scratch"/*/verdict/verdict-*; do [ ! -f "$v" ] || cat "$v" >> "$out/$(basename "$v")"; done
# one pack: what every job published, folded with nothing dropped
(cd "$scratch" && AVRA_CACHE_DIR="$scratch/fold" AVRA_MACHINE_STORE_DIR="$out" "$avra" cache clean >/dev/null 2>&1) ||
    { echo "std_answers: the answers were not compacted" >&2; exit 1; }
# the packs, the kept files naming every question in them (so a store's compaction keeps them), the
# verdict
find "$out" -mindepth 1 ! -name 'pack-*' ! -name 'kept-*' ! -name 'verdict-*' -delete
echo "$key" > "$out/inputs"
echo "std answers: $n packages, $(ls "$out" | wc -l | tr -d ' ') packs, $(du -sk "$out" | cut -f1) KB in $out"
