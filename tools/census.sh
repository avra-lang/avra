#!/bin/sh
# THE CENSUS BUILD: exact retain/release/list-write counts, and the
# callers that cause them. Counting costs ~8% of a run, so it never
# ships: a census compiler is built BESIDE build/avra, from a runtime
# compiled with -DAVRA_CENSUS, and the shipping runtime library is
# rebuilt on every exit.
#   sh tools/census.sh check packages/std-avrac
#
# THE SHIPPING COMPILER IS NEVER REMOVED. It builds the census
# compiler, so a census that deletes it first has nothing to build
# with, and every recovery that rebuilds needs the memory and disk the
# census run just spent.
#
# A CENSUS THAT PRINTS NO COUNTS FAILS. A check that examined nothing
# is not a check that passed: no `rc:` line means the binary carried no
# census, and the run exits 1 saying so.
set -eu
cd "$(dirname "$0")/.."
: "${LLVM_PREFIX:=/opt/homebrew/opt/llvm}"
export LLVM_PREFIX

[ -x build/avra ] || { echo "census: no build/avra to build the census compiler with — run \`make avra\` first"; exit 1; }
census=build/avra.census
stores=.avra-cache.census-saved
# The flags ride the objects' stamps, so each build below rebuilds
# exactly the objects whose flags moved, and the last one leaves the
# shipping runtime standing.
flags="CFLAGS_avra_runtime=-DAVRA_CENSUS CFLAGS_avra_hot=-DAVRA_CENSUS"
restore() {
    make --no-print-directory build/libavra_runtime.a > /dev/null 2>&1 || \
        echo "census: the shipping runtime did NOT rebuild — run \`make build/libavra_runtime.a\`"
    rm -f packages/cli/src/main packages/cli/src/main.av.ll
    if [ -d "$stores" ]; then rm -rf .avra-cache; mv "$stores" .avra-cache; fi
}
trap restore EXIT INT TERM

# shellcheck disable=SC2086
make --no-print-directory $flags build/libavra_runtime.a > /dev/null
rm -rf "$stores"
[ -d .avra-cache ] && mv .avra-cache "$stores"
# THE COUNTED LEAVES STAY CALLS: the bitcode the compiler inlines was
# built without the census, so an inlined retain would count nothing.
# THE MINTED BOXES ARE NAMED: each box a runtime row makes is counted by
# its type (AVRA_CENSUS_TYPES), the `type:` table.
AVRA_INLINE_RUNTIME=0 AVRA_CENSUS_TYPES=1 build/avra build packages/cli > build/census-build.out 2>&1 || {
    tail -20 build/census-build.out; echo "census: the census compiler did not build"; exit 1; }
mv packages/cli/src/main "$census"
# A C symbol wears a leading underscore on macOS and none on Linux.
nm "$census" | grep -Eq '[ _]note_retain$' || { echo "census: $census carries no census — refusing to report"; exit 1; }

# THE MEASURED RUN STARTS COLD: the census compiler's store is its own
# and was never filled, and the tree's stores stand aside until exit.
# THE FILTER DROPS `mem:`, IT DOES NOT SELECT LABELS: an allowlist of
# census labels is a second registry of them, and goes stale silently.
rm -rf .avra-cache
out="$(AVRA_MEM_STATS=1 AVRA_CENSUS_SITES=1 sh tools/memcap.sh 4000 "$census" "$@" 2>&1 >/dev/null \
    | grep -Ev '^(mem:|memcap:)' || true)"
printf '%s\n' "$out" | grep -q '^rc:' || { printf '%s\n' "$out" | tail -5; echo "census: the run printed no counts"; exit 1; }

# An unslid address's symbol: `atos` on macOS, `addr2line` elsewhere.
symbol_at() {
    if command -v atos > /dev/null 2>&1; then
        atos -o "$census" "$1" 2>/dev/null | head -1
    else
        addr2line -f -e "$census" "$1" 2>/dev/null | head -1 | grep -v '^??$' || true
    fi
}

# A SITE IS RESOLVED HERE, while the census binary those addresses
# belong to is still standing.
printf '%s\n' "$out" | while IFS= read -r line; do
    case "$line" in
        *": site 0x"*)
            # shellcheck disable=SC2086
            set -- $line
            name="$(symbol_at "$3")"
            case "$name" in
                ""|*"0x"*) echo "$line" ;;
                *) echo "$1 $name $4" ;;
            esac
            ;;
        *) echo "$line" ;;
    esac
done
