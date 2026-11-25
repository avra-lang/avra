#!/bin/sh
# Focused G1 rows for the tick's getpid path: the C gate round trip and
# spawn+join, beside their Go twins. Builds as tools/flow_bench/run.sh
# builds, runs only those rows, least of ROUNDS each.
set -eu
here=$(cd "$(dirname "$0")/../tools/flow_bench" && pwd)
root=$(cd "$here/../.." && pwd)
out=$root/build/flow-bench-pid
rounds=${ROUNDS:-5}
mkdir -p "$out"

probes=""
[ "$(uname -s)" = Darwin ] || probes=-fstack-clash-protection
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

go=$(command -v go || true)
[ -n "$go" ] || { [ -x /.sprite/bin/go ] && go=/.sprite/bin/go; } || true
[ -n "$go" ] || { echo "no go"; exit 2; }
(cd "$here/go" && GOFLAGS=-buildvcs=false "$go" build -o "$out/go-spawn" ./spawn)
(cd "$here/go" && GOFLAGS=-buildvcs=false "$go" build -o "$out/go-pingpong" ./pingpong)

# The Avra G1 rows need the branch's compiler; absent, they are skipped.
avra=$root/build/avra
[ -x "$avra" ] || { echo "no compiler at $avra — Avra rows skipped"; avra=; }
if [ -n "$avra" ]; then
    for p in pingpong spawn; do
        "$avra" build "$here/avra/$p" > /dev/null 2> "$out/$p.build" || { cat "$out/$p.build"; exit 1; }
    done
fi

# least of N lines matching a key in an output file
least() { awk -v k="$1" '$1==k { if (m=="" || $2<m) m=$2 } END { print m }' "$2"; }

# Each source row prints `<key> <total ns> <count>`; prefix the engine and
# keep the count, so the least is per unit whatever each row's count is.
take() { grep "^$2 " "$1" | sed "s/^/$3 /" ; }

: > "$out/raw"
r=1
while [ "$r" -le "$rounds" ]; do
    "$out/spawn_bench_today" c gate > "$out/o" 2>/dev/null
    take "$out/o" c_gate_round_trip c >> "$out/raw"
    "$out/spawn_bench_today" c > "$out/o" 2>/dev/null
    take "$out/o" c_spawn_one c >> "$out/raw"
    env GOMAXPROCS=1 "$out/go-spawn" > "$out/o" 2>/dev/null
    take "$out/o" spawn_one go1 >> "$out/raw"
    "$out/go-spawn" > "$out/o" 2>/dev/null
    take "$out/o" spawn_one goN >> "$out/raw"
    env GOMAXPROCS=1 "$out/go-pingpong" > "$out/o" 2>/dev/null
    take "$out/o" pingpong_rendezvous go1 >> "$out/raw"
    "$out/go-pingpong" > "$out/o" 2>/dev/null
    take "$out/o" pingpong_rendezvous goN >> "$out/raw"
    if [ -n "$avra" ]; then
        "$here/avra/pingpong/src/main" > "$out/o" 2>/dev/null
        take "$out/o" pingpong_rendezvous avra >> "$out/raw"
        "$here/avra/spawn/src/main" > "$out/o" 2>/dev/null
        take "$out/o" spawn_one avra >> "$out/raw"
    fi
    r=$((r + 1))
done

python3 - "$out/raw" <<'PY'
import sys
rows = {}
for line in open(sys.argv[1]):
    p = line.split()
    if len(p) == 4 and p[3] and int(p[3]) > 0:
        rows.setdefault(p[0] + " " + p[1], []).append(int(p[2]) / int(p[3]))

def least(k):
    v = rows.get(k, [])
    return min(v) if v else None

def best(*ks):
    vs = [least(k) for k in ks]
    vs = [v for v in vs if v]
    return min(vs) if vs else None

print("row                          least ns/unit")
for k in ("c c_gate_round_trip", "avra pingpong_rendezvous", "go1 pingpong_rendezvous", "goN pingpong_rendezvous",
          "c c_spawn_one", "avra spawn_one", "go1 spawn_one", "goN spawn_one"):
    v = least(k)
    print(f"{k:28s} {v if v else float('nan'):>10.1f}")
def vs_go(key, *gokeys):
    a, g = least(key), best(*gokeys)
    return f"{key}: {a/g:.2f}x vs best Go" if a and g else f"{key}: -"
print("C " + vs_go("c c_gate_round_trip", "go1 pingpong_rendezvous", "goN pingpong_rendezvous"))
print("C " + vs_go("c c_spawn_one", "go1 spawn_one", "goN spawn_one"))
print("Avra " + vs_go("avra pingpong_rendezvous", "go1 pingpong_rendezvous", "goN pingpong_rendezvous"))
print("Avra " + vs_go("avra spawn_one", "go1 spawn_one", "goN spawn_one"))
PY
