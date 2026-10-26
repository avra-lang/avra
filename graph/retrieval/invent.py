"""Invented evaluation corpora for retrieval, entity linking and schema
linking. The resident model invents every domain, name, alias, note and
question; nothing here lists a word. Typos are character edits of a name.

usage: python invent.py OUT.json [DOMAINS] [SEED]
Needs a model service on a socket (gym/llm.py finds it); starts none.
"""
import json
import os
import random
import re
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "gym"))
from llm import Llm  # noqa: E402


def lines(reply, fields):
    rows = []
    for line in reply.splitlines():
        parts = [p.strip().strip('"*`') for p in re.sub(r"^[\s\-*\d.)]+", "", line).split("|")]
        if len(parts) == fields and all(parts):
            rows.append(parts)
    return rows


def ask(llm, prompt, fields, want, tokens=500, tries=4):
    note = ""
    for _ in range(tries):
        rows = lines(llm.generate(prompt + note, tokens), fields)
        if len(rows) >= want:
            return rows[:want]
        note = f"\n\nReply with exactly {want} lines of {fields} fields separated by `|`, nothing else."
    raise SystemExit(f"invent: no usable reply for {prompt[:80]!r}")


def typo(name, rng):
    """One character edit inside a word of the name."""
    at = rng.choice([i for i, c in enumerate(name) if c.isalpha() and 0 < i < len(name) - 1] or [0])
    kind = rng.choice(["drop", "swap", "double"])
    if kind == "drop":
        return name[:at] + name[at + 1:]
    if kind == "swap" and at + 1 < len(name):
        return name[:at] + name[at + 1] + name[at] + name[at + 2:]
    return name[:at] + name[at] + name[at:]


def domain(llm, theme, rng, n_entities):
    entities = ask(llm, f"Domain: {theme}\nInvent {n_entities} distinct named things in this domain (people, places, groups, items). One per line: full name | the short name or nickname people use for it | its kind in one or two words. Names must be unusual and unique.", 3, n_entities)
    ents = [{"id": f"e{i}", "name": n, "alias": a, "kind": k, "typo": typo(n, rng)} for i, (n, a, k) in enumerate(entities)]
    passages, questions = [], []
    for e in ents:
        others = rng.sample([o for o in ents if o is not e], 2)
        rows = ask(llm, f"Domain: {theme}\nWrite 2 short private notes (one or two sentences each) about {e['name']}. Each states a different concrete fact (a date, number, place, or event) that only that note says. In each note refer to {e['name']} by its short form {e['alias']!r}, and mention {others[0]['name']} or {others[1]['name']} once by name. One note per line, then ` | ` then a question a person would later ask whose answer is exactly that note's fact, naming the subject only by {e['alias']!r}. Format: note | question", 2, 2, tokens=300)
        for note, question in rows:
            pid = f"p{len(passages)}"
            passages.append({"id": pid, "text": note, "mentions": [e["id"]]})
            questions.append({"question": question, "gold": [pid], "entity": e["id"], "mention": e["alias"]})
    kinds = ask(llm, f"Domain: {theme}\nInvent 5 kinds of record someone in this domain would keep (a type name in CamelCase, then a one-sentence description of what one record holds). Format: Name | description", 2, 5, tokens=300)
    schema = []
    for name, desc in kinds:
        asks = ask(llm, f"A record kind {name!r}: {desc}\nWrite 4 different casual questions someone would ask that this kind of record answers. Never use the words of its name. One per line, single field.", 1, 4, tokens=200)
        schema.append({"name": name, "description": desc, "phrases": [a[0] for a in asks]})
    return {"theme": theme, "entities": ents, "passages": passages, "questions": questions, "schema": schema}


def main():
    out, n = sys.argv[1], int(sys.argv[2]) if len(sys.argv) > 2 else 5
    seed = int(sys.argv[3]) if len(sys.argv) > 3 else 1
    rng = random.Random(seed)
    llm = Llm()
    themes = [r[0] for r in ask(llm, f"Invent {n} very different private settings a person might keep notes about (a hobby, a small business, a family matter, a trip, a club). One per line, one short phrase each.", 1, n, tokens=200)]
    domains = []
    for t in themes:
        domains.append(domain(llm, t, rng, 8))
        json.dump({"seed": seed, "domains": domains}, open(out, "w"), indent=1)
        print(f"{t}: {len(domains[-1]['passages'])} passages", file=sys.stderr)


if __name__ == "__main__":
    main()
