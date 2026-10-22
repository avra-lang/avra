# inspect what the .210 run left behind
cd "$(dirname "$0")/../.." || exit 1
echo "== outputs =="
ls -la build/t210 build/t210bc 2>&1 | head -40
echo "== traces =="
for f in build/t210/cold.err build/t210bc/b1.err build/t210bc/b2.err; do
  [ -f "$f" ] && echo "$f: $(wc -c < "$f") bytes, Qparse=$(grep -c -P '^Q\tparse' "$f"), Qattempt=$(grep -c -P '^Q\tattempt' "$f")"
done
echo "== objects now =="
find . -path '*/.avra-cache/*' -name '*.o' | wc -l
echo "== b2 =="
[ -f build/t210bc/b2.out ] && head -5 build/t210bc/b2.out
[ -f build/t210bc/b2.err ] && head -5 build/t210bc/b2.err
