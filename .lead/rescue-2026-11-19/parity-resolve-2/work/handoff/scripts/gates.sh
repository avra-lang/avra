cd /work/avra
AVRA_MEM_POOL_MB=12000 AVRA_MEM_CEILING_MB=12000 AVRA_PROGRAM_NET=0 build/avra-try check packages/std-avrac > /tmp/claude-0/checkavrac.log 2>&1; echo "EXIT $?" >> /tmp/claude-0/checkavrac.log
for s in avrac-a avrac-g avrac-b avrac-c avrac-d avrac-e avrac-f; do
  AVRA_MEM_POOL_MB=12000 sh tools/gate.sh $s > /tmp/claude-0/gate-$s.log 2>&1; echo "EXIT $?" >> /tmp/claude-0/gate-$s.log
done
AVRA_PROGRAM_NET=0 build/avra-try build packages/cli > /tmp/claude-0/cli.log 2>&1; echo "CLI EXIT $?" >> /tmp/claude-0/cli.log
sh tools/witness_program_refusal.sh build/avra-try > /tmp/claude-0/witness4.log 2>&1; echo "EXIT $?" >> /tmp/claude-0/witness4.log
AVRA_MEM_POOL_MB=12000 AVRA_PROGRAM=0 AVRA_MEM_CEILING_MB=12000 build/avra-try check packages/cli --baseline tools/idioms.baseline > /tmp/claude-0/idioms.log 2>&1; echo "EXIT $?" >> /tmp/claude-0/idioms.log
echo ALLDONE > /tmp/claude-0/gates.done
