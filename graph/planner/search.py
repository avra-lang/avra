"""A search over the planner's closed choices.

A walk is the sequence of choices the model makes, each with the log-probability
of every option. The walk of argmax picks is the root; every other candidate is
the root with some decisions flipped to their runner-up, flipped where the model
was least sure (smallest margin) and only after the last decision already
flipped, so no set of flips is tried twice. Model answers are remembered by
prompt, so a re-walk pays only for the decisions its flips changed. Candidates
are ranked by the joint log-probability of their picks; the graph's `check` op
admits them in that order. Nothing about an answer's content ranks a plan.
"""
from dataclasses import dataclass, field

from catalog import PARAMETERS
import structured


@dataclass
class Path:
    cypher: str
    tally: float
    script: dict
    trace: list = field(repr=False)

    def score(self):
        """Joint log-probability of the picks, or that per decision, as beam_score declares."""
        return self.tally / max(len(self.trace), 1) if PARAMETERS["beam_score"] == "mean" else self.tally


class Branching:
    """The model, remembered by prompt, with each decision's picks scripted or argmax."""

    def __init__(self, base):
        self.base, self.memo, self.script, self.trace, self.tally = base, {}, {}, [], 0.0
        self.budget = getattr(base, "budget", None)
        if hasattr(base, "rank"):
            self.rank = self.ranked
        if hasattr(base, "choose_many"):
            self.choose_many = self.chose_many
        if hasattr(base, "embed"):
            self.embed = self.embedded

    def remembered(self, key, ask):
        if key not in self.memo:
            self.memo[key] = ask()
        return self.memo[key]

    def choose(self, context, question, options):
        return self.remembered(("c", context, question, tuple(options)), lambda: self.base.choose(context, question, options))

    def chose_many(self, items):
        """Every item's answer from the base's one ask, remembered by the items."""
        key = ("m", tuple((it["context"], it["question"], tuple(it["options"])) for it in items))
        return self.remembered(key, lambda: self.base.choose_many(items))

    def ranked(self, context, question, shown, keys):
        return self.remembered(("r", context, question, tuple(shown), tuple(keys)),
                               lambda: self.base.rank(context, question, shown, keys))

    def embedded(self, texts, query=False):
        return self.remembered(("e", tuple(texts), query), lambda: self.base.embed(texts, query))

    def decide(self, logp):
        at = len(self.trace)
        self.trace.append(logp)
        forced = self.script.get(at)
        return forced if forced is not None else max(range(len(logp)), key=logp.__getitem__)

    def walk(self, make, script):
        self.script, self.trace, self.tally = script, [], 0.0
        return Path(make(self), self.tally, dict(script), self.trace)


def margin(logp):
    top = sorted(logp, reverse=True)
    return top[0] - top[1]


def runner_up(logp, taken):
    return max((i for i in range(len(logp)) if i != taken), key=logp.__getitem__)


def candidates(base, make, width=None, flips=None, rounds=None):
    """Every distinct plan the search reaches, best first by `score`."""
    width, flips, rounds = (PARAMETERS[k] if v is None else v for k, v in
                            (("beam_width", width), ("beam_flips", flips), ("beam_rounds", rounds)))
    model = Branching(base)
    root = model.walk(make, {})
    found, frontier = {root.cypher: root}, [root]
    for _ in range(rounds):
        fresh = []
        for path in frontier:
            last = max(path.script, default=-1)
            taken = {i: max(range(len(lp)), key=lp.__getitem__) for i, lp in enumerate(path.trace)}
            open_at = sorted((margin(path.trace[i]), i) for i in range(last + 1, len(path.trace)) if len(path.trace[i]) > 1)
            for _, i in open_at[:flips]:
                try:
                    child = model.walk(make, {**path.script, i: runner_up(path.trace[i], path.script.get(i, taken[i]))})
                except (ValueError, KeyError, IndexError):
                    continue
                if child.cypher not in found:
                    found[child.cypher] = child
                    fresh.append(child)
        frontier = sorted(fresh, key=Path.score, reverse=True)[:width]
        if not frontier:
            break
    return sorted(found.values(), key=Path.score, reverse=True)
