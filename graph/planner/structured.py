"""The structured planner arm: the model only makes closed choices, and the
query is composed from them, so it cannot invent a hop, drop the speaker or
loop. Each choice is scored by next-token probability over lettered options.

Choices, in order: what the question starts from (the speaker, an entity
named in the question, or every record of one model); each hop, from the
relationships the current node really has, or stop; on a relationship
record, its declared label value; an optional topic word on one text
property; the answer mode (values, a recorded status, a count); and the
returned properties, from the final node's real property list.
"""
import re

from subset import models_of, base_shape, reference_target, relation_ends
from prompt import line

FIRST_PERSON = re.compile(r"\b(i|me|my|mine|myself)\b", re.I)
MAX_HOPS = 4
MAX_PICKS = 4
ARRIVED = ["yes: the question asks about this record", "no: the answer lies further along"]
DONE = "nothing more"
STOPWORDS = {"what", "who", "when", "did", "does", "do", "is", "are", "was", "were", "the", "a", "an", "my",
             "me", "i", "about", "for", "to", "of", "say", "said", "ask", "asked", "how", "many", "much",
             "that", "his", "her", "she", "he", "it", "and", "or", "in", "on", "with", "could", "actually",
             "have", "has", "had", "be", "this", "there", "which", "whose"}


class Plan:
    """The composed query, built one choice at a time."""

    def __init__(self):
        self.parts, self.where, self.vars = [], [], []

    def node(self, label):
        var = f"n{len(self.vars)}"
        self.vars.append((var, label))
        return var

    def cypher(self, returns):
        text = "MATCH " + "".join(self.parts)
        if self.where:
            text += " WHERE " + " AND ".join(self.where)
        return f"{text} RETURN {returns}"


def quoted(text):
    return "'" + text.replace("'", "") + "'"


def best(chooser, context, question, options):
    """The likeliest option; one option is no choice, more than 26 run as heats."""
    if not options:
        raise ValueError(f"no options for: {question}")
    if len(options) == 1:
        return 0
    if len(options) > 26:
        heats = [options[i:i + 25] for i in range(0, len(options), 25)]
        winners = [heat[best(chooser, context, question, heat)] for heat in heats]
        return options.index(winners[best(chooser, context, question, winners)])
    p = chooser.choose(context, question, options)
    return max(range(len(options)), key=lambda i: p[i])


def names_in(question):
    """Runs of capitalized words, the question's candidate proper names."""
    words = [re.sub(r"['’]s$", "", w) for w in re.findall(r"[A-Za-z][A-Za-z'’-]*", question)]
    runs, run = [], []
    for i, w in enumerate(words):
        if w[0].isupper() and (i > 0 or w.lower() not in STOPWORDS) and w.lower() not in ("i",):
            run.append(w)
        else:
            if run:
                runs.append(" ".join(run))
            run = []
    if run:
        runs.append(" ".join(run))
    return [r for r in runs if r.lower() not in STOPWORDS]


def topic_words(question):
    """Lowercase content words, without the proper names the question anchors on."""
    named = {w.lower() for n in names_in(question) for w in n.split()}
    return [w for w in dict.fromkeys(re.findall(r"[a-z]{3,}", question.lower())) if w not in STOPWORDS | named]


def hops(models, label):
    """Each relationship a node of `label` really has, as (cypher, target, words):
    declared relation words first, then reference properties both ways."""
    out = []
    for m in models.values():
        ends = relation_ends(m)
        relation = ((m.get("semantics") or {}).get("relation")) or {}
        for l in (relation.get("labels", []) if ends else []):
            if ends[0] == label:
                also = [w for w in l.get("forward", []) if w != l["value"]]
                said = f" ({', '.join(also)})" if also else ""
                out.append((f"-[:{l['value']}]->", ends[1], f"their {l['value']}{said}: a {ends[1]}",
                            [l["value"], *also]))
            if ends[1] == label:
                for w in l.get("reverse", []):
                    out.append((f"-[:{w}]->", ends[0], f"their {w}: a {ends[0]}", [w]))
    for p in models[label]["properties"]:
        target = reference_target(p["shape"])
        if target:
            out.append((f"-[:{p['name']}]->", target, f"follow its {p['name']} to a {target}", []))
    for owner, m in models.items():
        for p in m["properties"]:
            if reference_target(p["shape"]) == label:
                about = line(m.get("description", ""), 80)
                out.append((f"<-[:{p['name']}]-", owner, f"{owner} records whose {p['name']} is this {label}: {about}", []))
    return out


