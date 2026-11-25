cd /work/avra; . /etc/profile.d/avra.sh
make try > /tmp/rc-try.log 2>&1; echo "try exit $?" > /tmp/rc-sum2.log
build/avra-try fmt --write packages/std-avrac/src/compiler/item_members.av > /dev/null 2>&1
for f in i1 i2 i3 i4 i5 x5 x6 x7 d5; do sh /tmp/p/cmp.sh /tmp/p/$f.av | cut -c1-160 >> /tmp/rc-sum2.log; done
AVRA_PROGRAM_NET=0 build/avra-try check packages/std-avrac > /tmp/rc-layer.log 2>&1; echo "layer check exit $?" >> /tmp/rc-sum2.log
AVRA_PROGRAM_NET=0 build/avra-try build packages/cli > /tmp/rc-cli.log 2>&1; echo "cli exit $? refusals $(grep -c '^error' /tmp/rc-cli.log)" >> /tmp/rc-sum2.log
sh tools/witness_program_refusal.sh build/avra-try > /tmp/rc-wit.log 2>&1; echo "witness exit $? $(tail -1 /tmp/rc-wit.log)" >> /tmp/rc-sum2.log
AVRA_PROGRAM=0 build/avra-try check packages/std-avrac --baseline tools/idioms.baseline > /tmp/rc-idioms.log 2>&1; echo "idioms exit $?; $(tail -1 /tmp/rc-idioms.log)" >> /tmp/rc-sum2.log
echo DONE2 >> /tmp/rc-sum2.log
