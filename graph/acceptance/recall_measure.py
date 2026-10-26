"""Extraction recall against the oracle's records, per stage-visible count.

usage: python recall_measure.py RESULTS.json [more.json …]

For each oracle record: is a record of its model extracted from the same source (present), and
how many of its scalar fields carry the oracle's value (equal). Also the extracted records per
model and the resolver's decisions. Reads the extractions a results file holds; runs no model.
"""
import collections
import datetime
import json
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent


def instant_ms(v):
    """Epoch milliseconds of an ISO date or time, else None."""
    if not isinstance(v, str) or not v[:1].isdigit() or "-" not in v:
        return None
    try:
        stamp = datetime.datetime.fromisoformat(v.replace("Z", "+00:00"))
    except ValueError:
        return None
    return int((stamp if stamp.tzinfo else stamp.replace(tzinfo=datetime.timezone.utc)).timestamp() * 1000)


def same(want, got):
    """The oracle's value is held by the extracted one: scalars equal, an instant by its milliseconds,
    an embedded value field by field (an absent bound equals a null one)."""
    if isinstance(want, dict):
        return isinstance(got, dict) and all(same(w, got.get(k)) for k, w in want.items())
    if want is None:
        return got is None
    if instant_ms(want) is not None and isinstance(got, int):
        return instant_ms(want) == got
    return not isinstance(got, (dict, list)) and str(got).strip().lower() == str(want).strip().lower()


def scalar(v):
    return not isinstance(v, list) and not (isinstance(v, str) and v.startswith("oracle:"))


def measure(path):
    results = json.loads(pathlib.Path(path).read_text())
    got = collections.defaultdict(list)
    per_model, decisions = collections.Counter(), collections.Counter()
    for e in {e["source"]: e for e in results["extractions"] if e.get("kind") == "source"}.values():
        result = e.get("result") or {}
        sid = e["source"]
        for r in result.get("records", []):
            per_model[r["model"]] += 1
            got[(sid, r["model"])].append({f["property"]: f["value"] for f in r["fields"]})
        for d in (e.get("resolve") or {}).get("resolved", []):
            c = d["choice"]
            decisions[c if c in ("new", "abstain") else "link"] += 1
    owed = present = fields = equal = 0
    missing = collections.Counter()
    for row in map(json.loads, open(HERE / "oracle" / "facts.jsonl")):
        for rec in row["records"]:
            owed += 1
            cands = got.get((row["source"], rec["model"]), [])
            present += bool(cands)
            if not cands:
                missing[rec["model"]] += 1
            for name, want in rec["value"].items():
                if not scalar(want):
                    continue
                fields += 1
                equal += any(same(want, c[name]) for c in cands if name in c)
    return {"records": sum(per_model.values()), "by_model": dict(per_model), "oracle_owed": owed, "present": present,
            "scalar_fields": fields, "fields_equal": equal, "missing_models": dict(missing), "resolver": dict(decisions),
            "answers_ok": results.get("counts", {}).get("pass"), "of": sum(results.get("counts", {}).values()) or None}


if __name__ == "__main__":
    for p in sys.argv[1:]:
        print(p)
        print(json.dumps(measure(p), indent=1))
