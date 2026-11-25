# refresh the seed from this tree, prove it, and print it back
set -e
P=/tmp/flow03-seedprobe
mkdir -p $P/ok $P/bad
printf 'extern fn avra_fiber_interrupted() -> int\n\nlet n = avra_fiber_interrupted()\n"${n}"\n' > $P/ok/probe.av
printf 'extern fn avra_fiber_interrupted() -> int\n\nlet n: string = avra_fiber_interrupted()\n"${n}"\n' > $P/bad/probe.av
probe() {
  echo "== $1 check"; build/avra check $P/ok/probe.av > $P/ok.log 2>&1 && echo "check exit 0" || { echo "check exit $?"; grep -E "error|refus" $P/ok.log | head -3; }
  build/avra check $P/bad/probe.av > $P/bad.log 2>&1 || true; echo "control errors: $(grep -c '^error' $P/bad.log)"
  build/avra run $P/ok/probe.av 2>&1 | tail -1
}
cp bootstrap/seed.ll build/seed.old.ll
make recover > /dev/null; probe old-seed
git -C . status >/dev/null 2>&1 || true
make avra > /dev/null 2>&1; make avra > /dev/null 2>&1
echo "== emit"; make seed
grep -c avra_fiber_interrupted bootstrap/seed.ll | sed 's/^/rows named in the seed: /'
grep -c avra_fiber_interrupted build/seed.old.ll | sed 's/^/rows named in the old seed: /' || true
make recover > /dev/null; probe new-seed
echo "== bootstrap"; make bootstrap > build/boot.out 2>&1; echo "bootstrap $?"; tail -1 build/boot.out
echo "== seed-check"; make seed-check 2>&1 | tail -2
sha256sum bootstrap/seed.ll bootstrap/seed.sources
echo "BEGIN-SEED"; gzip -9 -c bootstrap/seed.ll | base64 -w 0; echo; echo "END-SEED"
echo "BEGIN-SOURCES"; cat bootstrap/seed.sources; echo "END-SOURCES"
