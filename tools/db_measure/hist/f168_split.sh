#!/bin/sh
# avra-8sb5.57.168 second half: attribute the merged word-sized SideTable
# site. Builds a throwaway compiler carrying F168 eprintln probes in
# new_type_facts / new_name_facts / new_body_regs, runs one cold
# `check packages/cli`, and sums the cells each family allocates.
set -u
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
out=build/f168
mkdir -p "$out"
make try > "$out/probe-build.log" 2>&1 || { echo "BUILD FAILED"; tail -n 30 "$out/probe-build.log"; exit 1; }
echo "probe compiler built"
build/avra-try check packages/cli > /dev/null 2> "$out/probe.err"
echo "check exit=$? stderr lines=$(wc -l < "$out/probe.err")"
python3 - "$out/probe.err" <<'PY'
import sys, re
tot = {'t': 0, 'tn': 0, 'n': 0, 'nn': 0, 'be': 0, 'bs': 0, 'bp': 0, 'bn': 0}
for line in open(sys.argv[1], errors='replace'):
    if 'F168' not in line:
        continue
    m = re.match(r'F168 type_facts stmts=(\d+) exprs=(\d+)', line)
    if m:
        tot['t'] += int(m.group(1)); tot['tn'] += 1; continue
    m = re.match(r'F168 name_facts exprs=(\d+)', line)
    if m:
        tot['n'] += int(m.group(1)); tot['nn'] += 1; continue
    m = re.match(r'F168 body_regs exprs=(\d+) stmts=(\d+) pats=(\d+)', line)
    if m:
        tot['be'] += int(m.group(1)); tot['bs'] += int(m.group(2)); tot['bp'] += int(m.group(3)); tot['bn'] += 1
print(f"type_facts  calls={tot['tn']:7d} sum_stmts={tot['t']:12d} -> 3 stmt cols {3*tot['t']*8/1e6:8.1f} MB cells")
print(f"name_facts  calls={tot['nn']:7d} sum_exprs={tot['n']:12d} -> 5 cols      {5*tot['n']*8/1e6:8.1f} MB cells")
print(f"body_regs   calls={tot['bn']:7d} sumE={tot['be']} sumS={tot['bs']} sumP={tot['bp']}")
print(f"body_regs cells={2*tot['be']+3*tot['bs']+tot['bp']} -> {(2*tot['be']+3*tot['bs']+tot['bp'])*8/1e6:.1f} MB cells (transient)")
PY
