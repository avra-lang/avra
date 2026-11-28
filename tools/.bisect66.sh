set -u
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
git fetch -q origin +refs/heads/program:refs/remotes/origin/program +refs/heads/gate/lane-train66-3ad31785:refs/remotes/origin/gate/lane-train66-3ad31785 2> /dev/null
git fetch -q --deepen=200 origin 2> /dev/null || :
good=$(git merge-base origin/program origin/gate/lane-train66-3ad31785)
bad=$(git rev-parse origin/gate/lane-train66-3ad31785)
echo "BISECT good $good bad $bad"
cp -p build/avra build/avra.standing
cat > /tmp/step.sh <<'S'
set -u
c=$(git rev-parse --short HEAD)
cp -p build/avra.standing build/avra
if ! make try > /tmp/try-$c.log 2>&1; then echo "STEP $c: did not build (skip)"; tail -3 /tmp/try-$c.log; exit 125; fi
out=$(./avra-try test packages/std-avrac/src/compiler/tests/packages_test.av 2>&1)
said=$(printf '%s\n' "$out" | grep -E 'tests passed' | tail -1)
if printf '%s\n' "$out" | grep -q '✗'; then echo "STEP $c: BAD — $said"; printf '%s\n' "$out" | grep '✗' | head -3; exit 1; fi
echo "STEP $c: good — $said"; exit 0
S
git bisect start "$bad" "$good" > /dev/null
git bisect run sh /tmp/step.sh 2>&1 | grep -E '^STEP|is the first bad commit|^commit |^Author|^    [a-z]' | head -40
git bisect log | tail -3
git bisect reset > /dev/null 2>&1
