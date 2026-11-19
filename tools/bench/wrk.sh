#!/bin/sh
# The server under load, measured apart from its load: tools/bench/serve
# pinned to CORES cores (default 1), wrk driving it from the others,
# keep-alive and pipelined. Prints requests a second and the server's CPU per request
# — the number that does not move when the generator is the bottleneck.
#
#   sh tools/bench/wrk.sh            (on Linux: a Sprite, via `tools/work run`)
#   FLOOR=1 sh tools/bench/wrk.sh    the same load against tools/bench/floor,
#                                    the kernel's floor in C
#   CORES=4 sh tools/bench/wrk.sh    the server on cores 0-3, wrk on the rest
#                                    (LISTEN=reuseport: the floor's per-process
#                                    sockets)
set -eu
ulimit -n 65536 2>/dev/null || ulimit -n "$(ulimit -Hn)"
command -v wrk >/dev/null || sudo apt-get install -y wrk >/dev/null 2>&1
server=tools/bench/serve/src/main
if [ "${FLOOR:-}" = 1 ]; then
    mkdir -p build && cc -O2 -o build/floor tools/bench/floor/floor.c
    server=build/floor
else
    make libs >/dev/null
    build/avra build tools/bench/serve/src/main.av >/dev/null
fi
cores=$(nproc)
serving=${CORES:-1}
CORES=$serving taskset -c 0-$((serving - 1)) "$server" >/dev/null 2>&1 &
pid=$!
trap 'pkill -P $pid 2>/dev/null || true; kill $pid 2>/dev/null || true' EXIT
sleep 1
# The server's CPU is its whole process tree's: one process per core.
cpu() { for p in $pid $(pgrep -P $pid); do cat "/proc/$p/stat"; done 2>/dev/null | awk '{s += $14 + $15} END {print s}'; }
tick=$(getconf CLK_TCK)
pipeline=$(mktemp)
cat > "$pipeline" <<'EOF'
init = function(args)
  local r = {}
  for i = 1, 16 do r[i] = wrk.format(nil, "/") end
  req = table.concat(r)
end
request = function() return req end
EOF
run() {
    label=$1; shift
    before=$(cpu)
    out=$(taskset -c $serving-$((cores - 1)) wrk -t$((cores - serving)) -d5s "$@" http://127.0.0.1:18080/)
    after=$(cpu)
    rps=$(echo "$out" | awk '/Requests\/sec/ {print $2}')
    p99=$(echo "$out" | awk '/Latency/ {print $2}')
    echo "$label  $rps req/s  latency $p99  server cpu/req $(awk -v a="$after" -v b="$before" -v t="$tick" -v r="$rps" 'BEGIN {printf "%.2f", (a - b) / t / (r * 5) * 1000000}') us"
}
run "keep-alive   c=50  " -c50
run "keep-alive   c=200 " -c200
run "keep-alive   c=1000" -c1000
run "pipelined16  c=200 " -c200 -s "$pipeline"
rm -f "$pipeline"
