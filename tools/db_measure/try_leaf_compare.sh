# Yesterday's receipt edit (a comment appended to rules.av) and my baseline edit (a literal in shared.av), each under make try.
cd "$(dirname "$0")/../.."
R=packages/cli/src/commands/rules.av
L=packages/cli/src/commands/shared.av
mkdir -p build/tlc
cp $R build/tlc/rules.orig; cp $L build/tlc/shared.orig
make -s try >/dev/null 2>&1; echo "warm-up try exit $?"
for i in 1 2; do
  cp build/tlc/rules.orig $R; printf '\n// one leaf edit %s\n' "$(date +%s%N)" >> $R
  t0=$(date +%s%N); make -s try > /dev/null 2>&1; st=$?; t1=$(date +%s%N)
  echo "comment-edit try $i exit $st ms $(( (t1-t0)/1000000 )) | $(grep -h '^time:' build/avra-try-build.out | tail -n 1 | cut -c1-260)"
done
cp build/tlc/rules.orig $R
for i in 1 2; do
  python3 - $L build/tlc/shared.orig "$(date +%s%N)" <<'PY'
import sys
dest, orig, stamp = sys.argv[1:4]
text = open(orig, encoding="utf-8").read()
assert text.count("· memo") == 1
open(dest, "w", encoding="utf-8").write(text.replace("· memo", "· memo " + stamp, 1))
PY
  t0=$(date +%s%N); make -s try > /dev/null 2>&1; st=$?; t1=$(date +%s%N)
  echo "literal-edit try $i exit $st ms $(( (t1-t0)/1000000 )) | $(grep -h '^time:' build/avra-try-build.out | tail -n 1 | cut -c1-260)"
done
cp build/tlc/shared.orig $L
cmp -s build/tlc/rules.orig $R && cmp -s build/tlc/shared.orig $L && echo "restored both"
