#!/bin/sh
# System calls per request, Avra against the C floor: each server run
# under tools/bench/syscount.c's counting library while wrk drives it
# keep-alive (json) and pipelined x16 (plaintext). One read and one
# write per keep-alive request, and one of each per pipelined batch, is
# the floor's count; a row above it is the server's own syscalls.
#
#   sh tools/bench/syscalls.sh          (`make libs` first)
#   PORT=18090 SECS=10 sh tools/bench/syscalls.sh
set -eu
command -v wrk >/dev/null || { echo "syscalls.sh: wrk is not installed" >&2; exit 1; }
port=${PORT:-18090}
secs=${SECS:-5}
work=$(mktemp -d)
pid=
trap '[ -z "$pid" ] || kill "$pid" 2>/dev/null; rm -rf "$work"' EXIT INT TERM

if [ "$(uname)" = Darwin ]; then
    cc -O2 -shared -fPIC -o "$work/syscount.so" tools/bench/syscount.c
    preload=DYLD_INSERT_LIBRARIES
else
    cc -O2 -shared -fPIC -o "$work/syscount.so" tools/bench/syscount.c -ldl
    preload=LD_PRELOAD
fi
cc -O2 -DREPORT -o "$work/syscount" tools/bench/syscount.c
cc -O2 -o "$work/floor" tools/bench/floor/floor.c
build/avra build tools/bench/scenarios/src/main.av >"$work/build.log" 2>&1 || {
    tail -5 "$work/build.log" >&2
    echo "syscalls.sh: the scenarios server did not build — run \`make libs\` first" >&2
    exit 1
}
cat > "$work/pipeline.lua" <<'EOF'
init = function(args)
  local r = {}
  for i = 1, 16 do r[i] = wrk.format(nil, "/plaintext") end
  req = table.concat(r)
end
request = function() return req end
EOF

# One server under count for one route: its calls per request.
counted() {
    server=$1 route=$2
    ! nc -z 127.0.0.1 "$port" 2>/dev/null || { echo "syscalls.sh: port $port is already served" >&2; exit 1; }
    rm -f "$work/counts"
    case $server in
        avra) env SYSCOUNT="$work/counts" PORT="$port" "$preload=$work/syscount.so" tools/bench/scenarios/src/main >/dev/null 2>&1 & ;;
        floor) env SYSCOUNT="$work/counts" PORT="$port" ROUTE="$route" "$preload=$work/syscount.so" "$work/floor" >/dev/null 2>&1 & ;;
    esac
    pid=$!
    until nc -z 127.0.0.1 "$port" 2>/dev/null; do sleep 0.1; done
    [ -f "$work/counts" ] || { echo "syscalls.sh: $server did not load the counter (a protected binary drops $preload)" >&2; exit 1; }
    "$work/syscount" "$work/counts" 0
    if [ "$route" = plaintext ]; then set -- -s "$work/pipeline.lua"; else set --; fi
    n=$(wrk -t4 -c50 -d"${secs}s" "$@" "http://127.0.0.1:$port/$route" | awk '/requests in/ {print $1}')
    echo "## $server, /$route$([ "$route" = plaintext ] && echo ' pipelined x16'), $n requests"
    "$work/syscount" "$work/counts" "$n"
    echo
    kill "$pid"
    wait "$pid" 2>/dev/null || true
    while nc -z 127.0.0.1 "$port" 2>/dev/null; do sleep 0.1; done
    pid=
}

echo "Commit $(git rev-parse --short HEAD), $(uname -sm), wrk -t4 -c50, ${secs} s."
echo
for route in json plaintext; do
    counted avra "$route"
    counted floor "$route"
done
