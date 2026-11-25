#!/bin/sh
# THE CENSUS COMPILER: the cli this tree builds, over a runtime compiled with -DAVRA_CENSUS, written
# to <out>. It counts exactly what the shipping compiler does and never ships: the shipping runtime
# library is rebuilt before this answers, and the cli's own product is gone.
#   sh tools/census_compiler.sh build/avra.census
#
# THE BUILDER IS build/avra unless CENSUS_BUILDER names another: a layout rule is the BUILDING
# compiler's, so a census of a rule builds the census compiler with a compiler that has it.
set -eu
cd "$(dirname "$0")/.."
out=${1:-build/avra.census}
builder=${CENSUS_BUILDER:-build/avra}
[ -x "$builder" ] || { echo "census: no $builder to build the census compiler with — run \`make avra\` first"; exit 1; }
# A MADE BOX IS NAMED BY ITS CALLER'S CALLER, two frames up, which only frame pointers reach:
# macOS keeps them always, Linux only when asked, in the runtime and in every emitted fn.
counted="-DAVRA_CENSUS -fno-omit-frame-pointer"
shipping() {
    make --no-print-directory build/libavra_runtime.a > /dev/null 2>&1 || \
        echo "census: the shipping runtime did NOT rebuild — run \`make build/libavra_runtime.a\`"
    find packages/cli/src/main packages/cli/src/main.av.ll -maxdepth 0 -delete 2> /dev/null || :
}
trap shipping EXIT INT TERM
make --no-print-directory CFLAGS_avra_runtime="$counted" CFLAGS_avra_hot="$counted" build/libavra_runtime.a > /dev/null
# THE COUNTED LEAVES STAY CALLS: the bitcode the compiler inlines was
# built without the census, so an inlined retain would count nothing.
# THE MINTED BOXES ARE NAMED: each box a runtime row makes is counted by
# its type (AVRA_CENSUS_TYPES), the `type:` table.
# THE CENSUS COUNTS THE COMPILER'S OWN WORK: the old path's check the net runs first is not that work.
AVRA_FRAME_POINTERS=1 AVRA_INLINE_RUNTIME=0 AVRA_CENSUS_TYPES=1 AVRA_PROGRAM_MODE=release \
    "$builder" build packages/cli > build/census-build.out 2>&1 || {
    tail -20 build/census-build.out; echo "census: the census compiler did not build"; exit 1; }
# A BINARY THE PROGRAM LAYER PLACES IS ITS KEPT BINARY, LINKED: a census compiler left from an earlier
# run can be that same file, which `mv` will not move onto itself — the old one goes first.
[ ! -e "$out" ] || find "$out" -delete
mv packages/cli/src/main "$out"
# A C symbol wears a leading underscore on macOS and none on Linux.
nm "$out" | grep -Eq '[ _]note_retain$' || { echo "census: $out carries no census — refusing to report"; exit 1; }
# WHAT BUILT IT, beside it: its builder's record (tools/work built-from), which tools/cost.sh holds a
# census compiler built elsewhere — a gate's seed — to as it holds a builder
builder_record="$(dirname "$builder")/.$(basename "$builder")-built-from"
census_record="$(dirname "$out")/.$(basename "$out")-built-from"
# and this script's own hash, which decides the census's flags and so is part of what it is
if [ -s "$builder_record" ]; then
    read -r r_hash r_at r_gen _ < "$builder_record"
    echo "$r_hash $r_at $r_gen $(sha256sum tools/census_compiler.sh | cut -d' ' -f1)" > "$census_record"
else
    find "$census_record" -delete 2> /dev/null || :
fi
