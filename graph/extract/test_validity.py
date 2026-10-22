"""Witnesses that a relation's declared valid-time bounds are read from its sentence."""
import datetime
import unittest

import cascade
from test_plan import model, prop

SPEC = {"from": ["from_ms"], "until": ["until_ms"], "encoding": "unix_millis", "interval": "half_open"}
TEXT = "Rae leads the lab through 15 October 2026. From 16 October 2026 she advises."
ANCHOR = int(datetime.datetime(2026, 10, 14, 9, tzinfo=datetime.timezone.utc).timestamp() * 1000)


def midnight(day):
    return int(datetime.datetime(2026, 10, day, tzinfo=datetime.timezone.utc).timestamp() * 1000)


class Scripted:
    """A scorer that answers by question: which words, which meaning, whole day."""

    def __init__(self, words, day, whole):
        self.words, self.day, self.whole = words, day, whole

    def pick(self, ctx, question, options, tail=()):
        tail = list(tail)
        if question.startswith("Consider this claim"):
            hit = next((i for i, o in enumerate(options) if o == self.words[question.split("Which words give the time it ")[1].split(" ")[0]]), None)
        elif question.startswith("Which date or time"):
            hit = next((i for i, o in enumerate(options) if f"{self.day} October 2026" in o), None)
        else:
            hit = 0 if self.whole else 1
        out = [0.0] * (len(options) + len(tail))
        out[len(options) if hit is None else hit] = 1.0
        return out


class Bounds(unittest.TestCase):
    def cascade_over(self, words, day, whole):
        c = cascade.Cascade.__new__(cascade.Cascade)
        c.plan = cascade.Plan([
            model("Span", [prop("from_ms", {"optional": "integer"}), prop("until_ms", {"optional": "integer"})]),
            model("Role", [prop("who", "string"), prop("span", {"embedded": "Span"})]),
        ])
        c.plan.models["Span"]["semantics"]["validity"] = SPEC
        c.t = cascade.Text(TEXT)
        c.frames = []
        c.request = {"input": {"received_at_ms": ANCHOR}}
        first = TEXT.index("15 October 2026")
        second = TEXT.index("16 October 2026")
        c.spans = {"times": {cascade.TIME_EXPRESSION: [{"start": first, "end": first + 15}, {"start": second, "end": second + 15}]}}
        c.llm = Scripted(words, day, whole)
        return c

    def read(self, c):
        role = c.plan.models["Role"]
        return c.valued("Role", role["properties"][1], "Rae leads", 0, len(TEXT), (0, 3))["value"]

    def test_a_date_that_ends_the_span_and_is_included_ends_at_the_next_midnight(self):
        c = self.cascade_over({"starts": None, "stops": "15 October 2026"}, 15, True)
        self.assertEqual(self.read(c), {"until_ms": midnight(16)})

    def test_a_date_that_ends_the_span_and_is_excluded_ends_at_its_own_midnight(self):
        c = self.cascade_over({"starts": None, "stops": "15 October 2026"}, 15, False)
        self.assertEqual(self.read(c), {"until_ms": midnight(15)})

    def test_a_date_that_starts_the_span_starts_at_its_midnight(self):
        c = self.cascade_over({"starts": "16 October 2026", "stops": None}, 16, True)
        self.assertEqual(self.read(c), {"from_ms": midnight(16)})

    def test_both_bounds_land_beside_the_words_that_gave_them(self):
        c = self.cascade_over({"starts": "16 October 2026", "stops": "15 October 2026"}, 15, True)
        role = c.plan.models["Role"]
        f = c.valued("Role", role["properties"][1], "Rae leads", 0, len(TEXT), (0, 3))
        self.assertEqual(len(f["evidence"]), 2)

    def test_no_time_expression_leaves_the_value_empty_and_says_why(self):
        c = self.cascade_over({"starts": None, "stops": None}, 15, True)
        c.spans = {"times": {}}
        cascade.LOG.clear()
        self.assertEqual(self.read(c), {})
        self.assertIn("no time expression", cascade.LOG[0])


if __name__ == "__main__":
    unittest.main()
