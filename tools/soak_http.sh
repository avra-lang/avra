#!/bin/sh
# THE SERVER UNDER SOAK: `make soak-http`.
#
# @std/http on every core (packages/std-http/soak), held open by
# SOAK_HTTP_CONNECTIONS keep-alive connections (default 10000, oha) for
# SOAK_HTTP_SECONDS (default 300; SOAK_HTTP_QPS caps the rate, else
# as fast as the server answers), while the client's reset law is
# looped SOAK_HTTP_RESETS times (default 1000) under that load. Then
# it says what it saw:
#   - the load: requests, rate, success, p99;
#   - memory: the server's summed RSS sampled every 10 s, and each
#     core's live bytes at exit (AVRA_MEM_STATS) — flat means the last
#     sample under load within a quarter of the first after warm-up;
#   - descriptors: `lsof` over the server's processes before the load
#     and after it drains — equal, or one leaked;
#   - the reset law: how many attempts came back `net.read`.
# A status is a verdict: 0 when all four hold.
set -u
cd "$(dirname "$0")/.."
secs="${SOAK_HTTP_SECONDS:-300}"
conns="${SOAK_HTTP_CONNECTIONS:-10000}"
loops="${SOAK_HTTP_RESETS:-1000}"
qps="${SOAK_HTTP_QPS:-}"
port="${SOAK_HTTP_PORT:-18090}"
out=build/soak-http
bin=packages/std-http/soak/src/main
mkdir -p "$out"
command -v oha > /dev/null || { echo "soak-http: needs oha (brew install oha)"; exit 1; }
ulimit -n 30000 2> /dev/null || { echo "soak-http: cannot raise the descriptor limit to 30000"; exit 1; }
build/avra build packages/std-http/soak > "$out/build.log" 2>&1 || { tail -20 "$out/build.log"; exit 1; }
: > "$out/samples"

AVRA_MEM_STATS=1 SOAK_SECS=$((secs + 60)) SOAK_PORT="$port" "$bin" > "$out/server.log" 2>&1 &
server=$!
tries=0
until curl -s -o /dev/null "http://127.0.0.1:$port/up"; do
    tries=$((tries + 1))
    [ "$tries" -lt 100 ] || { echo "soak-http: the server never answered"; cat "$out/server.log"; exit 1; }
    sleep 0.1
done

procs() { echo "$server"; pgrep -P "$server"; }
fds() { t=0; for p in $(procs); do t=$((t + $(lsof -p "$p" 2> /dev/null | wc -l))); done; echo "$t"; }
rss() { t=0; for p in $(procs); do t=$((t + $(ps -o rss= -p "$p" 2> /dev/null || echo 0))); done; echo "$t"; }

fd_before=$(fds)
rm -f "$out/stop"
( while [ ! -e "$out/stop" ] && kill -0 "$server" 2> /dev/null; do echo "$(date +%s) $(rss) $(fds)" >> "$out/samples"; sleep 10; done ) &
sampler=$!

oha -c "$conns" -z "${secs}s" ${qps:+-q "$qps"} --no-tui "http://127.0.0.1:$port/soak" > "$out/oha.txt" 2>&1 &
load=$!
sleep 5
SOAK_MODE=reset SOAK_LOOPS="$loops" "$bin" > "$out/reset.log" 2>&1
wait "$load"
load_end=$(date +%s)
drained=0
until [ "$(fds)" -le "$fd_before" ] || [ "$drained" -ge 30 ]; do sleep 1; drained=$((drained + 1)); done
fd_after=$(fds)
touch "$out/stop"
wait "$server"
wait "$sampler"

ok=0
echo "soak-http: $conns connections for ${secs}s on every core, $(sysctl -n hw.ncpu) here"
grep -E 'Success rate|Requests/sec|99.00% in|Total:' "$out/oha.txt" | sed 's/^ */  /'
total=$(awk -F'[][]' '/\[200\]/ {print $0}' "$out/oha.txt" | grep -o '[0-9]* responses' | head -1)
[ -n "$total" ] && echo "  answered: $total"
grep -A20 'Error distribution' "$out/oha.txt" | grep -v '^$' | head -8 | sed 's/^ */  /'
grep -q 'Success rate:.*100.00%' "$out/oha.txt" || ok=1

warm=$(awk 'NR == 4 {print $2}' "$out/samples")
last=$(awk -v end="$load_end" '$1 <= end {v = $2} END {print v}' "$out/samples")
peak=$(awk 'BEGIN {m = 0} $2 > m {m = $2} END {print m}' "$out/samples")
echo "  RSS (all server processes): ${warm:-?} KB after warm-up, ${last:-?} KB at the end of the load, ${peak} KB peak"
if [ -n "${warm:-}" ] && [ -n "${last:-}" ] && [ "$last" -gt $((warm + warm / 4)) ]; then
    echo "  memory GREW past a quarter"; ok=1
fi
grep 'live .* bytes at exit' "$out/server.log" | sort | uniq -c | sed 's/^ */  at exit: /'

echo "  descriptors: $fd_before before the load, $fd_after after it drained"
[ "$fd_after" -le "$fd_before" ] || ok=1

cat "$out/reset.log" | sed 's/^/  /'
grep -q "^soak-reset: $loops/$loops " "$out/reset.log" || ok=1
grep 'soak-server' "$out/server.log" | sed 's/^/  /'
[ "$ok" -eq 0 ] && echo "soak-http: held" || echo "soak-http: FAILED"
exit "$ok"
