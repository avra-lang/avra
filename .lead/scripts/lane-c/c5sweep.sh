cd /Users/tristan/projects/tristanMatthias/avra-ho-c
export LLVM_PREFIX=/opt/homebrew/opt/llvm AVRA_CACHE_DIR=$PWD/build/machine-cache AVRA_MEM_CEILING_MB=9500 AVRA_MEM_POOL_WAIT_MS=2400000
mkdir -p /tmp/c5sw
for d in ${SWEEP:-packages/* tools/ui-board}; do
  [ -f $d/avra.toml ] || continue
  n=$(basename $d)
  timeout 2400 build/avra-try tapes $PWD/$d --findings > /tmp/c5sw/$n.find 2>&1; fe=$?
  timeout 2400 build/avra-try tapes $PWD/$d --ran --left > /tmp/c5sw/$n.ran 2>&1; re=$?
  echo "$n find=$fe type=$(grep -cE '^error\[type\.' /tmp/c5sw/$n.find) errors=$(grep -c '^error' /tmp/c5sw/$n.find) | ran=$re $(grep -E '^ran:' /tmp/c5sw/$n.ran | cut -c6-80) | seat-refused=$(grep -c 'seat refuses' /tmp/c5sw/$n.ran)"
done
find /Users/tristan/projects/tristanMatthias/avra-ho-c -name .avra-cache -type d -prune -exec find {} -mindepth 1 -delete \;
echo SWEEP_DONE
