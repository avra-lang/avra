"""Cross-source entity resolution: replay cached extractions into a graph,
optionally resolve, and count the entities each real thing ends up as.

usage: python bench_er.py [--resolve] [--upto N] [--dump FILE] [--gold bench/er_gold.json]
Sources are admitted in order from the extraction cache (the newest result
per request under the app's schema). Gold maps an admitted entity, by the
source and mention text that introduced it, to a real thing; the report is
entities per real thing, wrong merges and missed merges.
"""
import argparse
import glob
import json
import os
import pathlib
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
UNKNOWABLE = "unknowable"  # a mention the source itself leaves open: gold is 'cannot tell'
sys.path.insert(0, str(HERE.parent / "acceptance"))
import score  # noqa: E402


def cached_results(schema):
    found = {}
    for f in sorted(glob.glob(os.path.expanduser("~/.cache/avra-graph-score/acceptance/extractions/*.json")), key=os.path.getmtime):
        r = json.load(open(f))
        if r.get("schema") == schema["fingerprint"] and r.get("status") == "complete":
            found[r["request"]] = r
    return found


def replay(app, sources, results, resolver=None, upto=None, log=print, names=None):
    """Ingest and admit each source in order; the resolver (if any) runs after
    every admission. Returns {source id: admit receipt}; `names` is filled
    with each admitted entity's label as its own source stated it."""
    receipts = {}
    for s in sources[:upto]:
        app.call({"op": "ingest", "source": score.envelope(s)})
        result = results.get(f"extract:{s['observation']}:{s['revision']}")
        if result is None:
            log(f"{s['id']}: no cached extraction")
            continue
        receipts[s["id"]] = app.call({"op": "admit", "source": score.envelope(s)["source"], "result": result})
        for p in receipts[s["id"]].get("records", []):
            if names is not None:
                names[p["entity"]] = label_of(app, p["entity"], None)
        if resolver:
            resolver(app, s, receipts[s["id"]])
    return receipts


def groups(app):
    """Entity id -> its merge group's root, from the active merges."""
    parent = {}

    def find(x):
        while parent.get(x, x) != x:
            x = parent[x]
        return x

    for m in app.call({"op": "merges"}):
        if m.get("active"):
            a, b = find(m["left"]), find(m["right"])
            if a != b:
                parent[max(a, b)] = min(a, b)
    return find


def label_of(app, entity, model):
    fields = app.call({"op": "get", "id": entity}).get("fields", {})
    names = [c["value"] for c in fields.get("name", [])]
    return names[0] if names else None


def report(app, receipts, gold, names, models):
    """Per real thing: how many live entities it ended as; and the entities that
    joined two different things (a wrong merge) or a thing to a mention the
    gold does not name."""
    root = groups(app)
    live = {root(e) for m in models for e in app.call({"op": "find", "model": m, "limit": 500})}
    things, joined = {}, {}
    for sid, receipt in receipts.items():
        for p in receipt.get("records", []):
            label = names.get(p["entity"])
            if label is None or root(p["entity"]) not in live:
                continue
            thing = gold.get(f"{sid}:{label}")
            things.setdefault(thing or f"?{sid}:{label}", set()).add(root(p["entity"]))
            joined.setdefault(root(p["entity"]), set()).add(thing or f"?{sid}:{label}")
    known = {t: len(roots) for t, roots in sorted(things.items()) if not t.startswith("?")}
    return {"entities_per_thing": known, "things": len(known), "entities": sum(known.values()),
            "wrong_merges": [sorted(g) for g in joined.values() if len({x for x in g if not x.startswith("?")}) > 1],
            "joined_to_ungold": [sorted(g) for g in joined.values() if len(g) > 1 and any(x.startswith("?") for x in g)]}


