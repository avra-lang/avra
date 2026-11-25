#!/bin/sh
# The public benchmark: TechEmpower's shapes — plaintext pipelined x16,
# json and one database row per request — against tools/bench/scenarios
# (Avra), tools/bench/floor (the kernel's floor in C; plaintext and json
# only), and nginx and h2o when installed. wrk drives the load; oha, when
# installed, repeats the unpipelined rows as a second generator's word.
# Prints one markdown table, headed by the commit and the machine.
#
#   sh tools/bench/public.sh                 one server core, 2 rounds of 5 s
#   CORES=4 ROUNDS=3 SECS=10 sh tools/bench/public.sh
#   SERVERS="avra floor" sh tools/bench/public.sh
#   KEEP=1 sh tools/bench/public.sh         the work directory kept: rows, configs
#   PORT=18090 sh tools/bench/public.sh     another port, when 18080 is taken
#
# Rounds are INTERLEAVED — every server takes its turn before any takes
# a second — so a loaded machine drifts every column alike; each cell
# prints every round. On Linux the server is pinned to cores 0..CORES-1
# and wrk to the rest; macOS has no pinning, so there the scheduler
# places both. A row whose responses were not all 2xx says so in its
# own column, and so do wrk's socket errors: a count of fast refusals
# is not throughput.
set -eu
ulimit -n 65536 2>/dev/null || ulimit -n "$(ulimit -Hn)"
command -v wrk >/dev/null || { echo "public.sh: wrk is not installed" >&2; exit 1; }

cores=${CORES:-1}
rounds=${ROUNDS:-2}
secs=${SECS:-5}
servers=${SERVERS:-avra floor nginx h2o}
conns=${CONNS:-256}
port=${PORT:-18080}
work=$(mktemp -d)
trap 'stop; [ -n "${KEEP:-}" ] && echo "public.sh: kept $work" >&2 || rm -rf "$work"' EXIT INT TERM

if [ "$(uname)" = Darwin ]; then
    ncpu=$(sysctl -n hw.ncpu)
    machine="$(sysctl -n machdep.cpu.brand_string), $ncpu cores, macOS $(sw_vers -productVersion)"
    pinned() { shift; "$@"; }
else
    ncpu=$(nproc)
    machine="$(awk -F': ' '/model name/ {print $2; exit}' /proc/cpuinfo), $ncpu cores, $(uname -sr)"
    pinned() { range=$1; shift; taskset -c "$range" "$@"; }
fi
load_threads=$((ncpu - cores))
[ "$load_threads" -ge 1 ] || load_threads=1

# ── The servers ──────────────────────────────────────────────────────

pid=
# Whether any of these processes still runs.
alive() {
    for p in "$@"; do kill -0 "$p" 2>/dev/null && return 0; done
    return 1
}

# The server and every process under it ended — asked, then after 5 s
# told — so the next one finds its port free.
stop() {
    [ -n "$pid" ] || return 0
    pids=$(tree "$pid")
    kill $pids 2>/dev/null || true
    i=0
    while alive $pids; do
        i=$((i + 1))
        [ "$i" -lt 50 ] || kill -9 $pids 2>/dev/null || true
        sleep 0.1
    done
    wait "$pid" 2>/dev/null || true
    pid=
}

# Answers once the port takes a connection, or fails after 10 s.
listening() {
    i=0
    until curl -s -m 1 -o /dev/null "http://127.0.0.1:$port/plaintext"; do
        i=$((i + 1))
        [ "$i" -lt 100 ] || { echo "public.sh: $1 never listened on $port" >&2; exit 1; }
        sleep 0.1
    done
}

installed() {
    case $1 in
        avra | floor) return 0 ;;
        *) command -v "$1" >/dev/null ;;
    esac
}

# Whether `server` serves `scenario`: only Avra holds a database.
serves() {
    [ "$2" != db ] || [ "$1" = avra ]
}

# The servers built. The package libraries are `make libs`'s, run
# beforehand: that target rebuilds a stale compiler, which is no
# benchmark's side effect.
prepare() {
    build/avra build tools/bench/scenarios/src/main.av >"$work/build.log" 2>&1 || {
        tail -5 "$work/build.log" >&2
        echo "public.sh: the scenarios server did not build — run \`make libs\` first" >&2
        exit 1
    }
    cc -O2 -o "$work/floor" tools/bench/floor/floor.c
    cat > "$work/nginx.conf" <<EOF
worker_processes $cores;
daemon off;
pid $work/nginx.pid;
error_log /dev/null;
events { worker_connections 65536; }
http {
    access_log off;
    keepalive_requests 1000000000;
    client_body_temp_path $work;
    proxy_temp_path $work;
    fastcgi_temp_path $work;
    uwsgi_temp_path $work;
    scgi_temp_path $work;
    server {
        listen 127.0.0.1:$port;
        location = /plaintext { default_type "text/plain"; return 200 "Hello, World!"; }
        location = /json { default_type "application/json"; return 200 '{"message":"Hello, World!"}'; }
    }
}
EOF
    printf 'Hello, World!' > "$work/plaintext"
    printf '{"message":"Hello, World!"}' > "$work/json"
    cat > "$work/h2o.conf" <<EOF
listen:
  host: 127.0.0.1
  port: $port
num-threads: $cores
error-log: /dev/null
http1-request-timeout: 60
hosts:
  default:
    paths:
      /plaintext:
        file.file: $work/plaintext
      /json:
        file.file: $work/json
EOF
}

