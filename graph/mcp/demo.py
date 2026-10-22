#!/usr/bin/env python3
"""Feeds the slice's messages to a graph host over MCP and asks it questions.

    python3 graph/mcp/demo.py --binary <app> --db <db>

Starts `<app> mcp` with the planner and extractor commands and a launch grant
for ingest, speaks MCP to it, ingests five sources through the `ingest` tool,
then asks four questions through the `ask` tool and prints each answer as the
graph returns it. Needs the model service (see graph/QUICKSTART.md).
"""
import argparse
import importlib.util
import json
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(ROOT / "graph/acceptance"))
import score  # noqa: E402

spec = importlib.util.spec_from_file_location("roundtrip", HERE / "roundtrip.py")
roundtrip = importlib.util.module_from_spec(spec)
spec.loader.exec_module(roundtrip)

SOURCES = ("s01", "s02", "s09", "s22", "s30")
QUESTIONS = (
    ("Who is my wife?", None),
    ("When did my wife ask me to book dinner for?", None),
    ("Did I actually book that Friday dinner?", None),
    ("Who is my wife?", "alex-chen"),
)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--binary", required=True)
    parser.add_argument("--db", required=True)
    parser.add_argument("--planner", default="python3 graph/planner/plan.py")
    parser.add_argument("--extractor", default="python3 graph/extract/cascade.py --catalog {schema}")
    args = parser.parse_args()
    fixture = score.load_fixture()
    by_id = {s["id"]: s for s in fixture[1]}
    client = roundtrip.Client([args.binary, "mcp", "--db", args.db, "--planner", args.planner, "--extractor",
                               args.extractor, "--grantor", "owner", "--agent", "demo", "--grant", "ingest"])
    client.call("initialize", {"protocolVersion": "2025-06-18", "capabilities": {},
                               "clientInfo": {"name": "demo", "version": "1"}})
    print("tools:", [t["name"] for t in client.call("tools/list")["tools"]])
    for source_id in SOURCES:
        done = client.tool("ingest", source=json.dumps(score.envelope(by_id[source_id])))
        print(f"ingest {source_id}:", json.dumps(done)[:200])
    app = score.App(pathlib.Path(args.binary), pathlib.Path(args.db), pathlib.Path(args.db).parent)
    who = score.locator(app, fixture[2])
    for question, speaker in QUESTIONS:
        asked = {"question": question, "principal": who("person:rowan")}
        if speaker:
            asked["speaker"] = who(f"person:{speaker}")
        answer = client.tool("ask", **asked)
        print(f"\nQ: {question}" + (f"   (as {speaker})" if speaker else ""))
        print("cypher:", answer["cypher"])
        print(json.dumps(answer["answer"], indent=2))
    client.close()


if __name__ == "__main__":
    main()
