#!/usr/bin/env python3
"""Runs the planner free on the development questions and grades the plan it settles on.

    python3 graph/planner/bench/walks.py --config baseline,previews,beam3,both [--only q01,q07]

Each configuration walks every question in gold.jsonl against a graph built at
the question's checkpoint from the oracle's facts, with the shared model
service on PLANNER_SOCKET. A walk is right when the plan it settles on is the
gold plan; the plan's answer is also compared with the gold plan's answer
(equal field values). A walk that ends abstaining is wrong and counted apart.
Latency is the planning time per question, the view-time choice excluded.
Writes results/walks-<time>.json.
"""
import argparse
import datetime
import json
import pathlib
import subprocess
import sys
import tempfile
import time

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent.parent
sys.path.insert(0, str(HERE.parent))
sys.path.insert(0, str(ROOT / "graph/acceptance"))
import score  # noqa: E402
import beam  # noqa: E402
import structured  # noqa: E402
import record  # noqa: E402
from catalog import PARAMETERS  # noqa: E402
from plan import ChooseOnly, MODEL, HUB, SOCKET, Graph, Shared, params_of, remembered, shared_socket  # noqa: E402
from prompt import Budget, declared_context  # noqa: E402

CONFIGS = {
    "baseline": {"preview": False, "beam_k": 1, "beam_prune": False},
    "previews": {"preview": True, "beam_k": 1, "beam_prune": False},
    "beam3": {"preview": False, "beam_k": 3, "beam_prune": True},
    "both": {"preview": True, "beam_k": 3, "beam_prune": True},
    "beam1": {"preview": False, "beam_k": 1, "beam_prune": True},
    "both1": {"preview": True, "beam_k": 1, "beam_prune": True},
}


def values(answer):
    """The field values a query answered, order-free."""
    return sorted(json.dumps(f["value"], sort_keys=True) for f in answer.get("fields", []))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", default="baseline")
    parser.add_argument("--only")
    parser.add_argument("--rows", type=int, help="override preview_rows for this run")
    args = parser.parse_args()
    if not shared_socket():
        raise SystemExit(f"walks: no shared model answers on {SOCKET}")
    if args.rows is not None:
        PARAMETERS["preview_rows"] = args.rows
    fixture = score.load_fixture()
    questions = {q["id"]: q for q in fixture[3]}
    heldout = set(json.loads((ROOT / "graph/acceptance/split.json").read_text())["heldout"])
    gold = [json.loads(l) for l in (HERE / "gold.jsonl").read_text().splitlines() if l.strip()]
    only = set(args.only.split(",")) if args.only else None
    model = ChooseOnly(Shared(SOCKET))
    model.budget = Budget(declared_context(MODEL, HUB), PARAMETERS["answer_tokens"])
    names = args.config.split(",")
    rows, graphs = [], {}
    with tempfile.TemporaryDirectory(prefix="planner-walks-") as scratch:
        for row in gold:
            if (only and row["id"] not in only) or row["id"] in heldout:
                continue
            q = questions[row["id"]]
            if q["checkpoint"] not in graphs:
                graphs[q["checkpoint"]] = record.graph_at(q["checkpoint"], pathlib.Path(scratch), fixture)
            app, manifest, schema = graphs[q["checkpoint"]]
            context = score.question_context(q, manifest, schema.get("revision", 0), None)
            locate = score.locator(app, fixture[2])
            context = {**context, **{k: locate(context[k]) for k in ("principal", "speaker") if context[k]}}
            graph = Graph([str(app.binary), "request", "--db", str(app.db)])
            params = params_of(context)
            ask = lambda cypher: app.call({"op": "query", "cypher": cypher, "params": params})  # noqa: E731
            goal = values(ask(row["cypher"]))
            for name in names:
                PARAMETERS.update(CONFIGS[name])
                seek, read, probe = remembered(graph.search), remembered(graph.read), graph.prober(params)
                started = time.time()
                found = beam.candidates(model, lambda w: structured.plan(w, q["question"], schema, context, seek, None, read, probe), probe)
                ms = int((time.time() - started) * 1000)
                cypher = found[0].cypher if found else None
                got = values(ask(cypher)) if cypher else None
                out = {"config": name, "question_id": row["id"], "cypher": cypher, "gold": row["cypher"],
                       "right": cypher == row["cypher"], "answer_right": got == goal, "abstained": not found,
                       "finished": len(found), "ms": ms}
                rows.append(out)
                print(f"{name:<9} {row['id']} {'+' if out['right'] else '-'}{'a' if out['answer_right'] else ' '} {ms:>6} ms  {cypher}", flush=True)
    commit = subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=ROOT, text=True, capture_output=True).stdout.strip()
    summary = {}
    for name in names:
        mine = [r for r in rows if r["config"] == name]
        summary[name] = {"walks_right": sum(r["right"] for r in mine), "answers_right": sum(r["answer_right"] for r in mine),
                         "abstained": sum(r["abstained"] for r in mine), "questions": len(mine),
                         "mean_ms": round(sum(r["ms"] for r in mine) / max(len(mine), 1))}
        print(name, summary[name])
    out = HERE / "results" / f"walks-{time.strftime('%Y%m%dT%H%M%S')}.json"
    out.write_text(json.dumps({"commit": commit, "at": datetime.datetime.now().isoformat(timespec="seconds"),
                               "model": MODEL, "parameters": {k: PARAMETERS[k] for k in ("preview_rows", "beam_score", "rank_use")},
                               "configs": {n: CONFIGS[n] for n in names}, "summary": summary, "walks": rows}, indent=1))
    print("results:", out.relative_to(ROOT))


if __name__ == "__main__":
    main()
