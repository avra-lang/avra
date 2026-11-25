# .210 probe: is the object a check "could write" already computed?
cd "$(dirname "$0")/../.." || exit 1
D=/tmp/t210pkg.$$
mkdir -p "$D/src"
printf '[package]\nname = "t210pkg"\nversion = "0.1.0"\n' > "$D/avra.toml"
printf 'fn add(a: int, b: int) -> int { a + b }\nprintln("${add(1, 2)}")\n' > "$D/src/main.av"
fams() { ls "$D/.avra-cache"/*/ 2>/dev/null | sort -u | tr '\n' ' '; }
objs() { find "$D/.avra-cache" -name '*.o' 2>/dev/null | wc -l; }

echo "== check (cold)"
AVRA_QTRACE=1 ./avra check --time "$D" > "$D/chk.out" 2> "$D/chk.err"; echo "exit $?"
grep -h "^time:" "$D/chk.out" "$D/chk.err" | tail -1
echo "objects: $(objs)  families: $(fams)"
echo "unit rows: $(find "$D/.avra-cache" -path '*/unit/*' -type f -name '*[!s]' 2>/dev/null | wc -l)  Qparse: $(grep -c -P '^Q\tparse' "$D/chk.err")"

echo "== build right after the check"
AVRA_QTRACE=1 ./avra build --time "$D" > "$D/b1.out" 2> "$D/b1.err"; echo "exit $?"
grep -h "^time:" "$D/b1.out" "$D/b1.err" | tail -1
echo "objects: $(objs)  Qparse: $(grep -c -P '^Q\tparse' "$D/b1.err")"

echo "== check again after the build"
AVRA_QTRACE=1 ./avra check --time "$D" > "$D/chk2.out" 2> "$D/chk2.err"; echo "exit $?"
grep -h "^time:" "$D/chk2.out" "$D/chk2.err" | tail -1
echo "objects: $(objs)  Qparse: $(grep -c -P '^Q\tparse' "$D/chk2.err")"
echo "D=$D"
