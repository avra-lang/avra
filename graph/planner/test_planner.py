"""Planner checks that need no model: the subset gate, the schema prompt,
parameter binding and the retry loop (python3 -m unittest, from this dir)."""
import json
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from plan import Shared, drafted, params_of, planned, shared_socket  # noqa: E402
from prompt import render_schema  # noqa: E402
from subset import Refusal, check  # noqa: E402


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

PARAMS = {"asker": "p:rowan", "now": 1, "speaker": "p:rowan"}

SLICE = {
    "q01": "MATCH (me:Person)<-[:subject]-(r:PersonalRelationship)-[:relative]->(w:Person) WHERE id(me) = $speaker AND r.relation = 'wife' RETURN w.name AS person",
    "q07": "MATCH (a:Person)<-[:subject]-(r:PersonalRelationship)-[:relative]->(w:Person)<-[:person]-(m:GroupMembership) WHERE a.name = 'Alex Chen' AND r.relation = 'wife' RETURN m.person AS person, m.is_member AS on_styling_crew",
    "q16": "MATCH (me:Person)<-[:subject]-(r:PersonalRelationship)-[:relative]->(w:Person)<-[:actor]-(c:Commitment) WHERE id(me) = $speaker AND r.relation = 'wife' AND c.action CONTAINS 'guest' MATCH (e:Event) WHERE e.title CONTAINS 'launch' RETURN c.actor AS speaker, c.speech_act AS speech_act, c.condition AS condition, e.requested_guest_limit AS requested_guest_limit",
    "q46": "MATCH (me:Person)<-[:subject]-(r:PersonalRelationship)-[:relative]->(w:Person)<-[:requested_by]-(t:PersonalTask) WHERE id(me) = $speaker AND r.relation = 'wife' AND t.summary CONTAINS 'dinner' RETURN t.requested_by AS requested_by, t.assignee AS assignee, t.requested_reservation_at_ms AS requested_reservation_at",
    "q47": "MATCH (me:Person)<-[:assignee]-(t:PersonalTask) WHERE id(me) = $speaker AND t.summary CONTAINS 'dinner' RETURN t.assignee AS promised_by, t.confirmation_recorded AS booking_confirmed",
}


def refused(text, params=PARAMS):
    try:
        check(text, SCHEMA, params)
    except Refusal as r:
        return r.code
    return None


class Gate(unittest.TestCase):
    def test_slice_shapes_pass(self):
        for q, text in SLICE.items():
            with self.subTest(q):
                self.assertIsNone(refused(text))

    def test_refusals_name_the_graphs_codes(self):
        base = "MATCH (me:Person)<-[:subject]-(r:PersonalRelationship)-[:relative]->(w:Person) WHERE id(me) = $speaker"
        cases = {
            f"{base} AND r.relation = 'mum' RETURN w.name": "syntax",
            f"{base} OR r.relation = 'wife' RETURN w.name": "unsupported_or",
            f"{base} AND NOT r.relation = 'wife' RETURN w.name": "unsupported_not",
            f"{base} RETURN r.relation": "return_not_last",
            f"{base} RETURN w.age": "unknown_property",
            "MATCH (x:Spouse) RETURN x.name": "label_mismatch",
            "MATCH (x)-[:subject]->(y:Person) RETURN y.name": "unlabelled_node",
            "MATCH (me:Person)-[:subject]->(r:PersonalRelationship) RETURN r.relation": "unknown_property",
            "MATCH (me:Person)<-[:person]-(m:GroupMembership) RETURN m.is_member": None,
            "MATCH (r:PersonalRelationship) WHERE r.subject = 'p:rowan' RETURN r.relation": "syntax",
            "MATCH (me:Person) WHERE id(me) = $speaker SET me.name = 'x' RETURN me.name": "mutation_refused",
            "MATCH (me:Person) WHERE id(me) = $speaker RETURN count(me) AS n, me.name": "syntax",
            "MATCH (me:Person)<-[r:subject]-(x:PersonalRelationship) RETURN x.relation": "unsupported_relationship_variable",
            "MATCH (a:Person) MATCH (a:Person) RETURN a.name": "unknown_variable",
        }
        for text, code in cases.items():
            with self.subTest(text):
                self.assertEqual(refused(text), code)

    def test_an_unbound_speaker_is_refused(self):
        self.assertEqual(refused(SLICE["q01"], {"asker": "p:rowan", "now": 1}), "missing_parameter")


class Prompt(unittest.TestCase):
    def test_schema_comes_from_the_catalog(self):
        text = render_schema(SCHEMA)
        self.assertIn("(:PersonalRelationship) relative is subject's relation.", text)
        self.assertIn(".subject -> (:Person)", text)
        self.assertIn("'mum' = 'mother'", text)
        self.assertIn(".requested_guest_limit: integer?", text)
        self.assertNotIn("'wife' = 'wife'", text)
        self.assertIn("pattern: (a:Person)<-[:subject]-(r:PersonalRelationship)-[:relative]->(b:Person) WHERE r.relation = '<value>'", text)

    def test_an_unknown_hop_names_the_hops_there_are(self):
        try:
            check("MATCH (me:Person)-[:wife]->(w:Person) RETURN w.name", SCHEMA, PARAMS)
        except Refusal as r:
            self.assertIn("<-[:subject]-(:PersonalRelationship)", r.message)
        else:
            self.fail("an undeclared hop passed")


class Loop(unittest.TestCase):
    def test_params_bind_the_context(self):
        context = {"principal": "p:rowan", "speaker": "p:alex", "question_at_ms": 9,
                   "valid_at_ms": None, "known_revision": 3}
        self.assertEqual(params_of(context), {"asker": "p:rowan", "now": 9, "speaker": "p:alex", "known_revision": 3})
        self.assertNotIn("speaker", params_of({**context, "speaker": None}))

    def test_a_refused_draft_is_retried_with_its_refusal(self):
        replies = ["```cypher\nMATCH (me:Person) WHERE id(me) = $speaker RETURN me.age\n```", SLICE["q01"]]
        seen = []

        class Fake:
            def reply(self, turns):
                seen.append(turns[-1]["content"])
                return replies[len(seen) - 1]

        context = {"principal": "p:rowan", "speaker": "p:rowan", "question_at_ms": 1}
        out = planned(Fake(), "Who is my wife?", SCHEMA, context)
        self.assertEqual(out["cypher"], SLICE["q01"])
        self.assertIn("unknown_property", seen[1])
        json.dumps(out)

    def test_drafts_lose_fences_and_prose(self):
        self.assertEqual(drafted("Here it is:\n```\nMATCH (a:Person)\nRETURN a.name\n```"), "MATCH (a:Person) RETURN a.name")


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
