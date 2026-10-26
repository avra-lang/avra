"""Code-only checks of the gym: determinism, statistics and the structural fidelity checks. No model is used."""
import math
import random
import unittest

import cat
import facts
import plans
import stats
import times


class Stats(unittest.TestCase):
    def test_mcnemar_seven_to_none(self):
        self.assertAlmostEqual(stats.mcnemar_exact(7, 0), 2 * 0.5 ** 7)
        self.assertAlmostEqual(stats.mcnemar_midp(7, 0), 0.5 ** 7)

    def test_mcnemar_symmetry_and_tie(self):
        self.assertEqual(stats.mcnemar_midp(3, 5), stats.mcnemar_midp(5, 3))
        self.assertAlmostEqual(stats.mcnemar_midp(4, 4), 1.0)
        self.assertEqual(stats.mcnemar_midp(0, 0), 1.0)

    def test_accuracy_interval_contains_estimate_and_widens_with_clustering(self):
        clusters = [i // 10 for i in range(100)]
        hits = [1 if (i // 10) % 2 == 0 else 0 for i in range(100)]
        acc, lo, hi = stats.accuracy_ci(clusters, hits, draws=2000)
        self.assertAlmostEqual(acc, 0.5)
        flat = stats.accuracy_ci(list(range(100)), hits, draws=2000)
        self.assertLess(flat[2] - flat[1], hi - lo)

    def test_paired_difference_zero_when_equal(self):
        clusters = [i // 5 for i in range(50)]
        hits = [i % 3 == 0 for i in range(50)]
        got = stats.paired(clusters, hits, hits, draws=500)
        self.assertEqual((got["a_only"], got["b_only"]), (0, 0))
        self.assertEqual(got["difference"], 0)
        self.assertEqual(got["mcnemar_midp"], 1.0)

    def test_risk_coverage_orders_by_confidence(self):
        rows = [(0.9, True), (0.8, True), (0.7, False), (None, False)]
        curve, area = stats.risk_coverage(rows)
        self.assertEqual(curve[0], (0.25, 0.0))
        self.assertAlmostEqual(curve[-1][1], 1 / 3)
        self.assertAlmostEqual(stats.risk_at(curve, 0.5), 0.0)


CATALOG = {"models": [
    {"name": "Thing", "description": "d", "properties": [
        {"name": "label", "shape": "string", "rules": [], "description": ""},
        {"name": "weight", "shape": {"optional": "number"}, "rules": [], "description": ""},
        {"name": "dims", "shape": {"list": {"embedded": "Dim"}}, "rules": [], "description": ""},
        {"name": "seen_on", "shape": {"optional": "string"}, "rules": [], "description": "", "time": {"encoding": "iso_date"}},
        {"name": "parent", "shape": {"optional": {"reference": "Thing"}}, "rules": [], "description": ""}],
     "semantics": {"label": ["label"], "times": [{"path": ["seen_on"], "encoding": "iso_date"}], "quantities": [], "absences": [], "identities": []}},
    {"name": "Dim", "description": "e", "properties": [{"name": "w", "shape": "integer", "rules": [], "description": ""}], "semantics": {}}]}


class Walker(unittest.TestCase):
    def test_a_type_nobody_listed_is_walked(self):
        c = cat.Cat(CATALOG)
        self.assertEqual(c.embedded, {"Dim"})
        self.assertEqual(c.publishable(), ["Thing"])
        self.assertEqual([(p, s) for p, s, _, _ in c.leaves("Thing")],
                         [(("label",), "string"), (("weight",), "number"), (("seen_on",), "string")])
        self.assertEqual(c.time_paths("Thing"), {("seen_on",): "iso_date"})
        self.assertEqual(c.references("Thing"), [("parent", "Thing")])

    def test_time_encodings_round_trip(self):
        for enc in times.ENCODE:
            v = times.encode("2027-03-04T00:00:00Z", enc)
            self.assertEqual(times.day(v, enc), "2027-03-04")

    def test_rule_text_is_read_by_its_declared_arguments(self):
        self.assertEqual(cat.rule_args("range(min: 1, max: 9)"), ("range", {"min": 1, "max": 9}))

    def test_operators_come_from_the_grammar(self):
        ops = plans.operators()
        for op in ("=", "<", ">=", "CONTAINS", "IS NULL"):
            self.assertIn(op, ops)


class Fidelity(unittest.TestCase):
    lines = [{"names": ["Dana Kroll"], "literals": [{"date": "2027-03-04"}, {"number": 14}, {"amount": (12, 50)}, {"text": "blue crate"}]}]

    def test_carries_all(self):
        text = "Dana Kroll logged a blue crate on March 4, 2027: 14 units at 12.50."
        self.assertIsNone(facts.faithful(text, self.lines))

    def test_missing_name_is_named(self):
        self.assertEqual(facts.faithful("Someone logged 14 units", self.lines), "Dana Kroll")

    def test_missing_number(self):
        text = "Dana Kroll logged a blue crate on 2027-03-04 at 12.50."
        self.assertEqual(facts.faithful(text, self.lines), {"number": 14})

    def test_number_is_a_token_not_a_substring(self):
        self.assertFalse(facts.carried("it was 140 units", {"number": 14}))
        self.assertTrue(facts.carried("it was 14 units", {"number": 14}))

    def test_date_needs_year_and_day(self):
        self.assertFalse(facts.carried("in March 2027", {"date": "2027-03-04"}))
        self.assertTrue(facts.carried("on 4 March 2027", {"date": "2027-03-04"}))


if __name__ == "__main__":
    unittest.main()
