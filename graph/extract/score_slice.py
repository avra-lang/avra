"""Relation precision and recall of slice results against hand-labelled gold,
plus every other non-entity record for a judgement by hand.

usage: python score_slice.py RESULT_DIR [gold.json]   (RESULT_DIR/<sid>.result.json)
"""
import json
import os
import sys

gold = json.load(open(sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(__file__), "bench", "slice_gold.json")))
tp = fp = fn = 0
for sid in [k for k in gold if k != "note"]:
    path = os.path.join(sys.argv[1], f"{sid}.result.json")
    if not os.path.exists(path):
        print(sid, "missing")
        continue
    r = json.load(open(path))
    names = {x["local_id"]: x["fields"][0]["value"] for x in r["records"] if x["fields"]}
    got, other = set(), []
    for x in r["records"]:
        f = {k["property"]: k["value"] for k in x["fields"]}
        vals = [names.get(v, v) if isinstance(v, str) else v for v in f.values()]
        refs = [names[v] for v in f.values() if isinstance(v, str) and v in names and v != x["local_id"]]
        texts = [v for v in f.values() if isinstance(v, str) and v not in names]
        if x.get("resolution", {}).get("kind") in ("new", "abstain") and not refs:
            continue
        if len(refs) >= 2 and texts:
            got.add((x["model"], refs[0], texts[0].lower(), refs[1]))
        else:
            other.append(f"{x['model']} {vals}")
    want = {tuple([g[0], g[1], g[2].lower(), g[3]]) for g in gold[sid]}
    tp += len(got & want); fp += len(got - want); fn += len(want - got)
    print(sid, "hit", sorted(got & want), "WRONG", sorted(got - want), "missed", sorted(want - got))
    for o in other:
        print("   other:", o)
p = tp / (tp + fp) if tp + fp else 0
rcl = tp / (tp + fn) if tp + fn else 0
print(f"relations: tp={tp} fp={fp} fn={fn} precision={p:.3f} recall={rcl:.3f}")