def decision_rows(app, sources, results, gold, resolver, labels):
    """The cross-source choices the resolver would face if every earlier one
    had been made right: the gold links are merged as the sources arrive.
    Each row is a closed choice with its gold option (a candidate's index, or
    the count for 'someone new'); a mention with no gold is not asked."""
    import resolve

    rows, thing = [], {}
    for s in sources:
        app.call({"op": "ingest", "source": score.envelope(s)})
        result = results.get(f"extract:{s['observation']}:{s['revision']}")
        if result is None:
            continue
        receipt = app.call({"op": "admit", "source": score.envelope(s)["source"], "result": result})
        graph = resolve.Graph(app.call)
        own = [p["entity"] for p in receipt["records"]]
        for p in receipt["records"]:
            model = app.call({"op": "get", "id": p["entity"]}).get("model")
            label = resolver.labels.get(model)
            names = graph.fields(p["entity"]).get(label) if label else None
            if not names:
                continue
            g = gold.get(f"{s['id']}:{names[0]}")
            thing[p["entity"]] = g
            offered = resolver.offered(app.call, graph, s, own, p["entity"], model, names[0])
            if not offered or not g:
                continue
            candidates, row = offered
            held = [{thing.get(e) for e in graph.members(c)} for c in candidates]
            at = len(candidates) + 1 if g == UNKNOWABLE else next((i for i, h in enumerate(held) if g in h), len(candidates))
            rows.append({"id": f"er-{s['id']}-{p['entity'][6:14]}", "source": s["id"], "kind": "cross-source", **row, "gold": at, "candidates": len(candidates)})
            if at < len(candidates):
                resolve.merge(app.call, candidates[at], p["entity"], "gold")
                graph.cached.clear()
                asked = resolver.spellings(app.call, graph, graph.groups()(p["entity"]), model)
                shown = labels.get(g)
                if asked and shown in asked[1]["options"]:
                    rows.append({"id": f"nm-{s['id']}-{p['entity'][6:14]}", "source": s["id"], "kind": "name", **asked[1],
                                 "gold": asked[1]["options"].index(shown), "candidates": len(asked[0])})
    return rows


def scored(rows, chooser):
    return [{"id": r["id"], "p": chooser.choose(r["context"], r["question"], r["options"])} for r in rows]


