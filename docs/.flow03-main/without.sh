# the stop test and the TLS interrupt test, with Drain's `!stopped(e)` and without it
set -e
F=packages/std-http/src/server.av
for t in packages/std-http/src/tests/http_stop_zero packages/std-tls/src/tests/parked_tls_interrupt; do
  build/avra test $t > build/t.out 2>&1 && echo "with: $t passes" || { echo "with: $t FAILS"; grep -E "differ|expected|got|✗" build/t.out | head -4; }
done
cp $F build/server.av.keep
python3 - <<'PY'
p='packages/std-http/src/server.av'; t=open(p).read()
a="if !stopped(e) && !self.drain.running()"
assert t.count(a)==1
open(p,'w').write(t.replace(a,"if !self.drain.running()"))
PY
build/avra test packages/std-http/src/tests/http_stop_zero > build/t.out 2>&1 && echo "without: stop test passes" || { echo "without: stop test FAILS"; grep -vE "^\s*$" build/t.out | grep -E "differ|expected|got|answered|eval|native" | head -6; }
cp build/server.av.keep $F
