"""The planner's prompt: the subset's rules and a schema rendered from the catalog.

Everything domain-specific comes from the catalog the graph reports; the
worked examples use an unrelated ontology so they teach syntax, not answers.
"""
from subset import models_of, base_shape, reference_target

RULES = """You translate a question about a personal knowledge graph into ONE read-only query in a small openCypher subset. Output only the query, no prose, no code fence.

The subset:
- One or more `MATCH pattern [WHERE conditions]` clauses, then `RETURN item [AS name], ...`. A later MATCH may start from the LAST node of an earlier one, unlabelled and not filtered again, to reach more: `MATCH (c)-[:event]->(e:Event)`. No other variable is shared.
- A node is `(var:Model)`; the first node of each MATCH needs its Model label.
- `(a:A)-[:prop]->(b)` follows reference property `prop` of model A to its target. `(a)<-[:prop]-(b:B)` reaches the B records whose reference property `prop` points at a; label B there.
- A relationship record (such as a family relation or a membership) is a NODE with its own label; reach it with `<-[:prop]-` and leave it with `-[:prop]->`.
- WHERE joins conditions with AND only: `v.prop = 'text'`, `v.prop <> ...`, `< <= > >=` on numbers, `v.prop CONTAINS 'word'`, `v.prop IS NULL`, `v.prop IS NOT NULL`, and `id(v) = $speaker` on the first node of a MATCH. No OR, no NOT, no property maps, no relationship variables.
- RETURN reads properties of the LAST node of any MATCH only. Name each item with AS in snake_case after what the question asks. `count(v)` or `sum(v.prop)` must be the only item.
- Compare a reference property by following it with a pattern, never `v.ref = 'id'`.

Binding the question:
- "I", "me", "my" mean the speaker: start at `(me:Person)` with `WHERE id(me) = $speaker`. Never write an entity id.
- A person named in the question is matched by name: `p.name = 'Their Name'`.
- A relationship word (wife, mum, member of, ...) is never a relationship type. Walk the relationship record with the model's `pattern` line and filter its label property to one listed value.
- To narrow by a topic the question mentions, use CONTAINS on a text property with one lowercase key word from the question.
- Return the property that answers the question.
- A yes/no boolean may be absent. If the question asks what has been RECORDED ("has a confirmation been recorded?", "is there a record of ..."), absence means no: return `coalesce(v.prop, false) AS name` (it may sit beside other items of the same last node). If it asks about the world ("is it booked?", "did it happen?"), return `v.prop` as is, so absence is reported as unknown."""

EXAMPLE_SCHEMA = """(:Technician) A person who services devices.
  .name: string
(:Device) A device with a registry tag.
  .tag: string
  .owner -> (:Technician)
(:Assignment) Who looks after which device. relation is the technician's role.
  .technician -> (:Technician)
  .device -> (:Device)
  .relation: one of 'keeper', 'backup' (words: 'looks after' = 'keeper')
  pattern: (a:Technician)<-[:technician]-(r:Assignment)-[:device]->(b:Device) WHERE r.relation = '<value>'  — reads "a's <value> is b"
(:Service) A service visit.
  .device -> (:Device)
  .note: string
  .completed: boolean?"""

EXAMPLES = [
    ("Which device do I look after?",
     "MATCH (me:Technician)<-[:technician]-(a:Assignment)-[:device]->(d:Device) WHERE id(me) = $speaker AND a.relation = 'keeper' RETURN d.tag AS device"),
    ("Has the calibration visit on Kim Ito's device been completed?",
     "MATCH (t:Technician)<-[:owner]-(d:Device)<-[:device]-(s:Service) WHERE t.name = 'Kim Ito' AND s.note CONTAINS 'calibration' RETURN s.completed AS completed"),
    ("Is there a recorded completion for the calibration visit on my device?",
     "MATCH (me:Technician)<-[:owner]-(d:Device)<-[:device]-(s:Service) WHERE id(me) = $speaker AND s.note CONTAINS 'calibration' RETURN coalesce(s.completed, false) AS completion_recorded"),
    ("How many services did my devices get?",
     "MATCH (me:Technician)<-[:owner]-(d:Device)<-[:device]-(s:Service) WHERE id(me) = $speaker RETURN count(s) AS services"),
]


def shape_text(shape):
    shape = base_shape(shape)
    if isinstance(shape, str):
        return shape
    if "list" in shape:
        return f"list of {shape_text(shape['list'])}"
    if "embedded" in shape:
        return f"record {shape['embedded']}"
    return "?"


def line(text, limit=240):
    """One line of a description, cut at a sentence end within the limit."""
    text = " ".join(text.split())
    if len(text) <= limit:
        return text
    cut = text.rfind(". ", 0, limit)
    return text[: cut + 1] if cut > 0 else text[:limit]


def relation_pattern(name, m, models):
    """How a relationship record is walked, from its declared relation binding."""
    relation = ((m.get("semantics") or {}).get("relation")) or {}
    ends = [relation.get("from") or [], relation.get("to") or [], relation.get("label") or []]
    if any(len(path) != 1 for path in ends):
        return None
    props = {p["name"]: p for p in m["properties"]}
    source = reference_target(props[ends[0][0]]["shape"]) if ends[0][0] in props else None
    target = reference_target(props[ends[1][0]]["shape"]) if ends[1][0] in props else None
    if not source or not target:
        return None
    return (f"  pattern: (a:{source})<-[:{ends[0][0]}]-(r:{name})-[:{ends[1][0]}]->(b:{target}) "
            f"WHERE r.{ends[2][0]} = '<value>'  — reads \"a's <value> is b\"")


def render_schema(schema):
    out = []
    for name, m in models_of(schema).items():
        out.append(f"(:{name}) {line(m.get('description', ''))}".rstrip())
        relation = ((m.get("semantics") or {}).get("relation")) or {}
        label_path = relation.get("label") or []
        words = {l["value"]: [w for w in l.get("forward", []) if w != l["value"]] for l in relation.get("labels", [])}
        for p in m["properties"]:
            target = reference_target(p["shape"])
            if target:
                text = f"  .{p['name']} -> (:{target})"
            elif "enum" in p:
                text = f"  .{p['name']}: one of " + ", ".join(f"'{v}'" for v in p["enum"])
                if label_path == [p["name"]]:
                    synonyms = [f"'{w}' = '{v}'" for v, ws in words.items() for w in ws]
                    if synonyms:
                        text += f" (words: {', '.join(synonyms)})"
            else:
                optional = "?" if isinstance(p["shape"], dict) and "optional" in p["shape"] else ""
                text = f"  .{p['name']}: {shape_text(p['shape'])}{optional}"
            if p.get("description"):
                text += f" — {line(p['description'])}"
            out.append(text)
        pattern = relation_pattern(name, m, models_of(schema))
        if pattern:
            out.append(pattern)
    return "\n".join(out)


def messages(question, schema, context):
    shots = []
    for q, cypher in EXAMPLES:
        shots += [{"role": "user", "content": f"Question: {q}"}, {"role": "assistant", "content": cypher}]
    who = "The speaker is bound as $speaker." if context.get("speaker") else "No speaker is bound; do not use $speaker."
    return [
        {"role": "system", "content": f"{RULES}\n\nExample schema:\n{EXAMPLE_SCHEMA}"},
        *shots,
        {"role": "user", "content": f"Schema of this graph:\n{render_schema(schema)}\n\n{who}\nQuestion: {question}"},
    ]
