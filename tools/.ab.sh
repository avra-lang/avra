export LLVM_PREFIX=/usr/lib/llvm-22
find . -name .avra-cache -type d -prune -exec rm -rf {} + 2>/dev/null
for g in 1 2; do make avra > /tmp/ab_$g.log 2>&1 || { echo "gen$g FAILED"; grep -E "status|avra:|^error" /tmp/ab_$g.log | head -4; exit 1; }; echo "gen$g ok"; done
make -o avra libs >/dev/null 2>&1
for r in cold warm; do build/avra test packages/cli > /tmp/ab_$r.log 2>&1; echo "cli $r=$? defects=$(grep -ciE 'defect|out of mint order|nameless receiver' /tmp/ab_$r.log) $(grep 'tests passed' /tmp/ab_$r.log | tail -1)"; done
grep -iE "defect" /tmp/ab_warm.log | sort | uniq -c | sort -rn | head -3
