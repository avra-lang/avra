"""Score one closed-choice decision set with one backend; one at a time.

usage: python bench_choices.py service|qwen|jevk5 [decisions.jsonl] > scores.jsonl
Prints accuracy and latency per decision kind to stderr. Probabilities are
logged raw, for later calibration; they are not calibrated.
"""
import json
import os
import resource
import subprocess
import sys
import tempfile
import time
from collections import defaultdict

OLLAYA = "/usr/local/bin/ollaya"


def qwen():
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from cascade import Scorer

    s = Scorer()
    return lambda d: s.choose(d["context"], d["question"], d["options"])


def service():
    """The resident cascade service's scorer, so no second model loads."""
    import socket

    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from cascade import SOCKET

    def choose(d):
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.connect(SOCKET)
        with s:
            s.sendall(json.dumps({"op": "choose", "context": d["context"], "question": d["question"], "options": d["options"]}).encode() + b"\n")
            out = b"".join(iter(lambda: s.recv(1 << 16), b""))
        return json.loads(out)["p"]

    return choose


def jevk5():
    def choose(d):
        q = {"q": {"type": "choice", "instructions": f"Read `text`. {d['question']}", "criteria": d["options"]}}
        with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as f:
            json.dump(q, f)
        out = subprocess.run(
            [OLLAYA, "run", "jevk5", "--questions", f.name, "--format", "json", "--keepalive", "30m", "--state-json", json.dumps({"text": d["context"]})],
            capture_output=True, text=True, timeout=120,
        )
        os.unlink(f.name)
        probs = json.loads(out.stdout)["answers"]["q"]["probabilities"]
        return [probs[o] for o in d["options"]]

    return choose


def split(d):
    """A labelled-pair decision as label-or-none, then direction: two small choices."""
    opts = d["options"][:-1]
    x, rest = opts[0].split("'s ", 1)
    words = [o.split("'s ", 1)[1].split(" is ", 1)[0] for o in opts[::2]]
    y = rest.split(" is ", 1)[1]
    label = dict(d, options=[f"the sentence calls one of {x} and {y} the other's {w}" for w in words] + [d["options"][-1]], gold=d["gold"] // 2 if d["gold"] < len(opts) else len(words))
    return label, words, x, y


def decided(choose, d):
    """Answer a decision; a labelled-pair one is asked as two."""
    if d["kind"] != "relation" or len(d["options"]) <= 16:
        p = choose(d)
        return max(range(len(p)), key=lambda i: p[i]), p
    label, words, x, y = split(d)
    p = choose(label)
    k = max(range(len(p)), key=lambda i: p[i])
    if k == len(words):
        return len(d["options"]) - 1, p
    w = words[k]
    q = choose(dict(d, options=[f"{x}'s {w} is {y}", f"{y}'s {w} is {x}"]))
    return 2 * k + (0 if q[0] >= q[1] else 1), p + q


def main():
    backend = sys.argv[1]
    path = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(__file__), "bench", "decisions.jsonl")
    rows = [json.loads(l) for l in open(path)]
    t = time.time()
    choose = {"qwen": qwen, "service": service, "jevk5": jevk5}[backend]()
    choose(rows[0])
    print(f"{backend} load+first_s={time.time() - t:.1f}", file=sys.stderr)
    by = defaultdict(lambda: [0, 0, 0.0])
    for d in rows:
        t = time.time()
        best, p = decided(choose, d)
        dt = time.time() - t
        ok = best == d["gold"]
        for k in (d["kind"], "all"):
            by[k][0] += ok
            by[k][1] += 1
            by[k][2] += dt
        print(json.dumps({"id": d["id"], "backend": backend, "gold": d["gold"], "best": best, "ok": ok, "p": [round(x, 4) for x in p], "s": round(dt, 3)}))
    for k, (ok, n, dt) in sorted(by.items()):
        print(f"{backend} {k}: {ok}/{n} warm_s/decision={dt / n:.2f}", file=sys.stderr)
    print(f"{backend} client_maxrss_mb={resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1e6:.0f}", file=sys.stderr)


if __name__ == "__main__":
    main()
