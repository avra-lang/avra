#!/usr/bin/env python3
"""Derives the fast slice: the fewest development questions that cover every
question type and every source kind the development questions can reach.

A question's type is (split category, expected status, whether it follows a
previous question). A source kind is reached through the sources a question
cites as evidence. Greedy set cover over those elements: each round takes the
question covering the most uncovered elements, ties to the lower checkpoint
(fewer sources to extract), then to the lower id. Held-out questions never
enter. Writes slices.json with the inputs' digests, so the slice is
reproducible from the fixture and stale when the fixture moves.
"""
import hashlib
import json
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE / "slices.json"


def rows(name):
    return [json.loads(l) for l in (HERE / name).read_text().splitlines() if l.strip()]


def digest(name):
    return hashlib.sha256((HERE / name).read_bytes()).hexdigest()


def cited(question):
    expect = question["expect"]
    groups = expect.get("evidence_any", [])
    return set(expect.get("evidence_all", [])) | {s for g in groups for s in (g if isinstance(g, list) else [g])}


def elements(question, split, kinds):
    kind = ("type", split["categories"][question["id"]], question["expect"]["status"],
            bool(question.get("context", {}).get("previous_question")))
    return {kind} | {("kind", kinds[s]) for s in cited(question)}


def select(questions, split, kinds):
    held = set(split["heldout"])
    pool = {q["id"]: (q, elements(q, split, kinds)) for q in questions if q["id"] not in held}
    universe = set().union(*(e for _, e in pool.values()))
    covered, picked = set(), []
    while covered != universe:
        best = max(sorted(pool), key=lambda i: (len(pool[i][1] - covered), -pool[i][0]["checkpoint"]))
        picked.append(best)
        covered |= pool[best][1]
    return picked, universe, pool


def main():
    questions, sources, split = rows("questions.jsonl"), rows("sources.jsonl"), json.loads((HERE / "split.json").read_text())
    kinds = {s["id"]: s["kind"] for s in sources}
    picked, universe, pool = select(questions, split, kinds)
    checkpoint = max(pool[i][0]["checkpoint"] for i in picked)
    all_kinds = {s["kind"] for s in sources}
    reached = {k[1] for k in universe if k[0] == "kind"}
    out = {
        "fast": sorted(picked),
        "provenance": {
            "script": "select_slice.py",
            "rule": "greedy set cover over (type, source kind) elements of development questions; "
                    "ties to the lower checkpoint, then the lower id",
            "inputs": {n: digest(n) for n in ("questions.jsonl", "sources.jsonl", "split.json")},
            "elements": len(universe),
            "checkpoint": checkpoint,
            "sources_extracted": checkpoint,
            "kinds_not_cited_by_any_development_question": sorted(all_kinds - reached),
        },
    }
    OUT.write_text(json.dumps(out, indent=1) + "\n")
    print(json.dumps(out, indent=1))


if __name__ == "__main__":
    sys.exit(main())
