"""The graph's read-only openCypher subset, checked against one catalog.

A planner's draft passes only when it parses under the subset grammar
(graph/cypher/src/{lexicon,parser}.av) and every label, relationship type,
property, literal and parameter it names exists in the catalog. Errors
carry the problem codes the graph's own compiler uses, so a retry prompt
quotes the same refusal the graph would.
"""
import re

KEYWORDS = {"MATCH", "OPTIONAL", "WHERE", "AND", "OR", "NOT", "RETURN", "AS", "LIMIT",
            "CONTAINS", "IS", "NULL", "TRUE", "FALSE"}
REFUSED = {"CREATE": "mutation_refused", "MERGE": "mutation_refused", "SET": "mutation_refused",
           "DELETE": "mutation_refused", "DETACH": "mutation_refused", "REMOVE": "mutation_refused",
           "CALL": "procedure_refused", "WITH": "unsupported_clause", "UNWIND": "unsupported_clause",
           "UNION": "unsupported_clause", "ORDER": "unsupported_clause", "SKIP": "unsupported_clause",
           "DISTINCT": "unsupported_clause"}
CONTEXT = {"speaker", "asker"}
TOKEN = re.compile(r"""\s+|//[^\n]*|(?P<str>'[^']*'|"[^"]*")|(?P<param>\$[A-Za-z_][A-Za-z_0-9]*)
    |(?P<num>\d+(?:\.\d+)?)|(?P<ident>[A-Za-z_][A-Za-z_0-9]*)
    |(?P<op><-|->|<=|>=|<>|\.\.|[()\[\]{},.:=<>\-+*|;])""", re.X)


class Refusal(Exception):
    def __init__(self, code, message):
        super().__init__(f"{code}: {message}")
        self.code, self.message = code, message


def tokens(text):
    out, at = [], 0
    while at < len(text):
        m = TOKEN.match(text, at)
        if not m:
            raise Refusal("syntax", f"unexpected character {text[at]!r} at {at}")
        at = m.end()
        kind = m.lastgroup
        if kind:
            out.append((kind, m.group(kind)))
    return out


