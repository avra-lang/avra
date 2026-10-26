"""Planner checks that need no model: the subset gate, the schema prompt,
parameter binding and the retry loop (python3 -m unittest, from this dir)."""
import json
import re
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from plan import Shared, composed, params_of, shared_socket, viewed  # noqa: E402
from catalog import Refusal  # noqa: E402
from plan import gated  # noqa: E402


def prop(name, shape, description="", enum=None):
    p = {"name": name, "shape": shape, "description": description, "rules": [], "default_source": None}
    if enum is not None:
        p["enum"] = enum
    return p


def ref(target):
    return {"reference": target}


def opt(shape):
    return {"optional": shape}


SCHEMA = {"fingerprint": "f", "revision": 1, "models": [
    {"name": "Person", "description": "A person.", "properties": [prop("name", "string")], "semantics": {}},
    {"name": "PersonalRelationship", "description": "relative is subject's relation.", "properties": [
        prop("subject", ref("Person")),
        prop("relation", "string", enum=["wife", "husband", "mother"]),
        prop("relative", ref("Person"))],
     "semantics": {"relation": {"from": ["subject"], "to": ["relative"], "label": ["relation"], "labels": [
         {"value": "wife", "forward": ["wife"], "reverse": []},
         {"value": "mother", "forward": ["mother", "mum", "mom"], "reverse": []}]}}},
    {"name": "Group", "description": "", "properties": [prop("name", "string")], "semantics": {}},
    {"name": "GroupMembership", "description": "", "properties": [
        prop("person", ref("Person")), prop("group", ref("Group")), prop("is_member", "boolean")], "semantics": {}},
    {"name": "Event", "description": "", "properties": [
        prop("title", "string"), prop("requested_guest_limit", opt("integer"))], "semantics": {}},
    {"name": "Commitment", "description": "", "properties": [
        prop("actor", ref("Person")), prop("event", opt(ref("Event"))), prop("action", "string"),
        prop("speech_act", "string", enum=["request", "promise"]), prop("condition", opt("string"))], "semantics": {}},
    {"name": "PersonalTask", "description": "", "properties": [
        prop("summary", "string"), prop("requested_by", opt(ref("Person"))), prop("assignee", opt(ref("Person"))),
        prop("requested_reservation_at_ms", opt("integer")), prop("confirmation_recorded", opt("boolean"))],
     "semantics": {}},
]}

PARAMS = {"asker": "p:jonas", "now": 1, "speaker": "p:jonas"}

SLICE = {
    "q01": "MATCH (me:Person)<-[:subject]-(r:PersonalRelationship)-[:relative]->(w:Person) WHERE id(me) = $speaker AND r.relation = 'wife' RETURN w.name AS person",
    "q07": "MATCH (a:Person)<-[:subject]-(r:PersonalRelationship)-[:relative]->(w:Person)<-[:person]-(m:GroupMembership) WHERE a.name = 'Dana Holm' AND r.relation = 'wife' RETURN m.person AS person, m.is_member AS on_styling_crew",
    "q16": "MATCH (me:Person)<-[:subject]-(r:PersonalRelationship)-[:relative]->(w:Person)<-[:actor]-(c:Commitment) WHERE id(me) = $speaker AND r.relation = 'wife' AND c.action CONTAINS 'guest' MATCH (c)-[:event]->(e:Event) RETURN c.actor AS speaker, c.speech_act AS speech_act, c.condition AS condition, e.requested_guest_limit AS requested_guest_limit",
    "q46": "MATCH (me:Person)<-[:subject]-(r:PersonalRelationship)-[:relative]->(w:Person)<-[:requested_by]-(t:PersonalTask) WHERE id(me) = $speaker AND r.relation = 'wife' AND t.summary CONTAINS 'dinner' RETURN t.requested_by AS requested_by, t.assignee AS assignee, t.requested_reservation_at_ms AS requested_reservation_at",
    "q47": "MATCH (me:Person)<-[:assignee]-(t:PersonalTask) WHERE id(me) = $speaker AND t.summary CONTAINS 'dinner' RETURN t.assignee AS promised_by, t.confirmation_recorded AS booking_confirmed",
}


