"""The planner's closed decisions as data, for training and evaluation.

    from choices import walk, prompts

`walk` runs the structured planner over any catalog with a labeller in
place of the model: `label(context, question, options)` answers the index
of the right option, and every decision the planner asks is returned with
that gold index, exactly as the planner phrased it. `prompts` turns one
decision into the user messages the shared service scores, in both option
orders, as the planner sends them, through the service's own prompt
function, so training text is the runtime text byte for byte.
"""
import pathlib
import sys

import structured

EXTRACT = pathlib.Path(__file__).resolve().parent.parent / "extract"


class Labelled:
    """A chooser that asks the labeller once per decision and records it."""

    def __init__(self, label):
        self.label, self.decisions, self.pending = label, [], None

    def choose(self, context, question, options):
        if self.pending and self.pending[0] == (context, question) and sorted(self.pending[1]) == sorted(options):
            gold = self.pending[2]
            self.pending = None
        else:
            gold = options[self.label(context, question, options)]
            self.decisions.append({"context": context, "question": question, "options": options,
                                   "gold": options.index(gold)})
            self.pending = ((context, question), options, gold)
        return [1.0 if o == gold else 0.0 for o in options]


def walk(question, schema, context, label, search=None, depth=None, model_of=None):
    """(cypher, decisions): the query the labelled choices compose, and every decision on the way."""
    chooser = Labelled(label)
    cypher = structured.plan(chooser, question, schema, context, search, depth, model_of)
    return cypher, chooser.decisions


def prompts(decision):
    """[(user message, gold letter)] for the listed order and its reverse, as scored at runtime."""
    if str(EXTRACT) not in sys.path:
        sys.path.insert(0, str(EXTRACT))
    from cascade import choice_prompt

    out = []
    for options in (decision["options"], decision["options"][::-1]):
        gold = options.index(decision["options"][decision["gold"]])
        out.append((choice_prompt(decision["context"], decision["question"], options), chr(ord("A") + gold)))
    return out
