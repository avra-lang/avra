#!/usr/bin/env python3
"""Question planner: English + context in, one Cypher-subset query out.

stdin:  {contract, request, question, context, source_view, schema}
stdout: {"cypher": "...", "params": {...}}

A local model drafts the query; `subset.check` holds it to the subset
grammar and the catalog, and a refused draft is retried with the refusal
quoted. Context binds as parameters, never as text in the query.

Model, so only one copy is ever resident: the extraction service's shared
`generate` op when its socket answers, else PLANNER_ENDPOINT (an
OpenAI-compatible server), else — only with --local — Qwen3-4B
in-process through mlx_lm from the extraction lane's venv. Timings and retries go to stderr.
"""
import json
import os
import re
import pathlib
import sys
import time

HERE = pathlib.Path(__file__).resolve().parent
VENV_PYTHON = pathlib.Path.home() / ".cache/avra-graph-ml/venv/bin/python"
MODEL = "mlx-community/Qwen3-4B-Instruct-2507-4bit"
SOCKET = pathlib.Path.home() / ".cache/avra-graph-ml/cascade.sock"
TRIES = 3

sys.path.insert(0, str(HERE))
from prompt import messages  # noqa: E402
from subset import Refusal, check  # noqa: E402


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


def drafted(text):
    """The query in a reply: no fence, no prose before MATCH."""
    text = text.strip().strip("`").strip()
    if text.lower().startswith("cypher"):
        text = text[6:]
    at = text.upper().find("MATCH")
    start = text.upper().find("OPTIONAL MATCH")
    if 0 <= start < at:
        at = start
    return " ".join(text[at:].split()) if at >= 0 else text.strip()


class Local:
    """Qwen3-4B in this process, loaded once per run."""

    def __init__(self):
        os.environ.setdefault("HF_HOME", str(pathlib.Path.home() / ".cache/avra-graph-ml/hf"))
        os.environ.setdefault("HF_HUB_OFFLINE", "1")
        from mlx_lm import load

        started = time.time()
        self.model, self.tok = load(MODEL)
        log(f"loaded {MODEL} in {time.time() - started:.1f}s")

    def reply(self, turns):
        from mlx_lm import generate

        prompt = self.tok.apply_chat_template(turns, add_generation_prompt=True, tokenize=False)
        return generate(self.model, self.tok, prompt=prompt, max_tokens=200, verbose=False)


class Shared:
    """The model the extraction service already holds, over its socket."""

    def __init__(self, path):
        self.path = path

    def reply(self, turns):
        import socket

        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.connect(str(self.path))
            s.sendall((json.dumps({"op": "generate", "messages": turns, "max_tokens": 200}) + "\n").encode())
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
        return answer["text"]


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


class Remote:
    """A model already served on PLANNER_ENDPOINT."""

    def __init__(self, endpoint):
        self.endpoint = endpoint.rstrip("/")

    def reply(self, turns):
        import urllib.request

        body = json.dumps({"model": os.environ.get("PLANNER_MODEL", MODEL), "messages": turns,
                           "temperature": 0, "max_tokens": 200}).encode()
        req = urllib.request.Request(f"{self.endpoint}/v1/chat/completions", body,
                                     {"Content-Type": "application/json"})
        with urllib.request.urlopen(req, timeout=120) as r:
            return json.load(r)["choices"][0]["message"]["content"]


def tries():
    """`--tries N` caps the drafts; a single pass measures the prompt alone."""
    args = sys.argv[1:]
    return int(args[args.index("--tries") + 1]) if "--tries" in args else TRIES


FIRST_PERSON = re.compile(r"\b(i|me|my|mine|myself)\b", re.I)


def bound(question, cypher, context):
    """A question in the first person reads from the speaker, through $speaker."""
    if context.get("speaker") and FIRST_PERSON.search(question) and "$speaker" not in cypher:
        raise Refusal("unbound_speaker", "the question speaks as the speaker (my/I/me): start at (me:Person) WHERE id(me) = $speaker")


def planned(llm, question, schema, context, limit=TRIES):
    params = params_of(context)
    turns = messages(question, schema, context)
    last = None
    for attempt in range(1, limit + 1):
        started = time.time()
        cypher = drafted(llm.reply(turns))
        try:
            check(cypher, schema, params)
            bound(question, cypher, context)
            log(f"try {attempt} ok in {time.time() - started:.1f}s: {cypher}")
            return {"cypher": cypher, "params": params}
        except Refusal as refusal:
            last = refusal
            log(f"try {attempt} refused in {time.time() - started:.1f}s ({refusal}): {cypher}")
            turns = turns + [{"role": "assistant", "content": cypher},
                             {"role": "user", "content": f"The graph refuses that query: {refusal}. Write the corrected query only."}]
    raise SystemExit(f"planner: no valid query after {limit} tries; last refusal {last}")


def chosen():
    """One resident model: the extraction service's, a named server, or this process's."""
    path = shared_socket()
    if path:
        return Shared(path)
    if os.environ.get("PLANNER_ENDPOINT"):
        return Remote(os.environ["PLANNER_ENDPOINT"])
    if "--local" not in sys.argv[1:]:
        raise SystemExit(f"planner: no shared model answers on {SOCKET}; start the extraction service, or pass --local to load one here")
    in_model_env()
    return Local()


def main():
    llm = chosen()
    payload = json.load(sys.stdin)
    print(json.dumps(planned(llm, payload["question"], payload["schema"], payload["context"], tries())))


def in_model_env():
    """Re-run under the extraction venv when this python lacks mlx_lm."""
    try:
        import mlx_lm  # noqa: F401
    except ImportError:
        if VENV_PYTHON.exists() and pathlib.Path(sys.executable).resolve() != VENV_PYTHON.resolve():
            os.execv(str(VENV_PYTHON), [str(VENV_PYTHON), *sys.argv])
        raise SystemExit(f"planner: mlx_lm is missing and {VENV_PYTHON} does not exist")


if __name__ == "__main__":
    main()