class FakeGraph:
    """Answers the check op as the graph does: ok, or a refusal with its code."""

    def __init__(self, refusing=None):
        self.refusing, self.checked = refusing, []

    def call(self, body):
        self.checked.append(body)
        if self.refusing and self.refusing in body["cypher"]:
            return {"ok": False, "code": "unknown_property", "message": f"no `{self.refusing}`"}
        return {"ok": True, "steps": 1}

    def search(self, query):
        return []

    def read(self, entity):
        return {}

    def prober(self, params):
        return lambda cypher: self.call({"op": "query", "cypher": cypher, "params": params})


class Gate(unittest.TestCase):
    def test_the_graphs_check_op_is_the_gate(self):
        graph = FakeGraph(refusing="age")
        gated(SLICE["q01"], SCHEMA, PARAMS, graph)
        with self.assertRaises(Refusal) as refused:
            gated("MATCH (me:Person) RETURN me.age", SCHEMA, PARAMS, graph)
        self.assertEqual(refused.exception.code, "unknown_property")
        self.assertEqual(graph.checked[0], {"op": "check", "cypher": SLICE["q01"], "params": PARAMS})

    def test_without_a_graph_nothing_is_refused_here(self):
        gated("not cypher at all", SCHEMA, PARAMS, None)


class Budgeting(unittest.TestCase):
    def test_the_budget_is_the_declared_context_less_the_answer(self):
        import tempfile
        from prompt import Budget, declared_context

        hub = pathlib.Path(tempfile.mkdtemp())
        snapshot = hub / "models--acme--tiny" / "snapshots" / "r1"
        snapshot.mkdir(parents=True)
        (snapshot / "config.json").write_text(json.dumps({"max_position_embeddings": 50}))
        self.assertEqual(declared_context("acme/tiny", hub), 50)
        self.assertIsNone(declared_context("acme/absent", hub))
        budget = Budget(declared_context("acme/tiny", hub), 10)
        budget.holds("x" * 40)
        with self.assertRaises(SystemExit):
            budget.holds("x" * 30, "y" * 11)
        Budget(None, 10).holds("x" * 10_000)


class Loop(unittest.TestCase):
    def test_params_bind_the_context(self):
        context = {"principal": "p:jonas", "speaker": "p:dana", "question_at_ms": 9,
                   "valid_at_ms": None, "known_revision": 3}
        self.assertEqual(params_of(context), {"asker": "p:jonas", "now": 9, "speaker": "p:dana", "known_revision": 3})
        self.assertNotIn("speaker", params_of({**context, "speaker": None}))


class Derived(unittest.TestCase):
    SCHEMA = {"fingerprint": "f", "revision": 1, "models": [
        {"name": "Invoice", "description": "A bill.", "properties": [prop("number", "string")], "semantics": {}},
        {"name": "Payment", "description": "Money paid.", "properties": [prop("invoice", ref("Invoice")), prop("amount", "integer")],
         "semantics": {}},
        {"name": "PaymentStatus", "description": "", "properties": [prop("settled", "boolean")], "semantics": {}},
    ], "derivations": [{"name": "payment_status", "description": "Whether an invoice is settled.", "output": "PaymentStatus",
                        "parameters": [{"name": "invoice", "input": {"one": "Invoice"}},
                                       {"name": "payments", "input": {"all": "Payment"}}]}]}

    def test_a_declared_derivation_is_composed_from_its_seats(self):
        import structured

        chooser = Scripted(["Invoice", "yes", "payment_status"])
        cypher = structured.plan(chooser, "Is it paid?", self.SCHEMA, NOBODY)
        self.assertEqual(cypher, "MATCH (n0:Invoice) MATCH (n0)<-[:invoice]-(n1:Payment) "
                                 "RETURN payment_status(n0, collect(n1)) AS payment_status")
        self.assertNotIn("PaymentStatus", [o for q, os in chooser.asked for o in os if q.startswith("Which kind")])


