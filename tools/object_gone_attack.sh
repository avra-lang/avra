#!/bin/sh
# AN OBJECT THE MACHINE'S STORE NAMES MUST STAND, OR THE BUILD LOWERS AGAIN. The list of a
# program's buckets is kept in the machine's store and its objects in the tree's `.avra-cache`,
# so clearing the tree's cache leaves a list naming objects that are gone; the next build by the
# same compiler read the list and refused with "a held object disappeared". It CLEARS the
# tree's cache, as the attacks beside it do.
#   AVRA=build/avra-try sh tools/object_gone_attack.sh
. "$(dirname "$0")/lib/scratch.sh"
set -eu
# a store is copied, counted or emptied here between builds, so each build saves its own before it answers
export AVRA_STORE_KEPT_HERE=1
cd "$(dirname "$0")/.."
: "${LLVM_PREFIX:=/opt/homebrew/opt/llvm}"
export LLVM_PREFIX
avra="${AVRA:-build/avra}"
prog=packages/std-avrac/src/features/fns/tests/contained_task
scratch_dir out; out="$out/file"; : > "$out"
find .avra-cache -mindepth 1 -delete 2>/dev/null || true
"$avra" test "$prog" > "$out" 2>&1 || { tail -5 "$out"; echo "object_gone_attack: the first build failed"; exit 1; }
find .avra-cache -mindepth 1 -delete
"$avra" test "$prog" > "$out" 2>&1 || { grep -E "disappeared|^error" "$out" | head -3; echo "object_gone_attack: a build after the tree's cache was cleared failed"; exit 1; }
echo "object_gone_attack: a build after the tree's cache was cleared stands"
