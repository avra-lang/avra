"""Record-kind decisions on dev sources: how a kind is worded, and where to accept it.

usage: python bench_records.py ENVELOPES.json CATALOG.json ORACLE_FACTS.jsonl OUT_PREFIX
ENVELOPES is a JSON array of {"id", "envelope"} for the dev sources. The cascade runs over them
with record acceptance off, so every record-kind choice it would ask is
captured as asked. Each is labelled from the oracle facts whose anchor lies in
the sentence (a set: one sentence can state several records) and re-scored
under every framing in cascade.FRAMINGS. Writes OUT_PREFIX.decisions.jsonl,
OUT_PREFIX.<framing>.scores.jsonl and prints accuracy per framing. One model
at a time; run it alone.
"""
import json
import os
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cascade  # noqa: E402

QUESTION = "Which kind of record does this sentence itself state, if any?"


def sentence_of(context):
    return context[len('Sentence: "') : -1]


def labelled(sentence, source, facts, kinds):
    """The record kinds whose oracle anchor the sentence contains."""
    text = sentence.lower()
    return sorted({r["model"] for r in facts.get(source, []) if r["model"] in kinds and r["anchor"].lower() in text})


def main():
    envelopes, catalog, oracle, out = sys.argv[1:5]
    envs = json.load(open(envelopes))
    facts = {}
    for line in open(oracle):
        row = json.loads(line)
        facts[row["source"]] = row["records"]
    by_text = {e["id"]: e["envelope"]["content"] for e in envs}
    decisions = tempfile.mktemp(suffix=".jsonl")
    os.environ["CASCADE_DECISIONS"] = decisions
    cascade.ACCEPT_RECORD = 2.0
    models = cascade.Models()
    reqs = [cascade.requested(e["envelope"], catalog) for e in envs]
    for _ in cascade.extracted(reqs, models):
        pass
    plan = cascade.Plan(reqs[0]["catalog"]["descriptor"])
    kinds = list(plan.records)
    asked = [json.loads(l) for l in open(decisions)]
    asked = [d for d in asked if d["question"] == QUESTION and d["context"].startswith('Sentence: "')]
    rows = []
    for i, d in enumerate(asked):
        sentence = sentence_of(d["context"])
        source = next((s for s, t in by_text.items() if sentence in t), None)
        gold = labelled(sentence, source, facts, kinds)
        rows.append({"id": f"rk{i}", "source": source, "kind": "record", "context": d["context"], "question": QUESTION,
                     "options": kinds, "gold": [kinds.index(g) for g in gold]})
    with open(f"{out}.decisions.jsonl", "w") as f:
        for r in rows:
            f.write(json.dumps(r) + "\n")
    summary = {}
    for name, framing in cascade.FRAMINGS.items():
        options = [framing(plan.models[k]) for k in kinds]
        right = 0
        with open(f"{out}.{name}.scores.jsonl", "w") as f:
            for r in sorted(rows, key=lambda r: r["source"] or ""):
                models.llm.begin(by_text[r["source"]])
                p = models.llm.pick(r["context"], QUESTION, options, ["none of these"])
                f.write(json.dumps({"id": r["id"], "p": p}) + "\n")
                best = max(range(len(p)), key=lambda i: p[i])
                right += (best in r["gold"]) if r["gold"] else (best == len(kinds))
        summary[name] = right / len(rows)
    print(json.dumps({"decisions": len(rows), "with_a_record": sum(1 for r in rows if r["gold"]), "argmax_accuracy": summary}, indent=1))


if __name__ == "__main__":
    main()
