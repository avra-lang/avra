# make overhead, before (origin/main's Makefile) and after (this tree's): the
# objects check alone, then `make try` no-op and after one leaf edit.
cd "$(dirname "$0")/../.."
T(){ t0=$(date +%s%N); "$@" >/dev/null 2>&1; echo "$(( ($(date +%s%N)-t0)/1000000 )) ms  $*"; }
C="build/libavra_runtime.a build/llvm_wrapper.o build/ffi.o build/std_io.o build/std_io_watch.o build/std_process.o build/std_time.o build/std_net.o build/std_hash.a"
LEAF=packages/cli/src/commands/rules.av
for mk in tools/db_measure/Makefile.main Makefile; do
  echo "== $mk"
  make -s -f $mk $C >/dev/null 2>&1
  for i in 1 2 3; do T make -s -f $mk $C; done
  make -s -f $mk try >/dev/null 2>&1
  for i in 1 2; do T make -s -f $mk try; done
  cp $LEAF build/leaf.keep; printf '\n// one leaf edit %s\n' "$mk-$(date +%s%N)" >> $LEAF
  T make -s -f $mk try
  cp build/leaf.keep $LEAF
  T make -s -f $mk try
done
