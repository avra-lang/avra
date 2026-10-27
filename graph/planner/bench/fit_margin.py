#!/usr/bin/env python3
"""Fits the contrast margin on recorded candidates.

    python3 graph/planner/bench/fit_margin.py candidates.json --world dev/2 [--write]

For each margin the observed score gaps offer (every distinct gap of a
finished plan from its question's best, and zero), and for each choice of
last-round-only, the selection rule runs on every recorded question: plans
within the margin of the best are grouped by answer, one group is taken as is,
several are put to the model. A plan is right when its answer is the gold one.
The margin with the most right selections wins; a tie goes to the smaller
margin, then to the rule that asks the model less. Prints the table.
"""
import argparse
import json
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
PLANNER = HERE.parent
GYM = PLANNER.parent / "gym"
sys.path.insert(0, str(PLANNER))
sys.path.insert(0, str(GYM))
sys.path.insert(0, str(PLANNER / "train"))
import beam  # noqa: E402
import contrast  # noqa: E402
from catalog import PARAMETERS  # noqa: E402
from engine import App  # noqa: E402
from plan import ChooseOnly, HUB, MODEL, SOCKET, Graph, Shared, params_of, remembered  # noqa: E402
from prompt import Budget, declared_context  # noqa: E402
from sample import questions  # noqa: E402


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("candidates")
    parser.add_argument("--world", required=True)
    parser.add_argument("--write", action="store_true", help="record the fit in parameters.json")
    args = parser.parse_args()
    recorded = json.loads(pathlib.Path(args.candidates).read_text())
    items = {r["id"]: r for r in questions(argparse.Namespace(split=None, world=args.world))}
    model = ChooseOnly(Shared(SOCKET))
    model.budget = Budget(declared_context(MODEL, HUB), PARAMETERS["answer_tokens"])
    probes, correct = {}, {}
    for rec in recorded:
        item = items[rec["id"]]
        d = GYM / "out" / item["world_dir"]
        app = App(d / "app/src/main", d / "graph.db", d / "scratch")
        probes[rec["id"]] = Graph(app.argv).prober(params_of({"principal": item["params"]["asker"], "speaker": item["speaker"],
                                                              "question_at_ms": item["params"]["now"]}))
        correct[rec["id"]] = {p["cypher"]: p["correct"] for p in rec["plans"]}
    gaps = sorted({0.0} | {round(max(x["score"] for x in r["plans"]) - p["score"], 6) for r in recorded for p in r["plans"]})
    table = []
    for last in (False, True):
        for margin in gaps:
            right = asked = 0
            for rec in recorded:
                plans = [beam.Plan(p["cypher"], p["tally"], p["length"], tuple(p["steps"]), p["round"]) for p in rec["plans"]]
                if not plans:
                    continue
                plans.sort(key=beam.Plan.score, reverse=True)
                verdict = contrast.settle(model, f"Question: {items[rec['id']]['question']}", plans, probes[rec["id"]],
                                          PARAMETERS["preview_rows"], margin, last)
                asked += verdict.groups > 1
                right += bool(verdict.plan) and correct[rec["id"]][verdict.plan.cypher]
            table.append({"final_round": last, "margin": margin, "right": right, "asked_model": asked})
            print(table[-1], flush=True)
    best = min((t for t in table if t["right"] == max(x["right"] for x in table)), key=lambda t: (t["margin"], t["asked_model"]))
    print("best:", best, "of", len(recorded), "questions;", "oracle (any plan right):", sum(any(p["correct"] for p in r["plans"]) for r in recorded))
    if args.write:
        path = PLANNER / "parameters.json"
        d = json.loads(path.read_text())
        d["contrast_margin"]["value"] = best["margin"]
        d["contrast_final_round"]["value"] = best["final_round"]
        why = (f"fitted on {args.world}: {len(recorded)} questions, margin with the most right selections among the observed score gaps "
               f"(ties to the smaller margin), {best['right']} right; table in graph/planner/bench/results")
        d["contrast_margin"]["source"] = why
        d["contrast_final_round"]["source"] = why
        path.write_text(json.dumps(d, indent=1) + "\n")
    pathlib.Path(args.candidates).with_suffix(".fit.json").write_text(json.dumps({"table": table, "best": best}, indent=1))


if __name__ == "__main__":
    main()
