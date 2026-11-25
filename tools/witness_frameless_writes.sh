#!/bin/sh
# THE WRITE ROWS' FAST PATHS KEEP NO FRAME: runtime/avra_hot.c compiled at -O2 for x86-64 and
# aarch64, and each of the six write leaves shows no push, stp, `sub` of the stack pointer or save
# of the link register before its first branch. Prints each leaf's prologue up to that branch.
#   sh tools/witness_frameless_writes.sh
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'find "$tmp" -delete' EXIT
failed=0
for arch in x86_64 aarch64; do
    free=""
    [ "$arch" = aarch64 ] && free=-ffreestanding
    clang --target=$arch-linux-gnu -O2 -fPIC -ffunction-sections $free -c "$root/runtime/avra_hot.c" -o "$tmp/hot_$arch.o" || { echo "witness_frameless_writes: $arch did not compile" >&2; exit 1; }
    for fn in avra_array_push avra_array_push_owned avra_array_push_moved avra_slot_put avra_slot_set avra_slot_unique; do
        llvm-objdump -d --no-show-raw-insn --disassemble-symbols=$fn "$tmp/hot_$arch.o" | sed -n '/>:$/,$p' > "$tmp/$arch.$fn"
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
