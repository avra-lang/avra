"""Where each development question dies, from the extraction alone.

usage: python loss_attribution.py RESULTS.json

For a question's cited sources (`expect.evidence_all`), the oracle's records there are owed.
The question dies at the first stage that fails: a model never extracted (record pass), an
extracted record whose field values differ from the oracle's (field values), else the
extraction holds everything owed and the loss is the planner's or the read's.
Only the extractions and the question set are read; no model runs.
"""
import collections
import json
import pathlib
import subprocess
import sys
import tempfile

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "extract"))
from cascade import Plan  # noqa: E402
from recall_measure import HERE, same, scalar


def pass_of(plan):
    """The cascade pass that produces each model: entity, relation or record."""
    return {**{m: "entity pass" for m in plan.entities}, **{m: "relation pass" for m in plan.relations}, **{m: "record pass" for m in plan.records}}


def schema():
    with tempfile.TemporaryDirectory() as d:
        request = pathlib.Path(d, "r.json")
        request.write_text('{"op":"schema"}')
        return json.loads(subprocess.run([str(HERE / "app/src/main"), "request", "--db", str(pathlib.Path(d, "x.db")), str(request)], capture_output=True, text=True).stdout)


def main(path):
    s = schema()
    passes = pass_of(Plan(s["models"], s.get("derivations", ())))
    results = json.loads(pathlib.Path(path).read_text())
    got = collections.defaultdict(list)
    for e in {e["source"]: e for e in results["extractions"] if e.get("kind") == "source"}.values():
        for r in (e.get("result") or {}).get("records", []):
            got[(e["source"], r["model"])].append({f["property"]: f["value"] for f in r["fields"]})
    owed = collections.defaultdict(list)
    for row in map(json.loads, open(HERE / "oracle" / "facts.jsonl")):
        for rec in row["records"]:
            owed[row["source"]].append(rec)
    split = json.loads((HERE / "split.json").read_text())["heldout"]
    tally, lines = collections.Counter(), []
    for q in map(json.loads, open(HERE / "questions.jsonl")):
        if q["id"] in split:
            continue
        status = results["questions"].get(q["id"], {}).get("status")
        cited = q["expect"].get("evidence_all") or []
        missing, unequal = set(), set()
        for s in cited:
            for rec in owed.get(s, []):
                cands = got.get((s, rec["model"]), [])
                if not cands:
                    missing.add(rec["model"])
                elif any(scalar(w) and not any(n in c and same(w, c[n]) for c in cands) for n, w in rec["value"].items()):
                    unequal.add(rec["model"])
        by_pass = collections.defaultdict(list)
        for m in sorted(missing):
            by_pass[passes.get(m, "no pass proposes it")].append(m)
        first = next(iter(by_pass), None)
        stage = ("passed" if status == "pass" else first + ": " + ",".join(by_pass[first]) if missing
                 else "field values: " + ",".join(sorted(unequal)) if unequal
                 else "no cited evidence" if not cited else "planner/read (extraction complete)")
        tally[stage.split(":")[0]] += 1
        lines.append(f"{q['id']}  {stage}")
    print("\n".join(lines))
    print(dict(tally))


if __name__ == "__main__":
    main(sys.argv[1])
