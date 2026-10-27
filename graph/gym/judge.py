#!/usr/bin/env python3
"""The question judge, made strict and tested.

    python3 judge.py selftest --family eval --seeds 1,2 [--per-world 12]
    python3 judge.py refilter --family eval --seeds 1,2,3

A question is kept only if the generator, reading it, picks the plan's own
steps over minimal edits of them (another value, a dropped constraint, a moved
time window, another asked property), in both option orders. `selftest` shows
the judge can fail: it renders questions for the EDITED plans and measures how
often the judge, shown the original plan beside the edits, still picks the
original. The share it rejects is the judge's power, recorded in the split.
"""
import argparse
import json
import pathlib
import random
from concurrent.futures import ThreadPoolExecutor

import mutate
import render
import llm as llmmod
from cat import Cat

HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE / "out"


def world_of(d):
    return Cat(json.loads((d / "catalog.json").read_text())["catalog"]), json.loads((d / "world.json").read_text())


def strict_picks(llm, item, question, rivals):
    """Kept only if the question carries the plan's names and literals, asks for each step, and picks the plan over its edits."""
    return (render.carries(question, item) and render.steps_present(llm, item, question)
            and render.round_trips(llm, item, question, [{"steps": r} for _, r in rivals]))


def refilter(family, seed, llm, workers=4):
    d = OUT / family / str(seed)
    cat, world = world_of(d)
    rng = random.Random(f"judge:{family}:{seed}")
    items = json.loads((d / "items.json").read_text())

    def one(item):
        rivals = mutate.rivals(item, cat, world, rng)
        keep = strict_picks(llm, item, item["question"], rivals)
        return {**item, "judged": {"rivals": [k for k, _ in rivals], "kept": keep}}

    with ThreadPoolExecutor(workers) as pool:
        judged = list(pool.map(one, items))
    (d / "items.strict.json").write_text(json.dumps([j for j in judged if j["judged"]["kept"]], indent=1))
    (d / "judged.json").write_text(json.dumps(judged, indent=1))
    return len(items), sum(j["judged"]["kept"] for j in judged)


def selftest(family, seeds, llm, per_world=12, workers=4):
    """For each edit kind: of questions rendered from the EDITED plan, how many the judge refuses to attach to the original plan."""
    jobs = []
    for seed in seeds:
        d = OUT / family / str(seed)
        cat, world = world_of(d)
        domain = (d / "models.av").read_text().splitlines()[0].split(":", 1)[1].strip()
        rng = random.Random(f"selftest:{family}:{seed}")
        items = json.loads((d / "items.json").read_text())
        for item in rng.sample(items, min(per_world, len(items))):
            for kind, steps in mutate.rivals(item, cat, world, rng, want=2):
                jobs.append((domain, item, kind, steps, mutate.rivals(item, cat, world, rng)))

    def one(job):
        domain, item, kind, steps, rivals = job
        edited = {**item, "steps": steps, "anchors": item["anchors"], "literals": []}
        got = render.render_question(llm, domain, edited, family)
        if got is None:
            return kind, None
        q, _ = got
        return kind, strict_picks(llm, item, q, rivals)

    with ThreadPoolExecutor(workers) as pool:
        results = list(pool.map(one, jobs))
    by = {}
    for kind, kept in results:
        if kept is not None:
            by.setdefault(kind, []).append(kept)
    report = {k: {"n": len(v), "rejected": round(1 - sum(v) / len(v), 3)} for k, v in sorted(by.items())}
    allv = [x for v in by.values() for x in v]
    report["all"] = {"n": len(allv), "rejected": round(1 - sum(allv) / len(allv), 3) if allv else None}
    return report


def main():
    p = argparse.ArgumentParser(description=__doc__)
    sub = p.add_subparsers(dest="cmd", required=True)
    for name in ("selftest", "refilter"):
        s = sub.add_parser(name)
        s.add_argument("--family", default="eval")
        s.add_argument("--seeds", required=True)
        s.add_argument("--per-world", type=int, default=12)
        s.add_argument("--model", default="haiku")
    args = p.parse_args()
    llm = llmmod.Hosted(args.model)
    seeds = args.seeds.split(",")
    if args.cmd == "selftest":
        report = selftest(args.family, seeds, llm, args.per_world)
        (HERE / "splits").mkdir(exist_ok=True)
        (HERE / "splits" / f"judge-selftest-{args.family}.json").write_text(json.dumps(report, indent=1))
        print(json.dumps(report, indent=1))
    else:
        for seed in seeds:
            print(seed, refilter(args.family, seed, llm))


if __name__ == "__main__":
    main()
