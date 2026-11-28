#!/bin/sh
# THE WRITE ROWS' FAST PATHS KEEP NO FRAME: runtime/avra_hot.c compiled at -O2 for x86-64 and
# aarch64, and each of the six write leaves shows no push, stp, `sub` of the stack pointer or save
# of the link register before its first branch. Prints each leaf's prologue up to that branch.
#   sh tools/witness_frameless_writes.sh
. "$(dirname "$0")/lib/scratch.sh"
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
scratch_dir tmp
failed=0
# the disassembler as this machine names it: unversioned, or the image's llvm-22, or the prefix's
objdump=$(command -v llvm-objdump || command -v llvm-objdump-22 || { [ -x "${LLVM_PREFIX:-/usr/lib/llvm-22}/bin/llvm-objdump" ] && echo "${LLVM_PREFIX:-/usr/lib/llvm-22}/bin/llvm-objdump"; }) ||
    { echo "witness_frameless_writes: no llvm-objdump here (nor llvm-objdump-22, nor under LLVM_PREFIX) — nothing can be read" >&2; exit 1; }
for arch in x86_64 aarch64; do
    free=""
    [ "$arch" = aarch64 ] && free=-ffreestanding
    clang --target=$arch-linux-gnu -O2 -fPIC -ffunction-sections $free -c "$root/runtime/avra_hot.c" -o "$tmp/hot_$arch.o" || { echo "witness_frameless_writes: $arch did not compile" >&2; exit 1; }
    for fn in avra_array_push avra_array_push_owned avra_array_push_moved avra_slot_put avra_slot_set avra_slot_unique; do
        "$objdump" -d --no-show-raw-insn --disassemble-symbols=$fn "$tmp/hot_$arch.o" | sed -n '/>:$/,$p' > "$tmp/$arch.$fn"
        [ -s "$tmp/$arch.$fn" ] || { echo "witness_frameless_writes: $objdump read no $fn in the $arch object" >&2; failed=$((failed + 1)); continue; }
        first=$(grep -nE '^ +[0-9a-f]+:[[:space:]]+(j[a-z]+|b\.[a-z]+|cbn?z|tbn?z|b)[[:space:]]' "$tmp/$arch.$fn" | head -1 | cut -d: -f1)
        [ -n "$first" ] || { echo "witness_frameless_writes: $arch $fn has no branch" >&2; failed=$((failed + 1)); continue; }
        frames=$(head -n "$first" "$tmp/$arch.$fn" | grep -cE '^ +[0-9a-f]+:[[:space:]]+(push|stp|sub[[:space:]].*(%rsp|sp,)|str[[:space:]]+x30)')
        echo "== $arch $fn: $frames frame ops before the first branch"
        head -n "$first" "$tmp/$arch.$fn" | tail -n +2
        [ "$frames" = 0 ] || failed=$((failed + 1))
    done
done
[ "$failed" = 0 ] && echo "witness_frameless_writes: six write leaves frameless on x86-64 and aarch64"
[ "$failed" = 0 ]
