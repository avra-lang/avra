# the cli's link alone: which linker clang uses now, and the same link under lld
cd "$(dirname "$0")/../.."
REAL=$(command -v clang); [ -n "${LLVM_PREFIX:-}" ] && [ -x $LLVM_PREFIX/bin/clang ] && REAL=$LLVM_PREFIX/bin/clang
W=$PWD/build/cc-log.sh
printf '#!/bin/sh\nprintf "%%s\\n" "$@" > %s/build/cc-last.args\nexec %s "$@"\n' "$PWD" "$REAL" > $W; chmod +x $W
LEAF=packages/cli/src/commands/rules.av
cp $LEAF build/leaf.keep; printf '\n// link %s\n' "$(date +%s%N)" >> $LEAF
CC=$W ./avra build --time packages/cli > build/lp.out 2>&1; echo "build exit $?"; grep -oE "link [0-9]+ms" build/lp.out
cp build/leaf.keep $LEAF
echo "clang: $REAL"; $REAL -### -x c /dev/null -o /dev/null 2>&1 | grep -oE '"[^"]*(ld|lld|mold)[^"]*"' | head -2
echo "lld present: $(ls $(dirname $REAL)/ld.lld 2>/dev/null || command -v ld.lld || echo none)"
ARGS=$(tr '\n' '\001' < build/cc-last.args)
run() { t0=$(date +%s%N); IFS=$(printf '\001'); set -f; $REAL $ARGS "$@" >/dev/null 2>&1; s=$?; set +f; unset IFS; echo "$(( ($(date +%s%N)-t0)/1000000 )) ms exit $s $*"; }
for i in 1 2; do run; done
for i in 1 2; do run -fuse-ld=lld; done
echo "objects linked: $(grep -c '\.o$' build/cc-last.args)"