class Parser:
    def __init__(self, text):
        self.toks, self.i = tokens(text), 0
        for kind, value in self.toks:
            if kind == "ident" and value.upper() in REFUSED:
                raise Refusal(REFUSED[value.upper()], f"`{value}` is not part of the read-only subset")

    def peek(self, offset=0):
        at = self.i + offset
        return self.toks[at] if at < len(self.toks) else ("eof", "")

    def word(self, w):
        kind, value = self.peek()
        return kind == "ident" and value.upper() == w

    def op(self, o):
        return self.peek() == ("op", o)

    def take_word(self, w):
        if not self.word(w):
            raise Refusal("syntax", f"expected {w}, found {self.peek()[1]!r}")
        self.i += 1

    def take_op(self, o):
        if not self.op(o):
            raise Refusal("syntax", f"expected {o!r}, found {self.peek()[1]!r}")
        self.i += 1

    def ident(self):
        kind, value = self.peek()
        if kind != "ident" or value.upper() in KEYWORDS:
            raise Refusal("syntax", f"expected a name, found {value!r}")
        self.i += 1
        return value

    def query(self):
        chains = []
        while self.word("MATCH") or self.word("OPTIONAL"):
            optional = self.word("OPTIONAL")
            if optional:
                self.i += 1
            self.take_word("MATCH")
            nodes, rels = self.pattern()
            where = []
            if self.word("WHERE"):
                self.i += 1
                where = self.conditions()
            chains.append({"optional": optional, "nodes": nodes, "rels": rels, "where": where})
        if not chains:
            raise Refusal("syntax", "a query starts with MATCH")
        self.take_word("RETURN")
        items = [self.item()]
        while self.op(","):
            self.i += 1
            items.append(self.item())
        limit = None
        if self.word("LIMIT"):
            self.i += 1
            kind, value = self.peek()
            if kind != "num" or "." in value:
                raise Refusal("syntax", "LIMIT takes a whole number")
            self.i += 1
            limit = int(value)
        if self.peek()[0] != "eof":
            raise Refusal("syntax", f"unexpected {self.peek()[1]!r} after RETURN")
        return {"chains": chains, "items": items, "limit": limit}

    def pattern(self):
        nodes, rels = [self.node()], []
        while self.op("-") or self.op("<-"):
            incoming = self.op("<-")
            self.i += 1
            self.take_op("[")
            var = self.ident() if self.peek()[0] == "ident" else None
            self.take_op(":")
            rel = self.ident()
            if self.op("*"):
                raise Refusal("variable_length_path", "variable-length paths are not supported")
            self.take_op("]")
            self.take_op("-" if incoming else "->")
            rels.append({"type": rel, "incoming": incoming, "var": var})
            nodes.append(self.node())
        return nodes, rels

    def node(self):
        self.take_op("(")
        var = label = None
        if self.peek()[0] == "ident":
            var = self.ident()
        if self.op(":"):
            self.i += 1
            label = self.ident()
        props = []
        if self.op("{"):
            self.i += 1
            while not self.op("}"):
                key = self.ident()
                self.take_op(":")
                props.append((key, self.value()))
                if not self.op(","):
                    break
                self.i += 1
            self.take_op("}")
        self.take_op(")")
        if var is None:
            raise Refusal("syntax", "every node names a variable")
        return {"var": var, "label": label, "props": props}

    def conditions(self):
        conds = [self.condition()]
        while self.word("AND") or self.word("OR"):
            if self.word("OR"):
                raise Refusal("unsupported_or", "conditions are joined by AND only")
            self.i += 1
            conds.append(self.condition())
        return conds

    def condition(self):
        if self.word("NOT"):
            raise Refusal("unsupported_not", "NOT is not supported; use <> or IS NULL")
        if self.word("ID") and self.peek(1) == ("op", "("):
            self.i += 2
            var = self.ident()
            self.take_op(")")
            self.take_op("=")
            kind, value = self.peek()
            if kind != "param":
                raise Refusal("syntax", "id(var) compares to $speaker or $asker")
            self.i += 1
            return {"kind": "id", "var": var, "param": value[1:]}
        ref = self.prop()
        if self.word("CONTAINS"):
            self.i += 1
            return {"kind": "contains", "ref": ref, "value": self.value()}
        if self.word("IS"):
            self.i += 1
            negated = self.word("NOT")
            if negated:
                self.i += 1
            self.take_word("NULL")
            return {"kind": "null", "ref": ref, "negated": negated}
        kind, value = self.peek()
        if kind != "op" or value not in ("=", "<>", "<", "<=", ">", ">="):
            raise Refusal("syntax", f"expected a comparison after {ref[0]}.{ref[1]}")
        self.i += 1
        return {"kind": "compare", "ref": ref, "op": value, "value": self.value()}

    def prop(self):
        var = self.ident()
        self.take_op(".")
        return (var, self.ident())

    def value(self):
        kind, value = self.peek()
        negative = False
        if (kind, value) == ("op", "-"):
            self.i += 1
            kind, value = self.peek()
            negative = True
            if kind != "num":
                raise Refusal("syntax", "a minus sign precedes a number")
        self.i += 1
        if kind == "str":
            return ("text", value[1:-1])
        if kind == "num":
            number = float(value) if "." in value else int(value)
            return ("number", -number if negative else number)
        if kind == "param":
            return ("param", value[1:])
        if kind == "ident" and value.upper() in ("TRUE", "FALSE"):
            return ("bool", value.upper() == "TRUE")
        raise Refusal("syntax", f"expected a literal or parameter, found {value!r}")

    def item(self):
        kind, value = self.peek()
        if kind == "ident" and self.peek(1) == ("op", "(") and value.lower() in ("count", "sum", "coalesce"):
            fn = value.lower()
            self.i += 2
            if fn == "count" and self.op("*"):
                self.i += 1
                arg = None
            elif fn == "count":
                arg = self.ident()
            else:
                arg = self.prop()
            fallback = None
            if fn == "coalesce":
                self.take_op(",")
                fallback = self.value()
                if fallback != ("bool", False):
                    raise Refusal("syntax", "coalesce takes a boolean property and false")
            self.take_op(")")
            return {"fn": fn, "arg": arg, "as": self.alias()}
        return {"fn": None, "arg": self.prop(), "as": self.alias()}

    def alias(self):
        if self.word("AS"):
            self.i += 1
            return self.ident()
        return None


def models_of(schema):
    """The catalog's model descriptors from a `schema` op answer or a bare list."""
    models = schema.get("models", schema) if isinstance(schema, dict) else schema
    return {m["name"]: m for m in models}


def base_shape(shape):
    while isinstance(shape, dict) and "optional" in shape:
        shape = shape["optional"]
    return shape


def reference_target(shape):
    shape = base_shape(shape)
    if isinstance(shape, dict) and "list" in shape:
        shape = base_shape(shape["list"])
    return shape.get("reference") if isinstance(shape, dict) else None


def prop_of(models, label, name):
    for p in models[label]["properties"]:
        if p["name"] == name:
            return p
    raise Refusal("unknown_property", f"{label} has no property `{name}`; {reachable(models, label)}")


def hop_of(models, label, name):
    """The reference property a relationship type names, case-insensitively."""
    for p in models[label]["properties"]:
        if p["name"].lower() == name.lower():
            return p
    raise Refusal("unknown_relationship", f"`{name}` is no relationship of {label}; {reachable(models, label)}")


