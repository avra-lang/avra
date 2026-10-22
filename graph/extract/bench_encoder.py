"""Entity-span precision and recall of one encoder on the slice, with load
time, per-source time and peak memory. One encoder per process.

usage: CASCADE_ENCODER=base|large CASCADE_ENCODER_DEVICE=cpu|mps CASCADE_ENCODER_HALF=0|1 python bench_encoder.py CATALOG_JSON
"""
import json
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pins import ENCODER  # noqa: E402

here = os.path.dirname(os.path.abspath(__file__))
catalog = json.load(open(sys.argv[1]))
gold = json.load(open(os.path.join(here, "bench", "encoder_gold.json")))
sources = {json.loads(l)["id"]: json.loads(l)["content"] for l in open(os.path.join(here, "..", "acceptance", "sources.jsonl"))}
import cascade as c  # noqa: E402

plan = c.Plan(catalog["models"])
labels = {m.lower(): c.gloss(plan.models[m]) for m in plan.entities}
t = time.time()
enc = c.Encoder()
load_s = time.time() - t
loaded = enc.ask(op="footprint")["footprint"]
tp = fp = fn = 0
per = []
for sid, want in gold.items():
    if sid == "note":
        continue
    t = time.time()
    found = enc.mentions(sources[sid], labels)
    per.append(round(time.time() - t, 2))
    by = {m.lower(): m for m in plan.entities}
    got = {(by[l], x["text"]) for l, xs in found.items() for x in xs if l in by}
    want = {tuple(w) for w in want}
    tp += len(got & want); fp += len(got - want); fn += len(want - got)
    print(sid, "WRONG", sorted(got - want), "missed", sorted(want - got), file=sys.stderr)
end = enc.ask(op="footprint")["footprint"]
enc.close()
print(json.dumps({"encoder": ENCODER, "device": os.environ.get("CASCADE_ENCODER_DEVICE", "cpu"),
                  "half": os.environ.get("CASCADE_ENCODER_HALF") == "1", "footprint_loaded": loaded, "footprint_end": end, "tp": tp, "fp": fp, "fn": fn,
                  "precision": round(tp / (tp + fp), 3) if tp + fp else 0, "recall": round(tp / (tp + fn), 3),
                  "load_s": round(load_s, 1), "source_s": per,
                  }))
