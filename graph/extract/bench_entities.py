"""How an entity kind is worded as an encoder label: kind agreement on dev sources.

usage: python bench_entities.py ENVELOPES.json CATALOG.json ORACLE_FACTS.jsonl
For each wording in LABELS the encoder marks entity mentions over the dev
sources. A mention is consistent when an oracle record of its kind, in the same
source, holds a text value that contains it or is contained in it; recall is the
share of such oracle records some mention of their kind covers. The encoder only;
one process at a time.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cascade  # noqa: E402

LABELS = {
    "line": lambda m: cascade.gloss(m),
    "sentence": lambda m: cascade.first_sentence(m),
    "fields": lambda m: f"{m['name']} with {cascade.field_names(m)}",
    "bare": lambda m: "",
}


def texts(record):
    return [v.lower() for v in record.get("value", {}).values() if isinstance(v, str)] + [a.lower() for v in record.get("value", {}).values() if isinstance(v, list) for a in v if isinstance(a, str)]


def agrees(text, record):
    text = text.lower()
    return any(len(v) > 1 and (text in v or v in text) for v in texts(record))


def main():
    envs = json.load(open(sys.argv[1]))
    catalog = json.load(open(sys.argv[2]))
    facts = {}
    for line in open(sys.argv[3]):
        row = json.loads(line)
        facts[row["source"]] = row["records"]
    plan = cascade.Plan(catalog["models"], catalog.get("derivations", ()))
    by = {m.lower(): m for m in plan.entities}
    enc = cascade.Encoder()
    out = {}
    for name, wording in LABELS.items():
        labels = {m.lower(): wording(plan.models[m]) for m in plan.entities}
        wrong, total, covered, owed = [], 0, 0, 0
        for e in envs:
            found = enc.mentions(e["envelope"]["content"], labels)
            oracle = [r for r in facts.get(e["id"], []) if r["model"] in plan.entities]
            mentions = [(by[l], x["text"]) for l, xs in found.items() if l in by for x in xs]
            for kind, text in mentions:
                total += 1
                if not any(r["model"] == kind and agrees(text, r) for r in oracle):
                    wrong.append((e["id"], kind, text))
            for r in oracle:
                owed += 1
                covered += any(k == r["model"] and agrees(t, r) for k, t in mentions)
        out[name] = {"mentions": total, "inconsistent": len(wrong), "recall": round(covered / owed, 3), "examples": wrong[:14]}
    enc.close()
    print(json.dumps(out, indent=1))


if __name__ == "__main__":
    main()
