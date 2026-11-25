cd /work/avra; . /etc/profile.d/avra.sh
make try > /tmp/rc-try.log 2>&1; echo "try exit $?" > /tmp/rc-sum.log
AVRA_PROGRAM_NET=0 build/avra-try check packages/std-avrac > /tmp/rc-layer.log 2>&1; echo "layer check exit $?" >> /tmp/rc-sum.log
for f in sp1 sp2 pt1 pt4 co1 vb1 n1 bd1; do sh /tmp/p/cmp.sh /tmp/p/$f.av | cut -c1-200 >> /tmp/rc-sum.log; done
AVRA_PROGRAM_NET=0 build/avra-try build packages/cli > /tmp/rc-cli.log 2>&1; echo "cli exit $? refusals $(grep -c '^error' /tmp/rc-cli.log)" >> /tmp/rc-sum.log
for s in a b c d e f g; do sh tools/gate.sh avrac-$s > /tmp/rc-gate-$s.log 2>&1; grep "^GATE" /tmp/rc-gate-$s.log | tail -1 >> /tmp/rc-sum.log; done
sh tools/witness_program_refusal.sh build/avra-try > /tmp/rc-wit.log 2>&1; echo "witness exit $? $(tail -1 /tmp/rc-wit.log)" >> /tmp/rc-sum.log
AVRA_MEM_POOL_MB=13000 AVRA_PROGRAM=0 build/avra-try check packages/std-avrac --baseline tools/idioms.baseline > /tmp/rc-idioms.log 2>&1; echo "idioms exit $? $(grep -ci 'new' /tmp/rc-idioms.log) lines-with-new; $(tail -1 /tmp/rc-idioms.log)" >> /tmp/rc-sum.log
echo DONE >> /tmp/rc-sum.log
