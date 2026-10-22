"""Record-kind decisions on dev sources: how a kind is worded, and where to accept it.

usage: python bench_records.py ENVELOPES.json CATALOG.json ORACLE_FACTS.jsonl OUT_PREFIX [--rescore]
ENVELOPES is a JSON array of {"id", "envelope"} for the dev sources. The cascade runs over them
with record acceptance off, so every record-kind choice it would ask is
captured as asked. Each is labelled from the oracle facts whose anchor lies in
the sentence (a set: one sentence can state several records) and re-scored
under every framing in cascade.FRAMINGS. --rescore keeps the captured
sentences of OUT_PREFIX.decisions.jsonl and scores them again over the plan's
current record kinds (no cascade run). Writes OUT_PREFIX.decisions.jsonl,
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


def captured(envs, reqs, models, facts, by_text, kinds):
    """Every record-kind choice the cascade asks over the sources, labelled."""
    decisions = tempfile.mktemp(suffix=".jsonl")
    os.environ["CASCADE_DECISIONS"] = decisions
    cascade.ACCEPT_RECORD = 2.0
    cascade.ACCEPT_KIND = {}
    for _ in cascade.extracted(reqs, models):
        pass
    asked = [json.loads(l) for l in open(decisions)]
    asked = [d for d in asked if d["question"] == QUESTION and d["context"].startswith('Sentence: "')]
    rows = []
    for i, d in enumerate(asked):
        sentence = sentence_of(d["context"])
        source = next((s for s, t in by_text.items() if sentence in t), None)
        gold = labelled(sentence, source, facts, set(r["model"] for rs in facts.values() for r in rs))
        rows.append({"id": f"rk{i}", "source": source, "kind": "record", "context": d["context"], "question": QUESTION,
                     "options": kinds, "gold_models": gold, "gold": [kinds.index(g) for g in gold if g in kinds]})
    return rows


def main():
    envelopes, catalog, oracle, out = sys.argv[1:5]
    envs = json.load(open(envelopes))
    facts = {}
    for line in open(oracle):
        row = json.loads(line)
        facts[row["source"]] = row["records"]
    by_text = {e["id"]: e["envelope"]["content"] for e in envs}
    reqs = [cascade.requested(e["envelope"], catalog) for e in envs]
    plan = cascade.Plan(reqs[0]["catalog"]["descriptor"], reqs[0]["catalog"].get("derivations", ()))
    kinds = list(plan.records)
    models = cascade.Models()
    if "--rescore" in sys.argv:
        rows = [json.loads(l) for l in open(f"{out}.decisions.jsonl")]
        for r in rows:
            r["options"] = kinds
            r["gold"] = [kinds.index(g) for g in r["gold_models"] if g in kinds]
    else:
        rows = captured(envs, reqs, models, facts, by_text, kinds)
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
