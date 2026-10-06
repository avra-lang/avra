#!/bin/sh
# Prices the after-call test ON THE COMPILER ITSELF: the committed seed
# is the compiler as IR, and the compiler links a scheduler, so it pays.
# The seed is linked as `make recover` links it — plain, and rewritten
# with the test (rewrite.py) — and each compiler checks one package from
# cold, taking turns. A compiler finds its packages from where it
# stands, so each stands beside build/avra. Prints the census and each
# run's seconds.
#   WORK=packages/std-http ROUNDS=3 sh tools/flow_bench/probes/aftercall_ir/compiler.sh
#   KEEP=1 links nothing a run before it already linked.
set -u
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../../../.." && pwd)
out=$root/build/flow-bench/aftercall_ir
mkdir -p "$out/parked"
cd "$root" || exit 1
line=$(make -n recover 2> /dev/null | tr -d '\\\n' | sed -n 's/.*\(clang -w -O1 -rdynamic bootstrap\/seed.ll.*-o build\/avra\).*/\1/p' | sed 's/;.*//')
[ -n "$line" ] || { echo "no link line in \`make -n recover\`"; exit 1; }
clang -O2 -c -o "$out/probe_state.o" "$here/probe_state.c" || exit 1
python3 "$here/whiles.py" packages/std-* packages/cli | sort -u > "$out/whiles_all.txt"
for v in plain byte go; do
    python3 "$here/rewrite.py" bootstrap/seed.ll "$out/seed_$v.ll" $v "$out/whiles_all.txt" || exit 1
    t0=$(date +%s%N)
    cmd=$(echo "$line" | sed "s#bootstrap/seed.ll#$out/seed_$v.ll $out/probe_state.o#; s#-o build/avra#-lpthread -o build/avra_probe_$v#")
    [ -n "${KEEP:-}" ] && [ -x "build/avra_probe_$v" ] || sh -c "$cmd" 2> "$out/seedlink_$v.err" || { echo "$v does not link"; head -6 "$out/seedlink_$v.err"; exit 1; }
    echo "   $v: text $(size "build/avra_probe_$v" | awk 'NR == 2 { print $1 }') bytes, linked in $(( ($(date +%s%N) - t0) / 1000000 )) ms"
done
work=${WORK:-packages/std-http}
echo "== \`check $work\` from cold, seconds (wall, user)"
n=0
for round in $(seq 1 ${ROUNDS:-3}); do
    for v in plain byte go; do
        for c in $(find . -maxdepth 4 -name .avra-cache -not -path './build/*'); do n=$((n + 1)); mv "$c" "$out/parked/$$-$n"; done
        t0=$(date +%s%N)
        u0=$(awk '{ print $14 + $16 }' /proc/$$/stat)
        AVRA_MEM_CEILING_MB=5000 build/avra_probe_$v check "$work" > "$out/check_$v.out" 2>&1
        status=$?
        u1=$(awk '{ print $14 + $16 }' /proc/$$/stat)
        echo "round $round  $(printf '%-6s' $v) $(awk -v a=$t0 -v b=$(date +%s%N) 'BEGIN { printf "%.2f", (b - a) / 1e9 }') s wall  $(awk -v a=$u0 -v b=$u1 -v t=$(getconf CLK_TCK) 'BEGIN { printf "%.2f", (b - a) / t }') s user   exit $status, $(grep -c '^error' "$out/check_$v.out") errors"
    done
done
