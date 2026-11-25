P=/tmp/p6; mkdir -p $P/src
printf '[package]\nname = "p6"\nversion = "0.1.0"\n' > $P/avra.toml
cat > $P/src/main.av <<'AV'
use @std.meta.{Named}
fn shape(_t: Named, _r: int) {}
@shape(0)
type Dot = {
    state n: int = 0
}
collect enum Shape = @shape in self by it.mark.args[0]
let d = Dot { }
d.n = 4
let s = Shape.Dot(d.n + 1)
let got = match s { .Dot(x) -> x }
"${got} ${d.n}"
AV
echo "== item6 run"; ./avra run $P/src/main.av 2>&1 | grep -vE "^\s*$" | head -20
echo "== item6 build"; (cd $P && $OLDPWD/avra build src/main.av 2>&1 | tail -3; ls build 2>/dev/null; for b in build/*; do [ -x "$b" ] && [ -f "$b" ] && "$b"; done)
echo "== witness collects_test (pre-fix compiler)"
./avra test packages/std-avrac/src/features/collects/tests/collects_test.av > /tmp/w.log 2>&1; echo "exit $?"
grep -nE "tests passed|✗|FAIL|failed" /tmp/w.log | head -12
grep -nB2 -A8 "slot law" /tmp/w.log | grep -E "then|✗|FAIL|passed|failed" | head -12
