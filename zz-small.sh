F=packages/std-text/src/text.av
make -s try > b.out 2>&1; echo "BUILD $?"; tail -2 b.out | cut -c1-120
t0=$(date +%s); ./avra-try check packages/std-text > s1.out 2>&1; echo "COLD $? $(( $(date +%s) - t0 ))s"
sed -i '1i // zzprobe' $F
t1=$(date +%s); AVRA_QTRACE=1 ./avra-try check --time packages/std-text > s2.out 2> s2.err; echo "EDIT $? $(( $(date +%s) - t1 ))s"
sed -i '1d' $F
grep -a '^time:' s2.out s2.err 2>/dev/null | cut -c1-240
grep -a 'PROBE' s2.out s2.err 2>/dev/null | tail -3
grep -ac '^Q	parse' s2.err | sed 's/^/parses /'
grep -ac 'Q	facts' s2.err | sed 's/^/facts-lines /'
