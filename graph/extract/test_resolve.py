"""Witnesses for cross-source resolution over a scripted graph and chooser."""
import unittest

import resolve

SCHEMA = {"models": [{"name": "Person", "semantics": {"label": ["name"]}}, {"name": "Memo", "semantics": {}}]}
SOURCE = {"observation": "chat:a", "revision": 1, "content": "Elena sent the file. Rowan thanked her."}


class Fake:
    """A graph answering the ops the resolver uses."""

    def __init__(self, entities, referents):
        self.entities, self.found, self.merges, self.asked, self.choices = entities, referents, [], [], []

    def __call__(self, request):
        op = request["op"]
        if op == "get":
            e = self.entities[request["id"]]
            return {"model": e["model"], "fields": {k: [{"value": v, "claim": e["claim"] + i, "chosen": False, "denied": False} for i, v in enumerate(vs)] for k, vs in e["fields"].items()}}
        if op == "referents":
            self.asked.append(request)
            return [{"entity": e, "label": "x", "rank": -1.0} for e in self.found.get(request["mention"], []) if e != request["exclude"]]
        if op == "merges":
            return [{"left": m["left"], "right": m["right"], "active": True} for m in self.merges]
        if op == "merge":
            self.merges.append(request)
            return {"revision": len(self.merges)}
        if op == "choose":
            self.choices.append(request)
            return {"revision": 9}
        if op == "explain":
            return []
        if op == "source":
            return {"content": SOURCE["content"]}
        raise AssertionError(op)


class Scripted:
    """One probability row for every choice, or a list of rows answered in order."""

    def __init__(self, p):
        self.p, self.seen = p, []

    def choose(self, context, question, options):
        self.seen.append((context, question, options))
        return self.p[len(self.seen) - 1] if isinstance(self.p[0], list) else self.p


CLAIMS = iter(range(10, 1000, 10))


def person(*names, **rest):
    return {"model": "Person", "claim": next(CLAIMS), "fields": {"name": list(names), **{k: [v] for k, v in rest.items()}}}


def resolver(graph, p):
    r = resolve.Resolver(SCHEMA, graph, Scripted(p))
    r.margin, r.ceiling = 0.5, 0.25
    return r


def receipt(*entities):
    return {"records": [{"entity": e, "local_id": e, "link": "new"} for e in entities]}


