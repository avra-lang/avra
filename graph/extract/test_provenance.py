"""Every fitted parameter names the invented corpus it was fitted on; no fitting data holds fixture text."""
import json
import os
import re
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..", "acceptance")
FILES = ("params.json", "er_params.json")


def fixture_tokens():
    """Words of the fixture's gold entity names (labels written as names, case kept) and their identity keys."""
    words = set()
    for line in open(os.path.join(ROOT, "entities.jsonl")):
        e = json.loads(line)
        if all(w[:1].isupper() or not w[:1].isalpha() for w in e["label"].split()):
            words.update(re.findall(r"[A-Za-z]{4,}", e["label"]))
        if e.get("identity"):
            words.add(e["identity"]["key"])
    return words


def params(name):
    return json.load(open(os.path.join(HERE, name)))


class Provenance(unittest.TestCase):
    def test_every_fitted_value_names_the_corpus_it_was_fitted_on(self):
        for name in FILES:
            for key, p in params(name)["params"].items():
                if p.get("fitted"):
                    self.assertIn("corpus", p.get("data", {}), f"{name}: {key} is fitted but names no corpus")

    def test_no_file_a_parameter_was_fitted_from_holds_fixture_text(self):
        tokens = fixture_tokens()
        for name in FILES:
            for path in params(name).get("data", {}):
                full = os.path.join(HERE, path)
                if os.path.exists(full):
                    held = tokens & set(re.findall(r"[A-Za-z]{4,}|[\w.]+@[\w.\-]+", open(full).read()))
                    self.assertFalse(held, f"{name}: fitted from {path}, which holds fixture text {sorted(held)[:3]}")

    def test_the_check_sees_fixture_text(self):
        self.assertIn("Rowan", fixture_tokens())


if __name__ == "__main__":
    unittest.main()
