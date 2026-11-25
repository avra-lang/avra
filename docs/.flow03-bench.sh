#!/bin/sh
# Temporary: step 1's price — the instruction counts of the hot leaves,
# main's scheduler against this branch's, and the bench server under
# load linked against each.
set -u
here=$(pwd)
mkdir -p build/f03
cc=$(command -v clang)
for side in main branch; do
    src=runtime/avra_fiber.c; [ "$side" = main ] && src=docs/.flow03-main-fiber.c
    cp "$src" build/f03/fiber_$side.c
    $cc -O2 -fno-omit-frame-pointer -I runtime -c build/f03/fiber_$side.c -o build/f03/fiber_$side.o 2> build/f03/cc_$side.err || { echo "$side does not compile"; head -3 build/f03/cc_$side.err; exit 1; }
done
body() { objdump -d --no-show-raw-insn "$1" | awk -v f="<$2>:" '$2 == f { on=1; next } on && /^$/ { exit } on && /^ / { print }'; }
for fn in avra_fiber_yield avra_wait_park avra_fiber_sleep avra_task_join avra_fiber_park_fd avra_gate_claim; do
    echo "== $fn: main $(body build/f03/fiber_main.o $fn | wc -l), branch $(body build/f03/fiber_branch.o $fn | wc -l) instructions; frame ops before the first branch — main $(body build/f03/fiber_main.o $fn | awk '/\tj|\tb\.|\tcb|\tret/ {exit} /push|sub +\$0x[0-9a-f]+,%rsp|stp/ {n++} END {print n+0}'), branch $(body build/f03/fiber_branch.o $fn | awk '/\tj|\tb\.|\tcb|\tret/ {exit} /push|sub +\$0x[0-9a-f]+,%rsp|stp/ {n++} END {print n+0}')"
done
echo "== avra_fiber_yield, branch"; body build/f03/fiber_branch.o avra_fiber_yield | head -24
echo "== the servers"
cp runtime/avra_fiber.c build/f03/after.c
for side in main branch; do
    [ "$side" = main ] && cp docs/.flow03-main-fiber.c runtime/avra_fiber.c || cp build/f03/after.c runtime/avra_fiber.c
    make -s build/libavra_runtime.a > /dev/null 2>&1 || { echo "the $side runtime does not build"; cp build/f03/after.c runtime/avra_fiber.c; exit 1; }
    rm -rf tools/bench/serve/.avra-cache .avra-cache/build 2>/dev/null
    rm -f tools/bench/serve/src/main
    build/avra build tools/bench/serve/src/main.av > build/f03/build_$side.out 2>&1 || { echo "the $side server does not build"; tail -3 build/f03/build_$side.out; }
    cp tools/bench/serve/src/main build/f03/serve_$side
    nm build/f03/serve_$side | grep -c ' avra_unwinding$' | sed "s/^/   $side carries avra_unwinding: /"
done
cp build/f03/after.c runtime/avra_fiber.c
make -s build/libavra_runtime.a > /dev/null 2>&1
command -v wrk > /dev/null || sudo apt-get install -y wrk > /dev/null 2>&1
ulimit -n 65536 2> /dev/null || ulimit -n "$(ulimit -Hn)"
cores=$(nproc); hz=$(getconf CLK_TCK); secs=${SECS:-6}
cat > build/f03/pipeline.lua <<'LUA'
init = function(args)
  local r = {}
  for i = 1, 16 do r[i] = wrk.format(nil, "/") end
  req = table.concat(r)
end
request = function() return req end
LUA
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
    awk -v a="$after" -v b="$before" -v t="$hz" -v r="$got" -v s="$secs" 'BEGIN { printf "%10.0f req/s %6.2f us/req", r, (a - b) / t / (r * s) * 1000000 }'
}
for round in $(seq 1 ${ROUNDS:-4}); do
    for side in main branch; do
        echo "round $round  $(printf '%-6s' $side) keep-alive c=50 $(measured build/f03/serve_$side -c50)   pipelined16 c=200 $(measured build/f03/serve_$side -c200 -s build/f03/pipeline.lua)"
    done
done
