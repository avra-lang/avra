du -sm .avra-cache 2>/dev/null | cut -f1 | sed 's/^/store-before MB /'
t0=$(date +%s)
./avra-try check --time packages/cli > zt1.out 2>&1; echo "FIRST_STATUS $? wall $(( $(date +%s) - t0 ))s"
grep -a "^time:" zt1.out
du -sm .avra-cache 2>/dev/null | cut -f1 | sed 's/^/store-after-first MB /'
t1=$(date +%s)
./avra-try check --time packages/cli > zt2.out 2>&1; echo "REPEAT_STATUS $? wall $(( $(date +%s) - t1 ))s"
grep -a "^time:" zt2.out
sed -i 's/· memo/· memo zz9/' packages/cli/src/commands/shared.av
t2=$(date +%s)
AVRA_QTRACE=1 ./avra-try check --time packages/cli > zt3.out 2> zt3.err; echo "EDIT_STATUS $? wall $(( $(date +%s) - t2 ))s"
grep -a "^time:" zt3.out
echo "--- edit queries"
grep -ac "^Q	parse" zt3.err | sed 's/^/parses /'
grep -ac "^Q	saved	no row" zt3.err | sed 's/^/saved-misses /'
grep -ac "^Q	ask	Typed" zt3.err | sed 's/^/typed-asks /'
grep -ac "^Q	settle	Typed" zt3.err | sed 's/^/typed-settles /'
grep -ac "^Q	ask	Parsed" zt3.err | sed 's/^/parsed-asks /'
grep -ac "^Q	ask	Resolved" zt3.err | sed 's/^/resolved-asks /'
grep -ac "^Q	unit	lowered" zt3.err | sed 's/^/units-lowered /'
echo "--- diagnostics"
grep -aE "^(error|warning)\[" zt3.out | sed 's/:.*//' | sort | uniq -c | sort -rn | head -5
sed -i 's/· memo zz9/· memo/' packages/cli/src/commands/shared.av
du -sm .avra-cache 2>/dev/null | cut -f1 | sed 's/^/store-after-edit MB /'
