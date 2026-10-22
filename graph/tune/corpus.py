"""A synthetic domain as authored (corpus/*.json) and as the real code reads it.

A domain's `models` are written compactly; `descriptor` expands them into the
shape the app's `{"op":"schema"}` answers, which is all the extractor and the
planner ever see. `check` refuses a domain whose gold cannot be placed in its
own text, so a bad authoring step stops before any example is made from it.
"""
import json
import pathlib
import re

HERE = pathlib.Path(__file__).resolve().parent
CORPUS = HERE / "corpus"
SCALARS = {"string", "integer", "boolean"}


def domains(only=None):
    """Every authored domain, by name."""
    out = {}
    for path in sorted(CORPUS.glob("*.json")):
        d = json.loads(path.read_text())
        if not only or d["domain"] in only:
            out[d["domain"]] = d
    return out


def shape_of(text, models):
    """A compact shape: `string`, `integer?`, `[string]`, a model name (a
    reference, or embedded when that model says so)."""
    if text.endswith("?"):
        return {"optional": shape_of(text[:-1], models)}
    if text.startswith("[") and text.endswith("]"):
        return {"list": shape_of(text[1:-1], models)}
    if text in SCALARS:
        return text
    if text not in models:
        raise ValueError(f"shape {text!r} names no model")
    return {"embedded": text} if models[text].get("embedded") else {"reference": text}


def prop_of(name, spec, models):
    spec = spec if isinstance(spec, dict) else {"shape": spec}
    shape = spec["shape"]
    out = {"name": name, "description": spec.get("description", ""), "rules": [], "default_source": None}
    if isinstance(shape, list):
        out["shape"] = "string"
        out["rules"] = ["one_of(" + json.dumps(shape) + ")"]
        out["enum"] = shape
    else:
        out["shape"] = shape_of(shape, models)
        if isinstance(out["shape"], dict) and "list" in out["shape"]:
            out["default_source"] = "[]"
    return out


def descriptor(domain):
    """The catalog's model descriptors, as the schema op answers them."""
    models = domain["models"]
    out = []
    for name, m in models.items():
        props = [prop_of(n, s, models) for n, s in m["properties"].items()]
        relation = None
        if m.get("relation"):
            r = m["relation"]
            relation = {"from": [r["from"]], "to": [r["to"]], "label": [r["label"]], "phrasing": r["phrasing"],
                        "labels": [{"value": v, "forward": l.get("forward", []), "reverse": l.get("reverse", []), "broader": []}
                                   for v, l in r.get("labels", {}).items()]}
        semantics = {"version": 1,
                     "identities": [{"namespace": k, "path": [k], "normalization": "trim"} for k in m.get("identities", [])],
                     "relation": relation, "validity": None, "quantities": [],
                     "absences": [{"path": [k], "code": c} for k, c in m.get("absences", {}).items()]}
        out.append({"name": name, "description": m["description"], "properties": props, "rules": [], "semantics": semantics})
    return out


def schema(domain):
    return {"fingerprint": f"synthetic:{domain['domain']}", "revision": 1, "models": descriptor(domain)}


def placed(text, surfaces):
    """Each (surface, …) located in order: a repeated surface takes its next
    occurrence, and no surface lands inside one already placed."""
    cursor, spans = {}, []
    for item in surfaces:
        s = item[0]
        at = text.find(s, cursor.get(s, 0))
        while at >= 0 and (not whole(text, at, at + len(s)) or any(a < at + len(s) and at < b for a, b, _ in spans)):
            at = text.find(s, at + 1)
        if at < 0:
            raise ValueError(f"{s!r} is not in the text (after its earlier occurrences)")
        cursor[s] = at + len(s)
        spans.append((at, at + len(s), item))
    return spans


def whole(text, a, b):
    """A span that starts and ends at word boundaries."""
    return (a == 0 or not text[a - 1].isalnum()) and (b == len(text) or not text[b].isalnum())