class Resolution(unittest.TestCase):
    def test_a_confident_choice_merges_the_pair_with_a_decider(self):
        graph = Fake({"old": person("Elena Vale", email="e@x"), "new": person("Elena")}, {"Elena": ["old"]})
        done = resolver(graph, [0.9, 0.05, 0.05]).resolve(graph, SOURCE, receipt("new"))
        self.assertEqual(done[0]["choice"], "old")
        self.assertEqual([(m["left"], m["right"]) for m in graph.merges], [("new", "old")])
        self.assertTrue(graph.merges[0]["decider"].startswith("er:"))

    def test_a_linked_spelling_does_not_rival_the_established_name(self):
        old, new = person("Elena Vale"), person("Elena")
        graph = Fake({"old": old, "new": new}, {"Elena": ["old"]})
        resolver(graph, [0.9, 0.05, 0.05]).resolve(graph, SOURCE, receipt("new"))
        self.assertEqual([(c["claim"]) for c in graph.choices], [old["claim"]])

    def test_an_unsure_spelling_choice_leaves_the_rivals(self):
        graph = Fake({"old": person("Elena Vale"), "new": person("Elena")}, {"Elena": ["old"]})
        done = resolver(graph, [[0.9, 0.05, 0.05], [0.4, 0.45, 0.15]]).resolve(graph, SOURCE, receipt("new"))
        self.assertEqual(done[0]["name"]["choice"], "abstain")
        self.assertEqual(graph.choices, [])

    def test_the_spelling_choice_offers_each_spelling_once(self):
        graph = Fake({"old": person("Elena Vale"), "new": person("Elena")}, {"Elena": ["old"]})
        r = resolver(graph, [0.9, 0.05, 0.05])
        r.resolve(graph, SOURCE, receipt("new"))
        self.assertEqual(r.chooser.seen[1][2], ["Elena Vale", "Elena", resolve.UNSURE])

    def test_the_same_spelling_needs_no_choice(self):
        graph = Fake({"old": person("Elena Vale"), "new": person("Elena Vale")}, {"Elena Vale": ["old"]})
        resolver(graph, [0.9, 0.05, 0.05]).resolve(graph, SOURCE, receipt("new"))
        self.assertEqual(graph.choices, [])

    def test_the_options_carry_what_the_graph_knows_of_each_candidate(self):
        graph = Fake({"old": person("Elena Vale", email="e@x"), "new": person("Elena")}, {"Elena": ["old"]})
        r = resolver(graph, [0.9, 0.05, 0.05])
        r.resolve(graph, SOURCE, receipt("new"))
        options = r.chooser.seen[0][2]
        self.assertIn("Elena Vale", options[0])
        self.assertIn("email e@x", options[0])
        self.assertEqual(options[-2:], [resolve.NEW, resolve.UNSURE])

    def test_an_uncertain_choice_merges_nothing(self):
        graph = Fake({"old": person("Elena Vale"), "new": person("Elena")}, {"Elena": ["old"]})
        done = resolver(graph, [0.5, 0.2, 0.3]).resolve(graph, SOURCE, receipt("new"))
        self.assertEqual(done[0]["choice"], "abstain")
        self.assertEqual(graph.merges, [])

    def test_someone_new_merges_nothing(self):
        graph = Fake({"old": person("Elena Vale"), "new": person("Elena")}, {"Elena": ["old"]})
        done = resolver(graph, [0.02, 0.95, 0.03]).resolve(graph, SOURCE, receipt("new"))
        self.assertEqual(done[0]["choice"], "new")
        self.assertEqual(graph.merges, [])

    def test_entities_of_one_source_are_never_merged_with_each_other(self):
        graph = Fake({"a": person("Elena"), "b": person("Elena Vale")}, {"Elena": ["a", "b"], "Elena Vale": ["a", "b"]})
        r = resolver(graph, [0.9, 0.05, 0.05])
        self.assertEqual(r.resolve(graph, SOURCE, receipt("a", "b")), [])
        self.assertEqual(graph.merges, [])

    def test_a_model_without_a_label_is_not_resolved(self):
        graph = Fake({"m": {"model": "Memo", "claim": 1, "fields": {"subject": ["Elena"]}}}, {})
        self.assertEqual(resolver(graph, [1.0, 0.0]).resolve(graph, SOURCE, receipt("m")), [])
        self.assertEqual(graph.asked, [])

    def test_a_merged_group_is_one_candidate(self):
        graph = Fake({"old": person("Elena Vale"), "twin": person("Elena"), "new": person("Elena")},
                     {"Elena": ["old", "twin"]})
        graph.merges.append({"left": "old", "right": "twin"})
        r = resolver(graph, [0.9, 0.05, 0.05])
        r.resolve(graph, SOURCE, receipt("new"))
        self.assertEqual(len(r.chooser.seen[0][2]), 3)


class Rule(unittest.TestCase):
    def test_decide_links_only_with_the_margin(self):
        self.assertEqual(resolve.decide([0.8, 0.1, 0.1], 1, 0.5, 0.25), 0)
        self.assertEqual(resolve.decide([0.45, 0.4, 0.15], 1, 0.5, 0.25), "abstain")

    def test_decide_is_new_only_when_no_candidate_is_plausible(self):
        self.assertEqual(resolve.decide([0.1, 0.8, 0.1], 1, 0.5, 0.25), "new")
        self.assertEqual(resolve.decide([0.4, 0.5, 0.1], 1, 0.5, 0.25), "abstain")

    def test_sentence_is_the_one_holding_the_span(self):
        text = "Elena sent the file. Rowan thanked her. Done"
        at = text.index("Rowan")
        self.assertEqual(resolve.sentence(text, at, at + 5), "Rowan thanked her.")


if __name__ == "__main__":
    unittest.main()
