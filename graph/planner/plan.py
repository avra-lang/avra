#!/usr/bin/env python3
"""Question planner: English + context in, one Cypher-subset query out.

stdin:  {contract, request, question, context, source_view, schema, graph}
stdout: {"cypher": "...", "params": {...}}

The query is composed from closed choices the shared model makes (structured.py)
and held to the subset grammar and the catalog by the graph's own `check` op.
Context binds as parameters, never as text in the query. The model is the
extraction service's shared one, reached over its socket; its calls and every
refusal, with the refusal's reason, go to stderr.
"""
import json
import os
import pathlib
import sys
import tempfile
import time

HERE = pathlib.Path(__file__).resolve().parent
MODEL = "mlx-community/Qwen3-4B-Instruct-2507-4bit"
SOCKET = pathlib.Path(os.environ.get("PLANNER_SOCKET") or pathlib.Path.home() / ".cache/avra-graph-ml/cascade.sock")
HUB = pathlib.Path.home() / ".cache/avra-graph-ml/hf/hub"

sys.path.insert(0, str(HERE))
from prompt import Budget, declared_context  # noqa: E402
from catalog import Abstain, PARAMETERS, Refusal  # noqa: E402


def log(text):
    print(f"planner: {text}", file=sys.stderr, flush=True)


def params_of(context):
    """The context as query parameters; an unset binding is left out."""
    out = {"asker": context["principal"], "now": context["question_at_ms"]}
    for key, value in (("speaker", context.get("speaker")), ("valid_at", context.get("valid_at_ms")),
                       ("known_revision", context.get("known_revision"))):
        if value is not None:
            out[key] = value
    return out


def scored(answer):
    """One ranked answer's score: its summed log-probability, or that per token, as the rank_rule parameter declares."""
    return answer["logp"] / answer["tokens"] if PARAMETERS["rank_rule"] == "mean" else answer["logp"]


class Shared:
    """The model the extraction service already holds, over its socket."""

    def __init__(self, path):
        self.path = path

    def choose(self, context, question, options):
        return self.asked({"op": "choose", "context": context, "question": question, "options": options})["p"]

    def rank(self, context, question, shown, keys):
        """Each option's score as the service's rank op reports it, under the declared rule."""
        answer = self.asked({"op": "rank", "context": context, "question": question, "options": shown, "keys": keys})["scores"]
        return [scored(a) for a in answer]

    def embed(self, texts, query=False):
        """Unit vectors of the texts in the embedding model's space; `query` marks the asking side."""
        return self.asked({"op": "embed", "texts": texts, "query": query})["vectors"]

    def asked(self, body):
        started = time.time()
        try:
            return self.exchanged(body)
        finally:
            log(f"call op={body['op']} ms={int((time.time() - started) * 1000)}")

    def exchanged(self, body):
        import socket

        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.settimeout(float(os.environ["PLANNER_CALL_TIMEOUT_S"]) if "PLANNER_CALL_TIMEOUT_S" in os.environ else None)
            s.connect(str(self.path))
            s.sendall((json.dumps(body) + "\n").encode())
            data = b""
            while not data.endswith(b"\n"):
                chunk = s.recv(65536)
                if not chunk:
                    break
                data += chunk
        if not data.strip():
            raise SystemExit("planner: the shared model service went away mid-request; retry when it is back")
        answer = json.loads(data)
        if "error" in answer:
            raise SystemExit(f"planner: shared model refused: {answer['error']}")
        return answer


def shared_socket(path=SOCKET):
    """The extraction service's socket when something answers on it."""
    import socket

    if not path.exists():
        return None
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.connect(str(path))
    except OSError:
        return None
    return path


class Graph:
    """Read-only requests to the graph the question runs against: an argv
    prefix (`<binary> request --db <path>`) that takes one request file."""

    def __init__(self, argv):
        self.argv = argv

    def call(self, body):
        import subprocess

        with tempfile.TemporaryDirectory() as scratch:
            request = pathlib.Path(scratch) / "request.json"
            request.write_text(json.dumps(body))
            done = subprocess.run([*self.argv, str(request)], text=True, capture_output=True, timeout=60)
        try:
            return json.loads(done.stdout)
        except json.JSONDecodeError:
            raise SystemExit(f"planner: the graph did not answer {body['op']}: {(done.stderr or done.stdout)[:300]}")

    def read(self, entity):
        """The entity as the graph holds it: its model and its fields."""
        return self.call({"op": "get", "id": entity})

    def prober(self, params):
        """Read-only queries under the question's parameters, each asked once."""
        return remembered(lambda cypher: self.call({"op": "query", "cypher": cypher, "params": params}))

    def search(self, query):
        """Every passage the search op will return for the query, up to its declared maximum."""
        return self.call({"op": "search", "query": query, "limit": PARAMETERS["search_limit"]}).get("passages", [])


