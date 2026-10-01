#!/bin/sh
# BOXES A PROGRAM'S RUNTIME ROWS ANSWER, BY TYPE, ranked: the census's
# `type:` table for any program, not only the compiler. The program is
# built against a census runtime (-DAVRA_CENSUS), each owning row's
# answer counted by its type (AVRA_CENSUS_TYPES=1), the hot leaves kept
# as calls (AVRA_INLINE_RUNTIME=0), then run once.
#   sh tools/census_types.sh tools/bench/request/src/main.av [args...]
#
# A FLAGGED BUILD NEVER FILLS THE SHIPPING STORE. The tree's stores
# stand aside for the build and come back on every exit, with the
# shipping runtime library rebuilt.
set -eu
cd "$(dirname "$0")/.."
src=${1:?usage: sh tools/census_types.sh <program.av> [args...]}
shift
[ -x build/avra ] || { echo "census-types: no build/avra — run \`make avra\` first"; exit 1; }
stores=.avra-cache.census-types-saved
flags="CFLAGS_avra_runtime=-DAVRA_CENSUS CFLAGS_avra_hot=-DAVRA_CENSUS"
restore() {
    make --no-print-directory build/libavra_runtime.a > /dev/null 2>&1 || \
        echo "census-types: the shipping runtime did NOT rebuild — run \`make build/libavra_runtime.a\`"
    if [ -d "$stores" ]; then rm -rf .avra-cache; mv "$stores" .avra-cache; fi
}
trap restore EXIT INT TERM

# shellcheck disable=SC2086
make --no-print-directory $flags build/libavra_runtime.a > /dev/null
rm -rf "$stores"
[ -d .avra-cache ] && mv .avra-cache "$stores"
AVRA_CENSUS_TYPES=1 AVRA_INLINE_RUNTIME=0 build/avra build "$src" > build/census-types-build.out 2>&1 || {
    tail -20 build/census-types-build.out; echo "census-types: the program did not build"; exit 1; }
rm -rf .avra-cache
# the program's own output is not the census's; its counts arrive on stderr
out="$(AVRA_MEM_STATS=1 "${src%.av}" "$@" 2>&1 > /dev/null | grep -Ev '^mem:' || true)"
printf '%s\n' "$out" | grep -q '^type:' || { printf '%s\n' "$out" | tail -5; echo "census-types: the run printed no type counts"; exit 1; }
printf '%s\n' "$out"
