#!/usr/bin/env python3
"""Private-file witnesses for upgrades, lock contention and crash rollback."""
import json
import pathlib
import sqlite3
import subprocess
import sys
import tempfile
import time


class Graph:
    def __init__(self, root, binary):
        self.root, self.binary = root, binary
        self.database = root / "graph.db"
        self.request = root / "request.json"

    def start(self, request):
        self.request.write_text(json.dumps(request))
        return subprocess.Popen(
            [self.binary, "request", "--db", str(self.database), str(self.request)],
            text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        )

    def call(self, request, success=True):
        process = self.start(request)
        stdout, stderr = process.communicate(timeout=15)
        assert (process.returncode == 0) == success, (stdout, stderr)
        return json.loads(stdout)

    def seed(self):
        schema = self.call({"op": "schema"})
        observed = self.call({"op": "observe", "id": "source", "payload": "Ada"})
        publication = {
            "op": "publish", "id": "run", "producer": "extractor", "scope": "source",
            "input": "source", "input_revision": 1, "schema": schema["fingerprint"],
            "expected_revision": observed["revision"],
            "records": [{"id": "p1", "model": "Person", "value": {"name": "Ada"}}],
        }
        return publication, self.call(publication)


def upgrades(graph):
    publication, committed = graph.seed()
    for version in ("6", "7", "8"):
        with sqlite3.connect(graph.database) as raw:
            raw.execute("DROP TABLE SupersessionRow")
            raw.execute("DROP TABLE EvidenceRow")
            raw.execute("DROP TABLE VoiceRow")
            if version != "8":
                raw.execute("DROP TABLE ChoiceEndRow")
                raw.execute("DROP TABLE ChoiceRow")
            if version == "6":
                raw.execute("DROP TABLE ConfidenceRow")
            raw.execute("UPDATE Meta SET value=? WHERE key='format'", (version,))
        assert graph.call({"op": "value", "id": "p1"})["name"] == "Ada"
        [legacy] = graph.call({"op": "explain", "id": "p1", "property": "name"})
        assert (legacy["polarity"], legacy["modality"], legacy["anchor"], legacy["active"]) == ("affirmed", "asserted", None, True)
        assert graph.call(publication) == committed
        with sqlite3.connect(graph.database) as raw:
            assert raw.execute("SELECT value FROM Meta WHERE key='format'").fetchone() == ("9",)
            assert raw.execute("PRAGMA journal_mode").fetchone() == ("wal",)
            assert raw.execute("PRAGMA integrity_check").fetchone() == ("ok",)

    # A future store is refused before creating tables or installing a catalog.
    with sqlite3.connect(graph.database) as raw:
        raw.execute("UPDATE Meta SET value='999' WHERE key='format'")
        raw.execute("UPDATE Meta SET value='future-catalog' WHERE key='schema'")
        before = raw.execute("SELECT * FROM Meta ORDER BY id").fetchall()
        raw.execute("DROP TABLE ConfidenceRow")
    refused = graph.call({"op": "schema"}, success=False)
    assert "unsupported graph storage format" in refused["error"]
    with sqlite3.connect(graph.database) as raw:
        assert raw.execute("SELECT * FROM Meta ORDER BY id").fetchall() == before
        assert raw.execute("SELECT name FROM sqlite_master WHERE name='ConfidenceRow'").fetchone() is None
        raw.execute("UPDATE Meta SET value='9' WHERE key='format'")
    # Missing metadata is not mistaken for a fresh store, either.
    with sqlite3.connect(graph.database) as raw:
        raw.execute("DELETE FROM Meta WHERE key='format'")
    assert "unsupported graph storage format" in graph.call({"op": "schema"}, success=False)["error"]
    with sqlite3.connect(graph.database) as raw:
        raw.execute("DROP TABLE Meta")
    assert "missing its metadata table" in graph.call({"op": "schema"}, success=False)["error"]


def contention(graph):
    graph.seed()
    raw = sqlite3.connect(graph.database, isolation_level=None)
    process = None
    try:
        raw.execute("BEGIN IMMEDIATE")
        process = graph.start({"op": "observe", "id": "other", "payload": "Grace"})
        time.sleep(0.25)
        assert process.poll() is None, "writer did not wait for the existing transaction"
        raw.execute("COMMIT")
        stdout, stderr = process.communicate(timeout=15)
        assert process.returncode == 0, (stdout, stderr)
        assert json.loads(stdout)["input_revision"] == 1
    finally:
        raw.close()
        if process is not None and process.poll() is None:
            process.kill()
            process.communicate(timeout=5)

    # An established WAL reader retains its snapshot while a writer commits.
    with sqlite3.connect(graph.database, isolation_level=None) as reader:
        reader.execute("BEGIN")
        old = reader.execute("SELECT value FROM Meta WHERE key='revision'").fetchone()
        graph.call({"op": "observe", "id": "other", "payload": "Grace revised"})
        assert reader.execute("SELECT value FROM Meta WHERE key='revision'").fetchone() == old
        reader.execute("ROLLBACK")
        assert reader.execute("SELECT value FROM Meta WHERE key='revision'").fetchone() != old


def crash(graph):
    graph.seed()
    # Kill a child holding a partly written transaction. The graph must reopen
    # at its last committed revision, not adopt the child's partial metadata.
    child = subprocess.Popen(
        [sys.executable, "-u", "-c", """
import sqlite3, sys, time
db = sqlite3.connect(sys.argv[1], isolation_level=None)
db.execute('BEGIN IMMEDIATE')
db.execute("UPDATE Meta SET value='999999' WHERE key='revision'")
print('uncommitted', flush=True)
time.sleep(30)
""", str(graph.database)],
        text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    try:
        assert child.stdout.readline().strip() == "uncommitted"
    finally:
        child.kill()
        child.communicate(timeout=5)
    assert graph.call({"op": "schema"})["revision"] == 3
    assert graph.call({"op": "value", "id": "p1"})["name"] == "Ada"


def main():
    binary = str(pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "graph/src/main").resolve())
    for witness in (upgrades, contention, crash):
        with tempfile.TemporaryDirectory(prefix="avra-graph-durable-") as directory:
            witness(Graph(pathlib.Path(directory), binary))
    print("durability: additive upgrades, future/missing-format refusal, WAL, writer wait, reader snapshot, and killed-transaction rollback passed")


if __name__ == "__main__":
    main()
