t0=$(date +%s)
./avra-try build packages/cli > b.out 2>&1; echo "BUILD $? $(( $(date +%s) - t0 ))s"
tail -3 b.out | cut -c1-160
if [ -f packages/cli/src/main ]; then cp packages/cli/src/main build/avra-new; echo "WROTE build/avra-new"; fi
F=packages/std-text/src/text.av
./build/avra-new check packages/std-text > s1.out 2>&1; echo "COLD $?"
sed -i '1i // zzprobe' $F
AVRA_QTRACE=1 ./build/avra-new check --time packages/std-text > s2.out 2> s2.err; echo "EDIT $?"
sed -i '1d' $F
grep -a '^time:' s2.out s2.err 2>/dev/null | cut -c1-200
grep -a 'PROBE' s2.out s2.err 2>/dev/null | tail -3
grep -a '^Q	facts' s2.err | awk -F'\t' '{print $3,$4}' | sort | uniq -c | sort -rn | head -6
grep -ac '^Q	parse' s2.err | sed 's/^/parses /'
