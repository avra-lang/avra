set -x
find .avra-cache -mindepth 1 -delete 2>/dev/null; true
make -s try > zz-try.out 2>&1; echo try $?
tail -6 zz-try.out
find .avra-cache -mindepth 1 -delete 2>/dev/null; true
./avra-try check packages/cli > /dev/null 2>&1; echo cold $?
./avra-try check packages/cli > /dev/null 2>&1; echo warm $?
sed -i 's/· memo/· memo zz9/' packages/cli/src/commands/shared.av
./avra-try check --time packages/cli > zz-c.out 2> zz-c.txt; echo edit $?
sed -i 's/· memo zz9/· memo/' packages/cli/src/commands/shared.av
grep -aE "^(error|warning)\[" zz-c.out | sed "s/:.*//" | sort | uniq -c | sort -rn | head -6
grep -a "error\[" zz-c.out | head -3 | cut -c1-260
grep -aE "^(time:|read:)" zz-c.txt zz-c.out 2>/dev/null | head -5
