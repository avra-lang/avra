#!/bin/sh
# THE FLOW BENCH (ticket avra-8sb5.34.53.21): each row an Avra program
# and a Go twin, on THIS machine, the least of ROUNDS (5) printed side by
# side — Go under GOMAXPROCS=1 and under its default. Time rows are
# nanoseconds per unit; the parked rows are bytes per parked task, read
# from the process's own status (resident set, page tables).
#
#   sh tools/flow_bench/run.sh          the bench
#   sh tools/flow_bench/run.sh probes   the stack allocator's probes
set -eu
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../.." && pwd)
out=$root/build/flow-bench
rounds=${ROUNDS:-5}
mkdir -p "$out/go" "$out/rt"

# The runtime's objects, built as the Makefile builds them, the scheduler
# apart so a probe can stand a patched copy in its place.
runtime_built() {
    probes=""
    [ "$(uname -s)" = Darwin ] || probes=-fstack-clash-protection
    rest=""
    for c in "$root"/runtime/*.c; do
        o=$out/rt/$(basename "$c" .c).o
        cc -c -O2 -fPIC $probes -I"$root/runtime" -o "$o" "$c"
        [ "$(basename "$c")" = avra_fiber.c ] || rest="$rest $o"
    done
    echo "$rest"
}

# A scheduler variant `$1` (today|full|prefix) linked under the C bench.
spawn_bench() {
    case $1 in
        today) src=$root/runtime/avra_fiber.c ;;
        *) src=$out/fiber_$1.c; python3 "$here/probes/head.py" "$root/runtime/avra_fiber.c" "$1" "$src" ;;
    esac
    cc -c -O2 -fPIC $probes -I"$root/runtime" -o "$out/fiber_$1.o" "$src"
    cc -O2 -I"$root/runtime" -o "$out/spawn_bench_$1" "$here/probes/spawn_bench.c" "$out/fiber_$1.o" $rest
}

if [ "${1:-bench}" = probes ]; then
    rest=$(runtime_built)
    probes=""
    [ "$(uname -s)" = Darwin ] || probes=-fstack-clash-protection
    cc -O2 -o "$out/stacks" "$here/probes/stacks.c"
    echo "== $(uname -srm), page $(getconf PAGESIZE), vm.max_map_count $(cat /proc/sys/vm/max_map_count 2>/dev/null || echo n/a)"
    echo "== (b, c) reservation and guard, 448 bytes touched at each stack's top"
    for reserve in 1048576 262144; do
        for guard in mprotect madvise none; do
            "$out/stacks" $reserve $guard 20000 448
        done
    done
    echo "== (c) the ceiling: stacks asked for until the kernel refuses"
    "$out/stacks" 1048576 mprotect 1000000 448
    "$out/stacks" 262144 mprotect 1000000 448
    "$out/stacks" 262144 none 1000000 448
    echo "== (a) the fiber's record at 392 bytes: zeroed whole at spawn, or its live prefix alone"
    for v in today full prefix; do
        spawn_bench $v
        for r in 1 2 3; do "$out/spawn_bench_$v" "$v"; done | sort | awk '{ k=$1; v=$2/$3; if (!(k in best) || v < best[k]) best[k]=v } END { for (k in best) printf "  %-28s %.1f ns\n", k, best[k] }' | sort
    done
    echo "== (b) the same rows, today's scheduler, a 256 KiB reservation"
    for r in 1 2 3; do AVRA_FIBER_STACK=262144 "$out/spawn_bench_today" today256k; done | awk '{ k=$1; v=$2/$3; if (!(k in best) || v < best[k]) best[k]=v } END { for (k in best) printf "  %-28s %.1f ns\n", k, best[k] }' | sort
    exit 0
fi

# Go: the PATH's, the Sprite's, or one fetched into the build directory.
go=$(command -v go || true)
[ -n "$go" ] || { [ -x /.sprite/bin/go ] && go=/.sprite/bin/go; } || true
if [ -z "$go" ]; then
    arch=$(uname -m | sed 's/x86_64/amd64/; s/aarch64/arm64/')
    os=$(uname -s | tr A-Z a-z)
    echo "flow-bench: no go on this machine — fetching one into $out/toolchain" >&2
    mkdir -p "$out/toolchain"
    curl -fsSL "https://go.dev/dl/go1.25.1.$os-$arch.tar.gz" | tar -xz -C "$out/toolchain"
    go=$out/toolchain/go/bin/go
fi
(cd "$here/go" && GOFLAGS=-buildvcs=false "$go" build -o "$out/go/" ./...)

programs="switch spawn pingpong scope parked"
for p in $programs; do
    "$root/build/avra" build "$here/avra/$p" > /dev/null 2> "$out/$p.build" || { cat "$out/$p.build"; exit 1; }
done
rest=$(runtime_built)
probes=""
[ "$(uname -s)" = Darwin ] || probes=-fstack-clash-protection
spawn_bench today

: > "$out/raw"
# One run of `$2…` under engine `$1`, each row's key wearing `$FLOW_SUFFIX`;
# a run that dies leaves its last words as the row `$FLOW_ROW`.
ran() {
    engine=$1
    shift
    if "$@" > "$out/one" 2> "$out/err"; then
        sed "s/^\([a-z_0-9]*\)/$engine \1${FLOW_SUFFIX:-}/" "$out/one" >> "$out/raw"
    else
        echo "$engine $FLOW_ROW exit $?: $(tail -1 "$out/err" | cut -c1-120)" >> "$out/raw"
    fi
}

r=1
while [ "$r" -le "$rounds" ]; do
    FLOW_SUFFIX=""
    for p in switch spawn pingpong scope; do FLOW_ROW=$p; ran avra "$here/avra/$p/src/main"; done
    FLOW_ROW=spawn_bench
    ran c "$out/spawn_bench_today" c
    for g in switch spawn pingpong deadline fanin selectn canceltree; do
        FLOW_ROW=$g
        ran go1 env GOMAXPROCS=1 "$out/go/$g"
        ran goN "$out/go/$g"
    done
    r=$((r + 1))
done

# Parked tasks, once each: 1k, 100k and 1M, the last only where the
# machine has the memory to hold Go's.
free_kb=$(awk '/MemAvailable/ { print $2 }' /proc/meminfo 2>/dev/null || echo 99999999)
for n in 1000 30000 100000 1000000; do
    hold=$((2000 + n / 20))
    FLOW_ROW=parked_$n
    FLOW_SUFFIX=_$n
    ran avra env FLOW_N=$n FLOW_HOLD_MS=$hold "$here/avra/parked/src/main"
    if [ "$n" -ge 1000000 ] && [ "$free_kb" -lt 5000000 ]; then
        echo "go1 parked_$n skipped: $((free_kb / 1024)) MiB available" >> "$out/raw"
        continue
    fi
    ran go1 env FLOW_N=$n GOMAXPROCS=1 "$out/go/parked"
    ran goN env FLOW_N=$n "$out/go/parked"
done

load=$(cut -d' ' -f1-3 /proc/loadavg 2>/dev/null || sysctl -n vm.loadavg)
echo "$(uname -srm), $(nproc 2>/dev/null || sysctl -n hw.ncpu) cpus, page $(getconf PAGESIZE), load $load after the runs, least of $rounds, $("$go" version)"
echo
python3 "$here/table.py" "$out/raw"
