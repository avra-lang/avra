"""Where an extraction's time goes: encoder queries, each LLM-asking cascade method, and the load.

usage: python where_time.py SCHEMA_JSON SOURCES_JSONL [ids,comma,separated] [--local]

Runs the cascade over the named sources (default: all). With a resident model service on
AVRA_GRAPH_SOCKET the generative model is never loaded here: every closed choice goes to it
with the source text in the prompt and is charged the service's own compute time (the
extraction's per-source prefix cache is not used, so a choice pays the source's prefill).
--dump FILE keeps the extractions (replay.py serves them to the grader). --encoder-only stops after the encoder phase (no model service needed). --local loads the scorer in this process instead (the cascade as served, prefix cache on).
Prints one table: seconds, calls and prompt tokens per method, and per encoder query.
"""
import collections
import json
import os
import socket
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import cascade  # noqa: E402
from request import envelope, request  # noqa: E402


class RemoteScorer(cascade.Scorer):
    """The cascade's scorer, answered by the resident service."""

    def __init__(self, path):
        self.path, self.source, self.cache, self.prefix = path, "", None, False
        self.calls, self.spent, self.waited = 0, {}, 0.0

    def begin(self, source):
        self.source, self.spent = source, {}

    def choose(self, context, question, options, options_first=False):
        started = time.time()
        body = {"op": "choose", "context": (f'Text: "{self.source}"\n\n' if self.source else "") + context, "question": question, "options": options, "options_first": options_first}
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.connect(self.path)
            s.sendall((json.dumps(body) + "\n").encode())
            data = b""
            while not data.endswith(b"\n"):
                chunk = s.recv(65536)
                if not chunk:
                    break
                data += chunk
        answer = json.loads(data)
        self.calls += 1
        queue = answer.get("queue", {})
        self.waited += queue.get("wait_s", 0.0)
        self.spend(time.time() - queue.get("compute_s", 0.0), len(cascade.choice_prompt(context, question, options)) // 4)
        return answer["p"]


class RemoteModels(cascade.Models):
    def __init__(self, path):
        super().__init__()
        self.path = path

    @property
    def llm(self):
        if self._llm is None:
            self._llm = RemoteScorer(self.path)
        return self._llm


def main():
    flagged = {sys.argv[i + 1] for i, a in enumerate(sys.argv) if a == "--dump"}
    args = [a for a in sys.argv[1:] if not a.startswith("--") and a not in flagged]
    schema = json.load(open(args[0]))
    ids = set(args[2].split(",")) if len(args) > 2 else None
    rows = [r for r in map(json.loads, open(args[1])) if not ids or r["id"] in ids]
    reqs = [request(envelope(r), schema, cascade.MODEL_ID) for r in rows]
    models = cascade.Models() if "--local" in sys.argv else RemoteModels(os.environ["AVRA_GRAPH_SOCKET"])
    started = time.time()
    cascade.LOG.clear()
    spans = cascade.encoded(reqs, models)
    encoded_s = time.time() - started
    head = list(cascade.LOG)
    by_method = collections.defaultdict(lambda: [0, 0.0, 0])
    by_query = collections.defaultdict(lambda: [0, 0.0])
    per_source, loads, dumped = [], [], []
    for line in head:
        parts = line.split()
        if parts[:1] == ["encoder"] and len(parts) == 3:
            q = by_query[parts[1].split(":")[0]]
            q[0] += 1
            q[1] += float(parts[2].split("=")[1])
    for row, req, sp in zip(rows, reqs, spans) if "--encoder-only" not in sys.argv else ():
        t = time.time()
        result, logs = cascade.extract(req, models, sp)
        wall = time.time() - t
        dumped.append({"kind": "source", "source": row["id"], "log": logs, "result": result})
        calls = 0
        for line in logs:
            parts = line.split()
            if parts[:1] == ["profile"]:
                kv = dict(x.split("=") for x in parts[2:])
                row_ = by_method[parts[1]]
                row_[0] += int(kv["calls"])
                row_[1] += float(kv["s"])
                row_[2] += int(kv["tokens"])
                calls += int(kv["calls"])
        per_source.append((row["id"], len(row["content"]), calls, round(wall, 1), len(result.get("records", []))))
    if "--dump" in sys.argv:
        json.dump({"extractions": dumped}, open(sys.argv[sys.argv.index("--dump") + 1], "w"))
    total_calls = sum(v[0] for v in by_method.values())
    llm_s = sum(v[1] for v in by_method.values())
    print(f"sources={len(rows)} chars={sum(s[1] for s in per_source)} encoder_phase_s={encoded_s:.1f} llm_s={llm_s:.1f} llm_calls={total_calls} queue_wait_s={getattr(models._llm, 'waited', 0.0):.1f}")
    print("\nllm by cascade method (seconds, calls, prompt tokens):")
    for k, (n, s, tok) in sorted(by_method.items(), key=lambda kv: -kv[1][1]):
        print(f"  {k:20s} {s:7.1f}s {n:5d} calls {tok:8d} tok  {s / max(n, 1) * 1000:6.0f} ms/call")
    print("\nencoder by query kind (seconds, calls):")
    for k, (n, s) in sorted(by_query.items(), key=lambda kv: -kv[1][1]):
        print(f"  {k:20s} {s:7.1f}s {n:5d} calls")
    print("\nper source (id, chars, llm calls, wall s, records):")
    for row in per_source:
        print("  ", *row)


if __name__ == "__main__":
    main()
