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
# CENSUS_EDIT MEASURES A WARM EDIT: the command runs once cold to fill the store,
# then CENSUS_EDIT edits the tree, and only the run after it is counted.
#   CENSUS_EDIT='sh tools/db_measure/edit_literal.sh' sh tools/census.sh check packages/cli
#
# A CENSUS THAT PRINTS NO COUNTS FAILS. A check that examined nothing
# is not a check that passed: no `rc:` line means the binary carried no
# census, and the run exits 1 saying so.
# A cold run clears the tree's `.avra-cache`; the machine store lives there too, or "cold" would read the machine's rows.
export AVRA_CACHE_DIR="$(cd "$(dirname "$0")/.." && pwd)/.avra-cache"
set -eu
cd "$(dirname "$0")/.."
: "${LLVM_PREFIX:=/opt/homebrew/opt/llvm}"
export LLVM_PREFIX

# THE BUILDER IS build/avra unless CENSUS_BUILDER names another: a layout rule is the BUILDING
# compiler's, so a census of a rule builds the census compiler with a compiler that has it.
# THE CENSUS COUNTS THE COMPILER'S OWN WORK, under a memory cap: the old path's check the net runs
# before the program layer's is not that work, and its memory with the layer's passes the cap.
export AVRA_PROGRAM_NET=0
builder=${CENSUS_BUILDER:-build/avra}
[ -x "$builder" ] || { echo "census: no $builder to build the census compiler with — run \`make avra\` first"; exit 1; }
census=build/avra.census
stores=.avra-cache.census-saved
suffix=.census-saved
named="$*"
# The flags ride the objects' stamps, so each build below rebuilds
# exactly the objects whose flags moved, and the last one leaves the
# shipping runtime standing.
# A MADE BOX IS NAMED BY ITS CALLER'S CALLER, two frames up, which only frame pointers reach:
# macOS keeps them always, Linux only when asked, in the runtime and in every emitted fn.
counted="-DAVRA_CENSUS -fno-omit-frame-pointer"
restore() {
    make --no-print-directory build/libavra_runtime.a > /dev/null 2>&1 || \
        echo "census: the shipping runtime did NOT rebuild — run \`make build/libavra_runtime.a\`"
    rm -f packages/cli/src/main packages/cli/src/main.av.ll
    if [ -d "$stores" ]; then rm -rf .avra-cache; mv "$stores" .avra-cache; fi
    for d in $named; do
        if [ -d "$d/.avra-cache$suffix" ]; then rm -rf "$d/.avra-cache"; mv "$d/.avra-cache$suffix" "$d/.avra-cache"; fi
    done
}
trap restore EXIT INT TERM

make --no-print-directory CFLAGS_avra_runtime="$counted" CFLAGS_avra_hot="$counted" build/libavra_runtime.a > /dev/null
rm -rf "$stores"
[ -d .avra-cache ] && mv .avra-cache "$stores"
# THE COUNTED LEAVES STAY CALLS: the bitcode the compiler inlines was
# built without the census, so an inlined retain would count nothing.
# THE MINTED BOXES ARE NAMED: each box a runtime row makes is counted by
# its type (AVRA_CENSUS_TYPES), the `type:` table.
AVRA_FRAME_POINTERS=1 AVRA_INLINE_RUNTIME=0 AVRA_CENSUS_TYPES=1 AVRA_PROGRAM_MODE=release "$builder" build packages/cli > build/census-build.out 2>&1 || {
    tail -20 build/census-build.out; echo "census: the census compiler did not build"; exit 1; }
# A BINARY THE PROGRAM LAYER PLACES IS ITS KEPT BINARY, LINKED: a census compiler left from an earlier
# run can be that same file, which `mv` will not move onto itself — the old one goes first.
[ ! -e "$census" ] || find "$census" -delete
mv packages/cli/src/main "$census"
# A C symbol wears a leading underscore on macOS and none on Linux.
nm "$census" | grep -Eq '[ _]note_retain$' || { echo "census: $census carries no census — refusing to report"; exit 1; }

# THE MEASURED RUN STARTS COLD: the census compiler's store is its own
# and was never filled, and the tree's stores stand aside until exit.
# THE FILTER DROPS `mem:`, IT DOES NOT SELECT LABELS: an allowlist of
# census labels is a second registry of them, and goes stale silently.
# A PACKAGE NAMED ON THE COMMAND KEEPS ITS OWN STORE (`tapes <pkg>` writes `<pkg>/.avra-cache`), so it
# stands aside too, or the second census of one package reads the first one's answers.
rm -rf .avra-cache
for d in "$@"; do
    if [ -d "$d/.avra-cache" ]; then rm -rf "$d/.avra-cache$suffix"; mv "$d/.avra-cache" "$d/.avra-cache$suffix"; fi
done
if [ -n "${CENSUS_EDIT:-}" ]; then
    sh tools/memcap.sh "${CENSUS_CAP_MB:-4000}" "$census" "$@" > build/census-cold.out 2>&1 || { tail -5 build/census-cold.out; echo "census: the cold run failed"; exit 1; }
    sh -c "$CENSUS_EDIT"
fi
out="$(AVRA_MEM_STATS=1 AVRA_CENSUS_SITES=1 sh tools/memcap.sh "${CENSUS_CAP_MB:-4000}" "$census" "$@" 2>&1 >/dev/null \
    | tee build/census-raw.out | grep -Ev '^(mem:|memcap:)' || true)"
printf '%s\n' "$out" | grep -q '^rc:' || { printf '%s\n' "$out" | tail -5; echo "census: the run printed no counts"; exit 1; }

# THE STORE'S BYTES, read while the census run's own store stands (the exit trap puts the tree's
# back): a row ceiling alone misses rows that got larger.
python3 - <<'PY' > build/census-store.out 2>/dev/null || true
import os
n = 0
for d, _, files in os.walk(".avra-cache/store"):
    n += sum(os.path.getsize(os.path.join(d, f)) for f in files)
print("store: %d bytes" % n)
PY
out="$out
$(cat build/census-store.out 2>/dev/null)"

# Every site's symbol, one line per address in the order given: `atos` on macOS, `addr2line`
# elsewhere, each asked ONCE for all of them — a table of thousands of sites asked one at a time
# spends longer resolving than the census spent counting.
symbols_at() {
    if command -v atos > /dev/null 2>&1; then
        xargs atos -o "$census" 2>/dev/null
    else
        xargs addr2line -f -e "$census" 2>/dev/null | awk 'NR % 2 == 1'
    fi
}

# A SITE IS RESOLVED HERE, while the census binary those addresses
# belong to is still standing; an address no symbol names keeps its line as printed.
printf '%s\n' "$out" | awk '/: site 0x/ {print $3}' | sort -u > build/census-sites.out
symbols_at < build/census-sites.out | paste -d' ' build/census-sites.out - > build/census-names.out
printf '%s\n' "$out" | awk '
    NR == FNR { if ($2 != "" && $2 != "??" && $2 !~ /0x/) name[$1] = $2; next }
    /: site 0x/ && ($3 in name) { line = $1 " " name[$3]; for (i = 4; i <= NF; i++) line = line " " $i; print line; next }
    { print }
' build/census-names.out -
