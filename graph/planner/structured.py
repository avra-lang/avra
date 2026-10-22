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

from catalog import PARAMETERS, models_of, base_shape, reference_target, relation_ends
from prompt import line


LETTERS = PARAMETERS["choice_letters"]
ARRIVED = ["yes: the question asks about this record", "no: the answer lies further along"]
ENOUGH = "nothing else: the answer is complete"
RECORDED = ["the content of the records: values, words, dates, people (missing means unknown)",
            "only whether a yes/no status has been recorded (no record counts as no)"]


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
    """What the graph's own search says about the question.

    A record the question names is found by its whole value, whatever its
    words' frequency. Otherwise a word is evidence only where it is
    informative in this graph: its
    document frequency (passages the search returns for it alone) is at most
    the median over the question's words. Facts on enum properties are
    declared categories, matched by declarations, never by search; a
    reference's value is an entity id, never a word. A word a
    declaration, an anchor or a narrowing has explained stops counting."""

    def __init__(self, search, question, models):
        self.facts, self.every, self.words, self.spent = [], [], set(), set()
        self.used = set()
        if not search:
            return
        found = {w: search(w) for w in dict.fromkeys(tokens(question))}
        counts = sorted(len(v) for v in found.values() if v)
        if not counts:
            return
        median = counts[(len(counts) - 1) // 2]
        self.words = {w for w, hits in found.items() if hits and len(hits) <= median}
        for w, hits in found.items():
            for p in hits:
                fact = self.fact(p, models)
                if fact and fact not in self.every:
                    self.every.append(fact)
                if fact and w in self.words and fact not in self.facts:
                    self.facts.append(fact)

    @staticmethod
    def fact(passage, models):
        if passage.get("kind") != "fact":
            return None
        head, _, value = passage["text"].partition(": ")
        model, _, prop = head.partition(" ")
        declared = models.get(model, {}).get("properties", [])
        if not any(q["name"] == prop and not q.get("enum") and not reference_target(q["shape"]) for q in declared):
            return None
        return model, prop, value

    def explain(self, text):
        """Words some declaration or choice now accounts for."""
        self.words -= set(tokens(text))

    def named(self, question):
        """Facts whose whole value the question spells: records it names. A name
        is evidence however common its words are, since the whole value matches."""
        return [f for f in self.every if spoken(f[2], question.lower())]

    def models(self):
        """Models whose facts hold a still unexplained informative word."""
        return {m for m, _, value in self.facts if self.words & set(tokens(value))} - self.spent

    def points_at(self, prop):
        """Whether unexplained informative words of the question name this property."""
        text = prop["name"].replace("_", " ") + " " + prop.get("description", "")
        return bool(self.words & set(tokens(text)))

    def shown(self, hop):
        """A hop's words, with the facts of its target that hold unexplained words."""
        held = [value for m, _, value in self.facts if m == hop[1] and self.words & set(tokens(value))]
        return hop[2] + ("; such records hold: " + "; ".join(repr(v) for v in held) if held else "")

    def about(self, model, question):
        """(property, words) for this model's facts sharing words with the question:
        every shared word is offered, and the model chooses which, if any, narrows."""
        words = set(tokens(question))
        return [(prop, [w for w in tokens(value) if w in words]) for m, prop, value in self.every
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
    return max(range(len(options)), key=debiased(chooser, context, question, options).__getitem__)


def debiased(chooser, context, question, options):
    """Each option's probability averaged over the listed order and its reverse,
    so no option gains from where it is listed."""
    forward = chooser.choose(context, question, options)
    backward = chooser.choose(context, question, options[::-1])[::-1]
    return [(a + b) / 2 for a, b in zip(forward, backward)]


def hops(models, label):
    """Each relationship a node of `label` really has, as (cypher, target, words,
    phrases, record, meaning): declared relation phrases first, whose record
    model is named and whose meaning is every phrase of the label, both ways;
    then reference properties both ways."""
    out = []
    for name, m in models.items():
        ends = relation_ends(m)
        relation = ((m.get("semantics") or {}).get("relation")) or {}
        for l in (relation.get("labels", []) if ends else []):
            meaning = [l["value"], *l.get("forward", []), *l.get("reverse", [])]
            if ends[0] == label:
                also = [w for w in l.get("forward", []) if w != l["value"]]
                said = f" ({', '.join(also)})" if also else ""
                out.append((f"-[:{l['value']}]->", ends[1], f"their {l['value']}{said}: a {ends[1]}",
                            [l["value"], *also], name, meaning))
            if ends[1] == label:
                for w in l.get("reverse", []):
                    out.append((f"-[:{w}]->", ends[0], f"their {w}: a {ends[0]}", [w], name, meaning))
    for p in models[label]["properties"]:
        target = reference_target(p["shape"])
        if target:
            out.append((f"-[:{p['name']}]->", target, f"follow its {p['name']} to a {target}", [], None, []))
    for owner, m in models.items():
        for p in m["properties"]:
            if reference_target(p["shape"]) == label:
                about = line(m.get("description", ""))
                out.append((f"<-[:{p['name']}]-", owner, f"{owner} records whose {p['name']} is this {label}: {about}", [], None, []))
    return out


def plan(chooser, question, schema, context, search=None, depth=None, model_of=None):
    """One query composed from closed choices; `depth` caps the hops (the
    request's budget), else the catalog's size bounds the walk."""
    models = models_of(schema)
    head = f"Question: {question}"
    evidence = Evidence(search, question, models)
    out = Plan()
    var, label = anchored(chooser, head, question, models, context, evidence, out, model_of)
    came, held = None, None
    phrasing = question.lower()
    for hop in range(depth if depth is not None else len(models)):
        options = [h for h in hops(models, label) if not came or (h[0], h[1]) != came]
        trail = f"{head}\nSo far: {' '.join(out.parts)} — now at a {label}."
        evidence.explain(" ".join(p["name"].replace("_", " ") for p in models[label]["properties"]))
        if not options:
            break
        said = [i for i, h in enumerate(options) if any(spoken(p, phrasing) for p in h[3])]
        onward = [i for i, h in enumerate(options) if h[1] in evidence.models()]
        if said:
            pick = said[0] if len(said) == 1 else said[best(chooser, trail, "Which relation does the question mean?",
                                                              [options[i][2] for i in said])]
            evidence.explain(" ".join(options[pick][3]))
        else:
            if not onward and best(chooser, trail, f"Is the answer about this {label}?", ARRIVED) == 0:
                break
            ranked = onward or list(range(len(options)))
            pick = ranked[best(chooser, trail, "Where next?", [evidence.shown(options[i]) for i in ranked])]
        arrow, target, _, _, record, meaning = options[pick]
        phrasing = unsaid(meaning, phrasing)
        back = ("<-" + arrow[1:-2] + "-" if arrow.endswith("->") else arrow[1:-1] + "->")
        var = out.node(target)
        held = (f"r{len(out.vars) - 1}", record, len(out.parts)) if record else None
        out.parts.append(f"{arrow}({var}:{target})")
        came, label = (back, label), target
        narrowed(chooser, trail, models[target], var, out, question, evidence)
        evidence.spent.add(target)
    trail = f"{head}\nSo far: {' '.join(out.parts)} — the answer is about these {label} records."
    items = returns(chooser, trail, models[label], var, held and (held[0], models[held[1]]), evidence)
    if held and f"{held[0]}." in items:
        out.parts[held[2]] = out.parts[held[2]].replace("-[:", f"-[{held[0]}:", 1)
    return out.cypher(items)


def anchored(chooser, head, question, models, context, evidence, out, model_of=None):
    """The first node: the speaker, a record the question names, or every record of a kind."""
    named = evidence.named(question)
    starts = (["the person asking or speaking"] if context.get("speaker") else []) \
        + [f"the {m} whose {p} is {v!r}, named in the question" for m, p, v in named] + ["every record of one kind"]
    pick = best(chooser, head, "Who or what is the question about first?", starts)
    speaker = 1 if context.get("speaker") else 0
    if speaker and pick == 0:
        # The speaker is a graph entity: its model is a fact the graph holds.
        label = model_of(context["speaker"]) if model_of else None
        if label not in models:
            keyed = identified(models)
            label = keyed[best(chooser, head, "Which kind of record is the person asking?", keyed)]
        var = out.node(label)
        out.parts.append(f"({var}:{label})")
        out.where.append(f"id({var}) = $speaker")
    elif pick < speaker + len(named):
        label, prop, value = named[pick - speaker]
        evidence.used.add((label, prop, value))
        evidence.explain(value)
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
        narrowed(chooser, head, models[label], var, out, question, evidence)
        evidence.spent.add(label)
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
        evidence.explain(w)


def returns(chooser, trail, model, var, record=None, evidence=None):
    """The RETURN items: a count, one recorded status, or chosen values. The
    final node's properties are candidates; a relation record passed on the
    way is a path, so its own fields are candidates only where unexplained
    informative words of the question point at them, except its yes/no status
    fields, which answer a question that asks for a status."""
    props = [(var, model["name"], p) for p in model["properties"]]
    if record:
        props += [(record[0], record[1]["name"], p) for p in record[1]["properties"]
                  if evidence and evidence.points_at(p)]
    if best(chooser, trail, "What does the question ask for?",
            ["the value of one or more of their properties", "how many there are"]) == 1:
        return f"count({var}) AS count"
    flags = [(v, p["name"]) for v, _, p in props if base_shape(p["shape"]) == "boolean"]
    if record:
        flags += [(record[0], p["name"]) for p in record[1]["properties"]
                  if base_shape(p["shape"]) == "boolean" and (record[0], p["name"]) not in flags]
    if flags and best(chooser, trail, "What does the question want to know?", RECORDED) == 1:
        v, name = flags[best(chooser, trail, "Which recorded status?", [n for _, n in flags])]
        return f"coalesce({v}.{name}, false) AS {name}"
    shown = [f"the {owner}'s {p['name']}" + (f" ({line(p['description'])})" if p.get("description") else "")
             for _, owner, p in props]
    picked = compared(chooser, trail, shown)
    names = [props[i][2]["name"] for i in picked]
    return ", ".join(f"{props[i][0]}.{props[i][2]['name']} AS {props[i][2]['name']}"
                     + ("" if names.count(props[i][2]["name"]) == 1 else f"_{props[i][0]}")
                     for i in picked)


def compared(chooser, trail, shown):
    """One property chosen against the others, then more while the answer needs them."""
    picked = [best(chooser, trail, "Which property does the question ask for?", shown)]
    while len(picked) < len(shown):
        rest = [i for i in range(len(shown)) if i not in picked]
        asked = trail + "\nAlready answering with: " + "; ".join(shown[i] for i in picked)
        at = best(chooser, asked, "Which other property does the answer also need?",
                  [shown[i] for i in rest] + [ENOUGH])
        if at == len(rest):
            break
        picked.append(rest[at])
    return picked
