"""Measurements of a compiled catalog. Each docstring is the definition shown to the schema author."""
from cat import Cat


def named_models(c: Cat):
    """models whose records are mentioned by a declared label (a label binding)"""
    return len(c.named())


def sibling_reference_models(c: Cat):
    """models holding two or more reference properties to the same target model, under near-synonym names"""
    n = 0
    for m in c.publishable():
        targets = [t for _, t in c.references(m)]
        n += any(targets.count(t) > 1 for t in set(targets))
    return n


def relation_models(c: Cat):
    """models with a relation binding (subject, object and a closed set of labels) and a validity binding"""
    return sum(bool(c.relation(m) and c.validity(m)) for m in c.publishable())


def lookalike_relation_pairs(c: Cat):
    """pairs of relation models joining the same two models, with near-synonym labels"""
    ends = []
    for m in c.publishable():
        r = c.relation(m)
        if r:
            ends.append((c.target(c.prop(m, r["from"][0])["shape"]), c.target(c.prop(m, r["to"][0])["shape"])))
    return sum(ends.count(e) - 1 for e in set(ends))


def quantity_bindings(c: Cat):
    """quantity bindings (a numeric amount with a unit, constant or from a property)"""
    return sum(len(c.sem(m).get("quantities", [])) for m in c.models)


def time_bindings(c: Cat):
    """properties bound to a time encoding"""
    return sum(len(c.sem(m).get("times", [])) for m in c.models)


def absence_bindings(c: Cat):
    """optional properties with a declared reason code for being unrecorded"""
    return sum(len(c.sem(m).get("absences", [])) for m in c.models)


def embedded_models(c: Cat):
    """models used as embedded values inside other models (such as an amount with its currency)"""
    return len(c.embedded)


MEASURES = [named_models, sibling_reference_models, relation_models, lookalike_relation_pairs, quantity_bindings, time_bindings, absence_bindings, embedded_models]


def measured(c: Cat):
    return {f.__name__: f(c) for f in MEASURES}


def unmet(c: Cat, required):
    got = measured(c)
    return {k: (got[k], v) for k, v in required.items() if got[k] < v}


def definition(name):
    return next(f.__doc__ for f in MEASURES if f.__name__ == name)
