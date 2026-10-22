#!/usr/bin/env python3
"""An MCP client round trip against a graph host's `mcp` command.

    python3 graph/mcp/roundtrip.py [--ask "Who is my wife?" --principal <id>]

Builds a graph from the acceptance oracle's facts (as the scorer does),
starts `<app> mcp` on it as a stdio MCP server, and speaks MCP to it:
initialize, tools/list, then schema, search, explain and (with --ask, when
the shared model service is up) ask; then again under a launch grant,
checking the grant is listed and the write is audited under it. Prints each exchange; exits 1 on a
protocol or tool error.
"""
import argparse
import json
import pathlib
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(ROOT / "graph/acceptance"))
import score  # noqa: E402


class Client:
    def __init__(self, argv):
        self.proc = subprocess.Popen(argv, stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True, cwd=ROOT)
        self.next = 0

    def call(self, method, params=None):
        self.next += 1
        self.proc.stdin.write(json.dumps({"jsonrpc": "2.0", "id": self.next, "method": method,
                                          "params": params or {}}) + "\n")
        self.proc.stdin.flush()
        reply = json.loads(self.proc.stdout.readline())
        if "error" in reply:
            raise SystemExit(f"{method}: {reply['error']}")
        return reply["result"]

    def tool(self, name, **arguments):
        result = self.call("tools/call", {"name": name, "arguments": arguments})
        text = result["content"][0]["text"]
        if result.get("isError"):
            raise SystemExit(f"{name}: {text}")
        return json.loads(text)

    def close(self):
        self.proc.stdin.close()
        self.proc.wait(timeout=30)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ask")
    parser.add_argument("--principal", default="")
    parser.add_argument("--speaker")
    parser.add_argument("--planner", default="python3 graph/planner/plan.py --structured")
    args = parser.parse_args()
    fixture = score.load_fixture()
    with tempfile.TemporaryDirectory(prefix="graph-mcp-") as scratch:
        app = score.App(score.BINARY, pathlib.Path(scratch) / "g.db", pathlib.Path(scratch))
        schema = app.call({"op": "schema"})
        for s in score.prefix_of(fixture[1], 30):
            receipt = app.call({"op": "ingest", "source": score.envelope(s)})
            failure = receipt.get("error") or score.publish_source(app, "oracle-facts", {}, s, schema,
                                                                   receipt.get("graph_revision", 0))
            if failure:
                raise SystemExit(f"{s['id']}: {failure}")
        argv = [str(score.BINARY), "mcp", "--db", str(app.db)] + (["--planner", args.planner] if args.ask else [])
        client = Client(argv)
        hello = client.call("initialize", {"protocolVersion": "2025-06-18", "capabilities": {},
                                           "clientInfo": {"name": "roundtrip", "version": "1"}})
        print("initialize:", hello["serverInfo"])
        tools = client.call("tools/list")["tools"]
        print("tools:", [t["name"] for t in tools])
        described = client.tool("schema")
        print("schema: models", len(described["models"]))
        found = client.tool("search", query="dinner", limit=3)
        print("search:", [p["text"][:60] for p in found["passages"]])
        fact = next(p for p in found["passages"] if p["kind"] == "fact")
        entity = client.tool("search", query="Elena", limit=1)
        print("explain:", json.dumps(client.tool("explain", id="oracle:elena", property="name"))[:200])
        refused = client.call("tools/call", {"name": "uncorrect", "arguments": {"id": "none"}})
        print("uncorrect:", refused["isError"], refused["content"][0]["text"])
        if args.ask:
            principal = args.principal or score.locator(app, fixture[2])("person:rowan")
            asked = {"question": args.ask, "principal": principal}
            if args.speaker:
                asked["speaker"] = args.speaker
            answer = client.tool("ask", **asked)
            print("ask:", answer["cypher"])
            print("   ->", json.dumps({k: answer["answer"].get(k) for k in ("status", "fields", "problems")})[:400])
        client.close()
        granted = Client(argv + ["--grant", "uncorrect", "--grantor", "roundtrip-owner", "--agent", "roundtrip"])
        granted.call("initialize", {"protocolVersion": "2025-06-18", "capabilities": {},
                                    "clientInfo": {"name": "roundtrip", "version": "1"}})
        listed = next(t for t in granted.call("tools/list")["tools"] if t["name"] == "uncorrect")
        grant = listed["_meta"]["avra/mandates"][0]
        print("granted:", grant["issuer"], "->", grant["subject"], grant["actions"])
        tried = granted.call("tools/call", {"name": "uncorrect", "arguments": {"id": "none"}})
        if "requires a mandate" in tried["content"][0]["text"]:
            raise SystemExit("uncorrect: refused under its grant")
        audit = granted.tool("mandates")
        write = next(w for m in audit if m["mandate"]["id"] == grant["id"] for w in m["writes"])
        print("audit:", grant["id"], write)
        granted.close()
        print("round trip ok; fact seen:", fact["text"][:50], "; entity search hits:", len(entity["passages"]))


if __name__ == "__main__":
    main()
