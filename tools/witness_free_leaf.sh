#!/bin/sh
# THE FREE LEAF KEEPS NO FRAME: `avra_release_dead` (a box's death, reached from every release that
# frees) and `slab_free` (a slab block back to its page) take their common path — a list owning no
# cell, a page that stays as it was — with no frame op at all; every path that needs one is a tail
# call out of line. Reads the runtime object the shipping build compiled and refuses where either
# fn saves a register or moves the stack pointer.
#   sh tools/witness_free_leaf.sh [object]   (default build/avra_runtime.o)
set -eu
cd "$(dirname "$0")/.."
obj="${1:-build/avra_runtime.o}"
[ -f "$obj" ] || { echo "free-leaf: no $obj — run \`make build/libavra_runtime.a\` first"; exit 2; }
dis="$(objdump -d --no-show-raw-insn "$obj" 2>/dev/null)" || { echo "free-leaf: objdump could not read $obj"; exit 2; }
fails=0
for fn in avra_release_dead slab_free; do
    body="$(printf '%s\n' "$dis" | awk -v f="$fn" '$0 ~ "<_?" f ">:" {on = 1; next} on && /^$/ {exit} on {print}')"
    if [ -z "$body" ]; then echo "free-leaf: $fn is not in $obj"; fails=$((fails + 1)); continue; fi
    # x86-64: push, or a stack adjust; arm64: a register pair stored, or sp moved
    frame="$(printf '%s\n' "$body" | grep -cE '[[:space:]](push|stp)[[:space:]]|sub[[:space:]]+(\$0x[0-9a-f]+, *%rsp|sp, *sp)' || true)"
    if [ "$frame" != 0 ]; then echo "free-leaf: $fn keeps a frame ($frame frame op(s))"; fails=$((fails + 1)); else echo "free-leaf: $fn keeps no frame"; fi
done
[ "$fails" = 0 ]
