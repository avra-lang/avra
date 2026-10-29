"""What a model's reply to a query request is read as, and how it is asked for.

One definition, because a bench that reads replies differently from the trainer's own format
measures the reader rather than the model: a reply may open with a reasoning block, may be
fenced, and may carry the statement on any line.
"""
import json
import os
import re
import socket

SOCKET = os.environ.get("AVRA_GRAPH_SOCKET") or os.path.expanduser("~/.cache/avra-graph-ml/cascade.sock")


def ask(prompt, messages=(), max_tokens=260, sock=None):
    """The model's reply to one prompt, through the service."""
    body = {"op": "generate", "messages": [{"role": "user", "content": prompt}, *messages],
            "max_tokens": max_tokens}
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.settimeout(600)
    s.connect(sock or SOCKET)
    s.sendall((json.dumps(body) + "\n").encode())
    d = b""
    while not d.endswith(b"\n"):
        c = s.recv(65536)
        if not c:
            break
        d += c
    return json.loads(d).get("text", "")


def clean(reply):
    """The query a reply carries: a reasoning block dropped, fences stripped, and the
    statement taken from where it starts — the model may think before it answers."""
    t = reply.strip()
    t = re.sub(r"(?s)^\s*<think.*?<\s*/\s*think>\s*", "", t)
    t = re.sub(r"(?s)^\s*<\s*/\s*think>\s*", "", t)
    t = re.sub(r"(?s)^\s*<think\s*", "", t)
    for fence in ("```cypher", "```Cypher", "```"):
        if t.startswith(fence):
            t = t[len(fence):]
    if "```" in t:
        t = t.split("```")[0]
    lines = [l for l in t.splitlines() if l.strip()]
    start = next((i for i, l in enumerate(lines) if l.lstrip().upper().startswith(("MATCH", "OPTIONAL"))), 0)
    return " ".join(" ".join(lines[start:]).split())


def desugar(text):
    """`WITH <plain vars>` drops out: the subset carries every binding forward, so a WITH that
    only names variables means what the next clause already sees."""
    return re.sub(r"\bWITH\s+[A-Za-z_]\w*(\s*,\s*[A-Za-z_]\w*)*\s+", "", text)
