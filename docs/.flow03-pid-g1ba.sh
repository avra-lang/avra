#!/bin/sh
# Apples-to-apples before/after for the tick's cached pid: the SAME tree,
# the tick source swapped between the pre-fix file and this branch's, on
# one machine. C rows (runtime alone) and the Avra G1 rows beside Go.
set -eu
here=$(cd "$(dirname "$0")/../tools/flow_bench" && pwd)
root=$(cd "$here/../.." && pwd)
out=$root/build/flow-bench-pid; mkdir -p "$out"
rounds=${ROUNDS:-5}
avra=$root/build/avra
tick=$root/runtime/host/avra_tick.c

go=$(command -v go || true)
[ -n "$go" ] || { [ -x /.sprite/bin/go ] && go=/.sprite/bin/go; } || true
[ -n "$go" ] || { echo "no go"; exit 2; }
(cd "$here/go" && GOFLAGS=-buildvcs=false "$go" build -o "$out/go-spawn" ./spawn \
    && GOFLAGS=-buildvcs=false "$go" build -o "$out/go-pingpong" ./pingpong)

probes=""
[ "$(uname -s)" = Darwin ] || probes=-fstack-clash-protection
build_c() {
    rest=""
    for c in "$root"/runtime/*.c; do
        o=$out/$(basename "$c" .c).o
        cc -c -O2 -fPIC $probes -I"$root/runtime" -o "$o" "$c"
        [ "$(basename "$c")" = avra_fiber.c ] || rest="$rest $o"
    done
    cc -c -O2 -fPIC $probes -I"$root/runtime" -o "$out/avra_tick.o" "$root/runtime/host/avra_tick.c"
    rest="$rest $out/avra_tick.o"
    cc -c -O2 -fPIC $probes -I"$root/runtime" -o "$out/fiber_today.o" "$root/runtime/avra_fiber.c"
    cc -O2 -I"$root/runtime" -o "$out/spawn_bench_today" "$here/probes/spawn_bench.c" "$out/fiber_today.o" $rest
}
take() { grep "^$2 " "$1" | sed "s/^/$3 /"; }

: > "$out/go.raw"
r=1
while [ "$r" -le "$rounds" ]; do
    env GOMAXPROCS=1 "$out/go-pingpong" > "$out/o" 2>/dev/null; take "$out/o" pingpong_rendezvous go1 >> "$out/go.raw"
    "$out/go-pingpong" > "$out/o" 2>/dev/null; take "$out/o" pingpong_rendezvous goN >> "$out/go.raw"
    env GOMAXPROCS=1 "$out/go-spawn" > "$out/o" 2>/dev/null; take "$out/o" spawn_one go1 >> "$out/go.raw"
    "$out/go-spawn" > "$out/o" 2>/dev/null; take "$out/o" spawn_one goN >> "$out/go.raw"
    r=$((r + 1))
done

measure() {
    make -s -C "$root" build/libavra_runtime.a >/dev/null 2>&1 || true
    build_c
    for p in pingpong spawn; do
        rm -f "$here/avra/$p/src/main"          # relink against the swapped runtime archive
        "$avra" build "$here/avra/$p" >/dev/null 2>&1
    done
    : > "$out/$1.raw"
    r=1
    while [ "$r" -le "$rounds" ]; do
        "$out/spawn_bench_today" c gate > "$out/o" 2>/dev/null; take "$out/o" c_gate_round_trip c >> "$out/$1.raw"
        "$out/spawn_bench_today" c > "$out/o" 2>/dev/null; take "$out/o" c_spawn_one c >> "$out/$1.raw"
        "$here/avra/pingpong/src/main" > "$out/o" 2>/dev/null; take "$out/o" pingpong_rendezvous avra >> "$out/$1.raw"
        "$here/avra/spawn/src/main" > "$out/o" 2>/dev/null; take "$out/o" spawn_one avra >> "$out/$1.raw"
        r=$((r + 1))
    done
}

cp "$tick" /tmp/tick.after.c
cp "$root/docs/.flow03-pid-tick-before.c" "$tick"
measure before
cp /tmp/tick.after.c "$tick"
measure after

python3 - "$out" <<'PY'
import sys
out = sys.argv[1]
def load(name):
    rows = {}
    for line in open(f"{out}/{name}.raw"):
        p = line.split()
        if len(p) == 4 and p[3] and int(p[3]) > 0:
            rows.setdefault(p[0] + " " + p[1], []).append(int(p[2]) / int(p[3]))
    return rows
before, after, go = load("before"), load("after"), load("go")
def least(rows, k):
    v = rows.get(k, [])
    return min(v) if v else None
def best(rows, *ks):
    vs = [least(rows, k) for k in ks]
    vs = [v for v in vs if v]
    return min(vs) if vs else None
gpp = best(go, "go1 pingpong_rendezvous", "goN pingpong_rendezvous")
gsp = best(go, "go1 spawn_one", "goN spawn_one")
print(f"Go best: ping-pong {gpp:.1f} ns/rt, spawn+join {gsp:.1f} ns")
print(f"{'row':30s} {'before':>10s} {'after':>10s} {'speedup':>8s} {'after vs Go':>12s}")
for label, ck, ak in (("ping-pong (C)", "c c_gate_round_trip", None), ("spawn+join (C)", "c c_spawn_one", None)):
    b, a = least(before, ck), least(after, ck)
    print(f"{label:30s} {b:>10.1f} {a:>10.1f} {b/a:>7.2f}x")
for label, ak, g in (("ping-pong (Avra G1)", "avra pingpong_rendezvous", gpp),
                     ("spawn+join (Avra G1)", "avra spawn_one", gsp)):
    b, a = least(before, ak), least(after, ak)
    print(f"{label:30s} {b:>10.1f} {a:>10.1f} {b/a:>7.2f}x   {a/g:>10.2f}x" if b and a and g else f"{label}: -")
bp, bs = least(before, "avra pingpong_rendezvous"), least(before, "avra spawn_one")
ap, asp = least(after, "avra pingpong_rendezvous"), least(after, "avra spawn_one")
if bp and bs and gpp and gsp:
    print(f"before vs Go: ping-pong {bp/gpp:.2f}x, spawn+join {bs/gsp:.2f}x")
if ap and asp and gpp and gsp:
    print(f"after  vs Go: ping-pong {ap/gpp:.2f}x, spawn+join {asp/gsp:.2f}x")
PY
