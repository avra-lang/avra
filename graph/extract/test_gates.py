"""Witnesses that every refusal of a gate is logged with what decided it."""
import unittest

import cascade
from test_plan import Reading


class Gates(unittest.TestCase):
    def setUp(self):
        cascade.LOG.clear()

    def test_a_choice_above_the_threshold_is_taken_and_silent(self):
        self.assertEqual(cascade.taken("record", "x", [0.1, 0.9, 0.0], ["a", "b"], 0.5), 1)
        self.assertEqual(cascade.LOG, [])

    def test_a_best_option_under_the_threshold_is_logged_with_its_score_and_threshold(self):
        self.assertIsNone(cascade.taken("record", "kind of 'x'", [0.4, 0.3, 0.3], ["a", "b"], 0.95))
        self.assertEqual(len(cascade.LOG), 1)
        line = cascade.LOG[0]
        for part in ("gate record kind of 'x'", "below threshold", "p=0.400", "threshold=0.95", "'a'"):
            self.assertIn(part, line)

    def test_an_abstention_that_wins_is_logged_with_the_best_option_it_beat(self):
        self.assertIsNone(cascade.taken("field", "Event.title", [0.2, 0.1, 0.7], ["a", "b"], 0.5))
        self.assertIn("abstention", cascade.LOG[0])
        self.assertIn("p=0.200", cascade.LOG[0])

    def test_no_options_is_an_abstention_without_a_best_option(self):
        self.assertIsNone(cascade.taken("field", "Event.title", [1.0], [], 0.5))
        self.assertIn("abstention", cascade.LOG[0])

    def test_a_quantity_the_scorer_does_not_pick_is_logged(self):
        c = Reading().cascade_over("price EUR 12 now", [{"start": 6, "end": 9}])
        c.llm = type("L", (), {"pick": lambda self, ctx, q, opts, tail=(): [0.1] * len(opts) + [0.9]})()
        sale = c.plan.models["Sale"]
        self.assertIsNone(c.quantity_field("Sale", sale["properties"][1], ("units", "code", 2), "", 0, 16))
        self.assertIn("gate field Sale.price", cascade.LOG[0])


if __name__ == "__main__":
    unittest.main()
