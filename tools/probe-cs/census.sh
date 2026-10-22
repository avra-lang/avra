# Census + guard receipts. $1 = main compiler hash.
set -u
T=$PWD
cp /home/sprite/avra-compilers/$1/avra build/avra.main; MAIN=$T/build/avra.main
ls -l "$MAIN" build/avra
mkdir -p /tmp/cs && cp tools/probe-cs/*.av /tmp/cs/
flags="CFLAGS_avra_runtime=-DAVRA_CENSUS CFLAGS_avra_hot=-DAVRA_CENSUS"
make --no-print-directory $flags build/libavra_runtime.a >/dev/null
for who in main branch; do
  if [ $who = main ]; then C=$MAIN; else C=$T/build/avra; fi
  rm -rf .avra-cache /tmp/cs/.avra-cache
  echo "== $who: ir of bench fill"
  $C ir /tmp/cs/bench.av | grep -c "slot_get_owned"
  AVRA_INLINE_RUNTIME=0 $C build /tmp/cs/bench.av >/tmp/cs/b.out 2>&1 || tail /tmp/cs/b.out
  echo "== $who: census of native bench"
  AVRA_MEM_STATS=1 /tmp/cs/bench 2>&1 | grep -E "^(rc|alloc:|mem: live)"
  /tmp/cs/bench
done
make --no-print-directory build/libavra_runtime.a >/dev/null