class Searching(unittest.TestCase):
    class Model:
        calls = 0

        def choose(self, context, question, options):
            Searching.Model.calls += 1
            return [0.55, 0.45] if question == "q1" else [0.9, 0.1]

    @staticmethod
    def make(walker):
        import structured

        return "xy"[structured.best(walker, "c", "q1", ["x", "y"])] + "uv"[structured.best(walker, "c", "q2", ["u", "v"])]

    def test_candidates_flip_the_least_sure_decisions_and_rank_by_joint_score(self):
        import search

        self.assertEqual([p.cypher for p in search.candidates(self.Model(), self.make, width=2, flips=2, rounds=1)],
                         ["xu", "yu", "xv"])
        self.assertEqual([p.cypher for p in search.candidates(self.Model(), self.make, width=1, flips=0, rounds=1)], ["xu"])

    def test_a_remembered_prompt_is_asked_once(self):
        import search

        Searching.Model.calls = 0
        search.candidates(self.Model(), self.make, width=2, flips=2, rounds=1)
        self.assertEqual(Searching.Model.calls, 4)


class Beaming(unittest.TestCase):
    """A two-step walk: the first step prefers `a`, whose branch binds nothing."""

    class Model:
        def choose(self, context, question, options):
            weights = {"a": 0.6, "b": 0.3, "c": 0.1} if question == "first" else \
                {"x": 0.7, "y": 0.3} if context.endswith("a") else {"x": 0.4, "y": 0.6}
            return [weights[o] for o in options]

    @staticmethod
    def make(walker):
        import structured

        out = structured.Plan()
        walker.watch(out)
        first = "abc"[structured.best(walker, "so far:", "first", ["a", "b", "c"])]
        out.parts.append(f"({first})")
        out.node(first)
        second = "xy"[structured.best(walker, f"so far: {first}", "second", ["x", "y"])]
        out.parts.append(f"-[:{second}]")
        return "".join(out.parts)

    @staticmethod
    def probe(empty):
        def ask(query):
            hit = any(e in query for e in empty)
            return {"status": "unknown" if hit else "answered", "fields": [] if hit else [{"value": 1}]}
        return ask

    def test_k1_is_the_greedy_walk(self):
        import beam

        found = beam.candidates(self.Model(), self.make, None, 1)
        self.assertEqual([p.cypher for p in found], ["(a)-[:x]"])

    def test_a_partial_plan_binding_nothing_is_dropped_and_the_beam_moves_on(self):
        import beam

        found = beam.candidates(self.Model(), self.make, self.probe(["(a)"]), 1)
        self.assertEqual([p.cypher for p in found], ["(b)-[:y]"])

    def test_a_wider_beam_reaches_a_plan_greedy_scores_below(self):
        import beam

        found = beam.candidates(self.Model(), self.make, None, 2)
        self.assertEqual(found[0].cypher, "(a)-[:x]")
        self.assertGreater(len(found), 1)

    def test_a_finished_plan_with_an_empty_answer_is_never_chosen(self):
        import beam

        found = beam.candidates(self.Model(), self.make, self.probe(["-[:x]", "-[:y]"]), 3)
        self.assertEqual(found, [])

    def test_a_remembered_prompt_is_asked_once(self):
        import beam

        asked = []

        class Counting(self.Model):
            def choose(self, context, question, options):
                asked.append((context, question, tuple(options)))
                return super().choose(context, question, options)

        beam.candidates(Counting(), self.make, None, 2)
        self.assertEqual(len(asked), len(set(asked)))


class Contrasting(unittest.TestCase):
    @staticmethod
    def probe(rows):
        def ask(cypher):
            return {"status": "answered", "fields": [{"path": [e, col], "value": v} for e, col, v in rows[cypher]]}
        return ask

    @staticmethod
    def plan(cypher, steps, tally=0.0):
        import beam

        return beam.Plan(cypher, tally, len(steps), tuple(steps))

    def test_plans_with_the_same_answer_are_one_group_and_need_no_model(self):
        import contrast

        rows = {"a": [("e1", "title", "x")], "b": [("e1", "name", "x")]}
        verdict = contrast.settle(None, "Q", [self.plan("a", ["s"]), self.plan("b", ["t"])], self.probe(rows), 3)
        self.assertEqual((verdict.plan.cypher, verdict.groups), ("a", 1))

    def test_groups_are_described_by_their_rows_and_steps_and_the_model_may_decline(self):
        import contrast

        rows = {"a": [("e1", "title", "x"), ("e2", "title", "y")], "b": [("e1", "title", "x")]}
        seen = []

        class Model:
            def choose(self, context, question, options):
                seen.append(options)
                return [1.0 if o.startswith("none") else 0.0 for o in options]

        verdict = contrast.settle(Model(), "Q", [self.plan("a", ["follow actor"]), self.plan("b", ["follow recipient"])],
                                  self.probe(rows), 3)
        self.assertIsNone(verdict.plan)
        first = sorted(seen[0])
        self.assertTrue(any("chooses: follow actor" in o and "only this returns 1: title='y'" in o for o in first))
        self.assertTrue(any("chooses: follow recipient" in o and "leaves out 1: title='y'" in o for o in first))


