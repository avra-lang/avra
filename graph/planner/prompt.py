"""The planner's prompt: the subset's rules and a schema rendered from the catalog.

Everything domain-specific comes from the catalog the graph reports; the
worked examples use an unrelated ontology so they teach syntax, not answers.
"""
from catalog import models_of, base_shape, reference_target, relation_ends, relation_words

RULES = """You translate a question about a personal knowledge graph into ONE read-only query in a small openCypher subset. Output only the query, no prose, no code fence.

The subset:
- One or more `MATCH pattern [WHERE conditions]` clauses, then `RETURN item [AS name], ...`. A later MATCH may start from the LAST node of an earlier one, unlabelled and not filtered again, to reach more: `MATCH (c)-[:event]->(e:Event)`. No other variable is shared.
- A node is `(var:Model)`; the first node of each MATCH needs its Model label.
- `(a:A)-[:prop]->(b)` follows reference property `prop` of model A to its target. `(a)<-[:prop]-(b:B)` reaches the B records whose reference property `prop` points at a; label B there.
- A relation word listed under a model's `relationships` is itself a relationship type: `(me:Person)-[:wife]->(w:Person)` reads "w is my wife". Case does not matter.
- A node may carry equality filters in a property map: `(p:Person {name: 'Kim Ito'})`.
- WHERE joins conditions with AND only: `v.prop = 'text'`, `v.prop <> ...`, `< <= > >=` on numbers, `v.prop CONTAINS 'word'`, `v.prop IS NULL`, `v.prop IS NOT NULL`, and `id(v) = $speaker` on the first node of a MATCH. No OR, no NOT.
- RETURN reads properties of the LAST node of any MATCH only. Name each item with AS in snake_case after what the question asks. `count(v)` or `sum(v.prop)` must be the only item.
- Compare a reference property by following it with a pattern, never `v.ref = 'id'`.

Binding the question:
- "I", "me", "my" mean the speaker: start at `(me:Person)` with `WHERE id(me) = $speaker`. Never write an entity id.
- A person named in the question is matched by name: `(p:Person {name: 'Their Name'})`.
- A relationship word in the question (wife, mum, ...) is the listed relationship type of that word.
- To narrow by a topic the question mentions, use CONTAINS on a text property with one lowercase key word from the question.
- Return the property that answers the question.
- A yes/no boolean may be absent. If the question asks what has been RECORDED ("has a confirmation been recorded?", "is there a record of ..."), absence means no: return `coalesce(v.prop, false) AS name` (it may sit beside other items of the same last node). If it asks about the world ("is it booked?", "did it happen?"), return `v.prop` as is, so absence is reported as unknown."""

EXAMPLE_SCHEMA = """(:Technician) A person who services devices.
  .name: string
  relationships: -[:keeper]->(:Device), -[:backup]->(:Device)
(:Device) A device with a registry tag.
  .tag: string
  .owner -> (:Technician)
(:Assignment) Who looks after which device. relation is the technician's role.
  .technician -> (:Technician)
  .device -> (:Device)
  .relation: one of 'keeper', 'backup'
(:Service) A service visit.
  .device -> (:Device)
  .note: string
  .completed: boolean?"""

EXAMPLES = [
    ("Which device do I look after?",
     "MATCH (me:Technician)-[:keeper]->(d:Device) WHERE id(me) = $speaker RETURN d.tag AS device"),
    ("Has the calibration visit on Kim Ito's device been completed?",
     "MATCH (t:Technician {name: 'Kim Ito'})<-[:owner]-(d:Device)<-[:device]-(s:Service) WHERE s.note CONTAINS 'calibration' RETURN s.completed AS completed"),
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


def line(text):
    """A description on one line, whole: the prompt budget, not a cut, bounds it."""
    return " ".join(text.split())


class Budget:
    """The prompt budget, in tokens: the model's declared context window less
    the tokens an answer may take. A prompt's character count bounds its token
    count from above (a token spans at least one character), so a prompt whose
    characters fit the budget fits the model."""

    def __init__(self, context_tokens, answer_tokens):
        self.tokens = context_tokens - answer_tokens if context_tokens else None

    def holds(self, *texts):
        size = sum(len(t) for t in texts)
        if self.tokens is not None and size > self.tokens:
            raise SystemExit(f"planner: a prompt of {size} characters may exceed the model's {self.tokens}-token budget")


def declared_context(model_id, hub):
    """The context window the model's own config declares, if it is on disk."""
    import json
    import pathlib

    configs = sorted(pathlib.Path(hub).glob(f"models--{model_id.replace('/', '--')}/snapshots/*/config.json"))
    if not configs:
        return None
    return json.loads(configs[-1].read_text()).get("max_position_embeddings")


def relationships(label, models):
    """The relation words a node of `label` can walk, from every relation binding."""
    words = {}
    for m in models.values():
        ends = relation_ends(m)
        for word, forward in (relation_words(m) if ends else []):
            if ends[0 if forward else 1] == label:
                words.setdefault(word, ends[1 if forward else 0])
    return ", ".join(f"-[:{w}]->(:{target})" for w, target in words.items())


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
            elif p.get("enum"):
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
        walks = relationships(name, models_of(schema))
        if walks:
            out.append(f"  relationships: {walks}")
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
