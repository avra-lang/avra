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
import hashlib
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
from choices import walk  # noqa: E402
from plan import Graph  # noqa: E402


def labeller(question_id, labels, needed):
    """The gold option for each decision: the option holding the next label, or
    for a property choice the next needed property (then "nothing else")."""
    labels, needed = list(labels), set(needed)

    def label(context, question, options):
        if question.startswith(("Which property does", "Which other property")):
            given = set(re.findall(r"the \w+'s (\w+)", context.partition("Already answering with:")[2]))
            wanted = [i for i, o in enumerate(options)
                      if (m := re.match(r"the \w+'s (\w+)", o)) and m.group(1) in needed - given]
            return wanted[0] if wanted else next(i for i, o in enumerate(options) if not re.match(r"the \w+'s ", o))
        if not labels:
            raise SystemExit(f"{question_id}: no label left for: {question}\n  options: {options}")
        hits = [i for i, o in enumerate(options) if labels[0] in o]
        if len(hits) != 1:
            raise SystemExit(f"{question_id}: label {labels[0]!r} matches {len(hits)} of: {question}\n  options: {options}")
        labels.pop(0)
        return hits[0]

    label.unused = labels
    return label


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
            label = labeller(row["id"], row["choices"], row.get("needed", []))
            graph = Graph([str(app.binary), "request", "--db", str(app.db)])
            cypher, made = walk(q["question"], schema, context, label, graph.search, None, graph.model_of)
            if label.unused:
                raise SystemExit(f"{row['id']}: labels left unused: {label.unused}\n  composed: {cypher}")
            if row.get("cypher") and row["cypher"] != cypher:
                raise SystemExit(f"{row['id']}: gold walk composed\n  {cypher}\n  not\n  {row['cypher']}")
            print(f"{row['id']}: {len(made)} decisions: {cypher}")
            decisions += [{"question_id": row["id"], **d} for d in made]
    commit = subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=ROOT, text=True, capture_output=True).stdout.strip()
    header = {"recorded": datetime.datetime.now().isoformat(timespec="seconds"), "commit": commit,
              "binary": str(score.BINARY), "binary_sha256": hashlib.sha256(score.BINARY.read_bytes()).hexdigest(),
              "questions": sorted({d["question_id"] for d in decisions})}
    out = HERE / "decisions.jsonl"
    out.write_text("\n".join(json.dumps(r) for r in [header, *decisions]) + "\n")
    print(f"{len(decisions)} decisions -> {out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
