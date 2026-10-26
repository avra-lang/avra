#!/usr/bin/env python3
"""Entity-resolution choice rows with the exact bytes the resolver sends.

    python3 er_rows.py --family eval --seeds 1,2,3 --name er-v1 [--corpus er/er-v1.jsonl]

Each corpus source is admitted into its world's graph the way an extractor's
result is (one record per entity named in the source, its fullest surface as
the label, the surface's passage as evidence), then the resolver's own
`one()` runs with a chooser that answers from the world's identities. The
rows it is asked are the rows production would be asked, in the states gold
answers lead to. Link rows label the gold candidate or "someone new";
spelling rows label the entity's full name when it is among the spellings.
"""
import argparse
import json
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
EXTRACT = HERE.parent / "extract"
sys.path.insert(0, str(EXTRACT))
import resolve  # noqa: E402

from engine import App, envelope  # noqa: E402

OUT = HERE / "out"
CORPUS = HERE / "er"


class Truth:
    """Which world instance each graph entity stands for, and what the world calls it."""

    def __init__(self, names):
        self.of, self.names = {}, names


class Recorder:
    """The chooser: records the row it is shown and answers from the world."""

    def __init__(self, owner):
        self.owner, self.calls, self.seconds = owner, 0, 0.0

    def choose(self, context, question, options):
        self.calls += 1
        o = self.owner
        gold = o.gold_index(options)
        o.rows.append({"world": o.world, "source": o.source_id, "kind": o.mode, "context": context, "question": question, "options": options,
                       "gold": gold, "candidates": len(options) - 2 if o.mode == "link" else len(options) - 1,
                       "said_present": any(', as in "' in x for x in options), "mention": o.mention})
        return [1.0 if i == gold else 0.0 for i in range(len(options))]


class GoldResolver(resolve.Resolver):
    def __init__(self, schema, call, truth, world):
        super().__init__(schema, call, Recorder(self))
        self.truth, self.world, self.rows = truth, world, []
        self.mode, self.source_id, self.mention, self.graph, self.cands, self.root = "link", None, None, None, None, None

    def offered(self, call, graph, source, own, entity, model, name):
        got = super().offered(call, graph, source, own, entity, model, name)
        self.graph, self.cands = graph, got[0] if got else None
        return got

    def one(self, call, graph, source, own, entity, model, name):
        self.mode, self.entity, self.mention, self.source_id = "link", entity, name, source["source"]["observation"]
        return super().one(call, graph, source, own, entity, model, name)

    def settle(self, call, graph, root, model):
        self.mode, self.root, self.graph = "spell", root, graph
        return super().settle(call, graph, root, model)

    def gold_index(self, options):
        if self.mode == "link":
            want = self.truth.of[self.entity]
            for i, root in enumerate(self.cands):
                if any(self.truth.of.get(m) == want for m in self.graph.members(root)):
                    return i
            return len(self.cands)
        want = self.truth.of[self.root]
        full = self.truth.names[want]
        spelled = [o for o in options[:-1]]
        return spelled.index(full) if full in spelled else len(options) - 1


def passage(text, surface):
    a = text.index(surface)
    return {"selector": [{"kind": "TextPositionSelector", "start": a, "end": a + len(surface)},
                         {"kind": "TextQuoteSelector", "exact": surface, "prefix": text[max(0, a - 32):a], "suffix": text[a + len(surface):a + len(surface) + 32]}]}


def result_for(row, models, label_of, schema_fp, request):
    """One extractor result: a record per entity the source names, its fullest surface as the label."""
    best = {}
    for m in row["mentions"]:
        if m["entity"] in models and (m["entity"] not in best or len(m["surface"]) > len(best[m["entity"]])):
            best[m["entity"]] = m["surface"]
    records = [{"local_id": ent, "model": models[ent],
                "fields": [{"property": label_of[models[ent]], "value": s, "evidence": [passage(row["text"], s)], "factuality": "CT+", "speech_act": "assert", "frame": None}],
                "identities": []} for ent, s in best.items()]
    return {"contract": 2, "request": request, "source": {"observation": row["source"], "revision": 1}, "schema": schema_fp,
            "extractor": {"producer": "gym-oracle", "code": "gym", "model": "gold"}, "status": "complete", "records": records, "proposed_frames": [], "problems": [], "unplaced": []}


def world_rows(family, seed, corpus_rows, db=None):
    d = OUT / family / str(seed)
    world = json.loads((d / "world.json").read_text())
    catalog = json.loads((d / "catalog.json").read_text())["catalog"]
    labels = {m["name"]: m["semantics"]["label"][0] for m in catalog["models"] if (m.get("semantics") or {}).get("label")}
    models = {i: x["model"] for i, x in world["instances"].items()}
    names = {i: x["versions"][0][labels[x["model"]]] for i, x in world["instances"].items() if x["model"] in labels}
    db = pathlib.Path(db) if db else d / "er.db"
    if db.exists():
        raise SystemExit(f"gym: {db} exists; move it aside to rebuild the resolution rows")
    app = App(d / "app/src/main", db, d / "scratch")
    schema = app.call({"op": "schema"})
    truth = Truth(names)
    resolver = GoldResolver(schema, app.call, truth, f"{family}-{seed}")
    for k, row in enumerate(sorted(corpus_rows, key=lambda r: r["source"])):
        env = envelope(row["source"], row["text"], 1_700_000_000_000 + k)
        got = app.call({"op": "ingest", "source": env})
        if "error" in got:
            raise SystemExit(f"gym: ingest {row['source']}: {got['error']}")
        result = result_for(row, models, labels, schema["fingerprint"], f"gym-{row['source']}")
        receipt = app.call({"op": "admit", "source": result["source"], "result": result})
        if "error" in receipt:
            raise SystemExit(f"gym: admit {row['source']}: {receipt['error']}")
        for rec, made in zip(receipt.get("records", []), result["records"]):
            truth.of[rec["entity"]] = made["local_id"]
        resolver.resolve(app.call, env, receipt)
    return resolver.rows


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--family", default="eval")
    p.add_argument("--seeds", required=True)
    p.add_argument("--name", required=True)
    p.add_argument("--corpus")
    args = p.parse_args()
    corpus = [json.loads(l) for l in pathlib.Path(args.corpus or CORPUS / f"{args.name}.jsonl").read_text().splitlines() if l.strip()]
    rows = []
    for seed in args.seeds.split(","):
        mine = [r for r in corpus if r["world"] == f"{args.family}-{seed}"]
        rows += world_rows(args.family, seed, mine)
    CORPUS.mkdir(exist_ok=True)
    (CORPUS / f"{args.name}.rows.jsonl").write_text("\n".join(json.dumps(r) for r in rows) + "\n")
    meta = {"rows": len(rows), "link": sum(r["kind"] == "link" for r in rows), "spelling": sum(r["kind"] == "spell" for r in rows),
            "link_gold_new": sum(r["kind"] == "link" and r["gold"] == r["candidates"] for r in rows),
            "said_present": sum(r["said_present"] for r in rows)}
    (CORPUS / f"{args.name}.rows.meta.json").write_text(json.dumps(meta, indent=1))
    print(json.dumps(meta, indent=1))


if __name__ == "__main__":
    main()
