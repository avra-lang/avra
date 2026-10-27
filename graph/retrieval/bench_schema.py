"""Does schema retrieval rank the declared path a question needs?

usage: python3 bench_schema.py [--worlds dev,2 eval,3,...] [--kind flat|typed] [--items N]

For each gym question whose intent is `answer`, the gold plan names the declared
things an answer needs: the model an anchor names, the relation or reference each
hop crosses, the model a hop lands on, and the property the question asks for. This
asks the retrieval layer's own `link` op — the embedder ranking declared items by
their wording against the question — where each of those things ranks, and reports
recall@k. The wordings are built from declarations alone (a model's own description,
a relation's own phrasing and labels, a derivation's own description), so a new
declared type is indexed by being declared.

Nothing here writes a parameter: the fixture set is sealed and this reads invented
gym worlds only. Recall@k here bounds what a candidate enumerator can reach before
a single model call is spent.
"""
import argparse
import collections
import glob
import json
import os
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
GRAPH = HERE.parent
sys.path.insert(0, str(HERE))

KS = (1, 3, 5, 10, 20)


def first_sentence(description):
    """A declaration's first sentence, its wrapped lines joined."""
    text = " ".join((description or "").split())
    end = re.search(r"[.!?](\s|$)", text)
    return text[: end.end()].strip() if end else text


def label_field(model):
    """The property a model is named by: its declared label, else its first required text
    property — the same rule the extraction's own anchor uses."""
    declared = ((model.get("semantics") or {}).get("label") or [None])[0]
    if declared and any(p["name"] == declared for p in model["properties"]):
        return declared
    for p in model["properties"]:
        shape = p["shape"]
        if isinstance(shape, str) and shape == "string" and p.get("default_source") is None and not isinstance(p.get("shape"), dict):
            return p["name"]
    return None


def words(name):
    return name.replace("_", " ")


def model_items(models):
    """One item per declared model: its name, and the declaration that says what it is."""
    return [{"name": f"model/{name}", "description": first_sentence(m.get("description"))} for name, m in models.items()]


def property_items(models):
    """One item per declared property: the property of that model, worded as the extraction
    asks it (the same shape `Plan.record_queries` builds), over the model's own declaration."""
    return [
        {"name": f"property/{name}.{p['name']}", "description": f"the {words(p['name'])} of a {name}: {first_sentence(m.get('description'))}"}
        for name, m in models.items()
        for p in m["properties"]
    ]


def relation_items(models):
    """One item per declared relation record: its own phrasing and its own declared words."""
    out = []
    for name, m in models.items():
        rel = (m.get("semantics") or {}).get("relation")
        if rel:
            said = ", ".join(f"{v['value']} ({', '.join(v.get('forward') or [v['value']])})" for v in rel.get("labels") or [])
            out.append({"name": f"relation/{name}", "description": f"{rel.get('phrasing', '')}. {said}".strip(". ")})
    return out


def reference_items(models):
    """One item per declared reference property: the field that holds the link, and what it points at."""
    out = []
    for name, m in models.items():
        for p in m["properties"]:
            shape = p["shape"]
            inner = shape.get("optional") or shape.get("list") if isinstance(shape, dict) else None
            target = (inner or {}).get("reference") if isinstance(inner, dict) else (shape.get("reference") if isinstance(shape, dict) else None)
            if target:
                out.append({"name": f"reference/{name}.{p['name']}", "description": f"the {words(p['name'])} of a {name}, a {target}"})
    return out


class Fused:
    """A schema index read both ways: BM25 over the declared words and the embedder over the
    declared meaning, fused by rank. A name the question spells is a lexical match the
    embedder does not have to guess, and a paraphrase is the embedder's."""

    def __init__(self, items, embedder, store, k=60):
        import channels
        import numpy as np

        self.names = [c["name"] for c in items]
        self.texts = [f"{c['name'].split('/', 1)[1]}: {c['description']}" for c in items]
        self.lex = channels.Lexical(self.texts)
        self.store, self.embedder, self.k = store, embedder, k
        self.vectors = store.encode(embedder, self.texts, "document")
        self.channels = channels

    def link(self, phrase, n=None):
        import numpy as np

        qv = self.store.encode(self.embedder, [phrase], "query")[0]
        dense = [int(i) for i in np.argsort(-(self.vectors @ qv), kind="stable")[: max(n or len(self.names), 20)]]
        lexical = self.lex.rank(phrase, max(n or len(self.names), 20))
        fused = self.channels.rrf([dense, lexical], self.k)
        return [(self.names[i], 0.0) for i in fused[: n or len(self.names)]]


def schema_of(models, kind):
    """The declared things a question can name, as one index (`flat`) or one per kind (`typed`)."""
    kinds = {
        "model": model_items(models),
        "property": property_items(models),
        "relation": relation_items(models),
        "reference": reference_items(models),
    }
    if kind == "typed":
        return kinds
    return {"all": [item for items in kinds.values() for item in items]}


