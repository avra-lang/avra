"""Planner checks that need no model: the subset gate, the schema prompt,
parameter binding and the retry loop (python3 -m unittest, from this dir)."""
import json
import re
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from plan import Shared, drafted, params_of, planned, shared_socket  # noqa: E402
from prompt import render_schema  # noqa: E402
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

    def model_of(self, entity):
        return None


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


class Prompt(unittest.TestCase):
    def test_schema_comes_from_the_catalog(self):
        text = render_schema(SCHEMA)
        self.assertIn("(:PersonalRelationship) relative is subject's relation.", text)
        self.assertIn(".subject -> (:Person)", text)
        self.assertIn("'mum' = 'mother'", text)
        self.assertIn(".requested_guest_limit: integer?", text)
        self.assertNotIn("'wife' = 'wife'", text)
        self.assertIn("relationships: -[:wife]->(:Person), -[:mother]->(:Person), -[:mum]->(:Person)", text)


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

    def test_a_refused_draft_is_retried_with_its_refusal(self):
        replies = ["```cypher\nMATCH (me:Person) WHERE id(me) = $speaker RETURN me.age\n```", SLICE["q01"]]
        seen = []

        class Fake:
            def reply(self, turns):
                seen.append(turns[-1]["content"])
                return replies[len(seen) - 1]

        context = {"principal": "p:jonas", "speaker": "p:jonas", "question_at_ms": 1}
        out = planned(Fake(), "Who is my wife?", SCHEMA, context, limit=2, graph=FakeGraph(refusing="age"))
        self.assertEqual(out["cypher"], SLICE["q01"])
        self.assertIn("unknown_property", seen[1])
        json.dumps(out)

    def test_a_question_about_the_asker_must_read_from_the_speaker(self):
        unbound = SLICE["q01"].replace("id(me) = $speaker AND ", "")
        replies = [unbound, SLICE["q01"]]

        class Fake:
            calls = 0

            def reply(self, turns):
                Fake.calls += 1
                return replies[Fake.calls - 1]

            def choose(self, context, question, options):
                return [0.9 if o.startswith("yes") else 0.1 for o in options]

        context = {"principal": "p:jonas", "speaker": "p:jonas", "question_at_ms": 1}
        self.assertEqual(planned(Fake(), "Who is my wife?", SCHEMA, context, limit=2, graph=FakeGraph())["cypher"], SLICE["q01"])
        self.assertEqual(Fake.calls, 2)

    def test_drafts_lose_fences_and_prose(self):
        self.assertEqual(drafted("Here it is:\n```\nMATCH (a:Person)\nRETURN a.name\n```"), "MATCH (a:Person) RETURN a.name")


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

        chooser = Scripted(["person asking", "Person", "yes", "value"], {"name"})
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

        chooser = Scripted(["person asking", "Person", "contains 'guest'", "contains 'launch'", "value"],
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

        chooser = Scripted(["person asking", "Person", "yes", "value"], {"name"})
        cypher = structured.plan(chooser, "Who is my wife?", SCHEMA, SPEAKER, search)
        self.assertEqual(chooser.asked[0][1], ["the person asking or speaking", "every record of one kind"])
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
        recorded = Scripted(["person asking", "Person", "assignee is this", "contains 'table'", "yes", "value",
                             "recorded", "confirmation_recorded"])
        cypher = structured.plan(recorded, "Is my table booking on record?", SCHEMA, SPEAKER, search)
        self.assertTrue(cypher.endswith("RETURN coalesce(n1.confirmation_recorded, false) AS confirmation_recorded"), cypher)
        world = Scripted(["person asking", "Person", "assignee is this", "contains 'table'", "yes", "value", "content"],
                         {"confirmation_recorded"})
        cypher = structured.plan(world, "Did I book the table?", SCHEMA, SPEAKER, search)
        self.assertTrue(cypher.endswith("RETURN n1.confirmation_recorded AS confirmation_recorded"), cypher)

    def test_the_budget_caps_the_walk(self):
        import structured

        chooser = Scripted(["person asking", "Person", "value"], {"name"})
        cypher = structured.plan(chooser, "Who is my wife?", SCHEMA, SPEAKER, depth=0)
        self.assertEqual(cypher, "MATCH (n0:Person) WHERE id(n0) = $speaker RETURN n0.name AS name")


class Choices(unittest.TestCase):
    def test_a_walk_returns_its_decisions_and_their_runtime_prompts(self):
        import choices

        def label(context, question, options):
            for want in ("person asking", "Person", "yes", "value", "name"):
                hits = [i for i, o in enumerate(options) if want in o]
                if hits:
                    return hits[0]
            return len(options) - 1

        cypher, decisions = choices.walk("Who is my wife?", SCHEMA, SPEAKER, label)
        self.assertEqual(cypher, "MATCH (n0:Person)-[:wife]->(n1:Person) WHERE id(n0) = $speaker RETURN n1.name AS name")
        first = choices.prompts(decisions[0])
        self.assertEqual([gold for _, gold in first], ["A", "B"])
        self.assertTrue(first[0][0].startswith("Question: Who is my wife?\n\nWho or what is the question about first?\nA) the person asking"))
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
                        conn.sendall(b'{"text": "MATCH (a:Person) RETURN a.name"}\n')

        threading.Thread(target=serve, daemon=True).start()
        self.assertEqual(shared_socket(path), path)
        text = Shared(path).reply([{"role": "user", "content": "q"}])
        server.close()
        self.assertEqual(text, "MATCH (a:Person) RETURN a.name")
        self.assertEqual(asked[0]["op"], "generate")
        self.assertIsNone(shared_socket(path.parent / "absent.sock"))


if __name__ == "__main__":
    unittest.main()
