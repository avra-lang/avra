"""The structured planner arm: the model only makes closed choices, and the
query is composed from them, so it cannot invent a hop, drop the speaker or
loop. Each choice is scored by next-token probability over lettered options.

Nothing here names words of a language. Evidence comes from three places
only: the catalog's declarations (models, references, declared relation
phrases, enum values), the graph's own search over admitted facts, and the
model's closed choices. A choice the evidence settles alone (one declared
phrase spoken, one record the question names) is taken without the model.
"""
import re

from subset import models_of, base_shape, reference_target, relation_ends
from prompt import line

# The choose op letters its options A-Z; longer lists run as heats.
LETTERS = 26
ARRIVED = ["yes: the question asks about this record", "no: the answer lies further along"]
NEEDED = ["yes", "no"]
RECORDED = ["what has been recorded about it (no record counts as no)",
            "what is true or happened in the world (no record means unknown)"]


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


class Evidence:
    """What the graph's search says about the question: admitted facts as
    (model, property, value), best first. Without a graph there is none."""

    def __init__(self, search, question, models):
        self.facts = []
        for p in (search(question) if search else []):
            if p.get("kind") != "fact":
                continue
            head, _, value = p["text"].partition(": ")
            model, _, prop = head.partition(" ")
            if model in models and any(q["name"] == prop for q in models[model]["properties"]):
                self.facts.append((model, prop, value))
        self.spent, self.used = set(), set()

    def named(self, question):
        """Facts whose whole value the question spells: records it names."""
        return [f for f in self.facts if spoken(f[2], question.lower())]

    def models(self):
        """Models whose facts the question's words found and no hop has used yet."""
        return {m for m, _, _ in self.facts} - self.spent

    def about(self, model, question):
        """(property, shared words) for this model's facts that share words with the question."""
        words = set(tokens(question))
        return [(prop, [w for w in tokens(value) if w in words]) for m, prop, value in self.facts
                if m == model and (m, prop, value) not in self.used and words & set(tokens(value))]


def quoted(text):
    return "'" + text.replace("'", "") + "'"


def tokens(text):
    return re.findall(r"\w+", text.lower())


def spoken(phrase, text):
    """Whether a phrase occurs in the text as whole words."""
    return re.search(rf"\b{re.escape(phrase.lower())}\b", text) is not None


def unsaid(phrases, text):
    """The text without the phrases a hop has answered for."""
    for p in phrases:
        text = re.sub(rf"\b{re.escape(p.lower())}\b", " ", text)
    return text


def best(chooser, context, question, options):
    """The likeliest option; one option is no choice."""
    budget = getattr(chooser, "budget", None)
    if budget:
        budget.holds(context, question, *options)
    if not options:
        raise ValueError(f"no options for: {question}")
    if len(options) == 1:
        return 0
    if len(options) > LETTERS:
        heats = [options[i:i + LETTERS - 1] for i in range(0, len(options), LETTERS - 1)]
        winners = [heat[best(chooser, context, question, heat)] for heat in heats]
        return options.index(winners[best(chooser, context, question, winners)])
    p = chooser.choose(context, question, options)
    return max(range(len(options)), key=lambda i: p[i])


def hops(models, label):
    """Each relationship a node of `label` really has, as (cypher, target, words, phrases):
    declared relation phrases first, then reference properties both ways."""
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
                about = line(m.get("description", ""))
                out.append((f"<-[:{p['name']}]-", owner, f"{owner} records whose {p['name']} is this {label}: {about}", []))
    return out


def plan(chooser, question, schema, context, search=None, depth=None):
    """One query composed from closed choices; `depth` caps the hops (the
    request's budget), else the catalog's size bounds the walk."""
    models = models_of(schema)
    head = f"Question: {question}"
    evidence = Evidence(search, question, models)
    out = Plan()
    var, label = anchored(chooser, head, question, models, context, evidence, out)
    came = None
    phrasing = question.lower()
    for hop in range(depth if depth is not None else len(models)):
        options = [h for h in hops(models, label) if not came or (h[0], h[1]) != came]
        trail = f"{head}\nSo far: {' '.join(out.parts)} — now at a {label}."
        if not options:
            break
        said = [i for i, h in enumerate(options) if any(spoken(p, phrasing) for p in h[3])]
        onward = [i for i, h in enumerate(options) if h[1] in evidence.models()]
        if said:
            pick = said[0] if len(said) == 1 else said[best(chooser, trail, "Which relation does the question mean?",
                                                              [options[i][2] for i in said])]
            phrasing = unsaid(options[pick][3], phrasing)
        else:
            if hop > 0 and not onward and best(chooser, trail, f"Is the answer about this {label}?", ARRIVED) == 0:
                break
            ranked = onward or list(range(len(options)))
            pick = ranked[best(chooser, trail, "Where next?", [options[i][2] for i in ranked])]
        arrow, target, _, _ = options[pick]
        back = ("<-" + arrow[1:-2] + "-" if arrow.endswith("->") else arrow[1:-1] + "->")
        var = out.node(target)
        out.parts.append(f"{arrow}({var}:{target})")
        came, label = (back, label), target
        narrowed(chooser, trail, models[target], var, out, question, evidence)
        evidence.spent.add(target)
    trail = f"{head}\nSo far: {' '.join(out.parts)} — the answer is about these {label} records."
    return out.cypher(returns(chooser, trail, models[label], var))


