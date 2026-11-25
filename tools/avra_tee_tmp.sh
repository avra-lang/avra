#!/bin/sh
# probe wrapper: run build/avra with the query trace, one numbered file a call
T=$(cd "$(dirname "$0")/.." && pwd)
n=$(cat /tmp/tee_n 2>/dev/null || echo 0)
n=$((n + 1))
echo $n > /tmp/tee_n
AVRA_QTRACE=1 exec "$T/build/avra" "$@" 2> "/tmp/trace.$n.$1"
