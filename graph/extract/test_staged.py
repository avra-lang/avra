"""Witnesses for the two encoder stages: the record passes ask only for the kinds the sentences state."""
import unittest

import cascade
from test_plan import model, prop


def plan():
    return cascade.Plan([model(k, [prop("who", "string"), prop("what", "string")]) for k in ("Booking", "Payment", "Refund")])


class Queries(unittest.TestCase):
    def test_the_choice_free_queries_hold_no_record_or_field_query(self):
        q = plan().encoder_queries("text")
        self.assertFalse([k for k in q if k.startswith("record:") or k == "fields"])

    def test_record_queries_cover_exactly_the_given_kinds(self):
        q = plan().record_queries("text", ["Payment"])
        self.assertEqual(sorted(k for k in q if k.startswith("record:")), ["record:Payment"])
        self.assertTrue(all(k.startswith("Payment.") for k in q["fields"][2]))

    def test_no_kinds_ask_nothing(self):
        self.assertEqual(plan().record_queries("text", []), {})

    def test_a_kinds_labels_are_the_same_alone_as_among_all(self):
        p = plan()
        alone = p.record_queries("t", ["Payment"])["fields"][2]
        among = p.record_queries("t", ["Booking", "Payment", "Refund"])["fields"][2]
        self.assertTrue(alone.items() <= among.items())


class Scorer:
    calls, spent = 0, {}

    def begin(self, source):
        pass


class Models:
    load_s = 0.0

    def __init__(self):
        self.llm = Scorer()

    def drop_llm(self):
        pass

    def encoder(self):
        raise AssertionError("the encoder is stubbed out")


class Stages(unittest.TestCase):
    def setUp(self):
        self.encoded, self.choose, self.complete = cascade.encoded, cascade.Cascade.choose_records, cascade.Cascade.complete
        self.asked = []

        def encoded(reqs, models, asked):
            self.asked.append(asked)
            return [{} for _ in asked]

        cascade.encoded = encoded
        cascade.Cascade.choose_records = lambda c, source: setattr(c, "chosen", [("Payment", 0, 5, 1.0)]) or setattr(c, "records", []) or setattr(c, "frames", [])
        cascade.Cascade.complete = lambda c, source: None

    def tearDown(self):
        cascade.encoded, cascade.Cascade.choose_records, cascade.Cascade.complete = self.encoded, self.choose, self.complete

    def test_the_second_pass_asks_only_for_the_kinds_the_first_choices_stated(self):
        p = plan()
        req = {"request": "r", "input": {"content": "Ana paid 50.", "source": {}}, "catalog": {"descriptor": [{"name": m} for m in p.models], "fingerprint": "f"}, "extractor": {}}
        cascade.planned_for = lambda r: p
        results = cascade.extract_batch([req], Models())
        first, second = self.asked
        self.assertFalse([k for k in first[0] if k.startswith("record:") or k == "fields"])
        self.assertEqual(sorted(k for k in second[0] if k.startswith("record:")), ["record:Payment"])
        self.assertEqual(results[0][0]["status"], "complete")


def rec(local, model, fields, key=None):
    return {"local_id": local, "model": model, "identities": [{"identity": {"namespace": "sku", "key": key}}] if key else [],
            "fields": [{"property": p, "value": v, "factuality": "CT+", "speech_act": "assert", "frame": None} for p, v in fields]}


class Reconciled(unittest.TestCase):
    def names(self, records):
        return [[f["value"] for f in r["fields"] if f["property"] == "name"] for r in records]

    def test_the_same_claim_twice_on_one_entity_stays(self):
        out = cascade.reconciled([rec("r1", "P", [("name", "Jacket")], "A"), rec("r2", "P", [("name", "Jacket")], "A")])
        self.assertEqual(self.names(out), [["Jacket"], ["Jacket"]])

    def test_a_property_stated_two_ways_is_removed_from_every_record_and_logged(self):
        cascade.LOG.clear()
        out = cascade.reconciled([rec("r1", "P", [("name", "black"), ("code", "A")], "A"), rec("r2", "P", [("name", "navy"), ("code", "A")], "A")])
        self.assertEqual(self.names(out), [[], []])
        self.assertEqual([[f["property"] for f in r["fields"]] for r in out], [["code"], ["code"]])
        self.assertTrue(any("conflict P.name" in line and "black" in line and "navy" in line for line in cascade.LOG))

    def test_a_qualifier_that_differs_is_a_conflict_too(self):
        a, b = rec("r1", "P", [("name", "x")], "A"), rec("r2", "P", [("name", "x")], "A")
        b["fields"][0]["factuality"] = "Uu"
        self.assertEqual(self.names(cascade.reconciled([a, b])), [[], []])

    def test_records_of_different_identities_or_models_are_not_one_entity(self):
        out = cascade.reconciled([rec("r1", "P", [("name", "a")], "A"), rec("r2", "P", [("name", "b")], "B"), rec("r3", "Q", [("name", "c")], "A")])
        self.assertEqual(self.names(out), [["a"], ["b"], ["c"]])

    def test_records_without_identity_are_untouched(self):
        out = cascade.reconciled([rec("r1", "P", [("name", "a")]), rec("r2", "P", [("name", "b")])])
        self.assertEqual(self.names(out), [["a"], ["b"]])

    def test_identity_chains_join_through_a_shared_key(self):
        a, b, c = rec("r1", "P", [("name", "x")], "A"), rec("r2", "P", [("name", "y")], "A"), rec("r3", "P", [("name", "z")], "B")
        b["identities"].append({"identity": {"namespace": "sku", "key": "B"}})
        self.assertEqual(self.names(cascade.reconciled([a, b, c])), [[], [], []])


class Names(unittest.TestCase):
    def test_no_attribute_a_cascade_assigns_shadows_one_of_its_methods(self):
        import ast
        import inspect

        tree = ast.parse(inspect.getsource(cascade))
        cls = next(n for n in tree.body if isinstance(n, ast.ClassDef) and n.name == "Cascade")
        methods = {n.name for n in cls.body if isinstance(n, ast.FunctionDef)}
        assigned = {t.attr for n in ast.walk(cls) if isinstance(n, ast.Assign) for tgt in n.targets for t in (tgt.elts if isinstance(tgt, ast.Tuple) else [tgt])
                    if isinstance(t, ast.Attribute) and isinstance(t.value, ast.Name) and t.value.id == "self"}
        self.assertEqual(methods & assigned, set())


if __name__ == "__main__":
    unittest.main()
