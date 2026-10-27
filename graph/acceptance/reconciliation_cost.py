"""What end-of-extraction reconciliation drops, and how much of it is gold.

usage: python reconciliation_cost.py RESULTS.json [more.json ...]

Applies the cascade's reconciliation to every recorded extraction (one per source, the last wins) and
lists each property it removes. A drop is a gold loss when the oracle's record of that model in that
source holds one of the dropped values for that property.
"""
import copy
import json
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "extract"))
import cascade  # noqa: E402
from recall_measure import same  # noqa: E402


def main(paths):
    ex = {}
    for path in paths:
        for e in json.loads(pathlib.Path(path).read_text())["extractions"]:
            if e.get("kind") == "source" and (e.get("result") or {}).get("status") == "complete":
                ex[e["source"]] = e["result"]
    oracle = {row["source"]: row["records"] for row in map(json.loads, open(HERE / "oracle" / "facts.jsonl"))}
    drops = gold = 0
    for sid, result in sorted(ex.items()):
        before = copy.deepcopy(result["records"])
        cascade.LOG.clear()
        after = cascade.reconciled(copy.deepcopy(before))
        lost = {}
        for b, a in zip(before, after):
            for f in b["fields"]:
                if f["property"] not in {x["property"] for x in a["fields"]}:
                    lost.setdefault((b["model"], f["property"]), []).append(f["value"])
        for (model, prop), values in lost.items():
            drops += 1
            hit = any(prop in rec["value"] and any(same(rec["value"][prop], v) for v in values) for rec in oracle.get(sid, []) if rec["model"] == model)
            gold += hit
            print(sid, f"{model}.{prop}", values, "GOLD" if hit else "")
    print(f"sources={len(ex)} properties_dropped={drops} of_which_gold={gold}")


if __name__ == "__main__":
    main(sys.argv[1:])
