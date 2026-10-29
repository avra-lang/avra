"""The prompt that asks for a query, built here once so a training pair and the measurement
that judges it are the same bytes.

Every part comes from the catalog: the types with their property shapes, and the links the
query language allows. Nothing names a domain, so a new declared type changes the prompt by
being declared.
"""
import json


def compact(schema):
    """The schema as the query language needs it: type, properties with their shapes, and
    the declared one_of values — no descriptions, because prefill is what costs."""
    out = []
    for m in schema["models"]:
        props = []
        for p in m["properties"]:
            sh = p["shape"]
            if isinstance(sh, dict):
                inner = sh.get("optional") or sh.get("list") or sh
                kind = ("ref:" + inner["reference"]) if isinstance(inner, dict) and "reference" in inner else \
                       ("embedded:" + inner["embedded"]) if isinstance(inner, dict) and "embedded" in inner else \
                       ("list" if "list" in sh else "opt" if "optional" in sh else json.dumps(inner)[:16])
            else:
                kind = str(sh)
            if p.get("time"):
                kind += "/" + p["time"]["encoding"]
            if p.get("enum"):
                kind += "=" + "|".join(p["enum"])
            props.append(f"{p['name']}:{kind}")
        out.append(f"{m['name']}({', '.join(props)})")
    return "\n".join(out)


def reference(shape):
    """The model a reference shape points at, through optional and list."""
    if not isinstance(shape, dict):
        return None
    inner = shape.get("optional") or shape.get("list")
    return reference(inner) if inner is not None else shape.get("reference")


def links(schema):
    """Every edge the language allows: a reference property's own name, and a relation
    model's declared label values between its two endpoints."""
    out = []
    for m in schema["models"]:
        for p in m["properties"]:
            t = reference(p["shape"])
            if t:
                out.append(f"({m['name']})-[:{p['name']}]->({t})")
        rel = (m.get("semantics") or {}).get("relation")
        if rel:
            seat = {p["name"]: p for p in m["properties"]}
            ends = [reference(seat[rel[s][0]]["shape"]) if rel.get(s) and rel[s][0] in seat else None for s in ("from", "to")]
            if all(ends):
                for lab in [v["value"] for v in rel.get("labels") or []]:
                    out.append(f"({ends[0]})-[:{lab}]->({ends[1]})")
    return out


RULES = ("Rules: no WITH, no ORDER BY, no UNWIND; follow a reference with a LINK, never a.b.c; "
         "every RETURN item needs its own AS name; use $asker, $now, $speaker.\n"
         "Answer with the query only.")


def ask(question, schema):
    """The user message one question is answered from, exactly as training and measurement send it."""
    return (f"Write one Cypher query that answers the question.\n\n"
            f"TYPES (name(property:shape); ref:X points at type X; opt/list are optional/many):\n{compact(schema)}\n\n"
            f"LINKS (the only edges allowed, written (A)-[:name]->(B)):\n" + "\n".join(links(schema)) + "\n\n"
            f"{RULES}\n\n"
            f"QUESTION: {question}\n\nCypher:")
