# Four leaf-edit `make try` runs under AVRA_QTRACE: wall time, attempt lines, and the build's time line for each.
cd "$(dirname "$0")/../.."
LEAF=packages/cli/src/commands/shared.av
S=build/bimodal
mkdir -p $S
cp $LEAF $S/leaf.orig
for i in 1 2 3 4; do
  python3 - $LEAF $S/leaf.orig "$(date +%s%N)" <<'PY'
import sys
dest, orig, stamp = sys.argv[1:4]
text = open(orig, encoding="utf-8").read()
assert text.count("· memo") == 1
open(dest, "w", encoding="utf-8").write(text.replace("· memo", "· memo " + stamp, 1))
PY
  s=$(date +%s%N)
  AVRA_QTRACE=1 make try > $S/try$i.out 2>&1; st=$?
  e=$(date +%s%N)
  echo "run $i exit $st ms $(( (e - s) / 1000000 ))"
  echo "  attempts: $(grep -c -P '^Q\tattempt' $S/try$i.out) $(grep -P '^Q\tattempt' $S/try$i.out | tail -n 1 | cut -c1-120)"
  grep -h "^time:" $S/try$i.out | tail -n 1 | cut -c1-400
  grep -o "held [0-9]*/[0-9]*" $S/try$i.out | head -n 1
done
cp $S/leaf.orig $LEAF && cmp -s $S/leaf.orig $LEAF && echo "restored $LEAF"
