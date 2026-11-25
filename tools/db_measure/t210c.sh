# .210 C: the follow-up build, and the read reason the after-check build spoke.
cd "$(dirname "$0")/../.." || exit 1
echo "== follow-up build (store already holds the after-check build's objects)"
./avra build --time packages/cli > build/t210bc/b2.out 2> build/t210bc/b2.err
echo "follow-up exit $?"
grep -h "^time:" build/t210bc/b2.out build/t210bc/b2.err | tail -1
echo "== the after-check build's read reason"
echo "count 'nothing kept stands in': $(cat build/t210bc/b1.out build/t210bc/b1.err | grep -c 'nothing kept stands in')"
cat build/t210bc/b1.out build/t210bc/b1.err | grep -h 'nothing kept stands in' | head -1
echo "== store rows named missing"
cat build/t210bc/b1.out build/t210bc/b1.err | grep -h 'its object' | head -2
echo "== check's own reason (from check.err)"
head -3 build/t210bc/check.err