def reachable(models, label):
    """The relationship types a node of `label` can take, as a retry hint."""
    out = [f"-[:{p['name']}]->(:{reference_target(p['shape'])})" for p in models[label]["properties"]
           if reference_target(p["shape"])]
    into = [f"<-[:{p['name']}]-(:{owner})" for owner, m in models.items() for p in m["properties"]
            if reference_target(p["shape"]) == label]
    words = [f"-[:{w}]->(:{ends[1 if forward else 0]})" for m in models.values() if (ends := relation_ends(m))
             for w, forward in relation_words(m) if ends[0 if forward else 1] == label]
    hops = list(dict.fromkeys(words)) + out + into
    return f"from (:{label}) you can go " + ", ".join(hops) if hops else f"(:{label}) has no relationships"


def relation_words(model):
    """(word, forward) for every relationship type a relation binding declares."""
    relation = ((model.get("semantics") or {}).get("relation")) or {}
    for label in relation.get("labels", []):
        for word in [label["value"], *label.get("forward", [])]:
            yield word.lower(), True
        for word in label.get("reverse", []):
            yield word.lower(), False


def relation_ends(model):
    relation = ((model.get("semantics") or {}).get("relation")) or {}
    ends = [relation.get("from") or [], relation.get("to") or []]
    if any(len(path) != 1 for path in ends):
        return None
    props = {p["name"]: p for p in model["properties"]}
    targets = [reference_target(props[path[0]]["shape"]) if path[0] in props else None for path in ends]
    return None if None in targets else targets


def relation_word(models, labels, here, there, rel):
    """(record model, label of `there`) when the type is a declared relation word.

    `(x)-[:T]->(y)` reads "y is x's T"; `<-[:T]-` swaps which written node is x.
    A real reference property of the walking node's model wins over a word."""
    word = rel["type"].lower()
    owner = labels.get(here["var"]) if not rel["incoming"] else there["label"]
    if owner in models and any(p["name"].lower() == word and reference_target(p["shape"])
                               for p in models[owner]["properties"]):
        return None
    x = here if not rel["incoming"] else there
    near = labels.get(x["var"]) or x["label"]
    found = []
    for name, m in models.items():
        ends = relation_ends(m)
        for w, forward in (relation_words(m) if ends else []):
            if w == word and (near is None or ends[0 if forward else 1] == near):
                found.append((name, ends[0 if forward else 1], ends[1 if forward else 0]))
    found = list(dict.fromkeys(found))
    if not found:
        return None
    if len(found) > 1:
        raise Refusal("ambiguous_relationship", f"`{rel['type']}` names {', '.join(f[0] for f in found)}")
    record, x_label, y_label = found[0]
    if rel["incoming"]:
        if not there["label"]:
            raise Refusal("unlabelled_node", f"`{there['var']}` starts `{rel['type']}`; label it")
        if labels[here["var"]] != y_label:
            raise Refusal("label_mismatch", f"`{rel['type']}` reaches a {y_label}, not {labels[here['var']]}")
        return record, x_label
    return record, y_label


