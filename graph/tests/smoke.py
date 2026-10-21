#!/usr/bin/env python3
"""Native CLI persistence and authenticated HTTP exercise, in a private temp tree."""
import json
import pathlib
import socket
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request


def structured_sources(call, identity):
    source = {
        "contract": 2, "source": {"observation": identity, "revision": 1},
        "authored_at_ms": 0, "received_at_ms": 100, "author": "actor:a",
        "participants": ["actor:a", "actor:b"], "conversation": "thread:1",
        "media_type": "text/plain", "content": "Aé🙂Z",
        "frames": [{"id": "quote", "passage": {"selector": [
                        {"kind": "TextPositionSelector", "start": 1, "end": 3},
                        {"kind": "TextQuoteSelector", "exact": "é🙂"}]},
                    "parent": None, "speaker": "actor:b"}],
    }
    admitted = call({"op": "ingest", "source": source})
    assert admitted["changed"] and admitted["source"] == source["source"]
    replay = call({"op": "ingest", "source": {**source, "received_at_ms": 999}})
    assert replay == {**admitted, "changed": False}
    current = call({"op": "source", "id": identity})
    assert current == source
    changed = {**source, "source": {**source["source"], "revision": 2}, "author": "actor:c"}
    updated = call({"op": "ingest", "source": changed})
    assert updated["changed"] and updated["graph_revision"] == admitted["graph_revision"] + 1
    assert call({"op": "source", "id": identity, "revision": 1}) == source
    assert call({"op": "source", "id": identity}) == changed
    historical = call({"op": "ingest", "source": source})
    assert not historical["changed"] and historical["source"]["revision"] == 1
    assert historical["graph_revision"] == updated["graph_revision"]
    assert "error" in call({"op": "ingest", "source": {**source, "content": "altered"}}, success=False)
    assert "error" in call({"op": "ingest", "source": {**changed, "gold_answers": []}}, success=False)
    assert call({"op": "schema"})["revision"] == updated["graph_revision"]


