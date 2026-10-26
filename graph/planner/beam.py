"""A beam over the planner's closed choices, pruned by execution.

A walk is the sequence of choices the model makes. A partial plan is the walk
so far, a prefix of picks. Each round extends every kept prefix by each option of the
next decision and keeps the `k` best extensions by cumulative log-probability
that survive, trying them best first. A partial plan whose pattern binds no row in the
graph is dropped before the model is asked anything more of it, and a finished
plan whose answer is empty is never chosen: when every walk ends empty the
planner abstains. With k = 1 the walk is the greedy one.
"""
from dataclasses import dataclass

from catalog import PARAMETERS
from search import Branching


class Frontier(Exception):
    """The walk reached a decision its prefix does not settle."""

    def __init__(self, logp):
        super().__init__("frontier")
        self.logp = logp


class Pruned(Exception):
    """The walk's pattern binds nothing in the graph."""


@dataclass
class Plan:
    cypher: str
    tally: float
    length: int
    steps: tuple = ()

    def score(self):
        """Joint log-probability of the picks, or that per decision, as beam_score declares."""
        return self.tally / max(self.length, 1) if PARAMETERS["beam_score"] == "mean" else self.tally


class Walker(Branching):
    """The model, remembered by prompt, replaying a prefix of picks and stopping at the next decision."""

    def __init__(self, base, probe):
        super().__init__(base)
        self.probe, self.picks, self.plan, self.steps = probe, (), None, []

    def watch(self, plan):
        self.plan = plan

    def empty(self, query):
        answer = self.probe(query)
        return answer.get("status") == "unknown" or answer.get("status") == "answered" and not answer["fields"]

    def vet(self):
        """Refuses to go on from a pattern that binds nothing."""
        if self.probe and PARAMETERS["beam_prune"] and self.plan and self.plan.parts \
                and self.empty(self.plan.seen(f"count({self.plan.vars[-1][0]}) AS c")):
            raise Pruned()

    def choose(self, context, question, options):
        self.vet()
        return super().choose(context, question, options)

    def ranked(self, context, question, shown, keys):
        self.vet()
        return super().ranked(context, question, shown, keys)

    def took(self, option):
        self.steps.append(option)

    def decide(self, logp):
        at = len(self.trace)
        self.trace.append(logp)
        if at < len(self.picks):
            return self.picks[at]
        raise Frontier(logp)

    def run(self, make, picks):
        """('open', logp) at the next undecided choice, ('done', plan) when the walk ends, or None when it is dropped."""
        self.picks, self.trace, self.tally, self.plan, self.steps = tuple(picks), [], 0.0, None, []
        try:
            cypher = make(self)
        except Frontier as stop:
            return "open", stop.logp
        except Pruned:
            return None
        except (ValueError, KeyError, IndexError):
            return None
        if self.probe and PARAMETERS["beam_prune"] and self.empty(cypher):
            return None
        return "done", Plan(cypher, self.tally, len(self.trace), tuple(self.steps))


def candidates(base, make, probe=None, k=None):
    """Finished plans the beam reaches, best first; none when every walk ends empty."""
    k = PARAMETERS["beam_k"] if k is None else k
    walker = Walker(base, probe)
    first = walker.run(make, ())
    kept, finished = [((), 0.0, first)] if first else [], []
    while kept:
        pool = []
        for picks, tally, state in kept:
            if state[0] == "done":
                finished.append(state[1])
                continue
            logp = state[1]
            pool += [(picks + (j,), tally + logp[j]) for j in range(len(logp))]
        kept = []
        for picks, tally in sorted(pool, key=lambda c: c[1], reverse=True):
            if len(kept) == k:
                break
            state = walker.run(make, picks)
            if state:
                kept.append((picks, tally, state))
    return sorted(finished, key=Plan.score, reverse=True)
