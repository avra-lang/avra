"""The graph binary over one database file, and a world loaded into it."""
import json
import pathlib
import subprocess
import tempfile

from cat import Cat


class App:
    """Every call is a fresh process on the database file."""

    def __init__(self, binary, db, scratch=None):
        self.binary, self.db = pathlib.Path(binary), pathlib.Path(db)
        self.scratch = pathlib.Path(scratch or tempfile.mkdtemp(prefix="gym-app-"))
        self.scratch.mkdir(parents=True, exist_ok=True)
        self.calls = 0

    @property
    def argv(self):
        return [str(self.binary), "request", "--db", str(self.db)]

    def call(self, request):
        self.calls += 1
        path = self.scratch / f"req-{self.calls % 1000}.json"
        path.write_text(json.dumps(request))
        done = subprocess.run([*self.argv, str(path)], text=True, capture_output=True, timeout=90)
        try:
            return json.loads(done.stdout)
        except json.JSONDecodeError:
            return {"error": (done.stderr or done.stdout).strip()[:400]}

    def query(self, cypher, params, as_of=None):
        return self.call({"op": "query", "cypher": cypher, "params": params, **({"as_of": as_of} if as_of else {})})

    def check(self, cypher, params):
        return self.call({"op": "check", "cypher": cypher, "params": params})


def publication(cat, world, source, published, anchors=None):
    """One source's publication body: its statements, in the dependency order the world was built in."""
    anchors = anchors or {}
    records = []
    for vid, i in source["statements"]:
        inst = world["instances"][vid]
        records.append({"id": vid, "model": inst["model"], "mode": "complete", "value": inst["versions"][i], "identities": [],
                        "locator": {"source": source["id"], "span": anchors.get(vid, [0, 0])}})
        published.add(vid)
    return records


def envelope(source_id, text, ms):
    return {"contract": 2, "source": {"observation": source_id, "revision": 1}, "authored_at_ms": ms, "received_at_ms": ms, "author": "gym",
            "participants": [], "conversation": "gym", "media_type": "text/plain", "content": text, "frames": []}


def load(app, cat, world, texts, anchors=None, base_ms=1_700_000_000_000):
    """Ingests each source's text, publishes its statements, then hides the tombstoned records.
    Returns (graph revision before the tombstones, final revision, refusals)."""
    schema = app.call({"op": "schema"})
    published, refused = set(), []
    for k, source in enumerate(world["sources"]):
        got = app.call({"op": "ingest", "source": envelope(source["id"], texts[source["id"]], base_ms + k)})
        if "error" in got:
            raise SystemExit(f"gym: ingest {source['id']}: {got['error']}")
        body = {"op": "publish", "schema": schema["fingerprint"], "expected_revision": app.call({"op": "schema"})["revision"], "id": f"run-{source['id']}",
                "producer": "oracle", "scope": source["id"], "input": source["id"], "input_revision": 1,
                "records": publication(cat, world, source, published, (anchors or {}).get(source["id"]))}
        got = app.call(body)
        if "error" in got:
            raise SystemExit(f"gym: publish {source['id']} refused by the engine: {got['error']}")
    before = app.call({"op": "schema"})["revision"]
    for rid in world["tombstones"]:
        got = app.call({"op": "tombstone", "id": f"gone-{rid}", "entity": rid, "decider": "gym"})
        if "error" in got:
            raise SystemExit(f"gym: tombstone {rid}: {got['error']}")
    return before, app.call({"op": "schema"})["revision"]
