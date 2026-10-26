"""Hooks over a chooser that holds a service: python -m unittest test_hooks (needs the cached models)."""
import os
import unittest

os.environ.setdefault("HF_HUB_OFFLINE", "1")
os.environ.setdefault("RETRIEVAL_VECTORS", os.path.join(os.path.dirname(os.path.abspath(__file__)), "data", "vectors.db"))
import hooks
import service


class Holder:
    def asked(self, body):
        return service.answered(body)


class Wrapped:
    def __init__(self, base):
        self.base = base


class Hooks(unittest.TestCase):
    facts = [("Person", "name", "Elena Vale"), ("Person", "name", "Rowan Vale"), ("Organization", "name", "Maison Aster")]

    def test_a_misspelt_name_links(self):
        got = hooks.near_facts(Wrapped(Holder()), "What does Rowan Vail do at Maison Aster?", self.facts)
        self.assertIn(("Person", "name", "Rowan Vale"), got)
        self.assertIn(("Organization", "name", "Maison Aster"), got)
        self.assertNotIn(("Person", "name", "Elena Vale"), got)

    def test_no_service_answers_nothing(self):
        self.assertEqual(hooks.near_facts(object(), "Rowan Vale", self.facts), [])
        self.assertIsNone(hooks.agreement(object(), "q", ["p1"], []))

    def test_agreement_counts_held_support(self):
        ps = [{"id": "p1", "text": "Elena signed the contract on 3 May.", "source": "s1", "facts": ["f1"]},
              {"id": "p2", "text": "The order shipped to Paris.", "source": "s2", "facts": ["f2"]}]
        got = hooks.agreement(Holder(), "When did Elena sign the contract?", ["f1", "zzz"], ps)
        self.assertEqual(got["held"], ["f1"])
        self.assertEqual(got["agree"], 0.5)


class Support(unittest.TestCase):
    rows = {1: "Elena signed the contract on 3 May.", 2: "The order shipped to Paris on 9 June."}

    def search(self, word):
        return [{"row": r, "text": t, "observation": f"s{r}", "claim": r} for r, t in self.rows.items() if word.lower() in t.lower()]

    def test_a_held_answer_agrees(self):
        got = hooks.answer_support(Holder(), "When did Elena sign the contract?", {"fields": [{"value": "3 May"}]}, self.search)
        self.assertEqual(got, 1.0)

    def test_a_scalar_nowhere_in_the_passages_gives_no_opinion(self):
        self.assertIsNone(hooks.answer_support(Holder(), "When did Elena sign?", {"fields": [{"value": "17 July"}]}, self.search))
        self.assertIsNone(hooks.answer_support(Holder(), "How many?", {"fields": [{"value": True}]}, self.search))


if __name__ == "__main__":
    unittest.main()