class Speaker(unittest.TestCase):
    def test_the_gate_is_framed_with_the_speakers_declared_label(self):
        import structured

        schema = json.loads(json.dumps(SCHEMA))
        schema["models"][0]["semantics"] = {"label": ["name"]}
        seen = []

        class Asks:
            def choose(self, context, question, options):
                seen.append((context, question))
                return [0.2, 0.8]

        read = lambda entity: {"model": "Person", "fields": {"name": [{"value": "Jonas Berg", "chosen": False}]}}
        self.assertFalse(structured.speaking(Asks(), "Question: Who is Dana?", structured.models_of(schema), SPEAKER, read))
        self.assertEqual(seen[0][0], "Question: Who is Dana?\nAsked by Jonas Berg.")
        self.assertIn("about Jonas Berg, the one asking", seen[0][1])


class Reading(unittest.TestCase):
    def test_a_bound_valid_instant_is_the_views_without_a_choice(self):
        context = {"question_at_ms": 5, "valid_at_ms": 86_400_000}
        self.assertEqual(viewed(None, "q", context), {"valid_at": "1970-01-02T00:00:00Z"})

    def test_a_refused_composition_carries_the_graphs_reason(self):
        class Takes:
            def choose(self, context, question, options):
                return [1.0] + [0.0] * (len(options) - 1)

        context = {"principal": "p:jonas", "speaker": "p:jonas", "question_at_ms": 1}
        with self.assertRaises(Refusal) as refused:
            composed(Takes(), "Who is my wife?", SCHEMA, context, FakeGraph(refusing="Person"))
        self.assertIn("unknown_property", str(refused.exception))


class Picking:
    """Picks, call by call, the option containing the next scripted text."""

    def __init__(self, script):
        self.script, self.asked = list(script), []

    def choose(self, context, question, options):
        self.asked.append((context, question, options))
        want = self.script[0]
        if question == getattr(self, "last", None) and options == self.seen[::-1]:
            self.script.pop(0)
        self.last, self.seen = question, options
        return [1.0 if want in o else 0.0 for o in options]


class When(unittest.TestCase):
    """A question's time by calendar containment, anchored on a fixed asking instant."""

    # Wednesday 21 October 2026, 15:00 UTC.
    NOW = 1792594800000

    def test_now_is_no_span(self):
        import when

        self.assertIsNone(when.asked_time(Picking(["now"]), "Who is our creative director now?", self.NOW))

    def test_a_named_day_narrows_through_its_month_and_week(self):
        import when

        got = when.asked_time(Picking(["2026", "October", "12 October", "Wednesday"]),
                              "Who was our creative director on 14 October?", self.NOW)
        self.assertEqual(got["value"], "2026-10-14")
        self.assertEqual(got["end_ms"] - got["start_ms"], 86400000)

    def test_a_week_is_an_iso_week_in_the_asking_zone(self):
        import when

        got = when.asked_time(Picking(["2026", "October", "19 October", "all of"]),
                              "Am I still booked into the hotel this week?", self.NOW, "Europe/Paris")
        self.assertEqual(got["value"], "2026-W43")
        self.assertEqual(got["start_ms"], 1792360800000)  # Monday 19 October 2026 00:00 Paris (UTC+2)

    def test_a_whole_year(self):
        import when

        got = when.asked_time(Picking(["2025", "all of"]), "What did we ship last year?", self.NOW)
        self.assertEqual(got["value"], "2025")

    def test_a_month_spans_its_days(self):
        import when

        got = when.asked_time(Picking(["2026", "December", "all of"]), "What launched in December?", self.NOW)
        self.assertEqual((got["value"], got["end_ms"]), ("2026-12", 1798761600000))

    def test_the_asking_day_is_in_the_trail(self):
        import when

        chooser = Picking(["now"])
        when.asked_time(chooser, "Anything due?", self.NOW)
        self.assertIn("Wednesday 21 October 2026", chooser.asked[0][0])


