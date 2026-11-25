export LLVM_PREFIX=/opt/homebrew/opt/llvm
F=packages/cli/src/commands/shared.av
t0=$(date +%s); ./build/avra check packages/cli > /dev/null 2>&1; echo "WARM $? $(( $(date +%s) - t0 ))s"
timeout 20 python3 -c "p='$F'; s=open(p).read(); open(p,'w').write(s.replace('memo','memo zz9',1))"
t1=$(date +%s); ./build/avra check --time packages/cli > mt.out 2> mt.err; echo "EDIT $? wall $(( $(date +%s) - t1 ))s"
timeout 20 python3 -c "p='$F'; s=open(p).read(); open(p,'w').write(s.replace('memo zz9','memo',1))"
grep -a 'time:' mt.out mt.err 2>/dev/null | head -1 | cut -c1-260
