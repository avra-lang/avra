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
# fuzz, soak and gallery packages are its harnesses, never a program's import. Prints one line: how
# many packages, how many packs, how many kilobytes.
#   sh tools/std_answers.sh <avra> <std> <out> [package…]   (default every std package but those)
set -u
[ $# -ge 3 ] || { sed -n 2,10p "$0"; exit 2; }
avra=$1; std=$2; out=$3
shift 3
named="$*"
# the compiler's own packages, never a program's import
COMPILERS=" std-avrac std-http-fuzz std-http-soak std-ui_gallery "
[ -x "$avra" ] || { echo "std_answers: no compiler at $avra" >&2; exit 1; }
[ -d "$std" ] || { echo "std_answers: no std at $std" >&2; exit 1; }
scratch=$(mktemp -d)
trap 'find "$scratch" -delete' EXIT
mkdir -p "$out"
find "$out" -mindepth 1 -delete
n=0
for p in "$std"/std-*; do
    [ -f "$p/avra.toml" ] || continue
    if [ -n "$named" ]; then
        case " $named " in *" $(basename "$p") "*) ;; *) continue ;; esac
    else
        case "$COMPILERS" in *" $(basename "$p") "*) continue ;; esac
    fi
    # the verdict: the package's own check, its answers kept apart and let go
    AVRA_CACHE_DIR="$scratch" AVRA_MACHINE_STORE_DIR="$scratch/judged" AVRA_VERDICT_DIR="$out" AVRA_PROGRAM_NET=0 "$avra" check "$p" >/dev/null 2>"$scratch/said" ||
        { echo "std_answers: $(basename "$p") is refused by its own compiler:" >&2; cat "$scratch/said" >&2; exit 1; }
    # the answers: what a program over the package reads of it
    AVRA_CACHE_DIR="$scratch" AVRA_MACHINE_STORE_DIR="$out" AVRA_PROGRAM_NET=0 "$avra" cache dependents "$p" >/dev/null 2>"$scratch/said" ||
        { echo "std_answers: what a program reads of $(basename "$p") was not worked out:" >&2; cat "$scratch/said" >&2; exit 1; }
    find "$p" -name .avra-cache -type d -prune -exec find {} -delete \;
    n=$((n + 1))
done
find "$out" -mindepth 1 ! -name 'pack-*' ! -name 'verdict-*' -delete
echo "std answers: $n packages, $(ls "$out" | wc -l | tr -d ' ') packs, $(du -sk "$out" | cut -f1) KB in $out"