class Scripted:
    """Picks, call by call, the first option containing the next scripted word."""

    def __init__(self, script, wanted=()):
        self.script, self.wanted, self.asked, self.last = list(script), set(wanted), [], None

    def choose(self, context, question, options):
        if question.startswith(("Which property does", "Which other property")):
            self.asked.append((question, options))
            given = set(re.findall(r"the \w+'s (\w+)", context.partition("Already answering with:")[2]))
            named = [re.match(r"the \w+'s (\w+)", o) for o in options]
            hits = [i for i, m in enumerate(named) if m and m.group(1) in self.wanted - given]
            done = [i for i, m in enumerate(named) if not m]
            pick = hits[0] if hits else (done or [0])[0]
            return [1.0 if i == pick else 0.0 for i in range(len(options))]
        need = re.match(r"Does the answer need the \w+'s (\w+)", question)
        if need:
            self.asked.append((question, options))
            answer = "yes" if need.group(1) in self.wanted else "no"
            return [1.0 if o == answer else 0.0 for o in options]
        again = self.asked and self.asked[-1][0] == question and sorted(self.asked[-1][1]) == sorted(options)
        if again and self.last is not None:
            want, self.last = self.last, None
        else:
            want = self.script.pop(0)
            self.asked.append((question, options))
            self.last = want
        hits = [i for i, o in enumerate(options) if want in o]
        if not hits:
            raise AssertionError(f"{want!r} is not among {options}")
        return [1.0 if i == hits[0] else 0.0 for i in range(len(options))]


def facts(*rows):
    """A search stub answering the given admitted facts for any query."""
    return lambda query: [{"kind": "fact", "text": row} for row in rows]


SPEAKER = {"principal": "p:jonas", "speaker": "p:jonas", "question_at_ms": 1}
NOBODY = {"principal": "p:jonas", "speaker": None, "question_at_ms": 1}