# Starts `server` for `scenario` in the background, pinned to its cores.
start() {
    ! nc -z 127.0.0.1 "$port" 2>/dev/null || { echo "public.sh: port $port is already served — stop that server first" >&2; exit 1; }
    range=0-$((cores - 1))
    case $1 in
        avra) PORT=$port CORES=$cores pinned "$range" tools/bench/scenarios/src/main >/dev/null 2>&1 & ;;
        floor) PORT=$port ROUTE=$2 CORES=$cores pinned "$range" "$work/floor" >/dev/null 2>&1 & ;;
        nginx) pinned "$range" nginx -p "$work" -c "$work/nginx.conf" >/dev/null 2>&1 & ;;
        h2o) pinned "$range" h2o -c "$work/h2o.conf" >/dev/null 2>&1 & ;;
    esac
    pid=$!
    listening "$1"
    # the port may still be a stopped server's: the new one must be alive
    kill -0 "$pid" 2>/dev/null || { echo "public.sh: $1 exited at start" >&2; exit 1; }
}

# ── The measurement ──────────────────────────────────────────────────

# `$1` and every process below it.
tree() {
    echo "$1"
    for child in $(pgrep -P "$1"); do tree "$child"; done
}

# The server's CPU seconds so far: its whole process tree's.
cpu() {
    pids=$(tree "$pid" | tr '\n' ' ')
    if [ -r /proc/self/stat ]; then
        for p in $pids; do cat "/proc/$p/stat"; done 2>/dev/null |
            awk -v t="$(getconf CLK_TCK)" '{s += $14 + $15} END {printf "%.3f", s / t}'
    else
        # m:ss.cc, or h:mm:ss.cc past an hour
        ps -o time= -p "$(echo $pids | tr ' ' ',')" |
            awk -F: '{s += (NF == 3 ? $1 * 3600 + $2 * 60 + $3 : $1 * 60 + $2)} END {printf "%.3f", s}'
    fi
}

pipeline() {
    cat > "$work/pipeline.lua" <<EOF
init = function(args)
  local r = {}
  for i = 1, 16 do r[i] = wrk.format(nil, "/$1") end
  req = table.concat(r)
end
request = function() return req end
EOF
    echo "$work/pipeline.lua"
}

# One wrk run: "req/s p99 cpu/req-µs non-2xx socket-errors".
wrk_run() {
    scenario=$1
    set -- -t"$load_threads" -c"$conns" -d"${secs}s" --latency
    [ "$scenario" = plaintext ] && set -- "$@" -s "$(pipeline plaintext)"
    before=$(cpu)
    pinned "$cores-$((ncpu - 1))" wrk "$@" "http://127.0.0.1:$port/$scenario" > "$work/wrk.out"
    after=$(cpu)
    rps=$(awk '/Requests\/sec/ {print $2}' "$work/wrk.out")
    # a pipelining script's requests carry no send time for wrk to measure
    p99=$(awk '$1 == "99%" {print $2}' "$work/wrk.out")
    [ "$scenario" != plaintext ] || p99=—
    bad=$(awk '/Non-2xx/ {n = $5} END {print n + 0}' "$work/wrk.out")
    errors=$(awk '/Socket errors/ {gsub(/,/, ""); n = $4 + $6 + $8 + $10} END {print n + 0}' "$work/wrk.out")
    per=$(awk -v a="$after" -v b="$before" -v r="$rps" -v s="$secs" 'BEGIN {printf "%.2f", (r > 0 ? (a - b) / (r * s) * 1000000 : 0)}')
    echo "$rps $p99 $per $bad $errors"
}

# One oha run's requests a second, or "—" without oha.
oha_run() {
    command -v oha >/dev/null || { echo "—"; return; }
    pinned "$cores-$((ncpu - 1))" oha --no-tui -z "${secs}s" -c "$conns" --output-format json "http://127.0.0.1:$port/$1" 2>/dev/null |
        awk -F': ' '/"requestsPerSec"/ {gsub(/[ ,]/, "", $2); printf "%.0f", $2; exit}'
}

# ── The run ──────────────────────────────────────────────────────────

prepare
scenarios="plaintext json db"
for round in $(seq 1 "$rounds"); do
    for s in $servers; do
        installed "$s" || continue
        for sc in $scenarios; do
            serves "$s" "$sc" || continue
            start "$s" "$sc"
            echo "$round $s $sc $(wrk_run "$sc") $([ "$sc" = plaintext ] && echo "—" || oha_run "$sc")" >> "$work/rows"
            stop
            echo "round $round: $s $sc" >&2
        done
    done
done

echo "Commit $(git rev-parse --short HEAD), $(date -u +%Y-%m-%d), $machine, load average at the end $(uptime | sed 's/.*averages*: //')."
echo "Server on $cores core(s), wrk -t$load_threads -c$conns, ${secs} s x $rounds interleaved rounds (each cell: every round)."
echo
echo "| scenario | server | wrk req/s | p99 | server CPU/req | non-2xx | socket errors | oha req/s |"
echo "|---|---|---|---|---|---|---|---|"
for sc in $scenarios; do
    for s in $servers; do
        grep -q " $s $sc " "$work/rows" || continue
        awk -v s="$s" -v sc="$sc" '
            $2 == s && $3 == sc {
                rps = rps sep sprintf("%.0f", $4); p99 = p99 sep $5; cpu = cpu sep $6 " µs"
                bad = bad sep $7; errors = errors sep $8; oha = oha sep $9; sep = " / "
            }
            END { printf "| %s | %s | %s | %s | %s | %s | %s | %s |\n", sc, s, rps, p99, cpu, bad, errors, oha }
        ' "$work/rows"
    done
done
