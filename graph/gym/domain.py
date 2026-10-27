"""One invented domain end to end: structure, names, compiled graph, world,
source texts, loaded database, verified plans and rendered questions. Every
stage is written to disk, so a run resumes where it stopped."""
import argparse
import json
import pathlib
import random
import sys

import schemagen
import engine
import facts
import plans
import render
import world as worldmod
from cat import Cat
import llm as llmmod
from skeleton_knobs import KNOBS

HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE / "out"
DAY_MS = 86_400_000


def save(path, value):
    path.write_text(json.dumps(value, indent=1, sort_keys=True))


def stage(path, make):
    if path.exists():
        return json.loads(path.read_text())
    value = make()
    save(path, value)
    return value


def texts_of(llm, domain, cat, world, workers=4):
    """{source id: {text, made, lines}} written from each source's fact lines, sources in parallel."""
    from concurrent.futures import ThreadPoolExecutor

    def one(source):
        lines = facts.source_lines(cat, world, source)
        text, made = render.render_source(llm, domain, lines)
        return source["id"], {"text": text, "made": made, "lines": lines}

    with ThreadPoolExecutor(workers) as pool:
        return dict(pool.map(one, world["sources"]))


def loaded(d, cat, world, texts):
    app = engine.App(d / "app/src/main", d / "graph.db", d / "scratch")
    if (d / "revisions.json").exists():
        return app, json.loads((d / "revisions.json").read_text())
    anchors = {sid: render.anchors_of(t["lines"], t["text"]) for sid, t in texts.items()}
    before, after = engine.load(app, cat, world, {sid: t["text"] for sid, t in texts.items()}, anchors)
    save(d / "revisions.json", {"before_tombstones": before, "final": after})
    return app, {"before_tombstones": before, "final": after}


def accepted(plan, got):
    if plan["intent"] == "answer":
        return got["status"] == "answered" and bool(got["values"])
    return got["status"] in ("unknown", "ambiguous")


def verified_plans(app, revisions, sampler, rng, want):
    """Plans the engine confirms behave as their kind intends, each with its gold reading."""
    mix = KNOBS["plan_mix"]
    kinds = [k for k, w in mix.items() for _ in range(w)]
    out, seen, tries = [], set(), 0
    while len(out) < want and tries < want * 12:
        tries += 1
        plan = sampler.sample(rng.choice(kinds))
        if plan is None:
            continue
        key = (plan["cypher"], json.dumps(plan["as_of"]), plan["speaker"])
        if key in seen:
            continue
        seen.add(key)
        if not app.check(plan["cypher"], plan["params"]).get("ok"):
            continue
        got = plans.outcome(app, plan)
        if not accepted(plan, got):
            continue
        earlier = plans.read_answer(app.query(plan["cypher"], plan["params"], {**(plan["as_of"] or {}), "revision": revisions["before_tombstones"]}))
        if earlier["status"] != got["status"] or earlier["values"] != got["values"]:
            plan["tags"] = plan["tags"] + ["hidden_by_decision"]
        out.append({**plan, "gold": got})
    return out


def questions_of(llm, domain, items, rng, family, workers=4):
    """Items with a question that passes fidelity, rendered in parallel."""
    from concurrent.futures import ThreadPoolExecutor

    rivals = [rng.sample([i for i in items if i is not item], min(3, len(items) - 1)) for item in items]

    def one(args):
        item, rival = args
        got = render.render_question(llm, domain, item, family)
        if got is None:
            return None
        q, made = got
        if not render.round_trips(llm, item, q, rival) or not render.first_person_ok(llm, item, q):
            return None
        return {**item, "question": q, "made": made}

    with ThreadPoolExecutor(workers) as pool:
        return [r for r in pool.map(one, zip(items, rivals)) if r]


