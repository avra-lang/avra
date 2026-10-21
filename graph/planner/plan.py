#!/usr/bin/env python3
"""Question planner: English + context in, one Cypher-subset query out.

stdin:  {contract, request, question, context, source_view, schema}
stdout: {"cypher": "...", "params": {...}}

A local model drafts the query; `subset.check` holds it to the subset
grammar and the catalog, and a refused draft is retried with the refusal
quoted. Context binds as parameters, never as text in the query.

Model: PLANNER_ENDPOINT (an OpenAI-compatible server already running) is
used when set; otherwise Qwen3-4B loads in-process through mlx_lm from the
extraction lane's venv. Timings and retries go to stderr.
"""
import json
import os
import pathlib
import sys
import time

HERE = pathlib.Path(__file__).resolve().parent
VENV_PYTHON = pathlib.Path.home() / ".cache/avra-graph-ml/venv/bin/python"
MODEL = "mlx-community/Qwen3-4B-Instruct-2507-4bit"
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
        return generate(self.model, self.tok, prompt=prompt, max_tokens=320, verbose=False)


class Remote:
    """A model already served on PLANNER_ENDPOINT."""

    def __init__(self, endpoint):
        self.endpoint = endpoint.rstrip("/")

    def reply(self, turns):
        import urllib.request

        body = json.dumps({"model": os.environ.get("PLANNER_MODEL", MODEL), "messages": turns,
                           "temperature": 0, "max_tokens": 320}).encode()
        req = urllib.request.Request(f"{self.endpoint}/v1/chat/completions", body,
                                     {"Content-Type": "application/json"})
        with urllib.request.urlopen(req, timeout=120) as r:
            return json.load(r)["choices"][0]["message"]["content"]


def planned(llm, question, schema, context):
    params = params_of(context)
    turns = messages(question, schema, context)
    last = None
    for attempt in range(1, TRIES + 1):
        started = time.time()
        cypher = drafted(llm.reply(turns))
        try:
            check(cypher, schema, params)
            log(f"try {attempt} ok in {time.time() - started:.1f}s: {cypher}")
            return {"cypher": cypher, "params": params}
        except Refusal as refusal:
            last = refusal
            log(f"try {attempt} refused in {time.time() - started:.1f}s ({refusal}): {cypher}")
            turns = turns + [{"role": "assistant", "content": cypher},
                             {"role": "user", "content": f"The graph refuses that query: {refusal}. Write the corrected query only."}]
    raise SystemExit(f"planner: no valid query after {TRIES} tries; last refusal {last}")


def main():
    payload = json.load(sys.stdin)
    endpoint = os.environ.get("PLANNER_ENDPOINT")
    llm = Remote(endpoint) if endpoint else Local()
    print(json.dumps(planned(llm, payload["question"], payload["schema"], payload["context"])))


def in_model_env():
    """Re-run under the extraction venv when this python lacks mlx_lm."""
    if os.environ.get("PLANNER_ENDPOINT"):
        return
    try:
        import mlx_lm  # noqa: F401
    except ImportError:
        if VENV_PYTHON.exists() and pathlib.Path(sys.executable).resolve() != VENV_PYTHON.resolve():
            os.execv(str(VENV_PYTHON), [str(VENV_PYTHON), *sys.argv])
        raise SystemExit(f"planner: mlx_lm is missing and {VENV_PYTHON} does not exist")


if __name__ == "__main__":
    in_model_env()
    main()
