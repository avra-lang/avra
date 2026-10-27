set -x
find .avra-cache -mindepth 1 -delete 2>/dev/null; true
make -s try > zz-try.out 2>&1; echo TRY $?
tail -4 zz-try.out
find .avra-cache -mindepth 1 -delete 2>/dev/null; true
./avra-try check packages/cli >/dev/null 2>&1; echo COLD $?
./avra-try check packages/cli >/dev/null 2>&1; echo WARM $?
sed -i 's/· memo/· memo zz9/' packages/cli/src/commands/shared.av
AVRA_QTRACE=1 ./avra-try check --time packages/cli > zz-c.out 2> zz-c.txt; echo EDIT $?
sed -i 's/· memo zz9/· memo/' packages/cli/src/commands/shared.av
echo "=== defects"
grep -aE "^(error|warning)\[" zz-c.out | sed 's/:.*//' | sort | uniq -c | sort -rn | head -6
echo "=== sig reseat"
grep -ac "sig reseat" zz-c.txt
grep -a "sig reseat" zz-c.txt | head -8 | cut -c1-140
echo "=== record parts absent"
grep -ac "record parts absent" zz-c.txt
grep -a "record parts absent" zz-c.txt | head -8 | cut -c1-140
echo "=== named_type_fail"
grep -ac "named_type_fail" zz-c.txt
grep -a "named_type_fail" zz-c.txt | awk -F'\t' '{print $3}' | sort | uniq -c | sort -rn | head -8
echo "=== time"
grep -aE "^time:" zz-c.out zz-c.txt 2>/dev/null | head -3
