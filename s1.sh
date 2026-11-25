#!/bin/bash
# S1 on a runner: peak_mb rows for every cost workload, then a witness that an inflated census compiler trips build-cli's row.
set -u
cd "$(git rev-parse --show-toplevel)"
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
command -v taskset >/dev/null || { apt-get install -y util-linux >/dev/null 2>&1 || true; }
curl -fsSL --retry 3 -o build/gate-builder.tar.gz https://github.com/avra-lang/avra/releases/download/gate-builder/compiler.tar.gz
sh tools/gate.sh unpack build/gate-builder.tar.gz || exit 70
make -s objects libs >/dev/null 2>&1 || true
sh tools/census_compiler.sh build/avra.census > build/census.log 2>&1 || { tail -30 build/census.log; exit 70; }
cp build/.avra-built-from build/.avra.census-built-from
part=${S1_PART:-cold-a}
COST_COMPILER=build/avra.census COST_PART="$part" COST_EDITS=${S1_EDITS:-} sh tools/cost.sh > build/cost-run.log 2>&1; st=$?
tail -8 build/cost-run.log; [ $st = 0 ] || exit 1
echo "== rows ($part)"
python3 tools/cost_ratchet.py --rows build/cost | grep -E "peak_mb|snapshot"
grep -h "^mem: peak\|^mem:   list\|^mem:   bytes\|^mem:   strings" build/cost/*.out | head -12
python3 tools/cost_ratchet.py --judge build/cost | tail -4
[ -n "${S1_WITNESS:-}" ] || exit 0
echo "== witness: a 64 MB list held to exit by the build command"
python3 tools/cost_ratchet.py --rows build/cost > build/clean.rows
cp tools/cost.baseline build/cost.baseline.orig
# the clean run's rows stand as the baseline the inflated run is judged by
python3 - <<'PY'
import re
base = open("tools/cost.baseline").read().splitlines()
rows = [l for l in open("build/clean.rows").read().splitlines() if " peak_mb " in l]
keep = [l for l in base if " peak_mb " not in l]
open("tools/cost.baseline", "w").write("\n".join(sorted(keep + rows, key=lambda l: (l.startswith("#") is False, l))) + "\n")
PY
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
echo "== judge of the inflated run (must fail on build-cli peak_mb)"
python3 tools/cost_ratchet.py --judge build/cost | grep -E "peak_mb|rows," ; echo "judge status ${PIPESTATUS[0]}"
cp build/cost.baseline.orig tools/cost.baseline
