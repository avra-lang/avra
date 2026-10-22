#!/bin/sh
# The slice end to end: build the fixture app, check the model service, feed
# it five messages through its MCP door, ask four questions, print the
# answers. Needs the local model service (see QUICKSTART.md, step 3).
set -eu
cd "$(dirname "$0")/.."

APP=graph/acceptance/app
sh tools/watch.sh 3500 ./build/avra build "$APP"

SOCK="$HOME/.cache/avra-graph-ml/cascade.sock"
if ! python3 - "$SOCK" <<'PY'
import socket, sys
s = socket.socket(socket.AF_UNIX)
s.settimeout(3)
try:
    s.connect(sys.argv[1])
except OSError:
    sys.exit(1)
PY
then
    echo "no model service answers on $SOCK" >&2
    echo "start it in another terminal:  python3 graph/extract/cascade.py --serve" >&2
    exit 2
fi

DB="$(mktemp -d)/demo.db"
echo "graph: $DB"
python3 graph/mcp/demo.py --binary "$APP/src/main" --db "$DB"