class Structured(unittest.TestCase):
    def test_choices_compose_a_query_the_gate_admits(self):
        import structured

        chooser = Scripted(["yes", "Person", "yes", "value"], {"name"})
        cypher = structured.plan(chooser, "Who is my wife?", SCHEMA, SPEAKER)
        self.assertEqual(cypher, "MATCH (n0:Person)-[:wife]->(n1:Person) WHERE id(n0) = $speaker RETURN n1.name AS name")
        self.assertFalse(chooser.script)

    def test_a_record_the_question_names_comes_from_search(self):
        import structured

        chooser = Scripted(["Dana Holm", "yes", "value"], {"name"})
        search = facts("Person name: Dana Holm", "Group name: night shift")
        cypher = structured.plan(chooser, "Who is Dana Holm's wife?", SCHEMA, NOBODY, search)
        self.assertEqual(cypher, "MATCH (n0:Person)-[:wife]->(n1:Person) WHERE n0.name = 'Dana Holm' RETURN n1.name AS name")
        self.assertEqual(chooser.asked[0][1], ["the Person whose name is 'Dana Holm', named in the question", "every record of one kind"])

    def test_facts_the_question_reaches_lead_the_walk_on(self):
        import structured

        chooser = Scripted(["yes", "Person", "contains 'guest'", "contains 'launch'", "value"],
                           {"requested_guest_limit"})
        search = facts("Commitment action: keep the guest list short", "Event title: spring launch")
        cypher = structured.plan(chooser, "What guest limit did my wife set for the launch?", SCHEMA, SPEAKER, search)
        self.assertTrue(cypher.startswith("MATCH (n0:Person)-[:wife]->(n1:Person)<-[:actor]-(n2:Commitment)-[:event]->(n3:Event)"), cypher)
        self.assertIn("n2.action CONTAINS 'guest'", cypher)
        self.assertFalse(any("Is the answer about" in q for q, _ in chooser.asked))

    def test_competing_declared_phrases_are_the_models_choice(self):
        import copy
        import structured

        schema = copy.deepcopy(SCHEMA)
        membership = next(m for m in schema["models"] if m["name"] == "GroupMembership")
        membership["semantics"] = {"relation": {"from": ["person"], "to": ["group"], "label": [], "labels": [
            {"value": "member", "forward": ["member of", "on"], "reverse": []}]}}
        chooser = Scripted(["Dana Holm", "their wife", "yes", "value", "content"], {"name"})
        cypher = structured.plan(chooser, "Dana Holm said his wife was not on the crew. Who is she?", schema, NOBODY,
                                 facts("Person name: Dana Holm"))
        question, options = chooser.asked[1]
        self.assertEqual(question, "Which relation does the question mean?")
        self.assertEqual(len(options), 2)
        self.assertTrue(cypher.startswith("MATCH (n0:Person)-[:wife]->(n1:Person)"), cypher)

    def test_a_category_is_not_a_name_and_a_common_word_is_not_evidence(self):
        import structured

        def search(word):
            common = [{"kind": "source", "text": f"text {i}"} for i in range(9)]
            hits = {"wife": [{"kind": "fact", "text": "PersonalRelationship relation: wife"}],
                    "is": common + [{"kind": "fact", "text": "Group name: is club"}],
                    "my": common, "who": common}
            return hits.get(word, [])

        chooser = Scripted(["yes", "Person", "yes", "value"], {"name"})
        cypher = structured.plan(chooser, "Who is my wife?", SCHEMA, SPEAKER, search)
        self.assertEqual(chooser.asked[0][1], ["no", "yes"])
        self.assertEqual(cypher, "MATCH (n0:Person)-[:wife]->(n1:Person) WHERE id(n0) = $speaker RETURN n1.name AS name")

    def test_a_hop_shows_the_facts_that_point_to_it(self):
        import structured

        models = structured.models_of(SCHEMA)
        evidence = structured.Evidence(facts("Commitment action: keep the guest list short"), "the guest list", models)
        hop = next(h for h in structured.hops(models, "Person") if h[1] == "Commitment")
        self.assertIn("such records hold: 'keep the guest list short'", evidence.shown(hop))
        other = next(h for h in structured.hops(models, "Person") if h[1] == "PersonalTask")
        self.assertEqual(evidence.shown(other), other[2])

    def test_a_relation_records_own_properties_can_answer(self):
        import copy
        import structured

        schema = copy.deepcopy(SCHEMA)
        membership = next(m for m in schema["models"] if m["name"] == "GroupMembership")
        membership["semantics"] = {"relation": {"from": ["person"], "to": ["group"], "label": [], "labels": [
            {"value": "member", "forward": ["member of"], "reverse": []}]}}
        chooser = Scripted(["Dana Holm", "value", "content"], {"is_member"})
        cypher = structured.plan(chooser, "Is Dana Holm a member of the crew?", schema, NOBODY, facts("Person name: Dana Holm"), depth=1)
        self.assertEqual(cypher, "MATCH (n0:Person)-[r1:member]->(n1:Group) WHERE n0.name = 'Dana Holm' RETURN r1.is_member AS is_member")

    def test_a_crossed_records_status_answers_a_status_question(self):
        import copy
        import structured

        schema = copy.deepcopy(SCHEMA)
        membership = next(m for m in schema["models"] if m["name"] == "GroupMembership")
        membership["semantics"] = {"relation": {"from": ["person"], "to": ["group"], "label": [], "labels": [
            {"value": "member", "forward": ["member of"], "reverse": []}]}}
        chooser = Scripted(["Dana Holm", "value", "yes/no status", "is_member"])
        cypher = structured.plan(chooser, "Is Dana Holm a member of the night shift?", schema, NOBODY,
                                 facts("Person name: Dana Holm"), depth=1)
        self.assertEqual(cypher, "MATCH (n0:Person)-[r1:member]->(n1:Group) WHERE n0.name = 'Dana Holm' "
                                 "RETURN coalesce(r1.is_member, false) AS is_member")

    def test_a_relation_taken_one_way_spends_its_words_both_ways(self):
        import structured

        schema = {"models": [
            {"name": "Member", "description": "", "properties": [prop("name", "string")], "semantics": {}},
            {"name": "Apiary", "description": "", "properties": [prop("name", "string")], "semantics": {}},
            {"name": "Keeping", "description": "", "properties": [
                prop("member", ref("Member")), prop("apiary", ref("Apiary")), prop("relation", "string", enum=["keeps"])],
             "semantics": {"relation": {"from": ["member"], "to": ["apiary"], "label": ["relation"], "labels": [
                 {"value": "keeps", "forward": ["keeps"], "reverse": ["keeper"]}]}}},
        ]}
        chooser = Scripted(["Hilltop", "no:", "their keeper", "yes", "value"], {"name"})
        cypher = structured.plan(chooser, "Who keeps Hilltop?", schema, NOBODY, facts("Apiary name: Hilltop"))
        self.assertEqual(cypher, "MATCH (n0:Apiary)-[:keeper]->(n1:Member) WHERE n0.name = 'Hilltop' RETURN n1.name AS name")

    def test_hops_are_only_the_nodes_own(self):
        import structured

        hops = [h[2] for h in structured.hops(structured.models_of(SCHEMA), "Person")]
        self.assertIn("their mother (mum, mom): a Person", hops)
        self.assertTrue(any("PersonalRelationship records whose subject is this Person" in h for h in hops))
        self.assertFalse(any("Group" in h for h in hops[:3]))

    def test_recorded_or_world_is_the_models_choice(self):
        import structured

        search = facts("PersonalTask summary: book a table")
        recorded = Scripted(["yes", "Person", "assignee is this", "contains 'table'", "yes", "value",
                             "recorded", "confirmation_recorded"])
        cypher = structured.plan(recorded, "Is my table booking on record?", SCHEMA, SPEAKER, search)
        self.assertTrue(cypher.endswith("RETURN coalesce(n1.confirmation_recorded, false) AS confirmation_recorded"), cypher)
        world = Scripted(["yes", "Person", "assignee is this", "contains 'table'", "yes", "value", "content"],
                         {"confirmation_recorded"})
        cypher = structured.plan(world, "Did I book the table?", SCHEMA, SPEAKER, search)
        self.assertTrue(cypher.endswith("RETURN n1.confirmation_recorded AS confirmation_recorded"), cypher)

    def test_the_budget_caps_the_walk(self):
        import structured

        chooser = Scripted(["yes", "Person", "value"], {"name"})
        cypher = structured.plan(chooser, "Who is my wife?", SCHEMA, SPEAKER, depth=0)
        self.assertEqual(cypher, "MATCH (n0:Person) WHERE id(n0) = $speaker RETURN n0.name AS name")


