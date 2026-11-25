# The make-try regression, reproduced: a cold warm-up build+check of the cli,
# then one leaf and one core `make try`, each timed with the build's own `time:` line.
cd "$(dirname "$0")/../.."
export LLVM_PREFIX=/opt/homebrew/opt/llvm
LEAF=packages/cli/src/commands/shared.av
CORE=packages/std-avrac/src/core/side_table.av
S=build/t257
mkdir -p $S
cp $LEAF $S/leaf.orig
cp $CORE $S/core.orig
t0=$(date +%s%N)
./avra build packages/cli > $S/cold.out 2>&1; st=$?
echo "cold build exit $st ms $(( ($(date +%s%N)-t0)/1000000 ))"
t0=$(date +%s%N)
./avra check packages/cli > $S/coldcheck.out 2>&1; st=$?
echo "cold check exit $st ms $(( ($(date +%s%N)-t0)/1000000 ))"
python3 -c "
text=open('$S/leaf.orig',encoding='utf-8').read()
assert text.count('· memo')==1
open('$LEAF','w',encoding='utf-8').write(text.replace('· memo','· memo leaf',1))
"
t0=$(date +%s%N); make try > $S/leaf.out 2>&1; st=$?; t1=$(date +%s%N)
echo "make try LEAF exit $st wall_ms $(( (t1-t0)/1000000 ))"
grep -h '^time:' build/avra-try-build.out | tail -1 | cut -c1-260
cp $S/leaf.orig $LEAF
python3 -c "
text=open('$S/core.orig',encoding='utf-8').read()
assert text.count('holds [')==1
open('$CORE','w',encoding='utf-8').write(text.replace('holds [','holds [core ',1))
"
t0=$(date +%s%N); make try > $S/core.out 2>&1; st=$?; t1=$(date +%s%N)
echo "make try CORE exit $st wall_ms $(( (t1-t0)/1000000 ))"
grep -h '^time:' build/avra-try-build.out | tail -1 | cut -c1-260
cp $S/core.orig $CORE
cmp -s $S/leaf.orig $LEAF && cmp -s $S/core.orig $CORE && echo "restored both"
