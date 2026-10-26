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


class Anchor(unittest.TestCase):
    def entity(self, label):
        m = model("Item", [prop("code", "string"), prop("name", "string")])
        m["semantics"]["label"] = label
        return cascade.Plan([m, model("Use", [prop("item", {"reference": "Item"})])])

    def test_an_entity_is_named_by_its_declared_label_field(self):
        self.assertEqual(self.entity(["name"]).anchor("Item"), "name")

    def test_without_a_declared_label_the_first_required_text_names_it(self):
        self.assertEqual(self.entity(None).anchor("Item"), "code")


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


class Derived(unittest.TestCase):
    def test_a_derivations_output_is_never_proposed_from_text(self):
        d = descriptor() + [model("Total", [prop("label", "string")])]
        self.assertIn("Total", cascade.Plan(d).records)
        plan = cascade.Plan(d, [{"name": "sum", "output": "Total"}])
        self.assertNotIn("Total", plan.records)
        self.assertNotIn("Total", plan.blocked)


class Sentence(unittest.TestCase):
    def cascade_over(self, text, script):
        c = cascade.Cascade.__new__(cascade.Cascade)
        c.plan = cascade.Plan(descriptor())
        c.t = cascade.Text(text)
        c.frames = []
        c.filled = []
        c.fill = lambda kind, x, y, chosen: c.filled.append(kind)
        asked = []
        script = list(script)

        def pick(ctx, question, options, tail=(), **_):
            asked.append(list(options))
            want = script.pop(0)
            out = [0.0] * (len(options) + len(tail))
            out[len(options) if want is None else options.index(want)] = 1.0
            return out

        c.llm = type("L", (), {"pick": staticmethod(pick)})()
        return c, asked

    def test_every_kind_a_sentence_states_is_taken_in_turn_and_not_asked_again(self):
        c, asked = self.cascade_over("A and B.", ["Cash: x", "Sale: y", None])
        opts = {"Cash": "Cash: x", "Sale": "Sale: y", "Pair": "Pair: z"}
        self.assertEqual([k for k, _ in c.sentence_records(["Cash", "Sale", "Pair"], opts, 0, 8)], ["Cash", "Sale"])
        self.assertEqual([len(a) for a in asked], [3, 2, 1])

    def test_a_sentence_that_states_nothing_is_asked_once(self):
        c, asked = self.cascade_over("Nothing.", [None])
        self.assertEqual((c.sentence_records(["Cash"], {"Cash": "Cash: x"}, 0, 8), len(asked)), ([], 1))


class Partial(unittest.TestCase):
    def cascade_over(self, fields):
        c = cascade.Cascade.__new__(cascade.Cascade)
        c.plan = cascade.Plan(descriptor())
        c.t = cascade.Text("a sentence")
        c.frames = []
        c.records = []
        c.minted = 0
        c.value_of = lambda model, p, found, ctx, a, b: fields.get(p["name"])
        c.spans = {}
        c.qualifiers = lambda a, b, claim: {}
        c.llm = type("L", (), {"pick": staticmethod(lambda ctx, q, options, tail=(): [1.0, 0.0])})()
        return c

    def field(self, name, value):
        return {"property": name, "value": value, "evidence": []}

    def test_a_record_with_one_grounded_field_is_kept_though_a_required_one_is_missing(self):
        cascade.LOG.clear()
        c = self.cascade_over({"label": self.field("label", "x")})
        c.fill("Sale", 0, 10, 1.0)
        self.assertEqual([r["model"] for r in c.records], ["Sale"])
        self.assertTrue(any(line.startswith("partial Sale") for line in cascade.LOG))

    def test_a_record_nothing_grounds_is_dropped_and_says_so(self):
        cascade.LOG.clear()
        c = self.cascade_over({})
        c.fill("Sale", 0, 10, 1.0)
        self.assertEqual(c.records, [])
        self.assertTrue(any(line.startswith("drop Sale") for line in cascade.LOG))


class ValueTypes(unittest.TestCase):
    def test_a_value_type_held_in_a_list_is_never_a_record_of_its_own(self):
        d = descriptor() + [model("Part", [prop("label", "string")]), model("Whole", [prop("name", "string"), prop("parts", {"optional": {"list": {"embedded": "Part"}}})])]
        plan = cascade.Plan(d)
        self.assertNotIn("Part", plan.records)
        self.assertIn("Whole", plan.records)


if __name__ == "__main__":
    unittest.main()
