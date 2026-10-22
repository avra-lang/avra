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
    def __init__(self, root, binary, bare=None):
        self.root, self.binary, self.bare = root, binary, bare
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
    for version in ("6", "7", "8", "9", "10", "11", "12", "13"):
        with sqlite3.connect(graph.database) as raw:
            raw.execute("DROP TABLE ProposalDecisionRow")
            raw.execute("DROP TABLE UnplacedRow")
            if version != "13":
                raw.execute("DROP TABLE ClaimRetiredRow")
                raw.execute("DROP TABLE SchemaEdgeRow")
            if version not in ("12", "13"):
                raw.execute("DROP TABLE InputEpochRow")
            if version not in ("11", "12", "13"):
                raw.execute("DROP TABLE FailedRunRow")
            if version not in ("10", "11", "12", "13"):
                raw.execute("DROP TABLE CorrectionEndRow")
                raw.execute("DROP TABLE CorrectionRow")
            if version not in ("9", "10", "11", "12", "13"):
                raw.execute("DROP TABLE SupersessionRow")
                raw.execute("DROP TABLE EvidenceRow")
                raw.execute("DROP TABLE VoiceRow")
            if version not in ("8", "9", "10", "11", "12", "13"):
                raw.execute("DROP TABLE ChoiceEndRow")
                raw.execute("DROP TABLE ChoiceRow")
            if version == "6":
                raw.execute("DROP TABLE ConfidenceRow")
            raw.execute("UPDATE Meta SET value=? WHERE key='format'", (version,))
        assert graph.call({"op": "value", "id": "p1"})["name"] == "Ada"
        [legacy] = graph.call({"op": "explain", "id": "p1", "property": "name"})
        assert (legacy["factuality"], legacy["speech_act"], legacy["anchors"], legacy["active"]) == ("CT+", "assert", [], True)
        assert graph.call(publication) == committed
        assert graph.call({"op": "value", "id": "p1", "as_of": {"revision": committed["revision"]}})["name"] == "Ada"
        with sqlite3.connect(graph.database) as raw:
            assert raw.execute("SELECT value FROM Meta WHERE key='format'").fetchone() == ("14",)
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
        raw.execute("UPDATE Meta SET value='14' WHERE key='format'")
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


def corrections(graph):
    graph.seed()
    wrong = {"op": "correct", "id": "c1", "decider": "user", "kind": "wrong",
             "entity": "p1", "property": "name", "value": "Ada"}
    first = graph.call(wrong)
    assert graph.call(wrong) == first, "a correction replays by id across processes"
    [ada] = graph.call({"op": "get", "id": "p1"})["fields"]["name"]
    assert ada["denied"] is True
    assert "denied" in graph.call({"op": "value", "id": "p1"}, success=False)["error"]
    graph.call({"op": "uncorrect", "id": "c1"})
    [ada] = graph.call({"op": "get", "id": "p1"})["fields"]["name"]
    assert ada["denied"] is False
    [logged] = graph.call({"op": "corrections"})
    assert logged["kind"] == "wrong" and logged["until_revision"] > 0
    assert logged["request"]["value"] == "Ada" and logged["effects"]["run"] == "correct:c1"
    assert logged["before"]["entity"]["entity"]["fields"]["name"][0]["denied"] is False
    assert logged["after"]["entity"]["entity"]["fields"]["name"][0]["denied"] is True
    assert "undone" in graph.call(wrong, success=False)["error"]
    with sqlite3.connect(graph.database) as raw:
        assert raw.execute("SELECT count(*) FROM CorrectionRow").fetchone() == (1,)
        assert raw.execute("SELECT count(*) FROM CorrectionEndRow").fetchone() == (1,)


def evolution(graph):
    """A catalog that drops every model, with no migration declared, is
    refused by another process and leaves the store exactly as it was."""
    graph.seed()
    with sqlite3.connect(graph.database) as raw:
        before = raw.execute("SELECT key, value FROM Meta ORDER BY key").fetchall()
    bare = Graph(graph.root, graph.bare)
    refused = bare.call({"op": "schema"}, success=False)
    assert "needs a declared migration" in refused["error"], refused
    with sqlite3.connect(graph.database) as raw:
        assert raw.execute("SELECT key, value FROM Meta ORDER BY key").fetchall() == before
        assert raw.execute("SELECT count(*) FROM SchemaEdgeRow").fetchone() == (0,)
    assert graph.call({"op": "value", "id": "p1"})["name"] == "Ada"


def main():
    binary = str(pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "graph/examples/notes/src/main").resolve())
    bare = str(pathlib.Path(sys.argv[2] if len(sys.argv) > 2 else "graph/src/main").resolve())
    for witness in (upgrades, contention, crash, corrections, evolution):
        with tempfile.TemporaryDirectory(prefix="avra-graph-durable-") as directory:
            witness(Graph(pathlib.Path(directory), binary, bare))
    print("durability: additive upgrades, corrections across processes, refused catalog drops, future/missing-format refusal, WAL, writer wait, reader snapshot, and killed-transaction rollback passed")


if __name__ == "__main__":
    main()
