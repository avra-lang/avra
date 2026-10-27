t0=$(date +%s)
./avra-try check --time packages/cli > zt-warm.out 2>&1; echo WARM_UNCHANGED_STATUS $? wall $(( $(date +%s) - t0 ))s
grep -a "^time:" zt-warm.out
sed -i 's/· memo/· memo zz9/' packages/cli/src/commands/shared.av
t1=$(date +%s)
./avra-try check --time packages/cli > zt-edit.out 2>&1; echo EDIT_STATUS $? wall $(( $(date +%s) - t1 ))s
grep -a "^time:" zt-edit.out
sed -i 's/· memo zz9/· memo/' packages/cli/src/commands/shared.av
t2=$(date +%s)
./avra-try check --time packages/cli > zt-back.out 2>&1; echo REVERT_STATUS $? wall $(( $(date +%s) - t2 ))s
grep -a "^time:" zt-back.out
t3=$(date +%s)
./avra-try check packages/cli > /dev/null 2>&1; echo SECOND_UNCHANGED_STATUS $? wall $(( $(date +%s) - t3 ))s
