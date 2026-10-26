"""Choosing among surviving plans by how their answers differ.

Plans are executed and grouped by the answer they return; a group is one
behaviour. One group needs no choice. Several are put to the model as one
closed choice, each described by what only it returns, what it leaves out
that another returns, and the plan steps no other group took. Every figure
and phrase is read from the executed rows and the options the walk was
offered; the model may also decline every group.
"""
import json
from dataclasses import dataclass

from structured import best, fitted

DECLINE = "none of these readings is supported by the records"
ASK = "These readings of the question return different answers. Which one does the question mean?"


@dataclass
class Group:
    plans: list
    rows: dict

    @property
    def lead(self):
        return self.plans[0]


@dataclass
class Verdict:
    plan: object
    groups: int
    picked: int


def render(value):
    return repr(value) if isinstance(value, str) else json.dumps(value, sort_keys=True)


def rows_of(answer):
    """{(entity path, value): (column, shown value)}: an answer's rows, whatever the columns are called."""
    out = {}
    for f in answer.get("fields", []):
        out.setdefault((tuple(f["path"][:-1]), json.dumps(f["value"], sort_keys=True)), (f["path"][-1], render(f["value"])))
    return out


def grouped(plans, probe):
    """Plans (best first) that return the same rows share a group; groups keep the order of their best plan."""
    groups = {}
    for p in plans:
        rows = rows_of(probe(p.cypher))
        key = frozenset(rows)
        if key in groups:
            groups[key].plans.append(p)
        else:
            groups[key] = Group([p], rows)
    return list(groups.values())


def shown(rows, keys, n):
    return "; ".join(f"{rows[k][0]}={rows[k][1]}" for k in list(keys)[:n])


def described(group, others, n):
    """What sets this group apart: steps no other group's best plan took, rows only it returns, rows it leaves out."""
    elsewhere = {s for o in others for s in o.lead.steps}
    own = [s for s in group.lead.steps if s not in elsewhere]
    seen = {k: v for o in others for k, v in o.rows.items()}
    only = [k for k in group.rows if k not in seen]
    left = [k for k in seen if k not in group.rows]
    parts = []
    if own:
        parts.append("chooses: " + "; ".join(own))
    parts.append(f"{len(group.rows)} rows")
    if only:
        parts.append(f"only this returns {len(only)}" + (f": {shown(group.rows, only, n)}" if n else ""))
    if left:
        parts.append(f"leaves out {len(left)}" + (f": {shown(seen, left, n)}" if n else ""))
    return " — ".join(parts)


def settle(chooser, head, plans, probe, most):
    """The plan the model takes after contrasting the groups' answers, or none when it declines all of them."""
    groups = grouped(plans, probe)
    if not groups:
        return Verdict(None, 0, -1)
    if len(groups) == 1:
        return Verdict(groups[0].lead, 1, 0)
    options = fitted(most, chooser, head, ASK,
                     lambda n: [described(g, [o for o in groups if o is not g], n) for g in groups] + [DECLINE])
    pick = best(chooser, head, ASK, options)
    return Verdict(None if pick == len(groups) else groups[pick].lead, len(groups), pick)
