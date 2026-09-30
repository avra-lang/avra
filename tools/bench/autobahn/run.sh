#!/bin/sh
# The Autobahn testsuite against @std/http's WebSocket, both sides:
# its fuzzingclient drives tools/bench/autobahn/server, and its
# fuzzingserver is driven by tools/bench/autobahn/client. Reports land
# in build/autobahn/{servers,clients}; the summary counts each verdict
# and names every case that is neither OK nor informational.
#
#   sh tools/bench/autobahn/run.sh        (needs docker)
#   CASES='["1.*","2.*"]' sh tools/bench/autobahn/run.sh
#
# permessage-deflate (cases 12 and 13) is not implemented, so those
# cases are excluded rather than reported as failures.
set -eu
image=crossbario/autobahn-testsuite
out="$PWD/build/autobahn"
cases="${CASES:-[\"*\"]}"
mkdir -p "$out/config"
build/avra build tools/bench/autobahn/server/src/main.av >/dev/null
build/avra build tools/bench/autobahn/client/src/main.av >/dev/null

cat > "$out/config/fuzzingclient.json" <<JSON
{ "outdir": "/reports/servers",
  "servers": [{ "agent": "avra", "url": "ws://host.docker.internal:9001" }],
  "cases": $cases, "exclude-cases": ["12.*", "13.*"], "exclude-agent-cases": {} }
JSON
cat > "$out/config/fuzzingserver.json" <<JSON
{ "url": "ws://127.0.0.1:9001", "outdir": "/reports/clients",
  "cases": $cases, "exclude-cases": ["12.*", "13.*"], "exclude-agent-cases": {} }
JSON

AUTOBAHN_PORT=9001 tools/bench/autobahn/server/src/main >"$out/server.log" 2>&1 &
server=$!
trap 'kill $server 2>/dev/null || true; docker rm -f avra-fuzzingserver >/dev/null 2>&1 || true' EXIT
sleep 1
docker run --rm -v "$out:/reports" "$image" wstest -m fuzzingclient -s /reports/config/fuzzingclient.json >"$out/fuzzingclient.log" 2>&1
kill $server 2>/dev/null || true

docker run -d --name avra-fuzzingserver -p 9002:9001 -v "$out:/reports" "$image" \
    wstest -m fuzzingserver -s /reports/config/fuzzingserver.json >/dev/null
sleep 3
AUTOBAHN_PORT=9002 tools/bench/autobahn/client/src/main >"$out/client.log" 2>&1
docker rm -f avra-fuzzingserver >/dev/null

python3 - "$out" <<'PY'
import json, sys, collections
out = sys.argv[1]
for side in ("servers", "clients"):
    try:
        index = json.load(open(f"{out}/{side}/index.json"))
    except FileNotFoundError:
        print(f"{side}: no report"); continue
    for agent, results in index.items():
        tally = collections.Counter(r["behavior"] for r in results.values())
        close = collections.Counter(r["behaviorClose"] for r in results.values())
        print(f"{side} {agent}: {len(results)} cases, behavior {dict(tally)}, close {dict(close)}")
        for case, r in sorted(results.items(), key=lambda kv: [int(p) for p in kv[0].split('.')]):
            if r["behavior"] not in ("OK", "INFORMATIONAL", "NON-STRICT") or r["behaviorClose"] not in ("OK", "INFORMATIONAL"):
                print(f"  {case}: {r['behavior']} / close {r['behaviorClose']}")
PY
