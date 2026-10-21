#!/usr/bin/env python3
"""Records the planner's closed decisions on development questions, with gold labels.

    python3 graph/planner/bench/record.py [--only q01,q07]

For each question in gold.jsonl, a graph is built at the question's
checkpoint from the oracle's facts, and the structured planner walks with a
chooser that takes the labelled option at each decision. Every decision is
written to decisions.jsonl with its exact context, question, options and the
index of the gold option. A label that matches no option stops with the
options it was offered, so labels are written against what the planner
actually asks. Held-out questions are refused. No model is loaded.
"""
import argparse
import datetime
import json
import pathlib
import re
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent.parent
sys.path.insert(0, str(HERE.parent))
sys.path.insert(0, str(ROOT / "graph/acceptance"))
import score  # noqa: E402
import structured  # noqa: E402
from plan import Graph  # noqa: E402


class Gold:
    """Takes the option holding the next label; records every decision."""

    def __init__(self, question_id, labels, needed):
        self.id, self.labels, self.needed = question_id, list(labels), set(needed)
        self.decisions, self.pending = [], None

    def choose(self, context, question, options):
        if self.pending and self.pending[0] == question and sorted(self.pending[1]) == sorted(options):
            gold = self.pending[2]
            self.pending = None
            return [1.0 if o == gold else 0.0 for o in options]
        need = re.match(r"Does the answer need their (\w+)", question)
        if need:
            gold = "yes" if need.group(1) in self.needed else "no"
        else:
            if not self.labels:
                raise SystemExit(f"{self.id}: no label left for: {question}\n  options: {options}")
            label = self.labels.pop(0)
            hits = [o for o in options if label in o]
            if len(hits) != 1:
                raise SystemExit(f"{self.id}: label {label!r} matches {len(hits)} of: {question}\n  options: {options}")
            gold = hits[0]
        self.decisions.append({"question_id": self.id, "context": context, "question": question,
                               "options": options, "gold": options.index(gold)})
        self.pending = (question, options, gold)
        return [1.0 if o == gold else 0.0 for o in options]


def graph_at(checkpoint, scratch, fixture):
    """A graph holding the oracle's facts for every source up to the checkpoint."""
    manifest, sources, _, _ = fixture
    app = score.App(score.BINARY, scratch / f"bench-{checkpoint}.db", scratch)
    schema = app.call({"op": "schema"})
    for s in score.prefix_of(sources, checkpoint):
        receipt = app.call({"op": "ingest", "source": score.envelope(s)})
        failure = receipt.get("error") or score.publish_source(app, "oracle-facts", {}, s, schema,
                                                               receipt.get("graph_revision", 0))
        if failure:
            raise SystemExit(f"checkpoint {checkpoint}: {s['id']}: {failure}")
    return app, manifest, app.call({"op": "schema"})


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--only", help="comma-separated question ids")
    args = parser.parse_args()
    fixture = score.load_fixture()
    questions = {q["id"]: q for q in fixture[3]}
    heldout = set(json.loads((ROOT / "graph/acceptance/split.json").read_text())["heldout"])
    gold = [json.loads(l) for l in (HERE / "gold.jsonl").read_text().splitlines() if l.strip()]
    only = set(args.only.split(",")) if args.only else None
    decisions, graphs = [], {}
    with tempfile.TemporaryDirectory(prefix="planner-bench-") as scratch:
        for row in gold:
            if only and row["id"] not in only:
                continue
            if row["id"] in heldout:
                raise SystemExit(f"{row['id']} is held out; the bench holds development questions only")
            q = questions[row["id"]]
            if q["checkpoint"] not in graphs:
                graphs[q["checkpoint"]] = graph_at(q["checkpoint"], pathlib.Path(scratch), fixture)
            app, manifest, schema = graphs[q["checkpoint"]]
            context = score.question_context(q, manifest, schema.get("revision", 0), None)
            locate = score.locator(app, fixture[2])
            context = {**context, **{k: locate(context[k]) for k in ("principal", "speaker") if context[k]}}
            chooser = Gold(row["id"], row["choices"], row.get("needed", []))
            cypher = structured.plan(chooser, q["question"], schema, context,
                                     Graph([str(app.binary), "request", "--db", str(app.db)]).search)
            if chooser.labels:
                raise SystemExit(f"{row['id']}: labels left unused: {chooser.labels}\n  composed: {cypher}")
            if row.get("cypher") and row["cypher"] != cypher:
                raise SystemExit(f"{row['id']}: gold walk composed\n  {cypher}\n  not\n  {row['cypher']}")
            print(f"{row['id']}: {len(chooser.decisions)} decisions: {cypher}")
            decisions += chooser.decisions
    commit = subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=ROOT, text=True, capture_output=True).stdout.strip()
    header = {"recorded": datetime.datetime.now().isoformat(timespec="seconds"), "commit": commit,
              "binary": str(score.BINARY), "questions": sorted({d["question_id"] for d in decisions})}
    out = HERE / "decisions.jsonl"
    out.write_text("\n".join(json.dumps(r) for r in [header, *decisions]) + "\n")
    print(f"{len(decisions)} decisions -> {out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
