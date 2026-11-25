cd /work/avra
AVRA_MEM_POOL_MB=12000 AVRA_MEM_CEILING_MB=12000 AVRA_PROGRAM_NET=0 build/avra-try check packages/std-avrac > /tmp/claude-0/checkavrac.log 2>&1; echo "EXIT $?" >> /tmp/claude-0/checkavrac.log
for s in avrac-a avrac-g avrac-b avrac-c avrac-d avrac-e avrac-f; do
  AVRA_MEM_POOL_MB=12000 sh tools/gate.sh $s > /tmp/claude-0/gate-$s.log 2>&1; echo "EXIT $?" >> /tmp/claude-0/gate-$s.log
done
AVRA_MEM_POOL_MB=12000 AVRA_PROGRAM=0 AVRA_MEM_CEILING_MB=12000 build/avra-try check packages/cli --baseline tools/idioms.baseline > /tmp/claude-0/idioms.log 2>&1; echo "EXIT $?" >> /tmp/claude-0/idioms.log
echo ALLDONE > /tmp/claude-0/gates.done
