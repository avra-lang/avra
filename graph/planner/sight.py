"""What the graph holds at the walk's current point, shown beside an option.

An option's words say what a field or relation is called; a sample of what it
reaches from the records bound so far says which one the question means. Every
figure is read by executing a query against the graph (the `query` op), never
from the catalog's words. A record is shown by its declared label property,
else by its first declared string property.
"""
from catalog import base_shape, reference_target


class Sight:
    """Read-only previews through `probe`, a function from a query to the graph's answer."""

    def __init__(self, probe, models, rows):
        self.probe, self.models, self.rows = probe, models, rows

    def count(self, query):
        """How many rows the query binds; none when the graph refuses it."""
        answer = self.probe(query)
        if answer.get("status") == "answered":
            return answer["fields"][0]["value"]
        return 0 if answer.get("status") == "unknown" else None

    def sample(self, query):
        """The distinct values the query returns, in the graph's order; none when the graph refuses it."""
        answer = self.probe(query)
        if answer.get("status") not in ("answered", "unknown"):
            return None
        return list(dict.fromkeys(render(f["value"]) for f in answer["fields"]))

    def label_of(self, model):
        """The property that names a record of this model."""
        declared = ((self.models[model].get("semantics") or {}).get("label")) or []
        if len(declared) == 1:
            return declared[0]
        return next((p["name"] for p in self.models[model]["properties"]
                     if base_shape(p["shape"]) == "string" and not reference_target(p["shape"])), None)

    def reach(self, out, hop, rows):
        """What following the hop from the bound records reaches: how many, and some by label."""
        arrow, target = hop[0], hop[1]
        var = f"n{len(out.vars)}"
        tail = f"{arrow}({var}:{target})"
        n = self.count(out.seen(f"count({var}) AS c", tail))
        if n is None:
            return ""
        if n == 0:
            return " (reaches nothing)"
        prop = self.label_of(target)
        values = rows and prop and self.sample(out.seen(f"{var}.{prop} AS v", tail, limit=rows))
        return f" (reaches {n}" + (f", {prop}: {'; '.join(values)}" if values else "") + ")"

    def kept(self, out, var, prop, word):
        """How many of the bound records a narrowing keeps."""
        total = self.count(out.seen(f"count({var}) AS c"))
        left = self.count(out.seen(f"count({var}) AS c", where=[f"{var}.{prop} CONTAINS '{word.replace(chr(39), '')}'"]))
        return "" if total is None or left is None else f" (keeps {left} of {total})"

    def value(self, out, var, prop, rows, held=None):
        """Some values of a property on the bound records."""
        values = rows and self.sample(out.seen(f"{var}.{prop} AS v", limit=rows, held=held))
        if values is None:
            return ""
        return f" (e.g. {'; '.join(values)})" if values else " (no value recorded)"


def render(value):
    """A value as the line shows it: text quoted, anything else as written."""
    return repr(value) if isinstance(value, str) else str(value)
