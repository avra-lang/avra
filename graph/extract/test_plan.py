"""Witnesses for what the plan lets the cascade propose."""
import unittest

import cascade


def prop(name, shape, rules=()):
    return {"name": name, "shape": shape, "description": "", "rules": list(rules), "default_source": None}


def model(name, props, quantities=()):
    semantics = {"identities": [], "relation": None, "validity": None, "quantities": list(quantities), "times": []}
    return {"name": name, "description": name, "properties": props, "rules": [], "semantics": semantics}


AMOUNT = {"amount": ["price", "units"], "unit": {"path": ["price", "code"]}, "decimal_places": 2}


def descriptor(quantities=(AMOUNT,)):
    return [
        model("Cash", [prop("units", "integer"), prop("code", "string")]),
        model("Pair", [prop("left", "string"), prop("right", "string")]),
        model("Sale", [prop("label", "string"), prop("price", {"embedded": "Cash"})], quantities),
        model("Swap", [prop("label", "string"), prop("pair", {"embedded": "Pair"})], quantities),
    ]


class Embedding(unittest.TestCase):
    def test_a_value_type_the_model_reads_as_a_quantity_embeds_whole(self):
        plan = cascade.Plan(descriptor())
        self.assertIn("Sale", plan.records)
        sale = plan.models["Sale"]
        self.assertEqual(plan.quantity(sale, sale["properties"][1]), ("units", "code", 2))

    def test_the_same_value_type_without_a_declared_reading_blocks_its_model(self):
        plan = cascade.Plan(descriptor(()))
        self.assertIn("Sale", plan.blocked)

    def test_a_value_type_whose_required_fields_the_quantity_does_not_cover_blocks_its_model(self):
        plan = cascade.Plan(descriptor())
        self.assertIn("Swap", plan.blocked)

    def test_an_optional_embedded_property_is_read_through_optional(self):
        d = descriptor()
        d[2]["properties"][1] = prop("price", {"optional": {"embedded": "Cash"}})
        plan = cascade.Plan(d)
        sale = plan.models["Sale"]
        self.assertEqual(plan.quantity(sale, sale["properties"][1]), ("units", "code", 2))


class Reading(unittest.TestCase):
    def cascade_over(self, text, found):
        c = cascade.Cascade.__new__(cascade.Cascade)
        c.plan = cascade.Plan(descriptor())
        c.t = cascade.Text(text)
        c.spans = {"fields": {"Sale.price.code": found}}
        c.frames = []
        c.llm = type("L", (), {"pick": lambda self, ctx, q, opts, tail=(): [1.0] + [0.0] * (len(opts) - 1 + len(tail))})()
        return c

    def read(self, text, word):
        i = text.index(word)
        c = self.cascade_over(text, [{"start": i, "end": i + len(word)}])
        sale = c.plan.models["Sale"]
        return c.quantity_field("Sale", sale["properties"][1], ("units", "code", 2), "", 0, len(text))

    def test_a_unit_before_its_number_scales_by_the_declared_places(self):
        f = self.read("price EUR 12,600 excluding VAT", "EUR")
        self.assertEqual(f["value"], {"units": 1260000, "code": "EUR"})

    def test_a_unit_after_its_number_and_a_fraction(self):
        f = self.read("price 650.50 GBP now", "GBP")
        self.assertEqual(f["value"], {"units": 65050, "code": "GBP"})

    def test_a_unit_with_no_number_beside_it_states_nothing(self):
        self.assertIsNone(self.read("paid in EUR only", "EUR"))

    def test_an_amount_finer_than_the_declared_places_states_nothing(self):
        self.assertIsNone(self.read("price EUR 1.005 now", "EUR"))


if __name__ == "__main__":
    unittest.main()
