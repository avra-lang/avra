#!/bin/sh
# THE FLOW BENCH (ticket avra-8sb5.34.53.21): each row an Avra program
# and a Go twin, on THIS machine, the least of ROUNDS (5) printed side by
# side — Go under GOMAXPROCS=1 and under its default. Time rows are
# nanoseconds per unit; the parked rows are bytes per parked task, read
# from the process's own status (resident set, page tables).
#
#   sh tools/flow_bench/run.sh          the bench
#   sh tools/flow_bench/run.sh probes   the stack allocator's probes
#   FLOW_AVRA=0 …                       Go and the runtime's rows alone
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

# The scheduler linked under the C bench.
spawn_bench() {
    cc -c -O2 -fPIC $probes -I"$root/runtime" -o "$out/fiber_today.o" "$root/runtime/avra_fiber.c"
    cc -O2 -I"$root/runtime" -o "$out/spawn_bench_today" "$here/probes/spawn_bench.c" "$out/fiber_today.o" $rest
    cc -O2 -I"$root/runtime" -o "$out/latency_bench" "$here/probes/latency_bench.c" "$out/fiber_today.o" $rest
}

if [ "${1:-bench}" = probes ]; then
    rest=$(runtime_built)
    probes=""
    [ "$(uname -s)" = Darwin ] || probes=-fstack-clash-protection
    cc -O2 -o "$out/stacks" "$here/probes/stacks.c"
    spawn_bench
    echo "== $(uname -srm), page $(getconf PAGESIZE), vm.max_map_count $(cat /proc/sys/vm/max_map_count 2>/dev/null || echo n/a)"
    echo "== (b, c) reservation and guard, 448 bytes touched at each stack's top"
    for reserve in 1048576 262144; do
        for guard in mprotect madvise none; do
            "$out/stacks" $reserve $guard 20000 448
        done
    done
    echo "== a stack's top page: a fault at the first touch, or asked for by name first"
    for r in 1 2 3; do
        "$out/stacks" 262144 none 20000 448
        "$out/stacks" 262144 none 20000 448 populate
    done
    # A MILLION TOUCHED STACKS IS A MILLION RESIDENT PAGES: asked only where
    # the kernel has a mapping ceiling to find, and never on 16 KiB pages.
    if [ -r /proc/sys/vm/max_map_count ]; then
        echo "== (c) the ceiling: stacks asked for until the kernel refuses"
        "$out/stacks" 1048576 mprotect 1000000 448
        "$out/stacks" 262144 mprotect 1000000 448
        # as many unguarded stacks as the machine can hold touched, with room to spare
        free_kb=$(awk '/MemAvailable/ { print $2 }' /proc/meminfo)
        most=$(( (free_kb - 2500000) / 5 ))
        [ "$most" -lt 1000000 ] || most=1000000
        [ "$most" -lt 1000 ] || "$out/stacks" 262144 none "$most" 448
    fi
    echo "== the yield path: instructions in the object, and counted over ten million switches"
    # THE FRAME PROOF: a leaf's fast path saves nothing — no push, no stack
    # adjustment — before its first branch.
    for f in avra_fiber_yield avra_fiber_switch avra_wait_park avra_gate_claim avra_wait_gate avra_fiber_park_fd avra_task_slot avra_task_slot_set avra_task_id; do
        o=$out/fiber_today.o
        case $f in avra_task_*) o=$out/rt/avra_runtime.o ;; esac
        objdump -d --no-show-raw-insn "$o" 2>/dev/null | awk -v f="$f" '
            $2 ~ "<_?" f ">:" { on=1; next }
            on && /^$/ { exit }
            on && /^ / { n++; if (!branched) { if ($0 ~ /push|sub .*,%rsp|stp|sub\tsp/) frame++; if ($2 ~ /^(j|b\.|cb|tb|call|bl|ret)/ || $2 == "b") branched=1 } }
            END { printf "  %-22s %3d instructions, %d frame op(s) before the first branch\n", f, n+0, frame+0 }'
    done
    if command -v perf > /dev/null 2>&1; then
        perf stat -e instructions,cycles "$out/spawn_bench_today" today switch 2>&1 | grep -E "instructions|cycles|today_switch" || echo "  perf stat refused"
    else
        echo "  no perf on this machine"
    fi
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