def build(family, seed, llm, root=OUT, avoid_domains=(), stop_after=None, author=None):
    d = pathlib.Path(root) / family / str(seed)
    d.mkdir(parents=True, exist_ok=True)
    tag = f"{family}-{seed}"
    name = "gym_" + tag.replace("-", "_")
    if not (d / "catalog.json").exists():
        text, catalog, made = schemagen.author(author or llm, d / "app", name, random.Random(f"schema:{family}:{seed}"), avoid_domains)
        (d / "models.av").write_text(text)
        save(d / "catalog.json", {"catalog": catalog, "made": made})
    catalog = json.loads((d / "catalog.json").read_text())["catalog"]
    cat = Cat(catalog)
    if not (d / "app/src/main").exists():
        schemagen.package(d / "app", (d / "models.av").read_text(), name)
        built, text = schemagen.compile_package(d / "app")
        if not built:
            raise SystemExit(f"gym: {tag}: stored schema no longer compiles: {text[:400]}")
    domain = domain_of(d, llm, cat)
    part = d / "pools.partial.json"
    pool = stage(d / "pools.json", lambda: worldmod.pools(llm, cat, domain, json.loads(part.read_text()) if part.exists() else None, lambda o: save(part, o)))
    world = stage(d / "world.json", lambda: worldmod.make(cat, pool, random.Random(f"facts:{family}:{seed}")))
    if stop_after == "world":
        return d
    texts = stage(d / "texts.json", lambda: texts_of(llm, domain, cat, world))
    app, revisions = loaded(d, cat, world, texts)
    sampler = plans.Sampler(cat, world, app, random.Random(f"plans:{family}:{seed}"), world_now(cat, world))
    gold = stage(d / "plans.json", lambda: verified_plans(app, revisions, sampler, random.Random(f"mix:{family}:{seed}"), KNOBS["questions_per_world"]))
    if stop_after == "plans":
        return d
    stage(d / "items.json", lambda: questions_of(llm, domain, gold, random.Random(f"rivals:{family}:{seed}"), family))
    return d


def domain_of(d, llm, cat):
    """The domain's name as its author declared it on the file's first line."""
    first = (d / "models.av").read_text().splitlines()[0]
    return first.split(":", 1)[1].strip() if first.lower().startswith("// domain:") else d.name


def world_now(cat, world):
    """One day after the latest instant any statement holds."""
    latest = 0
    for x in world["instances"].values():
        tp = cat.time_paths(x["model"])
        for value in x["versions"]:
            for path, enc in tp.items():
                v = world_get(value, path)
                if isinstance(v, (int, float)) and enc == "unix_millis":
                    latest = max(latest, v)
    return latest + DAY_MS


def world_get(value, path):
    for k in path:
        if not isinstance(value, dict) or k not in value:
            return None
        value = value[k]
    return value


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--family", default="eval")
    p.add_argument("--seeds", required=True, help="comma separated seeds")
    p.add_argument("--out", default=str(OUT))
    p.add_argument("--generator", choices=("hosted", "local"), default="hosted")
    p.add_argument("--model", default="haiku", help="hosted model for pools, texts and questions")
    p.add_argument("--author-model", default="sonnet", help="hosted model that authors schemas")
    p.add_argument("--avoid-family", help="family whose built domains this run must differ from")
    p.add_argument("--stop-after", choices=("world", "plans"))
    args = p.parse_args()
    llm = llmmod.Hosted(args.model) if args.generator == "hosted" else llmmod.Llm()
    author = llmmod.Hosted(args.author_model) if args.generator == "hosted" else None
    domains = []
    if args.avoid_family:
        for f in sorted(g for fam in args.avoid_family.split(",") for g in (pathlib.Path(args.out) / fam).glob("*/models.av")):
            first = f.read_text().splitlines()[0]
            if first.lower().startswith("// domain:"):
                domains.append(first.split(":", 1)[1].strip())
    for seed in args.seeds.split(","):
        try:
            d = build(args.family, seed, llm, args.out, domains, args.stop_after, author)
        except (SystemExit, Exception) as why:
            print(f"failed {args.family}-{seed}: {str(why)[:300]}", flush=True)
            continue
        domains.append(domain_of(d, llm, None))
        print("built", d, "-", domains[-1], flush=True)


if __name__ == "__main__":
    main()