class Choices(unittest.TestCase):
    def test_a_walk_returns_its_decisions_and_their_runtime_prompts(self):
        import choices

        def label(context, question, options):
            for want in ("yes", "Person", "yes", "value", "name"):
                hits = [i for i, o in enumerate(options) if want in o]
                if hits:
                    return hits[0]
            return len(options) - 1

        cypher, decisions = choices.walk("Who is my wife?", SCHEMA, SPEAKER, label)
        self.assertEqual(cypher, "MATCH (n0:Person)-[:wife]->(n1:Person) WHERE id(n0) = $speaker RETURN n1.name AS name")
        first = choices.prompts(decisions[0])
        self.assertEqual([gold for _, gold in first], ["B", "A"])
        self.assertTrue(first[0][0].startswith("Question: Who is my wife?\n\nIs the question about the one asking, or about what belongs to them?\nA) no"))
        self.assertTrue(first[0][0].endswith("Answer with the letter only."))


class Socket(unittest.TestCase):
    def test_the_shared_model_answers_one_line(self):
        import socket
        import tempfile
        import threading

        path = pathlib.Path(tempfile.mkdtemp()) / "s.sock"
        server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        server.bind(str(path))
        server.listen(2)
        asked = []

        def serve():
            for _ in range(2):
                conn, _ = server.accept()
                with conn:
                    data = b""
                    while not data.endswith(b"\n"):
                        chunk = conn.recv(4096)
                        if not chunk:
                            break
                        data += chunk
                    if data:
                        asked.append(json.loads(data))
                        conn.sendall(b'{"p": [0.25, 0.75]}\n')

        threading.Thread(target=serve, daemon=True).start()
        self.assertEqual(shared_socket(path), path)
        p = Shared(path).choose("c", "q", ["a", "b"])
        server.close()
        self.assertEqual(p, [0.25, 0.75])
        self.assertEqual(asked[0]["op"], "choose")
        self.assertIsNone(shared_socket(path.parent / "absent.sock"))


if __name__ == "__main__":
    unittest.main()