def anchored(chooser, head, question, models, context, evidence, out):
    """The first node: the speaker, a record the question names, or every record of a kind."""
    named = evidence.named(question)
    starts = (["the person asking or speaking"] if context.get("speaker") else []) \
        + [f"the {m} whose {p} is {v!r}" for m, p, v in named] + ["every record of one kind"]
    pick = best(chooser, head, "Who or what is the question about first?", starts)
    speaker = 1 if context.get("speaker") else 0
    if speaker and pick == 0:
        keyed = identified(models)
        label = keyed[best(chooser, head, "Which kind of record is the person asking?", keyed)]
        var = out.node(label)
        out.parts.append(f"({var}:{label})")
        out.where.append(f"id({var}) = $speaker")
    elif pick < speaker + len(named):
        label, prop, value = named[pick - speaker]
        evidence.used.add((label, prop, value))
        var = out.node(label)
        out.parts.append(f"({var}:{label})")
        out.where.append(f"{var}.{prop} = {quoted(value)}")
        evidence.spent.add(label)
    else:
        kinds = list(models)
        label = kinds[best(chooser, head, "Which kind of record holds the answer?",
                           [k + ": " + line(models[k].get("description", "")) for k in kinds])]
        var = out.node(label)
        out.parts.append(f"({var}:{label})")
    return var, label


def identified(models):
    """Models whose records carry a declared identity: who a context id can name."""
    keyed = [k for k, m in models.items() if ((m.get("semantics") or {}).get("identities"))]
    return keyed or list(models)


def narrowed(chooser, trail, model, var, out, question, evidence):
    """A relationship record's declared label value, then a word its facts share with the question."""
    relation = ((model.get("semantics") or {}).get("relation")) or {}
    label = relation.get("label") or []
    props = {p["name"]: p for p in model["properties"]}
    if len(label) == 1 and props.get(label[0], {}).get("enum"):
        values = props[label[0]]["enum"]
        words = {l["value"]: l.get("forward", []) for l in relation.get("labels", [])}
        options = [f"{v} ({', '.join(words.get(v, [v]))})" for v in values] + ["any of them"]
        pick = best(chooser, trail, f"Which {label[0]} does the question mean?", options)
        if pick < len(values):
            out.where.append(f"{var}.{label[0]} = {quoted(values[pick])}")
    shared = [(prop, w) for prop, words in evidence.about(model["name"], question) for w in words
              if base_shape(props[prop]["shape"]) == "string" and not props[prop].get("enum")]
    shared = list(dict.fromkeys(shared))
    if not shared:
        return
    options = [f"its {prop} contains {w!r}" for prop, w in shared] + ["no narrowing"]
    pick = best(chooser, trail, f"Which of these narrows the {model['name']} records to the ones the question means?", options)
    if pick < len(shared):
        prop, w = shared[pick]
        out.where.append(f"{var}.{prop} CONTAINS {quoted(w)}")


def returns(chooser, trail, model, var):
    """The RETURN items: a count, one recorded status, or chosen values."""
    props = model["properties"]
    if best(chooser, trail, "What does the question ask for?",
            ["the value of one or more of their properties", "how many there are"]) == 1:
        return f"count({var}) AS count"
    flags = [p["name"] for p in props if base_shape(p["shape"]) == "boolean"]
    if flags and best(chooser, trail, "Does the question ask about", RECORDED) == 0:
        name = flags[best(chooser, trail, "Which recorded status?", flags)]
        return f"coalesce({var}.{name}, false) AS {name}"
    readable = [i for i, p in enumerate(props)
                if not (isinstance(base_shape(p["shape"]), dict) and "embedded" in base_shape(p["shape"]))]
    picked = []
    for i in readable:
        p = props[i]
        about = f"{p['name']}" + (f" ({line(p['description'])})" if p.get("description") else "")
        if best(chooser, trail, f"Does the answer need their {about}?", NEEDED) == 0:
            picked.append(i)
    return ", ".join(f"{var}.{props[i]['name']} AS {props[i]['name']}" for i in picked or [0])
