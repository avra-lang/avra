"""Whether the entity pass emits the entities the oracle owes, and by which label.

usage: python bench_entity_pass.py ENVELOPES.json CATALOG.json ORACLE_FACTS.jsonl
       python bench_entity_pass.py ENVELOPES.json CATALOG.json ORACLE_FACTS.jsonl --wording bare

ENVELOPES.json is a JSON list of {"id", "envelope": {"content"}}, one per source;
CATALOG.json is the app's `{"op":"schema"}` answer; ORACLE_FACTS.jsonl is the
oracle's records per source. A record the oracle owes is RIGHT when a mention of
its own model covers one of its text values or its anchor, MISTYPED when only a
mention of another model covers it, ABSENT otherwise. The encoder only, one
process at a time. DIAGNOSTIC ONLY: it reads fixture text and writes nothing, so
no parameter may be fitted from it -- see test_provenance.py.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cascade  # noqa: E402

WORDINGS = {
    "gloss": cascade.gloss,
    "sentence": cascade.first_sentence,
    "bare": lambda m: m["name"],
}


def strings(record):
    """The strings an oracle record is named by: its text values, then its anchor."""
    out = [v for v in record.get("value", {}).values() if isinstance(v, str) and not v.startswith("oracle:")]
    if record.get("anchor"):
        out = out + [record["anchor"]]
    return [s for s in out if len(s) > 1]


def covers(text, record):
    """Whether a mention's text names the record: either contains the other."""
    t = text.lower().strip()
    return bool(t) and any(t in s.lower() or s.lower() in t for s in strings(record))


def owed(oracle, mentions, model):
    """right, mistyped or absent for one oracle entity record."""
    want = record_model = model.lower()
    if any(kind == want and covers(text, oracle) for kind, text in mentions):
        return "right", []
    other = [kind for kind, text in mentions if kind != record_model and covers(text, oracle)]
    return ("mistyped", other) if other else ("absent", [])


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    envelopes, catalog, facts_path = json.load(open(args[0])), json.load(open(args[1])), args[2]
    wording = sys.argv[sys.argv.index("--wording") + 1] if "--wording" in sys.argv else "gloss"
    plan = cascade.Plan(catalog["models"], catalog.get("derivations", ()))
    labels = {m.lower(): WORDINGS[wording](plan.models[m]) for m in plan.entities}
    facts = {}
    for line in open(facts_path):
        row = json.loads(line)
        facts[row["source"]] = row["records"]
    tally, lines = {"right": 0, "mistyped": 0, "absent": 0}, []
    enc = cascade.Encoder()
    try:
        for e in envelopes:
            found = enc.mentions(e["envelope"]["content"], labels)
            mentions = [(k, x["text"]) for k, xs in found.items() if k in labels for x in xs]
            for record in [r for r in facts.get(e["id"], []) if r["model"] in plan.entities]:
                verdict, other = owed(record, mentions, record["model"])
                tally[verdict] += 1
                if verdict != "right":
                    lines.append(f'{e["id"]} {record["model"]} {verdict} for {strings(record)[0]!r} {other or ""}')
    finally:
        enc.close()
    print("\n".join(lines))
    print(json.dumps({"wording": wording, **tally, "of": sum(tally.values())}))


if __name__ == "__main__":
    main()