def fit(rows, scores, out):
    """margin and new_ceiling by the cascade's own objective (no wrong merge,
    then the most right, then the fewest duplicates; calibrate.er_outcome) over
    the cross-source rows, and name_margin by the same order over the spelling
    rows: no wrong spelling, then the most right."""
    import calibrate
    from pins import SCORER

    by = {s["id"]: s["p"] for s in scores}
    pairs = [(r, by[r["id"]]) for r in rows if r["id"] in by]
    links = [x for x in pairs if x[0]["kind"] == "cross-source"]
    names = [x for x in pairs if x[0]["kind"] == "name"]
    fits = []
    for m in calibrate.GRID:
        for c in calibrate.GRID:
            o = [calibrate.er_outcome(r, p, m, c) for r, p in links]
            fits.append((o.count("wrong"), -o.count("right"), o.count("duplicate"), -m, (m, c)))
    wrong, right, dup, _, (margin, ceiling) = min(fits)
    spelled = []
    for m in calibrate.GRID:
        o = [calibrate.er_outcome(dict(r, candidates=len(r["options"]) - 1), p, m, 0.0) for r, p in names]
        spelled.append((o.count("wrong"), -o.count("right"), -m, m))
    name_wrong, name_right, _, name_margin = min(spelled)
    data = {"rows": calibrate.digest(rows_path), "scores": calibrate.digest(scores_path)}
    json.dump({"fitted_at": __import__("time").strftime("%Y-%m-%dT%H:%M:%S%z"), "scorer": SCORER,
               "method": "grid search, step 0.05; ties go to the larger margin (calibrate.py's rule)", "data": data,
               "params": {"margin": {"value": margin, "fitted": True, "objective": "no wrong merge, then most right, then fewest duplicates", "dev_wrong": wrong, "dev_right": -right, "dev_duplicate": dup, "n": len(links)},
                          "new_ceiling": {"value": ceiling, "fitted": True, "objective": "joint with margin", "n": len(links)},
                          "name_margin": {"value": name_margin, "fitted": True, "objective": "no wrong spelling, then most right", "dev_wrong": name_wrong, "dev_right": -name_right, "n": len(names)}}},
              open(out, "w"), indent=2)
    return {"margin": margin, "new_ceiling": ceiling, "wrong": wrong, "right": -right, "duplicate": dup, "n": len(links),
            "name_margin": name_margin, "name_wrong": name_wrong, "name_right": -name_right, "name_n": len(names)}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--resolve", action="store_true")
    ap.add_argument("--upto", type=int)
    ap.add_argument("--gold", default=str(HERE / "bench" / "er_gold.json"))
    ap.add_argument("--dump")
    ap.add_argument("--audit", metavar="DIR", help="report on the er.db a previous --resolve run left in DIR")
    ap.add_argument("--rows", help="write the cross-source decision rows (gold-merged history) to this file")
    ap.add_argument("--score", nargs=2, metavar=("ROWS", "OUT"), help="score rows with the model service")
    ap.add_argument("--fit", nargs=3, metavar=("ROWS", "SCORES", "OUT"), help="fit margin and new_ceiling to er_params.json form")
    ap.add_argument("--budget", type=float, default=100, help="seconds a --score call may spend; rerun resumes")
    args = ap.parse_args()
    if args.score:
        import resolve

        rows = [json.loads(l) for l in open(args.score[0])]
        done = {json.loads(l)["id"] for l in open(args.score[1])} if os.path.exists(args.score[1]) else set()
        chooser, started = resolve.Chooser(), __import__("time").time()
        with open(args.score[1], "a") as out:
            for r in rows:
                if r["id"] not in done and __import__("time").time() - started < args.budget:
                    out.write(json.dumps(scored([r], chooser)[0]) + "\n")
                    out.flush()
        return
    if args.fit:
        global rows_path, scores_path
        rows_path, scores_path = args.fit[0], args.fit[1]
        print(json.dumps(fit([json.loads(l) for l in open(rows_path)], [json.loads(l) for l in open(scores_path)], args.fit[2])))
        return
    manifest, sources, entities, _ = score.load_fixture()
    scratch = pathlib.Path(tempfile.mkdtemp(prefix="bench-er-"))
    score.BINARY = pathlib.Path(os.environ.get("GRAPH_BINARY", score.BINARY))
    app = score.App(score.BINARY, scratch / "er.db", scratch)
    schema = app.call({"op": "schema"})
    resolver = None
    if args.rows:
        import resolve

        gold = json.load(open(args.gold))
        labels = {e["id"]: e["label"] for e in entities}
        rows = decision_rows(app, sources, cached_results(schema), gold, resolve.Resolver(schema, app.call), labels)
        open(args.rows, "w").write("".join(json.dumps(r) + "\n" for r in rows))
        cross = [r for r in rows if r["kind"] == "cross-source"]
        print(f"{len(rows)} rows; links: " + json.dumps({"link": sum(r["gold"] < r["candidates"] for r in cross), "new": sum(r["gold"] == r["candidates"] for r in cross), "name": len(rows) - len(cross)}))
        return
    if args.resolve:
        import resolve

        resolver = resolve.Resolver(schema).after_admit
    names = {}
    receipts = replay(app, sources, cached_results(schema), resolver, args.upto, names=names)
    if args.audit:
        app = score.App(score.BINARY, pathlib.Path(args.audit) / "er.db", pathlib.Path(args.audit))
    if args.dump:
        json.dump(receipts, open(args.dump, "w"))
    gold = json.load(open(args.gold)) if os.path.exists(args.gold) else {}
    print(json.dumps(report(app, receipts, gold, names, [m['name'] for m in schema['models'] if (m.get('semantics') or {}).get('label')]), indent=1))


if __name__ == "__main__":
    main()