def matched(models, means):
    """The model a plan's `means` text declares: the catalog's own declaration, matched by prefix."""
    said = " ".join((means or "").split())
    for name, m in models.items():
        if said.startswith(first_sentence(m.get("description"))[:60]):
            return name
    return None


def targets(item, models):
    """What the gold plan needs a question to reach: (kind, name) pairs."""
    out = []
    for step in item.get("steps") or []:
        start, hop, ask, filt = step.get("start"), step.get("hop"), step.get("ask"), step.get("filter")
        if start:
            model = matched(models, start.get("means"))
            if model:
                out.append(("model", model))
        if hop:
            if hop.get("relation_record"):
                out.append(("relation", hop["relation_record"]))
            if hop.get("through_property"):
                out.append(("reference", f"{hop['property_owner']}.{hop['through_property']}"))
            out.append(("model", hop.get("to_model")))
        if ask:
            out.append(("model", ask.get("model")))
            out.append(("asked", f"{ask.get('model')}.{ask.get('property')}"))
        if filt:
            out.append(("model", filt.get("model")))
            out.append(("asked", f"{filt.get('model')}.{filt.get('property')}"))
    return [(k, v) for k, v in out if isinstance(v, str) and v]


def worlds(selection):
    """The gym worlds to read, as (family, seed) pairs; every built world by default."""
    if selection:
        return [tuple(s.split(",")) for s in selection]
    found = []
    for family in ("dev", "eval"):
        for path in sorted(glob.glob(str(GRAPH / "gym" / "out" / family / "*" / "items.json"))):
            found.append((family, pathlib.Path(path).parent.name))
    return found


def ranks(links):
    return {name: i + 1 for i, (name, _) in enumerate(links)}


def measure(worlds, kind, limit, retrieval, index="dense"):
    """recall@k per target kind. A property the question asks for is judged twice: as the
    model's own label field (which the model's index must carry) and as any other declared
    property (which the property's own wording must carry)."""
    import link

    hits = collections.defaultdict(lambda: collections.Counter())
    totals = collections.Counter()
    sizes = collections.Counter()
    questions = 0
    for family, seed in worlds:
        base = GRAPH / "gym" / "out" / family / seed
        catalog = json.loads((base / "catalog.json").read_text())["catalog"]
        models = {m["name"]: m for m in catalog["models"]}
        readers = link.SchemaLinker if index == "dense" else Fused
        linkers = {each: readers(items, retrieval.embedder, retrieval.store) for each, items in schema_of(models, kind).items()}
        for each, linker in linkers.items():
            sizes[each] += len(linker.names)
        for item in json.loads((base / "items.json").read_text()):
            if item.get("intent") != "answer":
                continue
            ranked_by = {each: ranks(linker.link(item["question"], 10_000)) for each, linker in linkers.items()}
            questions += 1
            for target, name in targets(item, models):
                if target == "asked":
                    model, _, prop = name.partition(".")
                    labelled = prop == label_field(models.get(model) or {"properties": []})
                    judged, key = ("label", f"model/{model}") if labelled else ("property", f"property/{name}")
                else:
                    judged, key = target, f"{target}/{name}"
                totals[judged] += 1
                rank = (ranked_by["model"] if judged == "label" else ranked_by[judged]).get(key)
                for k in KS:
                    hits[judged][k] += bool(rank and rank <= k)
            if limit and questions >= limit:
                break
    return hits, totals, sizes, questions, len(worlds)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--worlds", nargs="*", help="family,seed pairs; every built world by default")
    parser.add_argument("--kind", choices=("flat", "typed"), default="typed")
    parser.add_argument("--items", type=int, default=0, help="stop after this many questions (0 is every one)")
    parser.add_argument("--index", choices=("dense", "fused"), default="dense", help="how a schema index is read")
    args = parser.parse_args()
    sys.path.insert(0, str(HERE))
    import service

    retrieval = service.Retrieval()
    retrieval.ready()
    hits, totals, sizes, questions, worlds_read = measure(worlds(args.worlds), args.kind, args.items, retrieval, args.index)
    index = ", ".join(f"{each} {sizes[each] / max(1, worlds_read):.0f}" for each in sorted(sizes))
    print(f"{args.kind}/{args.index}: {questions} questions over {worlds_read} worlds, {sum(totals.values())} targets")
    print(f"index sizes per world: {index}")
    print(f"{'target':10s} {'n':>5s} " + " ".join(f"@{k:<4d}" for k in KS))
    for target in sorted(totals):
        print(f"{target:10s} {totals[target]:5d} " + " ".join(f"{hits[target][k] / totals[target]:5.3f}" for k in KS))


if __name__ == "__main__":
    main()
