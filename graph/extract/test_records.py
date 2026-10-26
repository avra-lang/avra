"""Witnesses for the per-kind record question and its gate."""
import unittest

import cascade
from test_plan import model, prop


class Scripted:
    """A scorer that answers each kind's question from a table keyed by the kind's name."""

    def __init__(self, yes):
        self.yes, self.asked = yes, []

    def pick(self, context, question, options, tail=()):
        self.asked.append((context, question, options))
        name = question.split("Kind: ")[-1].split(":")[0] if "Kind: " in question else next(k for k in self.yes if f"{k}: " in question)
        p = self.yes[name]
        return [p, 1 - p]


def cascade_over(yes, text="Sam booked a table. Ana paid 50."):
    plan = cascade.Plan([model("Booking", [prop("who", "string")]), model("Payment", [prop("who", "string")])])
    c = cascade.Cascade(plan, {}, Scripted(yes))
    c.t, c.filled = cascade.Text(text), []
    c.fill = lambda kind, x, y, p: c.filled.append((kind, x, y, p))
    return c


class KindQuestion(unittest.TestCase):
    def test_the_question_names_the_kind_and_offers_only_yes_and_no(self):
        plan = cascade.Plan([model("Booking", [prop("who", "string")])])
        context, question, options = cascade.record_ask(plan.models["Booking"], "Sam booked a table.")
        self.assertEqual(options, ["yes", "no"])
        self.assertIn("Booking", question)
        self.assertIn('"Sam booked a table."', context)

    def test_the_question_does_not_mention_the_other_kinds(self):
        plan = cascade.Plan([model("Booking", [prop("who", "string")]), model("Payment", [prop("who", "string")])])
        _, question, _ = cascade.record_ask(plan.models["Booking"], "x")
        self.assertNotIn("Payment", question)


class Gate(unittest.TestCase):
    def test_a_kind_is_taken_at_or_above_the_threshold_and_a_sentence_may_state_several(self):
        t = cascade.ACCEPT_KIND_YES
        c = cascade_over({"Booking": t, "Payment": t})
        c.sentence_kinds(list(c.plan.records), 0, 10)
        self.assertEqual([k for k, *_ in c.filled], ["Booking", "Payment"])

    def test_a_kind_below_the_threshold_is_left_and_the_drop_is_logged(self):
        c = cascade_over({"Booking": 0.0, "Payment": 1.0})
        cascade.LOG.clear()
        c.sentence_kinds(list(c.plan.records), 0, 10)
        self.assertEqual([k for k, *_ in c.filled], ["Payment"])
        self.assertTrue(any("gate record Booking" in line for line in cascade.LOG))

    def test_every_kind_is_asked_once_per_sentence(self):
        c = cascade_over({"Booking": 0.0, "Payment": 0.0})
        c.sentence_kinds(list(c.plan.records), 0, 10)
        self.assertEqual(len(c.llm.asked), 2)


if __name__ == "__main__":
    unittest.main()
