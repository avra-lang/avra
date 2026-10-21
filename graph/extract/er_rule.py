"""Entity-resolution outcomes of logged scores under the cascade's rule.

usage: python er_rule.py antecedents.jsonl SCORES.jsonl [SCORES.jsonl]
With two score files, the ensemble keeps a decision only when both rules
reach it; any disagreement abstains.
"""
import json
import sys

MARGIN, NEW_CEILING = 0.5, 0.25


def decide(p, n):
    """link:i, new, or abstain: the cascade's antecedent rule."""
    ranked = sorted(range(len(p)), key=lambda i: -p[i])
    if ranked[0] < n and p[ranked[0]] - p[ranked[1]] >= MARGIN:
        return ranked[0]
    return "new" if ranked[0] == n and max(p[:n]) <= NEW_CEILING else "abstain"


def outcome(choice, gold, n):
    if isinstance(choice, int):
        return "correct link" if choice == gold else "WRONG MERGE"
    if choice == "new":
        return "correct new" if gold == n else "missed link (duplicate)" if gold < n else "new for cannot-tell"
    return "abstain (gold unknowable)" if gold == n + 1 else "abstain"


rows = {json.loads(l)["id"]: json.loads(l) for l in open(sys.argv[1])}
runs = [{json.loads(l)["id"]: json.loads(l)["p"] for l in open(f)} for f in sys.argv[2:]]
names = [f.split("/")[-1].split(".")[0] for f in sys.argv[2:]] + (["ensemble"] if len(runs) == 2 else [])
tally = {n: {} for n in names}
for rid, row in rows.items():
    n = row["candidates"]
    choices = [decide(r[rid], n) for r in runs]
    if len(runs) == 2:
        a, b = choices
        choices.append(a if a == b else "abstain")
    line = []
    for name, ch in zip(names, choices):
        o = outcome(ch, row["gold"], n)
        tally[name][o] = tally[name].get(o, 0) + 1
        line.append(f"{name}={o}")
    print(rid, "|", " ".join(line))
for name, t in tally.items():
    print(name, json.dumps(t))