def graph_of(payload):
    """The question's graph from the payload, else PLANNER_CHECK's CLI on a scratch db."""
    if payload.get("graph"):
        return Graph(payload["graph"])
    binary = os.environ.get("PLANNER_CHECK")
    if binary:
        return Graph([binary, "request", "--db", str(pathlib.Path(tempfile.mkdtemp(prefix="planner-")) / "check.db")])
    return None


def gated(cypher, schema, params, graph=None):
    """The graph's own check; without a graph at hand a draft goes unchecked
    to whoever runs it, and the graph refuses it there."""
    if graph is None:
        log("no graph at hand: the draft is not checked here")
        return
    answer = graph.call({"op": "check", "cypher": cypher, "params": params})
    if answer.get("ok") is True:
        return
    if "code" not in answer:
        raise SystemExit(f"planner: the graph's check op did not answer: {str(answer)[:300]}")
    raise Refusal(answer["code"], answer.get("message", ""))


class ChooseOnly:
    """The shared model with its lettered choice alone, when ranked answers are not declared in use."""

    def __init__(self, shared):
        self.choose, self.asked, self.budget = shared.choose, shared.asked, None


def chosen():
    """The extraction service's resident model."""
    path = shared_socket()
    if not path:
        raise SystemExit(f"planner: no shared model answers on {SOCKET}; start the extraction service")
    return Shared(path) if PARAMETERS["rank_use"] else ChooseOnly(Shared(path))


def instant(ms):
    import datetime

    return datetime.datetime.fromtimestamp(ms / 1000, datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def viewed(chooser, question, context):
    """The read's valid-time view: the context's own instant when it binds one,
    else the calendar span the model chooses (the asking instant when none)."""
    if context.get("valid_at_ms") is not None:
        return {"valid_at": instant(context["valid_at_ms"])}
    import when

    span = when.asked_time(chooser, question, context["question_at_ms"])
    return {"valid_at": instant(span["start_ms"] if span else context["question_at_ms"])}


def remembered(call):
    """A read-only call answered once per argument within one question."""
    seen = {}
    return lambda arg: seen[arg] if arg in seen else seen.setdefault(arg, call(arg))


def composed(chooser, question, schema, context, graph=None, depth=None):
    """The closed choices composed into one query, the search's candidates
    admitted by the graph's check op in score order, with the time it is read at."""
    import beam
    import contrast
    import structured

    started = time.time()
    params = params_of(context)
    seek = remembered(graph.search) if graph else None
    read = remembered(graph.read) if graph else None
    probe = graph.prober(params) if graph else None
    found = beam.candidates(chooser, lambda walker: structured.plan(walker, question, schema, context, seek, depth, read, probe), probe)
    if not found:
        raise Abstain("every walk the beam tried binds nothing in the graph")
    if PARAMETERS["contrast"] and probe:
        verdict = contrast.settle(chooser, f"Question: {question}", found, probe, PARAMETERS["preview_rows"])
        if verdict.plan is None:
            raise Abstain("no reading of the question is supported by its answer")
        found = [verdict.plan]
    refusal = None
    for path in found:
        try:
            gated(path.cypher, schema, params, graph)
        except Refusal as refused:
            refusal = refused
            log(f"refused ({refused}): {path.cypher}")
            continue
        log(f"composed in {time.time() - started:.1f}s from {len(found)} finished plan(s), score {path.score():.2f}: {path.cypher}")
        return {"cypher": path.cypher, "params": params, "as_of": viewed(chooser, question, context)}
    raise refusal


def fitted_from_argv():
    """`--set name=value` overrides a declared parameter for one run, so a fit never edits the declarations."""
    args = sys.argv[1:]
    for i, a in enumerate(args):
        if a == "--set":
            name, _, value = args[i + 1].partition("=")
            PARAMETERS[name] = json.loads(value)


def main():
    fitted_from_argv()
    llm = chosen()
    llm.budget = Budget(declared_context(MODEL, HUB), PARAMETERS["answer_tokens"])
    payload = json.load(sys.stdin)
    try:
        out = composed(llm, payload["question"], payload["schema"], payload["context"], graph_of(payload),
                       (payload.get("budget") or {}).get("depth"))
    except Refusal as refusal:
        raise SystemExit(f"planner: the graph refuses the composed query ({refusal})")
    except Abstain as why:
        out = {"abstain": str(why)}
    print(json.dumps(out))


if __name__ == "__main__":
    main()
