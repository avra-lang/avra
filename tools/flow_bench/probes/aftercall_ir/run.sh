#!/bin/sh
# Prices the cancel slice's tests ON AVRA'S OWN CODE: the bench server
# (tools/bench/serve) is emitted as LLVM IR, rewritten four ways
# (rewrite.py), linked as `avra build` links it, and put under the same
# load, the variants taking turns (`built` is `avra build`'s own binary,
# beside the four made here by clang -O2). Prints the census, each binary's text
# size, and requests a second with the server's CPU a request.
#   ROUNDS=3 SECS=6 sh tools/flow_bench/probes/aftercall_ir/run.sh
set -u
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../../../.." && pwd)
out=$root/build/flow-bench/aftercall_ir
mkdir -p "$out"
cd "$root" || exit 1
real=$(command -v clang)
make -s libs > /dev/null 2>&1
build/avra build tools/bench/serve/src/main.av > "$out/build.log" 2>&1 || { echo "the bench server does not build"; head -5 "$out/build.log"; exit 1; }
cp tools/bench/serve/src/main "$out/serve_built"
link=$(python3 "$here/linkrows.py" "$root" tools/bench/serve)
build/avra emit tools/bench/serve > "$out/serve.ll" 2> "$out/emit.err" || { echo "emit failed"; head -5 "$out/emit.err"; exit 1; }
[ -s "$out/serve.ll" ] || cp tools/bench/serve/build/main.ll "$out/serve.ll" 2> /dev/null
echo "== $(uname -srm); the emitted program: $(wc -l < "$out/serve.ll") lines of IR; linked with: $link"
$real -O2 -c -o "$out/probe_state.o" "$here/probe_state.c" || exit 1
for v in plain byte task edge; do
    python3 "$here/rewrite.py" "$out/serve.ll" "$out/serve_$v.ll" $v || exit 1
    t0=$(date +%s%N)
    $real -w -O2 "$out/serve_$v.ll" "$out/probe_state.o" $link -o "$out/serve_$v" 2> "$out/link_$v.err" || { echo "$v does not link"; head -8 "$out/link_$v.err"; exit 1; }
    echo "   $v: text $(size "$out/serve_$v" | awk 'NR == 2 { print $1 }') bytes, clang -O2 $(( ($(date +%s%N) - t0) / 1000000 )) ms"
done
command -v wrk > /dev/null || sudo apt-get install -y wrk > /dev/null 2>&1
ulimit -n 65536 2> /dev/null || ulimit -n "$(ulimit -Hn)"
cores=$(nproc)
tick=$(getconf CLK_TCK)
secs=${SECS:-6}
pipeline=$out/pipeline.lua
cat > "$pipeline" <<'LUA'
init = function(args)
  local r = {}
  for i = 1, 16 do r[i] = wrk.format(nil, "/") end
  req = table.concat(r)
end
request = function() return req end
LUA
# One server, pinned to core 0, under one load; its CPU is its whole tree's.
measured() {
    bin=$1; shift
    CORES=1 taskset -c 0 "$bin" > /dev/null 2>&1 &
    pid=$!
    sleep 1
    cpu() { for p in $pid $(pgrep -P $pid); do cat "/proc/$p/stat"; done 2> /dev/null | awk '{ s += $14 + $15 } END { print s }'; }
    before=$(cpu)
    got=$(taskset -c 1-$((cores - 1)) wrk -t$((cores - 1)) -d${secs}s "$@" http://127.0.0.1:18080/ | awk '/Requests\/sec/ { print $2 }')
    after=$(cpu)
    for p in $(pgrep -P $pid) $pid; do kill "$p" 2> /dev/null; done
    wait $pid 2> /dev/null
    awk -v a="$after" -v b="$before" -v t="$tick" -v r="$got" -v s="$secs" 'BEGIN { printf "%10.0f req/s %6.2f us/req", r, (a - b) / t / (r * s) * 1000000 }'
}
echo "== requests a second and server CPU a request, core 0, ${secs}s a run"
for round in $(seq 1 ${ROUNDS:-3}); do
    for v in built plain byte task edge; do
        bin=$out/serve_$v
        echo "round $round  $(printf '%-6s' $v) keep-alive c=50 $(measured "$bin" -c50)   pipelined16 c=200 $(measured "$bin" -c200 -s "$pipeline")"
    done
done
