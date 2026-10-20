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


def main():
    binary = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "graph/src/main").resolve()
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
                {"id": "p1", "model": "Person", "value": {"name": "Ada"}},
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
        assert cli({"op": "explain", "id": "w1", "property": "assignee"})[0]["locator"] == {"section": "title"}
        moved = {**publication, "records": [
            {**record, "locator": {"section": "metadata"}} if record["id"] == "w1" else record
            for record in publication["records"]
        ]}
        assert "error" in cli(moved, success=False)
        assert cli({"op": "schema"})["revision"] == published["revision"]

        invalid = {**publication, "id": "bad", "expected_revision": published["revision"],
                   "records": [{"id": "bad-person", "model": "Person", "value": {"name": ""}}]}
        assert "error" in cli(invalid, success=False)
        assert cli({"op": "schema"})["revision"] == published["revision"]
        assert "error" in cli({"op": "get", "id": "bad-person"}, success=False)

        partial = {
            **publication, "id": "partial:status", "producer": "status-agent", "scope": "partial:w2",
            "expected_revision": published["revision"],
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
        assert len(cli({"op": "dirty"})) == 4
        assert not cli({"op": "explain", "id": "p1", "property": "name"})[0]["active"]
        assert "error" in cli({**publication, "id": "stale", "expected_revision": changed["revision"]}, success=False)

        import sqlite3
        with sqlite3.connect(database) as raw:
            raw.execute("DROP TABLE evidence")
            raw.execute("UPDATE graph_meta SET value='1' WHERE key='format'")
        assert cli({"op": "schema"})["fingerprint"] == schema["fingerprint"]
        with sqlite3.connect(database) as raw:
            assert raw.execute("SELECT value FROM graph_meta WHERE key='format'").fetchone()[0] == "2"
            assert raw.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='evidence'").fetchone()
        assert cli({"op": "explain", "id": "p1", "property": "name"})[0]["locator"] is None
    print("native smoke: persistence, partial assertions, evidence locators, format migration, replay, validation, rollback, traversal, HTTP auth, and stale-input invalidation passed")


if __name__ == "__main__":
    main()
