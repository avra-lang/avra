"""Base vs adapter on the decision benches: the only thing that decides promotion.

Each bench is scored as its own runner scores it, through the real scorer's
choose() with no source prefix (as the service's `choose` op asks):
  planner   graph/planner/bench/decisions.jsonl — both orders averaged (structured.debiased)
  extract   graph/extract/bench/decisions.jsonl + decisions.triple.jsonl — one order, as asked
  er        graph/extract/bench/antecedents.jsonl — one order; also the cascade's link/new/abstain rule
None of these appear in training (corpus.py refuses fixture names; the
domains are invented). One model is resident at a time: base, then adapter.

An adapter is promoted only if it gains on the planner bench AND on the
extraction benches (er included) and no kind anywhere loses more decisions
than it gains by `params.json`'s noise allowance.

usage: python evaluate.py --adapter adapters/<run>/best [--valid N]
"""
import argparse
import collections
import gc
import json
import os
import pathlib
import sys
import time

HERE = pathlib.Path(__file__).resolve().parent
GRAPH = HERE.parent
sys.path.insert(0, str(GRAPH / "extract"))
sys.path.insert(0, str(GRAPH / "planner"))
import cascade  # noqa: E402
from structured import debiased  # noqa: E402

PARAMS = {k: v["value"] for k, v in json.loads((HERE / "params.json").read_text()).items()}
sys.path.insert(0, str(GRAPH / "planner" / "bench"))
from bench import kind as planner_kind  # noqa: E402


class Scorer(cascade.Scorer):
    """The real scorer, optionally with an adapter."""

    def __init__(self, adapter=None):
        from mlx_lm import load

        self.model, self.tok = load(cascade.SCORER.split("@")[0], adapter_path=adapter)
        self.calls, self.source, self.cache, self.prefix = 0, "", None, False


def rows(path):
    out = [json.loads(l) for l in open(path) if l.strip()]
    return out[1:] if "question_id" not in out[0] and "kind" not in out[0] else out


def benches():
    b = GRAPH / "extract" / "bench"
    return {
        "planner": [dict(d, kind=planner_kind(d["question"]), id=f"{d['question_id']}-{i}")
                    for i, d in enumerate(rows(GRAPH / "planner" / "bench" / "decisions.jsonl"))],
        "extract": rows(b / "decisions.jsonl") + [dict(d, id="triple-" + d["id"]) for d in rows(b / "decisions.triple.jsonl")],
        "er": rows(b / "antecedents.jsonl"),
    }


def decide(p, n):
    """The cascade's antecedent rule over n candidates: link index, new, or abstain."""
    ranked = sorted(range(len(p)), key=lambda i: -p[i])
    if ranked[0] < n and p[ranked[0]] - p[ranked[1]] >= cascade.MARGIN:
        return ranked[0]
    return "new" if ranked[0] == n and max(p[:n]) <= cascade.NEW_CEILING else "abstain"


def score(scorer, sets, valid=None):
    out = {}
    for name, ds in sets.items():
        res = []
        for d in ds:
            t = time.time()
            if name == "planner":
                p = debiased(scorer, d["context"], d["question"], d["options"])
            else:
                p = scorer.choose(d["context"], d["question"], d["options"])
            pick = max(range(len(p)), key=p.__getitem__)
            r = {"id": d["id"], "kind": d["kind"], "gold": d["gold"], "pick": pick, "p_gold": p[d["gold"]], "ms": int((time.time() - t) * 1000)}
            if name == "er":
                r["rule"] = decide(p, d["candidates"])
            res.append(r)
        out[name] = res
    if valid:
        res = []
        for x in valid:
            scorer.source = x["source"]
            p = scorer.choose(x["context"], x["question"], x["options"])
            pick = max(range(len(p)), key=p.__getitem__)
            res.append({"kind": x["kind"], "domain": x["domain"], "gold": x["gold"], "pick": pick, "p_gold": p[x["gold"]]})
        scorer.source = ""
        out["heldout_synthetic"] = res
    return out


