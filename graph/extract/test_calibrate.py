"""Witnesses for the record-kind fit: what it maximises and how it chooses its granularity."""
import json
import os
import tempfile
import unittest

import calibrate


def pair(source, gold, p):
    return {"id": "x", "source": source, "options": ["A", "B"], "gold": gold}, p


class RecordFit(unittest.TestCase):
    def test_the_threshold_is_the_tightest_one_that_keeps_every_right_lead(self):
        pairs = [pair("s1", [0], [0.8, 0.1, 0.1]), pair("s2", [0], [0.9, 0.05, 0.05]), pair("s3", [], [0.4, 0.3, 0.3])]
        self.assertEqual(calibrate.fit_threshold(pairs), 0.8)

    def test_a_lead_that_is_wrong_is_left_by_a_threshold_above_its_score(self):
        pairs = [pair("s1", [0], [0.9, 0.05, 0.05]), pair("s2", [], [0.6, 0.2, 0.2])]
        t = calibrate.fit_threshold(pairs)
        self.assertTrue(0.6 < t <= 0.9)

    def test_none_leading_is_not_a_decision_about_a_kind(self):
        row, p = pair("s1", [], [0.1, 0.1, 0.8])
        self.assertIsNone(calibrate.leader(row, p))
        self.assertEqual(calibrate.record_accuracy([(row, p)], {None: 0.5}), 0.0)

    def test_per_kind_thresholds_win_when_the_kinds_score_on_different_scales(self):
        pairs = [pair(f"a{i}", [0], [0.9, 0.05, 0.05]) for i in range(3)] + [pair(f"b{i}", [], [0.6, 0.1, 0.3]) for i in range(3)]
        pairs += [pair(f"c{i}", [1], [0.1, 0.6, 0.3]) for i in range(3)] + [pair(f"d{i}", [], [0.1, 0.4, 0.5]) for i in range(3)]
        pairs += [pair(f"e{i}", [], [0.1, 0.45, 0.45]) for i in range(3)]
        self.assertGreater(calibrate.held_out_accuracy(pairs, True), calibrate.held_out_accuracy(pairs, False))

    def test_record_params_name_the_best_framing_and_say_how_it_was_chosen(self):
        rows = [{"id": f"r{i}", "source": f"s{i}", "options": ["A", "B"], "gold": g} for i, g in enumerate([[0], [1], []])]
        good = [[0.9, 0.05, 0.05], [0.1, 0.8, 0.1], [0.1, 0.1, 0.8]]
        bad = [[0.1, 0.8, 0.1], [0.9, 0.05, 0.05], [0.8, 0.1, 0.1]]
        with tempfile.TemporaryDirectory() as d:
            paths = {}
            decisions = os.path.join(d, "dec.jsonl")
            open(decisions, "w").write("".join(json.dumps(r) + "\n" for r in rows))
            for name, ps in (("worse", bad), ("better", good)):
                paths[name] = os.path.join(d, name)
                open(paths[name], "w").write("".join(json.dumps({"id": r["id"], "p": p}) + "\n" for r, p in zip(rows, ps)))
            record, framing = calibrate.record_params(decisions, list(paths.items()))
        self.assertEqual(framing["value"], "better")
        self.assertEqual(framing["accuracy"], {"worse": 0.0, "better": 1.0})
        self.assertTrue(record["fitted"])
        self.assertIn(record["granularity"], ("pooled", "per kind"))


if __name__ == "__main__":
    unittest.main()
