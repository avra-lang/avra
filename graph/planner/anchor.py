"""Which records a question names.

A question names a record by writing one of the values that record holds, or part of one:
"Alex's" for a label of "Alex Chen", "Hotel Bellora" for a travel booking's provider. So the
anchor is found by matching the question against EVERY declared text value in the graph, not
only against labels — and the match is token overlap, because a name is a string and an
embedding adds nothing to a string.

Nothing here is a list: the values come from the graph, the properties from the catalog, and
the only number is a coverage a caller declares.
"""
import json
import re

WORD = re.compile(r"[A-Za-z][A-Za-z'’-]{2,}")


def tokens(text):
    """A text's words, lower-cased, with a possessive's tail dropped: a question says "Alex's"
    and the value it names is "Alex Moreau", so the two must land on the same word."""
    out = []
    for word in WORD.findall(text):
        word = word.lower()
        if word.endswith(("'s", "’s")):
            word = word[:-2]
        if word:
            out.append(word)
    return out


def text_props(models, model):
    """The declared text properties of a model: a value written in words."""
    out = []
    for p in models[model]["properties"]:
        shape = p["shape"]
        inner = (shape.get("optional") or shape.get("list") or shape) if isinstance(shape, dict) else shape
        if inner == "string" and not p.get("enum") and not p.get("time"):
            out.append(p["name"])
    return out


def index(models, query):
    """Every value the graph holds in a declared text property: (model, property, value).

    Built once per revision. `query(cypher)` runs one read against the graph."""
    out = []
    for model in models:
        for prop in text_props(models, model):
            answer = query(f"MATCH (a:{model}) RETURN a.{prop} AS v")
            for field in answer.get("fields", []):
                value = field.get("value")
                if isinstance(value, str) and len(value) > 1:
                    out.append((model, prop, value))
    return out


def weights(index_entries):
    """How much a word says: a word in every value names nothing, so its weight falls with the
    share of values that carry it. The index decides, never a list of stop words."""
    import math

    seen = {}
    for _, _, value in index_entries:
        for word in set(tokens(value)):
            seen[word] = seen.get(word, 0) + 1
    total = max(1, len(index_entries))
    return {word: math.log(total / count) + 1.0 for word, count in seen.items()}


def named(question, index_entries, evidence):
    """The records a question names, best first: a value every significant token of which the
    question carries, or one that appears in it whole. A value of one token must appear as a
    word; a longer one may be covered in part, because a question says "Avery's" for
    "Avery Stone"."""
    said = set(tokens(question))
    weight = weights(index_entries)
    found = []
    for model, prop, value in index_entries:
        parts = tokens(value)
        if not parts:
            continue
        whole = value.lower() in question.lower()
        # evidence is the weight a value's matched words carry: a rare word is enough to name a
        # value, a common one is not, so the measure is absolute and no fraction is chosen
        carried = sum(weight.get(t, 1.0) for t in parts if t in said)
        if whole or (carried >= evidence and len(parts) > 1):
            found.append((model, prop, value, 1.0 if whole else carried))
    found.sort(key=lambda f: (-f[3], -len(f[2])))
    return [(m, p, v) for m, p, v, _ in found]