def check(text, schema, params):
    """The parsed query when it is valid against the catalog; else a Refusal."""
    q = Parser(text).query()
    models = models_of(schema)
    labels, seen, lasts = {}, set(), []
    for chain in q["chains"]:
        nodes, rels = chain["nodes"], chain["rels"]
        rebound = nodes[0]["var"] in lasts
        if rebound and not rels:
            raise Refusal("unused_match", "a rebound variable needs a hop to reach something new")
        if not rebound and not nodes[0]["label"]:
            raise Refusal("unlabelled_node", f"the first node `{nodes[0]['var']}` of a MATCH needs a label")
        if rebound and nodes[0]["label"] and nodes[0]["label"] != labels[nodes[0]["var"]]:
            raise Refusal("label_mismatch", f"`{nodes[0]['var']}` is a {labels[nodes[0]['var']]}")
        for n in nodes[1:] if rebound else nodes:
            if n["var"] in seen:
                raise Refusal("duplicate_variable", f"a variable names one node: {n['var']} (only the last node of an earlier MATCH may start a later one)")
            seen.add(n["var"])
            if n["label"] and n["label"] not in models:
                raise Refusal("label_mismatch", f"no model is named `{n['label']}`")
        if rebound:
            if any(c["kind"] != "id" and c["ref"][0] == nodes[0]["var"] for c in chain["where"]):
                raise Refusal("unsupported_rebound_filter", "filter a rebound variable where it was first matched")
        else:
            labels[nodes[0]["var"]] = nodes[0]["label"]
        for i, rel in enumerate(rels):
            here, there = nodes[i], nodes[i + 1]
            virtual = relation_word(models, labels, here, there, rel)
            if virtual:
                record, far = virtual
                if there["label"] and there["label"] != far:
                    raise Refusal("label_mismatch", f"`{rel['type']}` reaches a {far}, not {there['label']}")
                labels[there["var"]] = far
                if rel["var"]:
                    if rel["var"] in seen:
                        raise Refusal("duplicate_variable", f"a variable names one node: {rel['var']}")
                    seen.add(rel["var"])
                    labels[rel["var"]] = record
                continue
            if rel["var"]:
                raise Refusal("relationship_variable", "only a relation word's relationship can be named")
            if rel["incoming"]:
                if not there["label"]:
                    raise Refusal("unlabelled_node", f"`{there['var']}` owns `{rel['type']}`; label it")
                target = reference_target(hop_of(models, there["label"], rel["type"])["shape"])
                if target is None:
                    raise Refusal("label_mismatch", f"{there['label']}.{rel['type']} is not a reference")
                if target != labels[here["var"]]:
                    raise Refusal("label_mismatch", f"{there['label']}.{rel['type']} points at {target}, not {labels[here['var']]}")
                labels[there["var"]] = there["label"]
            else:
                target = reference_target(hop_of(models, labels[here["var"]], rel["type"])["shape"])
                if target is None:
                    raise Refusal("label_mismatch", f"{labels[here['var']]}.{rel['type']} is not a reference")
                if there["label"] and there["label"] != target:
                    raise Refusal("label_mismatch", f"{labels[here['var']]}.{rel['type']} points at {target}, not {there['label']}")
                labels[there["var"]] = target
        for n in nodes:
            for key, value in n["props"]:
                chain["where"].append({"kind": "compare", "ref": (n["var"], key), "op": "=", "value": value})
        for cond in chain["where"]:
            check_condition(cond, models, labels, nodes[0]["var"], params)
        lasts.append(nodes[-1]["var"])
        lasts.extend(r["var"] for r in rels if r["var"])
    aggregate = [it for it in q["items"] if it["fn"] in ("count", "sum")]
    if aggregate and len(q["items"]) > 1:
        raise Refusal("syntax", f"{aggregate[0]['fn']}(...) must be the only RETURN item")
    names = []
    for it in q["items"]:
        if it["fn"] == "count":
            if it["arg"] is not None and it["arg"] not in seen:
                raise Refusal("unknown_variable", f"`{it['arg']}` is not bound")
            continue
        var, name = it["arg"]
        if var not in labels:
            raise Refusal("unknown_variable", f"`{var}` is not bound")
        if var not in lasts:
            raise Refusal("return_not_last", f"only the last node of a MATCH can be returned, not `{var}`")
        p = prop_of(models, labels[var], name)
        shape = base_shape(p["shape"])
        if it["fn"] == "sum" and shape != "integer":
            raise Refusal("syntax", f"sum reads an integer property, {labels[var]}.{name} is not one")
        if it["fn"] == "coalesce" and shape != "boolean":
            raise Refusal("syntax", f"coalesce reads a boolean property, {labels[var]}.{name} is not one")
        names.append(it["as"] or name)
    if len(set(names)) != len(names):
        raise Refusal("syntax", "RETURN names must be distinct")
    return q


def check_condition(cond, models, labels, first, params):
    if cond["kind"] == "id":
        if cond["var"] != first:
            raise Refusal("syntax", "id(var) applies only to the first node of its MATCH")
        if cond["param"] not in CONTEXT:
            raise Refusal("unbound_parameter", "id(var) compares only to $speaker or $asker")
        if cond["param"] not in params:
            raise Refusal("missing_parameter", f"${cond['param']} is not bound in this context")
        return
    var, name = cond["ref"]
    if var not in labels:
        raise Refusal("unknown_variable", f"`{var}` is not bound")
    p = prop_of(models, labels[var], name)
    if cond["kind"] == "null":
        return
    kind, value = cond["value"]
    if kind == "param":
        if value not in params:
            raise Refusal("missing_parameter", f"${value} is not bound")
        return
    shape = base_shape(p["shape"])
    if cond["kind"] == "contains" and shape != "string":
        raise Refusal("syntax", f"CONTAINS reads text, {labels[var]}.{name} is not text")
    if reference_target(p["shape"]) is not None:
        raise Refusal("syntax", f"{labels[var]}.{name} is a reference; follow it with -[:{name}]-> instead of comparing it")
    expected = {"string": "text", "integer": "number", "number": "number", "boolean": "bool"}.get(shape)
    if expected != kind:
        raise Refusal("syntax", f"{labels[var]}.{name} is {shape}, compared with a {kind} literal")
    if cond["kind"] == "compare" and "enum" in p and value not in p["enum"]:
        raise Refusal("syntax", f"{labels[var]}.{name} is one of {', '.join(p['enum'])}; {value!r} is not")
