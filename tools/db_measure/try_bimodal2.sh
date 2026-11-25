# The edit loop's order: a leaf edit, check, build, then two leaf `make try` runs; each build's own time line kept.
cd "$(dirname "$0")/../.."
LEAF=packages/cli/src/commands/shared.av
S=build/bimodal2
mkdir -p $S
cp $LEAF $S/leaf.orig
edit() {
  python3 - $LEAF $S/leaf.orig "$(date +%s%N)" <<'PY'
import sys
dest, orig, stamp = sys.argv[1:4]
text = open(orig, encoding="utf-8").read()
assert text.count("· memo") == 1
open(dest, "w", encoding="utf-8").write(text.replace("· memo", "· memo " + stamp, 1))
PY
}
edit
./avra check --time packages/cli > $S/check.out 2>&1; echo "check exit $?"
edit
./avra build --time packages/cli > $S/build.out 2>&1; echo "build exit $?"
for i in 1 2; do
  edit
  s=$(date +%s%N)
  AVRA_QTRACE=1 make try > $S/try$i.out 2>&1; st=$?
  e=$(date +%s%N)
  echo "make try run $i exit $st ms $(( (e - s) / 1000000 ))"
  grep -h "^time:" build/avra-try-build.out | tail -n 1 | cut -c1-400
  echo "  attempts in build log: $(grep -c -P '^Q\tattempt' build/avra-try-build.out)"
  cp build/avra-try-build.out $S/try$i.log
done
cp $S/leaf.orig $LEAF && cmp -s $S/leaf.orig $LEAF && echo "restored $LEAF"