def er_outcome(rule, gold, n):
    if isinstance(rule, int):
        return "correct link" if rule == gold else "WRONG MERGE"
    if rule == "new":
        return "correct new" if gold == n else "missed link" if gold < n else "new for cannot-tell"
    return "abstain"


def summary(base, tuned, sets):
    report, verdict = {}, {"gains": {}, "regressions": []}
    for name in base:
        decides = name != "heldout_synthetic"
        by = collections.defaultdict(lambda: {"n": 0, "base": 0, "adapter": 0, "gained": 0, "lost": 0, "p_gold_base": 0.0, "p_gold_adapter": 0.0})
        for b, a in zip(base[name], tuned[name]):
            for k in (b["kind"], "all"):
                s = by[k]
                rb, ra = b["pick"] == b["gold"], a["pick"] == a["gold"]
                s["n"] += 1
                s["base"] += rb
                s["adapter"] += ra
                s["gained"] += ra and not rb
                s["lost"] += rb and not ra
                s["p_gold_base"] += b["p_gold"]
                s["p_gold_adapter"] += a["p_gold"]
        for s in by.values():
            s["p_gold_base"] = round(s["p_gold_base"] / s["n"], 3)
            s["p_gold_adapter"] = round(s["p_gold_adapter"] / s["n"], 3)
        report[name] = dict(by)
        if not decides:
            continue
        verdict["gains"][name] = by["all"]["adapter"] - by["all"]["base"]
        for k, s in by.items():
            if k != "all" and s["lost"] - s["gained"] > PARAMS["noise_decisions"]:
                verdict["regressions"].append(f"{name}/{k}: lost {s['lost']}, gained {s['gained']}")
    if "er" in base:
        ns = {d["id"]: d["candidates"] for d in sets["er"]}
        report["er_rule"] = {w: dict(collections.Counter(er_outcome(r["rule"], r["gold"], ns[r["id"]]) for r in res))
                             for w, res in (("base", base["er"]), ("adapter", tuned["er"]))}
    extraction = verdict["gains"].get("extract", 0) + verdict["gains"].get("er", 0)
    verdict["promote"] = verdict["gains"].get("planner", 0) > 0 and extraction > 0 and not verdict["regressions"]
    return report, verdict


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adapter", required=True)
    parser.add_argument("--valid", type=int, default=0, help="also score this many held-out synthetic examples")
    a = parser.parse_args()
    sets = benches()
    valid = None
    if a.valid:
        import random

        xs = [json.loads(l) for l in open(HERE / "data" / "valid.jsonl")]
        valid = random.Random(PARAMS["seed"]).sample(xs, min(a.valid, len(xs)))
    results = {}
    for who, adapter in (("base", None), ("adapter", a.adapter)):
        t = time.time()
        s = Scorer(adapter)
        results[who] = score(s, sets, valid)
        print(f"{who}: scored in {time.time() - t:.0f}s", file=sys.stderr)
        del s
        gc.collect()
    report, verdict = summary(results["base"], results["adapter"], sets)
    out = HERE / "results" / f"eval-{pathlib.Path(a.adapter).parent.name}-{time.strftime('%Y%m%dT%H%M%S')}.json"
    out.parent.mkdir(exist_ok=True)
    out.write_text(json.dumps({"adapter": a.adapter, "report": report, "verdict": verdict, "results": results}, indent=1))
    for name, by in report.items():
        if name == "er_rule":
            print("er rule:", json.dumps(by))
            continue
        print(f"{name}:")
        for k, s in sorted(by.items(), key=lambda x: (x[0] != "all", x[0])):
            print(f"  {k:<14} base {s['base']}/{s['n']}  adapter {s['adapter']}/{s['n']}  (+{s['gained']} -{s['lost']})  p_gold {s['p_gold_base']} -> {s['p_gold_adapter']}")
    print("verdict:", json.dumps(verdict))
    print("results:", out.relative_to(GRAPH.parent))


if __name__ == "__main__":
    os.environ.setdefault("HF_HOME", os.path.expanduser("~/.cache/avra-graph-ml/hf"))
    os.environ.setdefault("HF_HUB_OFFLINE", "1")
    main()
