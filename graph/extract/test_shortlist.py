"""Witnesses for the kind shortlist and the harness that fits it; no model, no socket."""
import unittest

import cascade
import fit_shortlist as fs
from test_plan import model, prop


def cascade_over(kinds):
    plan = cascade.Plan([model(k, [prop("who", "string")]) for k in kinds])
    c = cascade.Cascade(plan, {}, None)
    c.t = cascade.Text("Sam booked a table.")
    return c, {k: f"{k} wording" for k in kinds}


class Shortlist(unittest.TestCase):
    def setUp(self):
        self.k, self.link = cascade.SHORTLIST_K, cascade.retrieval_op
        cascade.retrieval_op = lambda body: {"links": {body["phrases"][0]: [["k2", 0.9], ["k0", 0.5]][: body["n"]]}}

    def tearDown(self):
        cascade.SHORTLIST_K, cascade.retrieval_op = self.k, self.link

    def test_off_offers_every_kind(self):
        cascade.SHORTLIST_K = None
        c, opts = cascade_over(["A", "B", "C"])
        self.assertEqual(c.shortlisted(["A", "B", "C"], opts, 0, 5), ["A", "B", "C"])

    def test_the_ranked_kinds_come_back_in_declared_order(self):
        cascade.SHORTLIST_K = 2
        c, opts = cascade_over(["A", "B", "C"])
        self.assertEqual(c.shortlisted(["A", "B", "C"], opts, 0, 5), ["A", "C"])

    def test_a_schema_no_wider_than_k_is_not_ranked(self):
        cascade.SHORTLIST_K = 3
        c, opts = cascade_over(["A", "B"])
        cascade.retrieval_op = None
        self.assertEqual(c.shortlisted(["A", "B"], opts, 0, 5), ["A", "B"])


class Harness(unittest.TestCase):
    def test_recall_counts_stated_kinds_within_the_top_k(self):
        rows = [{"gold": [1]}, {"gold": [0, 2]}]
        self.assertEqual(fs.recall(rows, [[1, 0, 2], [2, 1, 0]], (1, 2, 3)), {1: 0.667, 2: 0.667, 3: 1.0})

    def test_the_leader_is_taken_at_the_threshold_and_none_leading_takes_nothing(self):
        self.assertEqual(fs.taken([0.2, 0.7, 0.1], [4, 5, None], 0.5), 5)
        self.assertIsNone(fs.taken([0.2, 0.4, 0.4], [4, 5, None], 0.5))
        self.assertIsNone(fs.taken([0.1, 0.2, 0.7], [4, 5, None], 0.5))

    def test_a_decision_is_right_on_a_stated_kind_or_on_nothing_when_none_is_stated(self):
        self.assertTrue(fs.right(5, [5]))
        self.assertFalse(fs.right(4, [5]))
        self.assertTrue(fs.right(None, []))
        self.assertFalse(fs.right(5, []))

    def test_the_winner_has_the_best_held_out_accuracy_and_fewer_calls_on_a_tie(self):
        table = [{"variant": "a", "held_out": 0.6, "calls_per_sentence": 5}, {"variant": "b", "held_out": 0.6, "calls_per_sentence": 1}, {"variant": "c", "held_out": 0.5, "calls_per_sentence": 1}]
        self.assertEqual(fs.winner(table)["variant"], "b")

    def test_variant_kinds_keep_the_offered_order(self):
        self.assertEqual(fs.variant_rows({"order": [7, 2, 5, 0]}, 3), [2, 5, 7])


if __name__ == "__main__":
    unittest.main()
