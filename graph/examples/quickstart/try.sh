#!/bin/sh
# Feeds one message to the quickstart app, writes by hand the facts an
# extractor would, and asks one question; prints the answer as the graph gives it.
set -eu
cd "$(dirname "$0")/../../.."
Q=graph/examples/quickstart/src/main
D="$(mktemp -d)"
DB="$D/qs.db"

echo '{"op":"schema"}' > "$D/schema.json"
echo '{"op":"ingest","source":{"contract":2,"source":{"observation":"mail:1","revision":1},"authored_at_ms":1792573200000,"received_at_ms":1792573200000,"author":null,"participants":[],"conversation":null,"media_type":"text/plain","content":"Ada Okafor <ada@example.test>: Please send the report to Sam by 2026-11-05.","frames":[]}}' > "$D/ingest.json"
$Q request --db "$DB" "$D/ingest.json" > /dev/null

SCHEMA="$($Q request --db "$DB" "$D/schema.json")"
python3 - "$SCHEMA" "$D/publish.json" <<'PY'
import json, sys
schema = json.loads(sys.argv[1])
open(sys.argv[2], "w").write(json.dumps({
    "op": "publish", "id": "by-hand-1", "producer": "quickstart", "scope": "mail:1", "input": "mail:1",
    "input_revision": 1, "schema": schema["fingerprint"], "expected_revision": schema["revision"],
    "records": [
        {"id": "ada", "model": "Person", "mode": "partial", "value": {"name": "Ada Okafor", "email": "ada@example.test"},
         "identities": [{"namespace": "mail", "key": "ada@example.test"}], "locator": {"span": [0, 26]}},
        {"id": "sam", "model": "Person", "mode": "partial", "value": {"name": "Sam"}, "identities": [], "locator": {"span": [48, 51]}},
        {"id": "report", "model": "Chore", "mode": "partial",
         "value": {"title": "Send the report", "owner": "ada", "due_on": "2026-11-05"}, "identities": [], "locator": {"span": [8, 47]}},
    ]}))
PY
$Q request --db "$DB" "$D/publish.json" > /dev/null

echo '{"op":"query","cypher":"MATCH (c:Chore) WHERE c.title CONTAINS '"'"'report'"'"' RETURN c.title AS chore, c.due_on AS due","params":{"asker":"ada","now":1792573200000}}' > "$D/ask.json"
$Q request --db "$DB" "$D/ask.json" | python3 -m json.tool
