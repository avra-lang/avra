"""The one resident model, reached over a socket some service already holds.
The gym never starts a model: with no service answering it stops."""
import json
import os
import pathlib
import socket

CACHE = pathlib.Path.home() / ".cache/avra-graph-ml"


def answering(path):
    if not path.exists():
        return False
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.settimeout(2)
            s.connect(str(path))
        return True
    except OSError:
        return False


def socket_path():
    """GYM_SOCKET, else the first service socket that answers."""
    if os.environ.get("GYM_SOCKET"):
        return pathlib.Path(os.environ["GYM_SOCKET"])
    for name in ("beam.sock", "cascade.sock"):
        if answering(CACHE / name):
            return CACHE / name
    raise SystemExit("gym: no model service answers on a socket; the gym starts none")


class Llm:
    def __init__(self, path=None, timeout=300):
        self.path, self.timeout, self.calls = pathlib.Path(path) if path else socket_path(), timeout, 0

    def asked(self, body):
        self.calls += 1
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.settimeout(self.timeout)
            s.connect(str(self.path))
            s.sendall((json.dumps(body) + "\n").encode())
            data = b""
            while not data.endswith(b"\n"):
                chunk = s.recv(65536)
                if not chunk:
                    break
                data += chunk
        if not data.strip():
            raise SystemExit("gym: the model service went away mid-request")
        answer = json.loads(data)
        if "error" in answer:
            raise SystemExit(f"gym: the model service refused: {answer['error']}")
        return answer

    def generate(self, prompt, max_tokens=400, system=None, stop=()):
        messages = ([{"role": "system", "content": system}] if system else []) + [{"role": "user", "content": prompt}]
        return self.asked({"op": "generate", "messages": messages, "max_tokens": max_tokens, "stop": list(stop)})["text"]

    def choose(self, context, question, options):
        """The probability the model gives each lettered option."""
        return self.asked({"op": "choose", "context": context, "question": question, "options": options})["p"]


class Hosted:
    """Sonnet through the `claude -p` CLI, for development-time generation of invented content only.
    Every call records the model id and a hash of its prompt in `last`."""

    def __init__(self, model="sonnet", workers=4):
        import tempfile
        self.model, self.workers, self.calls = model, workers, 0
        self.cwd = tempfile.mkdtemp(prefix="gym-hosted-")
        self.local, self.used = __import__("threading").local(), set()

    def generate(self, prompt, max_tokens=400, system=None, stop=()):
        import hashlib
        import subprocess
        self.calls += 1
        body = (system + "\n\n" if system else "") + prompt
        done = subprocess.run(["claude", "-p", "--model", self.model, "--output-format", "json"], input=body, text=True,
                              capture_output=True, cwd=self.cwd, timeout=240)
        try:
            got = json.loads(done.stdout)
        except json.JSONDecodeError:
            raise SystemExit(f"gym: hosted model failed: {(done.stderr or done.stdout)[:300]}")
        model = next(iter(got.get("modelUsage", {})), self.model)
        self.local.last = {"model": model, "prompt_sha": hashlib.sha256(body.encode()).hexdigest()[:16]}
        self.used.add(model)
        return got["result"]

    @property
    def last(self):
        return self.local.last

    def choose(self, context, question, options):
        """One-hot probabilities: the hosted model names a letter."""
        import string
        letters = string.ascii_uppercase[: len(options)]
        listing = "\n".join(f"{l}. {o}" for l, o in zip(letters, options))
        reply = self.generate(f"{context}\n\n{question}\n{listing}\nAnswer with the single letter of the best option.").strip().upper()
        import re
        found = re.search(rf"(?<![A-Za-z])([{letters}])(?![A-Za-z])", reply)
        if not found:
            raise SystemExit(f"gym: the judge named no option: {reply[:80]!r}")
        pick = letters.index(found.group(1))
        return [1.0 if i == pick else 0.0 for i in range(len(options))]
