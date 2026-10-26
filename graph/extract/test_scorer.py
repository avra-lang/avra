"""Witnesses for the scorer's prefix reuse; no model is loaded."""
import unittest

import cascade


class Prefix(unittest.TestCase):
    def test_common_prefix_counts_leading_equal_items(self):
        self.assertEqual(cascade.common_prefix([1, 2, 3], [1, 2, 9, 3]), 2)
        self.assertEqual(cascade.common_prefix([], [1]), 0)
        self.assertEqual(cascade.common_prefix([1, 2], [1, 2]), 2)


class Trimming(cascade.Scorer):
    """A scorer whose cache is a list of the tokens it holds."""

    def __init__(self, held):
        self.held, self.cache = list(held), list(held)

    def reuse(self, ids):
        keep = min(cascade.common_prefix(self.held, ids), len(ids) - 1)
        del self.cache[keep:]
        self.held = self.held[:keep]
        return keep


class Reuse(unittest.TestCase):
    def test_the_shared_prefix_is_kept_and_the_rest_is_fed(self):
        s = Trimming([1, 2, 3, 4])
        self.assertEqual(s.reuse([1, 2, 3, 9, 9]), 3)
        self.assertEqual(s.cache, [1, 2, 3])

    def test_at_least_one_token_is_always_fed(self):
        s = Trimming([1, 2, 3])
        self.assertEqual(s.reuse([1, 2, 3]), 2)

    def test_nothing_shared_feeds_everything(self):
        s = Trimming([5, 6])
        self.assertEqual(s.reuse([1, 2]), 0)
        self.assertEqual(s.cache, [])


class Sound(unittest.TestCase):
    def test_a_span_past_the_end_of_the_text_is_dropped(self):
        got = cascade.sound("abc.", {"quotation": [{"text": ".", "start": 4, "end": 5}, {"text": "bc", "start": 1, "end": 3}]})
        self.assertEqual([x["text"] for x in got["quotation"]], ["bc"])

    def test_an_empty_span_is_dropped(self):
        self.assertEqual(cascade.sound("abc", {"x": [{"start": 2, "end": 2}]}), {"x": []})

    def test_a_record_field_outside_the_text_is_dropped_and_the_rest_kept(self):
        got = cascade.sound("abc", [{"name": {"start": 0, "end": 3}, "code": {"start": 3, "end": 4}}])
        self.assertEqual(got, [{"name": {"start": 0, "end": 3}}])


if __name__ == "__main__":
    unittest.main()
