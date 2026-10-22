# .210 B/C: a check, then the build right after it, then the follow-up.
cd "$(dirname "$0")/../.." || exit 1
S=build/t210bc
mkdir -p "$S"
clear() {
  n=0
  find . -name .avra-cache -type d -prune | while read -r d; do
    n=$((n + 1))
    mv "$d" "build/aside.210bc.$1.$$.$n"
  done
}
objs() { find . -path '*/.avra-cache/*' -name '*.o' | wc -l; }
line() { grep -h "^time:" "$S/$1.out" "$S/$1.err" | tail -1; }

clear chk
./avra check --time packages/cli > "$S/check.out" 2> "$S/check.err"; echo "check exit $?"
echo "check: $(line check)"
echo "objects after check: $(objs)"

AVRA_QTRACE=1 ./avra build --time packages/cli > "$S/b1.out" 2> "$S/b1.err"; echo "build-after-check exit $?"
echo "build-after-check: $(line b1)"
echo "objects after build-after-check: $(objs)"
echo "Q parse: $(grep -c -P '^Q\tparse' "$S/b1.err")  attempt: $(grep -c -P '^Q\tattempt' "$S/b1.err") discarded: $(grep -c -P '^Q\t.*discarded' "$S/b1.err")"
echo "files read as 'nothing kept stands in': $(cat "$S/b1.out" "$S/b1.err" | grep -c 'nothing kept stands in')"
grep -h "nothing kept stands in" "$S/b1.out" "$S/b1.err" | head -1

./avra build --time packages/cli > "$S/b2.out" 2> "$S/b2.err"; echo "follow-up build exit $?"
echo "follow-up: $(line b2)"