def main():
    binary = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "graph/examples/notes/src/main").resolve()
    with tempfile.TemporaryDirectory(prefix="avra-graph-") as directory:
        root = pathlib.Path(directory)
        database = root / "graph.db"
        request_file = root / "request.json"

        def cli(request, success=True):
            request_file.write_text(json.dumps(request))
            result = subprocess.run(
                [str(binary), "request", "--db", str(database), str(request_file)],
                text=True, capture_output=True, timeout=15,
            )
            assert (result.returncode == 0) == success, (result.returncode, result.stdout, result.stderr)
            return json.loads(result.stdout)

        schema = cli({"op": "schema"})
        assert {m["name"] for m in schema["models"]} == {"Person", "Message", "WorkItem"}
        observed = cli({"op": "observe", "id": "mail:1", "payload": "Ada: review the design."})
        publication = {
            "op": "publish", "id": "run:1", "producer": "classifier-v1", "scope": "mail:1",
            "input": "mail:1", "input_revision": observed["input_revision"],
            "schema": schema["fingerprint"], "expected_revision": observed["revision"],
            "records": [
                {"id": "p1", "model": "Person", "identities": [{"namespace": "mail", "key": "ada@example.com"}],
                 "value": {"name": "Ada"}},
                {"id": "m1", "model": "Message", "value": {"author": "p1", "recipients": [], "body": "review the design"}},
                {"id": "w1", "model": "WorkItem", "locator": {"section": "title"},
                 "value": {"title": "Review the design", "assignee": "p1", "messages": ["m1"]}},
            ],
        }
        published = cli(publication)
        assert cli(publication) == published
        assert cli({"op": "value", "id": "w1"})["status"] == "open"
        assert "status" not in cli({"op": "get", "id": "w1"})["fields"]
        assert set(cli({"op": "traverse", "id": "w1"})) == {"w1", "m1", "p1"}
        assert len(cli({"op": "edges", "id": "p1", "incoming": True})) == 2
        assert cli({"op": "explain", "id": "p1", "property": "name"})[0]["active"]
        assert cli({"op": "explain", "id": "p1", "property": "name"})[0]["locator"] is None
        assert cli({"op": "resolve", "namespace": "mail", "key": "ada@example.com"})["entity"] == "p1"
        assert cli({"op": "aliases", "id": "p1"}) == [{"namespace": "mail", "key": "ada@example.com"}]
        assert cli({"op": "aliases", "id": "w1"}) == []
        assert "error" in cli({"op": "resolve", "namespace": "mail", "key": "nobody@example.com"}, success=False)
        assert "error" in cli({"op": "publish", "id": "rebind", "producer": "other-agent", "scope": "other:1",
                               "input": "mail:1", "input_revision": 1, "schema": schema["fingerprint"],
                               "expected_revision": published["revision"],
                               "records": [{"id": "p2", "model": "Person", "identities": [{"namespace": "mail", "key": "ada@example.com"}],
                                            "value": {"name": "Grace"}}]}, success=False)
        assert cli({"op": "explain", "id": "w1", "property": "assignee"})[0]["locator"] == {"section": "title"}
        moved = {**publication, "records": [
            {**record, "locator": {"section": "metadata"}} if record["id"] == "w1" else record
            for record in publication["records"]
        ]}
        assert "error" in cli(moved, success=False)
        assert cli({"op": "schema"})["revision"] == published["revision"]

        second = {"id": "p2", "model": "Person", "mode": "partial", "value": {"email": "grace@example.com"},
                  "identities": [{"namespace": "mail", "key": "grace@example.com"}]}
        cli({"op": "publish", "id": "run:2", "producer": "directory-agent", "scope": "directory:1",
             "input": "mail:1", "input_revision": 1, "schema": schema["fingerprint"],
             "expected_revision": published["revision"], "records": [second]})
        merged = cli({"op": "merge", "id": "merge:1", "left": "p1", "right": "p2", "decider": "smoke"})
        assert cli({"op": "merges", "id": "p1"})[0]["active"] is True
        assert set(cli({"op": "get", "id": "p2"})["fields"]) == {"email", "name"}
        assert cli({"op": "find", "model": "Person"}) == ["p1"]
        assert cli({"op": "merge", "id": "merge:1", "left": "p1", "right": "p2", "decider": "smoke"})["revision"] == merged["revision"]
        assert "error" in cli({"op": "merge", "id": "merge:bad", "left": "p1", "right": "w1", "decider": "smoke"}, success=False)
        split = cli({"op": "split", "id": "merge:1"})
        assert set(cli({"op": "get", "id": "p2"})["fields"]) == {"email"}
        assert cli({"op": "merges", "id": "p1"})[0]["active"] is False
        assert cli({"op": "split", "id": "merge:1"})["revision"] == split["revision"]

        cli({"op": "tombstone", "id": "gone:1", "entity": "p2", "decider": "smoke"})
        assert "error" in cli({"op": "get", "id": "p2"}, success=False)
        assert "error" in cli({"op": "value", "id": "p2"}, success=False)
        assert cli({"op": "find", "model": "Person"}) == ["p1"]
        assert "error" in cli({"op": "resolve", "namespace": "mail", "key": "grace@example.com"}, success=False)
        assert cli({"op": "tombstones", "id": "p2"})[0]["active"] is True
        assert "error" in cli({"op": "publish", "id": "onto-gone", "producer": "other-agent", "scope": "other:2",
                               "input": "mail:1", "input_revision": 1, "schema": schema["fingerprint"],
                               "expected_revision": cli({"op": "schema"})["revision"],
                               "records": [{"id": "p2", "model": "Person", "mode": "partial",
                                            "value": {"email": "grace@example.com"}}]}, success=False)
        revived = cli({"op": "revive", "id": "gone:1"})
        assert cli({"op": "find", "model": "Person"}) == ["p1", "p2"]
        assert cli({"op": "tombstones", "id": "p2"})[0]["active"] is False
        assert cli({"op": "revive", "id": "gone:1"})["revision"] == revived["revision"]
        settled = cli({"op": "schema"})["revision"]

        invalid = {**publication, "id": "bad", "expected_revision": settled,
                   "records": [{"id": "bad-person", "model": "Person", "value": {"name": ""}}]}
        assert "error" in cli(invalid, success=False)
        assert cli({"op": "schema"})["revision"] == settled
        assert "error" in cli({"op": "get", "id": "bad-person"}, success=False)

        partial = {
            **publication, "id": "partial:status", "producer": "status-agent", "scope": "partial:w2",
            "expected_revision": settled,
            "records": [{"id": "w2", "model": "WorkItem", "mode": "partial", "value": {"status": "done"}}],
        }
        partial_revision = cli(partial)
        assert cli(partial) == partial_revision
        assert set(cli({"op": "get", "id": "w2"})["fields"]) == {"status"}
        assert "error" in cli({"op": "value", "id": "w2"}, success=False)
        title = {
            **partial, "id": "partial:title", "producer": "title-agent",
            "expected_revision": partial_revision["revision"],
            "records": [{"id": "w2", "model": "WorkItem", "mode": "partial", "value": {"title": "Review"}}],
        }
        title_revision = cli(title)
        assert cli({"op": "value", "id": "w2"})["status"] == "done"
        assert "error" in cli({
            **title, "id": "bad:mode", "expected_revision": title_revision["revision"],
            "records": [{"id": "w2", "model": "WorkItem", "mode": "patch", "value": {"title": "Review"}}],
        }, success=False)

        token = "test-only-token-for-local-graph-smoke"
        token_file = root / "token"
        token_file.write_text(token)
        token_file.chmod(0o600)
        with socket.socket() as sock:
            sock.bind(("127.0.0.1", 0))
            port = sock.getsockname()[1]
        server = subprocess.Popen(
            [str(binary), "serve", "--db", str(database), "--port", str(port), "--token-file", str(token_file)],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
        )

        def http(request, authenticated=True, media="application/json"):
            headers = {"Content-Type": media}
            if authenticated:
                headers["Authorization"] = "Bearer " + token
            wire = urllib.request.Request(f"http://127.0.0.1:{port}/graph", json.dumps(request).encode(), headers)
            try:
                with urllib.request.urlopen(wire, timeout=3) as response:
                    return response.status, response.read()
            except urllib.error.HTTPError as error:
                return error.code, error.read()

        try:
            deadline = time.monotonic() + 10
            while True:
                try:
                    status, body = http({"op": "schema"})
                    break
                except urllib.error.URLError:
                    if server.poll() is not None or time.monotonic() > deadline:
                        raise AssertionError("server did not start")
                    time.sleep(0.05)
            assert status == 200, body
            assert json.loads(body)["fingerprint"] == schema["fingerprint"]
            assert http({"op": "schema"}, authenticated=False)[0] == 401
            assert http({"op": "schema"}, media="text/plain")[0] == 415
            assert http({"op": "unknown"})[0] == 400
            status, body = http({"op": "value", "id": "w1"})
            assert status == 200 and json.loads(body)["assignee"] == "p1"
            status, body = http({
                **partial, "id": "partial:http", "producer": "http-agent",
                "expected_revision": title_revision["revision"],
                "records": [{"id": "w2", "model": "WorkItem", "mode": "partial", "value": {"assignee": None}}],
            })
            assert status == 200, body
            status, body = http({"op": "get", "id": "w2"})
            assert status == 200 and json.loads(body)["fields"]["assignee"][0]["value"] is None
            status, body = http({"op": "resolve", "namespace": "mail", "key": "ada@example.com"})
            assert status == 200 and json.loads(body)["entity"] == "p1"

            def authenticated(request, success=True):
                status, body = http(request)
                assert (status == 200) == success, (status, body)
                return json.loads(body)

            structured_sources(authenticated, "http:structured")
        finally:
            server.terminate()
            try:
                server.communicate(timeout=5)
            except subprocess.TimeoutExpired:
                server.kill()
                server.communicate(timeout=5)

        changed = cli({"op": "observe", "id": "mail:1", "payload": "The message was edited."})
        assert changed["input_revision"] == 2
        assert cli({"op": "find", "model": "WorkItem"}) == []
        assert len(cli({"op": "dirty"})) == 5
        assert not cli({"op": "explain", "id": "p1", "property": "name"})[0]["active"]
        assert "error" in cli({**publication, "id": "stale", "expected_revision": changed["revision"]}, success=False)

        import sqlite3
        with sqlite3.connect(database) as raw:
            assert raw.execute("SELECT value FROM Meta WHERE key='format'").fetchone()[0] == "9"
            for table in ("Meta", "EntityRow", "RunRow", "ClaimRow", "SupportRow", "AliasRow", "MergeRow", "TombstoneRow"):
                assert raw.execute("SELECT name FROM sqlite_master WHERE type='table' AND name=?", (table,)).fetchone()
        assert cli({"op": "explain", "id": "p1", "property": "name"})[0]["locator"] is None
        assert cli({"op": "aliases", "id": "p1"}) == []
        decisions = cli({"op": "merges"})
        assert len(decisions) == 1 and decisions[0]["active"] is False
        graves = cli({"op": "tombstones"})
        assert len(graves) == 1 and graves[0]["active"] is False
        structured_sources(cli, "cli:structured")
    print("native smoke: persistence, partial assertions, evidence locators, external identities, merge/split, tombstones, std-first store, replay, validation, rollback, traversal, HTTP auth, structured source revisions, and stale-input invalidation passed")


if __name__ == "__main__":
    main()
