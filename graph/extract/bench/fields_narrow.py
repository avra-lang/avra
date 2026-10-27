"""The record passes over only the kinds an extraction stated, against over every kind: same answers for those kinds, and the time of each.

usage: python fields_narrow.py SCHEMA_JSON SOURCES_JSONL RESULTS_JSON id,id,...     (the encoder's python; no generative model)
RESULTS_JSON is a score results file or a where_time --dump; the kinds a source stated are the record models its extraction holds.
"""
import json
import os
import sys
import time

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import cascade  # noqa: E402


def close(a, b):
    """Equal structure and text; numbers within the half-precision tolerance."""
    if isinstance(a, dict):
        return a.keys() == b.keys() and all(close(a[k], b[k]) for k in a)
    if isinstance(a, list):
        return len(a) == len(b) and all(close(x, y) for x, y in zip(a, b))
    return abs(a - b) < 0.01 if isinstance(a, float) else a == b


def run(enc, queries):
    t = time.time()
    got = {k: enc.mentions(*a) if op == "mentions" else enc.records(*a) for k, (op, *a) in queries.items()}
    return got, time.time() - t


def main():
    schema = json.load(open(sys.argv[1]))
    plan = cascade.Plan(schema["models"], schema.get("derivations", ()))
    rows = {r["id"]: r for r in map(json.loads, open(sys.argv[2]))}
    results = {e["source"]: e["result"] for e in json.load(open(sys.argv[3]))["extractions"] if e.get("kind") == "source"}
    enc = cascade.Encoder()
    full_s = narrow_s = 0.0
    for sid in sys.argv[4].split(","):
        text = rows[sid]["content"]
        stated = [m for m in plan.records if any(r["model"] == m for r in results[sid].get("records", []))]
        full, a = run(enc, plan.record_queries(text, list(plan.records)))
        narrow, b = run(enc, plan.record_queries(text, stated))
        full_s, narrow_s = full_s + a, narrow_s + b
        bad = [k for k in narrow if k != "fields" and not close(narrow[k], full[k])]
        if "fields" in narrow:
            kept = {k: v for k, v in full["fields"].items() if k in narrow["fields"]}
            bad += ["fields"] if not close(narrow["fields"], kept) else []
        print(sid, "kinds", stated, "differ", bad)
    print(f"every kind {full_s:.1f}s  stated kinds {narrow_s:.1f}s")
    enc.close()


if __name__ == "__main__":
    main()
