#!/usr/bin/env python3
"""Records every plan the beam finishes on gym questions, with its score, round and whether its answer is the gold one.

    python3 graph/planner/bench/candidates.py --world dev/2 --out candidates.json

The record lets a selection rule over the finished plans be evaluated without
walking again.
"""
import argparse
import json
import pathlib
import sys
import time

HERE = pathlib.Path(__file__).resolve().parent
PLANNER = HERE.parent
GYM = PLANNER.parent / "gym"
sys.path.insert(0, str(PLANNER))
sys.path.insert(0, str(GYM))
sys.path.insert(0, str(PLANNER / "train"))
import beam  # noqa: E402
import plans as gymplans  # noqa: E402
import structured  # noqa: E402
from catalog import PARAMETERS  # noqa: E402
from engine import App  # noqa: E402
from plan import ChooseOnly, HUB, MODEL, SOCKET, Graph, Shared, params_of, remembered  # noqa: E402
from prompt import Budget, declared_context  # noqa: E402
from sample import questions  # noqa: E402


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--world")
    parser.add_argument("--split")
    parser.add_argument("--only")
    parser.add_argument("--out", required=True)
    parser.add_argument("--config", default="both", help="both: previews and beam k=3 with pruning")
    args = parser.parse_args()
    rows = [r for r in questions(args) if r["intent"] == "answer"]
    if args.only:
        rows = [rows[int(i)] for i in args.only.split(",")]
    PARAMETERS.update({"preview": True, "beam_k": 3, "beam_prune": True, "contrast": False})
    model = ChooseOnly(Shared(SOCKET))
    model.budget = Budget(declared_context(MODEL, HUB), PARAMETERS["answer_tokens"])
    out, apps = [], {}
    for item in rows:
        d = GYM / "out" / item["world_dir"]
        if item["world"] not in apps:
            app = App(d / "app/src/main", d / "graph.db", d / "scratch")
            apps[item["world"]] = (app, app.call({"op": "schema"}), Graph(app.argv))
        app, schema, graph = apps[item["world"]]
        context = {"principal": item["params"]["asker"], "speaker": item["speaker"], "conversation": None,
                   "question_at_ms": item["params"]["now"], "valid_at_ms": None,
                   "known_revision": schema.get("revision", 0), "previous_answer": None}
        params = params_of(context)
        seek, read, probe = remembered(graph.search), remembered(graph.read), graph.prober(params)
        started = time.time()
        found = beam.candidates(model, lambda w: structured.plan(w, item["question"], schema, context, seek, None, read, probe), probe)
        plans = []
        for p in found:
            got = gymplans.read_answer(app.query(p.cypher, params, item["as_of"]))
            plans.append({"cypher": p.cypher, "score": p.score(), "tally": p.tally, "length": p.length, "round": p.round,
                          "steps": list(p.steps), "correct": got["status"] == "answered" and got["values"] == item["gold"]["values"]})
        out.append({"id": item["id"], "kind": item["kind"], "plans": plans, "ms": int((time.time() - started) * 1000)})
        pathlib.Path(args.out).write_text(json.dumps(out, indent=1))
        print(f"{item['id']} {item['kind']:<10} {len(plans)} plans, {sum(p['correct'] for p in plans)} correct, {out[-1]['ms']} ms", flush=True)


if __name__ == "__main__":
    main()
