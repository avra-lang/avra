set -x
rm -rf .avra-cache
make -s try > zz-try.out 2>&1; echo TRY $?
tail -3 zz-try.out
rm -rf .avra-cache
./avra-try check --time packages/cli > zz-cold.out 2>&1; echo COLD $?
grep -aE "^time:" zz-cold.out | head -1
sed -i 's/· memo/· memo zz9/' packages/cli/src/commands/shared.av
./avra-try check --time packages/cli > zz-c.out 2> zz-c.txt; echo EDIT $?
sed -i 's/· memo zz9/· memo/' packages/cli/src/commands/shared.av
grep -aE "^time:" zz-c.out zz-c.txt 2>/dev/null | head -1
echo "=== diagnostics"
grep -aE "^(error|warning)\[" zz-c.out | sed 's/:.*//' | sort | uniq -c | sort -rn | head -8
grep -a "error\[" zz-c.out | head -3 | cut -c1-180
