# .210: a build right after a check re-parses and re-analyses every file.
# Cold build, then check -> build, then a follow-up build. Real phases + QTRACE.
cd "$(dirname "$0")/../.." || exit 1
S=build/t210
mkdir -p "$S"
clear() {
  n=0
  find . -name .avra-cache -type d -prune | while read -r d; do
    n=$((n + 1))
    mv "$d" "build/aside.210.$1.$$.$n"
  done
}
store() { find . -path '*/.avra-cache/*' -name '*.o' | wc -l; }
line() { grep -h "^time:" "$S/$1.out" "$S/$1.err" | tail -1; }
held() { grep -h "held" "$S/$1.out" "$S/$1.err" | tail -1; }

echo "=== A: cold build (reference)"
clear cold
AVRA_QTRACE=1 ./avra build --time packages/cli > "$S/cold.out" 2> "$S/cold.err"; echo "exit $?"
line cold
held cold
echo "objects after: $(store)"
echo "Q parse: $(grep -c -P '^Q\tparse' "$S/cold.err")  attempt: $(grep -c -P '^Q\tattempt' "$S/cold.err")"

echo "=== B: check, then build"
clear chk
./avra check --time packages/cli > "$S/check.out" 2> "$S/check.err"; echo "check exit $?"
line check
echo "objects after check: $(store)"
AVRA_QTRACE=1 ./avra build --time packages/cli > "$S/b1.out" 2> "$S/b1.err"; echo "build-after-check exit $?"
line b1
held b1
echo "objects after build-after-check: $(store)"
echo "Q parse: $(grep -c -P '^Q\tparse' "$S/b1.err")  attempt: $(grep -c -P '^Q\tattempt' "$S/b1.err")"
echo "files read as 'nothing kept stands in': $(cat "$S/b1.out" "$S/b1.err" | grep -c 'nothing kept stands in')"
grep -h "nothing kept stands in" "$S/b1.out" "$S/b1.err" | head -1

echo "=== C: follow-up build"
AVRA_QTRACE=1 ./avra build --time packages/cli > "$S/b2.out" 2> "$S/b2.err"; echo "build2 exit $?"
line b2
held b2
echo "Q parse: $(grep -c -P '^Q\tparse' "$S/b2.err")  attempt: $(grep -c -P '^Q\tattempt' "$S/b2.err")"
echo "=== check phase"
grep -h "^time:" "$S/check.out" "$S/check.err" | tail -1
