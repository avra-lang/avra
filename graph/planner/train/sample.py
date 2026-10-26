#!/usr/bin/env python3
"""Rejection-samples the planner's closed choices on the gym.

    python3 graph/planner/train/sample.py --world dev/2 --only 0,1,2 --out rows.jsonl
    python3 graph/planner/train/sample.py --split graph/gym/splits/train-v1.jsonl --out rows.jsonl

For each answerable question, `samples` walks are drawn through the real
planner prompts: at every closed choice the base model's own distribution over
the options (the service's `choose` op, both option orders averaged) is
sampled at the declared temperature. A walk is executed against the question's
graph and kept when its answer is the gold answer. Each decision of a kept
walk becomes a training row holding the exact user message the service builds
(`choices.prompts`) and the picked letter, in both option orders. Where kept
walks disagree on a prompt, the pick most kept walks made stands.

Eval splits and fixtures are refused. A model's answer to a prompt is asked
once and remembered, so more samples cost only the prompts they newly reach.
"""
import argparse
import collections
import json
import math
import pathlib
import random
import sys
import time

HERE = pathlib.Path(__file__).resolve().parent
PLANNER = HERE.parent
ROOT = PLANNER.parent.parent
GYM = ROOT / "graph/gym"
for p in (PLANNER, GYM):
    sys.path.insert(0, str(p))
import importlib.util  # noqa: E402
import beam  # noqa: E402
import choices  # noqa: E402
import plans as gymplans  # noqa: E402
import structured  # noqa: E402
from catalog import PARAMETERS  # noqa: E402
from engine import App  # noqa: E402
from plan import ChooseOnly, HUB, MODEL, SOCKET, Graph, Shared, params_of, remembered, shared_socket  # noqa: E402
from prompt import Budget, declared_context  # noqa: E402

spec = importlib.util.spec_from_file_location("planner_bench", PLANNER / "bench/bench.py")
planner_bench = importlib.util.module_from_spec(spec)
spec.loader.exec_module(planner_bench)
TRAINING = {k: v["value"] for k, v in json.loads((HERE / "params.json").read_text()).items()}


class Sampler(beam.Walker):
    """A walk that draws each pick from the model's distribution and records the decision it drew from."""

    def __init__(self, base, probe, rng, temperature):
        super().__init__(base, probe)
        self.rng, self.temperature, self.decisions, self.shown, self.half = rng, temperature, [], None, False

    def choose(self, context, question, options):
        if not self.half:
            self.shown = (context, question, list(options))
        self.half = not self.half
        return super().choose(context, question, options)

    def decide(self, logp):
        weights = [math.exp(x / self.temperature) for x in logp]
        pick = self.rng.choices(range(len(logp)), weights)[0]
        context, question, options = self.shown
        self.decisions.append({"context": context, "question": question, "options": options, "gold": pick})
        self.half = False
        return pick

    def walk(self, make):
        self.decisions, self.steps, self.plan, self.half = [], [], None, False
        try:
            cypher = make(self)
        except (beam.Pruned, ValueError, KeyError, IndexError):
            return None
        return cypher, self.decisions


def questions(args):
    if args.split:
        rows = [json.loads(l) for l in pathlib.Path(args.split).read_text().splitlines() if l.strip()]
        name = pathlib.Path(args.split).name
        if "eval" in name:
            raise SystemExit(f"sample: {name} is an eval split; it is never trained on")
        return rows
    family, seed = args.world.split("/")
    if "eval" in family:
        raise SystemExit(f"sample: {family} is an eval family; it is never trained on")
    d = GYM / "out" / family / seed
    items = json.loads((d / "items.json").read_text())
    return [{"id": f"{family}-{seed}:{n:02d}", "world": f"{family}-{seed}", "world_dir": f"{family}/{seed}", "kind": it["kind"],
             "intent": it["intent"], "question": it["question"], "cypher": it["cypher"], "params": it["params"],
             "as_of": it["as_of"], "speaker": it["speaker"], "gold": it["gold"]} for n, it in enumerate(items, 1)]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--world", help="a built gym world, <family>/<seed>, e.g. dev/2")
    parser.add_argument("--split", help="a frozen split file of training questions")
    parser.add_argument("--only", help="comma-separated 0-based question positions")
    parser.add_argument("--samples", type=int, default=TRAINING["samples"])
    parser.add_argument("--out", required=True)
    parser.add_argument("--seed", type=int, default=TRAINING["seed"])
    args = parser.parse_args()
    if bool(args.world) == bool(args.split):
        raise SystemExit("sample: name one of --world or --split")
    if not shared_socket():
        raise SystemExit(f"sample: no shared model answers on {SOCKET}")
    rows = [r for r in questions(args) if r["intent"] == "answer"]
    if args.only:
        rows = [rows[int(i)] for i in args.only.split(",")]
    model = ChooseOnly(Shared(SOCKET))
    model.budget = Budget(declared_context(MODEL, HUB), PARAMETERS["answer_tokens"])
    PARAMETERS.update({"preview": TRAINING["preview"], "beam_prune": True})
    rng, apps, kept, report = random.Random(args.seed), {}, collections.defaultdict(collections.Counter), []
    worlds = {}
    samples = {}
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
        sampler = Sampler(model, probe, rng, TRAINING["temperature"])
        make = lambda w: structured.plan(w, item["question"], schema, context, seek, None, read, probe)  # noqa: E731
        started, good, curve, seen = time.time(), 0, [], set()
        for n in range(1, args.samples + 1):
            walked = sampler.walk(make)
            if walked and walked[0] not in seen:
                seen.add(walked[0])
            if walked:
                answer = gymplans.read_answer(app.query(walked[0], params, item["as_of"]))
                if answer["status"] == "answered" and answer["values"] == item["gold"]["values"]:
                    good += 1
                    for d_ in walked[1]:
                        key = json.dumps([d_["context"], d_["question"], d_["options"]])
                        kept[key][d_["gold"]] += 1
                        worlds.setdefault(key, item["world"])
            curve.append(good)
        report.append({"id": item["id"], "kind": item["kind"], "samples": args.samples, "kept": good,
                       "distinct_plans": len(seen), "kept_after": curve, "ms": int((time.time() - started) * 1000)})
        print(f"{item['id']} {item['kind']:<10} kept {good}/{args.samples} distinct plans {len(seen)} {report[-1]['ms']} ms", flush=True)
    out = []
    for key, picks in kept.items():
        context, question, options = json.loads(key)
        pick = picks.most_common(1)[0][0]
        decision = {"context": context, "question": question, "options": options, "gold": pick}
        out += [{"prompt": prompt, "completion": letter, "world": worlds[key], "kind": planner_bench.kind(question)} for prompt, letter in choices.prompts(decision)]
    pathlib.Path(args.out).write_text("\n".join(json.dumps(r) for r in out) + ("\n" if out else ""))
    pathlib.Path(args.out + ".report.json").write_text(json.dumps({"questions": report, "rows": len(out), "temperature": TRAINING["temperature"]}, indent=1))
    print(f"{len(kept)} kept decisions -> {len(out)} rows -> {args.out}")


if __name__ == "__main__":
    main()
