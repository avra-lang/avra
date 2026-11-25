#!/bin/bash
# S1 rows on this tree: its compiler at generation 2, the census compiler, every part but the ledger's,
# judged then accepted; then a witness that a 64 MB list held by the build command trips build-cli's peak_mb.
set -u
cd "$(git rev-parse --show-toplevel)"
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
curl -fsSL --retry 3 -o build/gate-builder.tar.gz https://github.com/avra-lang/avra/releases/download/gate-builder/compiler.tar.gz
tar xzf build/gate-builder.tar.gz build/avra build/.avra-built-from
make -s objects libs >/dev/null 2>&1 || true
for gen in 1 2; do
    find .avra-cache packages/cli/.avra-cache -mindepth 1 -delete 2>/dev/null
    make avra > build/gen$gen.log 2>&1 || { tail -30 build/gen$gen.log; exit 70; }
    cat build/.avra-built-from
done
sh tools/census_compiler.sh build/avra.census > build/census.log 2>&1 || { tail -30 build/census.log; exit 70; }
cp build/.avra-built-from build/.avra.census-built-from
COST_COMPILER=build/avra.census COST_PART="warm cold-a cold-b laid" sh tools/cost.sh > build/cost-run.log 2>&1 || { tail -20 build/cost-run.log; exit 1; }
grep -E "^cost: " build/cost-run.log | tail -12
echo "== judge"
python3 tools/cost_ratchet.py --judge build/cost | grep -vE "^candidate" | tail -12
echo "== accept"
python3 tools/cost_ratchet.py --accept build/cost | tail -3
git diff -U0 tools/cost.baseline | grep -E "^[-+][a-z]"
cp tools/cost.baseline build/cost.baseline.accepted
echo "== witness: a 64 MB list held to exit by the build command"
cp packages/cli/src/commands/build.av build/build.av.orig
python3 - <<'PY'
p = "packages/cli/src/commands/build.av"
t = open(p).read()
t = t.replace("    fn run(args: CliResult) -> int {\n", "    fn run(args: CliResult) -> int {\n        ballast().set([i for i in 0..8000000])\n", 1)
t += "\nonce fn ballast() -> Cell<List<int>> { Cell.new([]) }\n"
open(p, "w").write(t)
PY
sh tools/census_compiler.sh build/avra.census > build/census2.log 2>&1 || { tail -30 build/census2.log; exit 70; }
cp build/build.av.orig packages/cli/src/commands/build.av
make -s build/libavra_runtime.a >/dev/null 2>&1 || true
COST_COMPILER=build/avra.census COST_PART=cold-a sh tools/cost.sh > build/cost-run2.log 2>&1 || { tail -8 build/cost-run2.log; exit 1; }
grep -h "^mem: peak" build/cost/build-cli.out
python3 tools/cost_ratchet.py --judge build/cost | grep -E "peak_mb|rows,"; echo "witness judge status ${PIPESTATUS[0]} (1 = the row tripped)"
echo "== the accepted baseline rows (new)"
grep -E " (peak_mb|decoded) " build/cost.baseline.accepted