# A tree with no compiler still measures the runtime's rows and Go.
programs="switch spawn spawnparked pingpong scope latency parked"
[ "${FLOW_AVRA:-1}" = 1 ] && [ -x "$root/build/avra" ] || { echo "flow-bench: no compiler asked for or found — the compiled Avra rows are not run" >&2; programs=""; }
for p in $programs; do
    "$root/build/avra" build "$here/avra/$p" > /dev/null 2> "$out/$p.build" || { cat "$out/$p.build"; exit 1; }
done
rest=$(runtime_built)
probes=""
[ "$(uname -s)" = Darwin ] || probes=-fstack-clash-protection
spawn_bench

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
    for p in $programs; do
        [ "$p" = parked ] && continue
        FLOW_ROW=$p
        ran avra "$here/avra/$p/src/main"
    done
    FLOW_ROW=spawn_bench
    ran c "$out/spawn_bench_today" c
    ran c "$out/spawn_bench_today" c parked
    ran c "$out/spawn_bench_today" c gate
    ran c "$out/spawn_bench_today" c within
    ran c "$out/latency_bench" c
    FLOW_ROW=spawn_chan
    ran go1 env GOMAXPROCS=1 FLOW_CHAN=1 "$out/go/spawn"
    ran goN env FLOW_CHAN=1 "$out/go/spawn"
    for g in switch spawn spawnparked pingpong deadline fanin selectn canceltree; do
        FLOW_ROW=$g
        ran go1 env GOMAXPROCS=1 "$out/go/$g"
        ran goN "$out/go/$g"
    done
    r=$((r + 1))
done

# Parked tasks, once each. A size runs only where the machine can hold it
# with room to spare: 8 KiB a task is asked for, more than either engine
# takes, since a machine out of memory answers nobody.
sizes="1000 30000 100000 500000 1000000"
[ -r /proc/self/status ] && [ -n "$programs" ] || { echo "flow-bench: the parked rows need /proc and the compiler — not run" >&2; sizes=""; }
for n in $sizes; do
    hold=$((2000 + n / 20))
    FLOW_ROW=parked_$n
    FLOW_SUFFIX=_$n
    free_kb=$(awk '/MemAvailable/ { print $2 }' /proc/meminfo 2>/dev/null || echo 99999999)
    if [ $((n * 8)) -gt $((free_kb - 1500000)) ]; then
        for e in avra go1 goN; do echo "$e parked_$n not run: $((free_kb / 1024)) MiB available, $((n * 8 / 1024)) MiB asked for" >> "$out/raw"; done
        continue
    fi
    ran avra env FLOW_N=$n FLOW_HOLD_MS=$hold "$here/avra/parked/src/main"
    ran go1 env FLOW_N=$n GOMAXPROCS=1 "$out/go/parked"
    ran goN env FLOW_N=$n "$out/go/parked"
done

# Where the host has no /proc, a parked task's bytes are read from outside:
# the resident set `ps` reports while the tasks stand parked, less the
# same program's with none.
held_rss() {
    "$@" > /dev/null &
    sleep 2
    kb=$(ps -o rss= -p $! 2>/dev/null | tr -d ' ')
    wait
    echo "${kb:-0}"
}
if [ ! -r /proc/self/status ]; then
    for n in 1000 30000; do
        none=$(held_rss "$out/spawn_bench_today" c hold 0 3000)
        some=$(held_rss "$out/spawn_bench_today" c hold $n 3000)
        echo "c parked_rss_$n $(((some - none) * 1024)) $n" >> "$out/raw"
        none=$(held_rss env FLOW_N=0 FLOW_HOLD_MS=3000 GOMAXPROCS=1 "$out/go/parked")
        some=$(held_rss env FLOW_N=$n FLOW_HOLD_MS=3000 GOMAXPROCS=1 "$out/go/parked")
        echo "go1 parked_rss_$n $(((some - none) * 1024)) $n" >> "$out/raw"
    done
fi

load=$(cut -d' ' -f1-3 /proc/loadavg 2>/dev/null || sysctl -n vm.loadavg)
echo "$(uname -srm), $(nproc 2>/dev/null || sysctl -n hw.ncpu) cpus, page $(getconf PAGESIZE), load $load after the runs, least of $rounds, $("$go" version)"
echo
python3 "$here/table.py" "$out/raw"
