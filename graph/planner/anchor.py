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
    return [w.lower() for w in WORD.findall(text)]


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


def named(question, index_entries, coverage):
    """The records a question names, best first: a value every significant token of which the
    question carries, or one that appears in it whole. A value of one token must appear as a
    word; a longer one may be covered in part, because a question says "Avery's" for
    "Avery Stone"."""
    said = set(tokens(question))
    found = []
    for model, prop, value in index_entries:
        parts = tokens(value)
        if not parts:
            continue
        whole = value.lower() in question.lower()
        covered = sum(1 for t in parts if t in said) / len(parts)
        if whole or (len(parts) > 1 and covered >= coverage):
            found.append((model, prop, value, 1.0 if whole else covered))
    found.sort(key=lambda f: (-f[3], -len(f[2])))
    return [(m, p, v) for m, p, v, _ in found]