def plan(chooser, question, schema, context):
    models = models_of(schema)
    head = f"Question: {question}"
    named = names_in(question)
    speaks = bool(context.get("speaker")) and FIRST_PERSON.search(question) is not None
    starts = [f"the one named {n!r} in the question" for n in named] + ["every record of one kind"]
    start = "the speaker" if speaks else starts[best(chooser, head, "What does answering the question start from?", starts)]
    out = Plan()
    if start == "the speaker":
        label = person_like(chooser, head, identified(models), "Which kind of record is the speaker?")
        var = out.node(label)
        out.parts.append(f"({var}:{label})")
        out.where.append(f"id({var}) = $speaker")
    elif start.startswith("the one named"):
        name = named[starts.index(start)]
        label = person_like(chooser, head, models, f"Which kind of record is {name}?")
        var = out.node(label)
        out.parts.append(f"({var}:{label})")
        out.where.append(f"{var}.{naming(models[label])} = {quoted(name)}")
    else:
        kinds = list(models)
        label = kinds[best(chooser, head, "Which kind of record holds the answer?", [k + ": " + line(models[k].get("description", ""), 100) for k in kinds])]
        var = out.node(label)
        out.parts.append(f"({var}:{label})")
    came = None
    words = set(re.findall(r"[a-z]+", question.lower()))
    leftover = {stem(w) for w in topic_words(question)}
    for hop in range(MAX_HOPS):
        options = [h for h in hops(models, label) if not came or (h[0], h[1]) != came]
        trail = f"{head}\nSo far: {' '.join(out.parts)} — now at a {label}."
        if not options:
            break
        said = [i for i, h in enumerate(options) if h[3] and words.intersection(h[3])]
        about = [i for i, h in enumerate(options) if leftover & mentions(models, h[1])]
        if len(said) == 1:
            pick = said[0]
            words.difference_update(options[pick][3])
            leftover -= {stem(w) for w in options[pick][3]}
        else:
            if hop > 0 and not about and best(chooser, trail, f"Is the answer about this {label}?", ARRIVED) == 0:
                break
            ranked = about or list(range(len(options)))
            pick = ranked[best(chooser, trail, "Where next?", [options[i][2] for i in ranked])]
            leftover -= mentions(models, options[pick][1], depth=0)
        arrow, target, _, _ = options[pick]
        back = ("<-" + arrow[1:-2] + "-" if arrow.endswith("->") else arrow[1:-1] + "->")
        var = out.node(target)
        out.parts.append(f"{arrow}({var}:{target})")
        came, label = (back, label), target
        used = filtered(chooser, trail, models[target], var, out, question)
        if used:
            leftover.discard(stem(used))
    trail = f"{head}\nSo far: {' '.join(out.parts)} — the answer is about these {label} records."
    return out.cypher(returns(chooser, trail, models[label], var))


def stem(word):
    return word.lower()[:5]


def mentions(models, label, depth=1):
    """Stems of what a model is about: its name, description and property names,
    and with depth 1 those of the models it references."""
    seen = [label] + ([reference_target(p["shape"]) for p in models[label]["properties"] if reference_target(p["shape"])] if depth else [])
    text = " ".join(f"{re.sub(r'(?<!^)(?=[A-Z])', ' ', m)} {models[m].get('description', '')} "
                    + " ".join(p["name"].replace("_", " ") for p in models[m]["properties"]) for m in seen if m in models)
    return {stem(w) for w in re.findall(r"[A-Za-z]{3,}", text)} - {stem(w) for w in STOPWORDS}


def identified(models):
    """Models whose records carry a declared identity: who a context id can name."""
    keyed = {k: m for k, m in models.items() if ((m.get("semantics") or {}).get("identities"))}
    return keyed or models


def person_like(chooser, head, models, question):
    named = [k for k, m in models.items() if naming(m)]
    return named[best(chooser, head, question, named)]


def naming(model):
    """The text property a record is named by, if it has one."""
    for p in model["properties"]:
        if p["name"] in ("name", "title") and base_shape(p["shape"]) == "string":
            return p["name"]
    return None


def filtered(chooser, trail, model, var, out, question):
    """A relationship record's label value, then an optional topic word."""
    relation = ((model.get("semantics") or {}).get("relation")) or {}
    label = relation.get("label") or []
    props = {p["name"]: p for p in model["properties"]}
    if len(label) == 1 and "enum" in props.get(label[0], {}):
        values = props[label[0]]["enum"]
        words = {l["value"]: l.get("forward", []) for l in relation.get("labels", [])}
        options = [f"{v} ({', '.join(words.get(v, [v]))})" for v in values] + ["any of them"]
        pick = best(chooser, trail, f"Which {label[0]} does the question mean?", options)
        if pick < len(values):
            out.where.append(f"{var}.{label[0]} = {quoted(values[pick])}")
    texts = [p for p in model["properties"] if base_shape(p["shape"]) == "string" and "enum" not in p
             and p["name"] not in label]
    words = topic_words(question)
    if not texts or not words:
        return
    options = [f"narrow by its {p['name']}" for p in texts] + ["no narrowing"]
    pick = best(chooser, trail, f"Does the question narrow these {model['name']} records by a topic word?", options)
    if pick == len(texts):
        return
    word = words[best(chooser, trail, f"Which word must its {texts[pick]['name']} contain?", words)]
    out.where.append(f"{var}.{texts[pick]['name']} CONTAINS {quoted(word)}")
    return word


def returns(chooser, trail, model, var):
    """The RETURN items: a count, one recorded status, or chosen values."""
    modes = ["the value of one or more of their properties",
             "whether a yes/no status has been recorded (absent counts as no)", "how many there are"]
    mode = best(chooser, trail, "What does the question ask for?", modes)
    props = model["properties"]
    if mode == 2:
        return f"count({var}) AS count"
    if mode == 1:
        flags = [p["name"] for p in props if base_shape(p["shape"]) == "boolean"]
        if flags:
            name = flags[best(chooser, trail, "Which recorded status?", flags)]
            return f"coalesce({var}.{name}, false) AS {name}"
    names = [p["name"] + (": " + line(p["description"], 80) if p.get("description") else "") for p in props]
    picked = []
    for _ in range(MAX_PICKS):
        options = [n for i, n in enumerate(names) if i not in picked] + [DONE]
        at = best(chooser, trail + ("\nAlready returned: " + ", ".join(props[i]["name"] for i in picked) if picked else ""),
                  "Which property answers the question?" if not picked else "Which other property does the answer need?",
                  options)
        if at == len(options) - 1 and picked:
            break
        if at == len(options) - 1:
            continue
        picked.append(names.index(options[at]))
    return ", ".join(f"{var}.{props[i]['name']} AS {props[i]['name']}" for i in picked or [0])