def fixture_names():
    """Names from the evaluation fixtures, which no synthetic text may use:
    every gold label, and the surname of every person in them."""
    names = set()
    for f in ("acceptance/entities.jsonl", "acceptance/portability/entities.jsonl"):
        for line in (HERE.parent / f).read_text().splitlines():
            e = json.loads(line)
            names.add(e["label"].lower())
            words = e["label"].split()
            if e["id"].split(":")[0] in ("person", "resident") and len(words) > 1:
                names.add(words[-1].lower())
    return names


def check(domain):
    """Problems with a domain's gold, as strings; empty when it is usable."""
    problems = []
    texts = [m["text"] for m in domain["messages"]] + [q["q"] for q in domain.get("questions", [])] \
        + [e["name"] for e in domain["entities"].values()]
    for name in sorted(fixture_names()):
        if any(re.search(rf"\b{re.escape(name)}\b", t.lower()) for t in texts):
            problems.append(f"uses evaluation fixture name {name!r}")
    try:
        desc = {m["name"]: m for m in descriptor(domain)}
    except (ValueError, KeyError) as e:
        return [f"models: {e}"]
    ents = domain["entities"]
    for eid, e in ents.items():
        if e["model"] not in desc:
            problems.append(f"entity {eid}: no model {e['model']}")
    for m in domain["messages"]:
        where = f"{m['id']}"
        t = m["text"]
        try:
            placed(t, m.get("mentions", []))
        except ValueError as e:
            problems.append(f"{where} mention: {e}")
        for mention in m.get("mentions", []):
            ref = mention[1]
            if ref not in ents and ref not in ("none", "?"):
                problems.append(f"{where}: mention {mention[0]!r} names unknown entity {ref}")
            if ref in ("none", "?") and "ref" not in mention[2:]:
                problems.append(f"{where}: only a reference word may point at {ref!r}")
        for q in m.get("quotes", []):
            if q[0] not in t:
                problems.append(f"{where}: quote {q[0]!r} not in text")
            if q[1] not in ents and q[1] not in ("author", "?"):
                problems.append(f"{where}: quote speaker {q[1]} unknown")
        for f in m.get("facts", []):
            if f["in"] not in t:
                problems.append(f"{where}: fact cue {f['in']!r} not in text")
            model = desc.get(f["model"])
            if not model:
                problems.append(f"{where}: fact model {f['model']} unknown")
                continue
            props = {p["name"]: p for p in model["properties"]}
            rel = model["semantics"]["relation"]
            if rel:
                for end in ("from", "to"):
                    if f.get(end) not in ents:
                        problems.append(f"{where}: {f['model']} {end} {f.get(end)} is no entity")
                if f.get("label") not in {l["value"] for l in rel["labels"]}:
                    problems.append(f"{where}: {f['model']} label {f.get('label')!r} undeclared")
            for k, v in f.get("fields", {}).items():
                if k not in props:
                    problems.append(f"{where}: {f['model']} has no field {k}")
                elif props[k].get("enum") and v not in props[k]["enum"]:
                    problems.append(f"{where}: {f['model']}.{k}={v!r} not one of {props[k]['enum']}")
            if f.get("act", "assert") not in ("assert", "report", "plan", "request", "condition", "draft"):
                problems.append(f"{where}: act {f.get('act')!r}")
    for i, q in enumerate(domain.get("questions", [])):
        if q.get("speaker") and q["speaker"] not in ents:
            problems.append(f"question {i}: speaker {q['speaker']} unknown")
        if not re.match(r"MATCH \(n0:\w+\)", q["cypher"]):
            problems.append(f"question {i}: cypher must start MATCH (n0:Model)")
    return problems


if __name__ == "__main__":
    import sys

    total = 0
    for name, d in domains(set(sys.argv[1:]) or None).items():
        p = check(d)
        total += len(p)
        print(f"{name}: {len(d['messages'])} messages, {len(d.get('questions', []))} questions, {len(p)} problems")
        for x in p:
            print("   ", x)
    sys.exit(1 if total else 0)
