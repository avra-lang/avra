t0=$(date +%s)
sed -i 's/· memo/· memo zz9/' packages/cli/src/commands/shared.av
AVRA_QTRACE=1 ./avra-try check --time packages/cli > e.out 2> e.err
echo "EDIT_STATUS $? wall $(( $(date +%s) - t0 ))s"
sed -i 's/· memo zz9/· memo/' packages/cli/src/commands/shared.av
grep -a "^time:" e.out | cut -c1-300
grep -a "KEEPPROBE\|LOWERPROBE" e.err
grep -ac "^Q	parse" e.err | sed 's/^/parses /'
grep -ac "^Q	settle	Typed" e.err | sed 's/^/typed-settles /'
