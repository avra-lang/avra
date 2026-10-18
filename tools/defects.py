#!/usr/bin/env python3
"""THE DEFECT-VOICE KEEPER. Runs `avra check` over every malformed and
edge program in tools/defects/corpus.txt, and over deterministic
mutations of its `@mutate` bases, and FAILS when any run answers with
the compiler blaming itself (`language.defect`, "survived typing") or
with a trap (`avra: ...`, exit past 1). A user's mistake is always a
refusal; a defect voice or a trap on a user's program is the compiler's.

Each case is the entry of a one-file package in a scratch directory
(a lone file reads no std and no prelude, and a file inside this tree
is silent), so a refusal actually prints.

usage: defects.py [--avra PATH] [--only NAME] [--list] [--show]
"""
import argparse
import os
import re
import subprocess
import threading
import time
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CORPUS = os.path.join(ROOT, "tools", "defects", "corpus.txt")
BAD = re.compile(
    r"language\.defect|survived typing|^avra: |out of bounds|Segmentation|internal error|panicked",
    re.M,
)
TIMEOUT = 60
# @mutate adds the case's mutations; @check runs only `check` — a program
# whose own run traps by the language's law (an index past the end)
FLAGS = {"@mutate", "@check"}
# check examines and lowers; run evaluates what check let through; build
# emits and links what it accepted
MANIFEST = '[package]\nname = "probe"\nversion = "0.1.0"\n\n[bin]\npath = "src/main.av"\n'


def cases(text):
    """(name, flags, body) for each `### name` case, in file order. The
    flags are the `@` words on the lines after the name."""
    out = []
    name, body = None, []
    for line in text.split("\n"):
        if line.startswith("### "):
            if name is not None:
                out.append(finish(name, body))
            name, body = line[4:].strip(), []
        elif name is not None:
            body.append(line)
        elif not line.startswith("#") and line.strip():
            sys.exit("defects: text before the first case: %r" % line)
    if name is not None:
        out.append(finish(name, body))
    return out


def finish(name, body):
    flags = set()
    while body and body[0] in FLAGS:
        flags.add(body[0])
        body = body[1:]
    while body and body[-1] == "":
        body = body[:-1]
    return name, flags, "\n".join(body) + ("\n" if body else "")


def mutants(name, text):
    """Deterministic mutations: each line prefix, each line deleted,
    each closing bracket dropped, each adjacent word pair swapped."""
    lines = text.split("\n")
    seen = {text}
    out = []

    def add(tag, body):
        if body not in seen:
            seen.add(body)
            out.append(("%s~%s" % (name, tag), body))

    for i in range(1, len(lines)):
        add("head%d" % i, "\n".join(lines[:i]) + "\n")
    for i in range(len(lines)):
        add("drop%d" % i, "\n".join(lines[:i] + lines[i + 1 :]))
    for k, m in enumerate(re.finditer(r"[)}\]]", text)):
        add("close%d" % k, text[: m.start()] + text[m.end() :])
    for i, line in enumerate(lines):
        words = line.split(" ")
        for j in range(len(words) - 1):
            if words[j] and words[j + 1]:
                w = words[:]
                w[j], w[j + 1] = w[j + 1], w[j]
                add("swap%d_%d" % (i, j), "\n".join(lines[:i] + [" ".join(w)] + lines[i + 1 :]))
    return out


# One watchdog holds the whole keeper, so each compile skips the shim's
# per-run lock (`AVRA_WATCH_HELD`) and the cases run side by side.
WORKERS = int(os.environ.get("AVRA_DEFECT_WORKERS", "4"))
ENV = dict(os.environ, AVRA_WATCH_HELD="1")


def run(avra, verb, package):
    try:
        p = subprocess.run(
            [avra, verb, package],
            env=ENV,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=TIMEOUT,
        )
    except subprocess.TimeoutExpired:
        return 124, "timed out after %ds" % TIMEOUT
    return p.returncode, p.stdout.decode("utf-8", "replace")


# The compile limiter's own queue notice is no voice of the compiler.
WAITING = re.compile(r"^avra: waiting for a compile slot.*$", re.M)


def verdict(code, out):
    """The reason a run is refused, or None."""
    if code > 1:
        return "exit %d" % code
    hit = BAD.search(WAITING.sub("", out))
    return "voice %r" % hit.group(0).strip() if hit else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--avra", default=os.path.join(ROOT, "avra"))
    ap.add_argument("--only")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--show", action="store_true", help="print every run's output")
    a = ap.parse_args()
    all_cases = cases(open(CORPUS, encoding="utf-8").read())
    work = []
    for name, flags, body in all_cases:
        verbs = ["check"] if "@check" in flags else ["check", "run"]
        work.append((name, verbs, body))
        if "@mutate" in flags:
            work.extend((n, verbs, b) for n, b in mutants(name, body))
    if a.only:
        work = [w for w in work if w[0].startswith(a.only)]
    if a.list:
        for n, _, _ in work:
            print(n)
        return 0
    if not work:
        print("defects: examined nothing")
        return 1
    bad = []
    started = time.time()
    jobs = max(1, min(WORKERS, len(work)))
    out_lock = threading.Lock()
    queue = list(reversed(work))

    def attack(d):
        os.makedirs(os.path.join(d, "src"))
        with open(os.path.join(d, "avra.toml"), "w", encoding="utf-8") as f:
            f.write(MANIFEST)
        while True:
            with out_lock:
                if not queue:
                    return
                n, verbs, body = queue.pop()
            with open(os.path.join(d, "src", "main.av"), "w", encoding="utf-8") as f:
                f.write(body)
            clean = False
            for verb in verbs + ["build"]:
                if verb == "build" and not clean:
                    continue
                code, out = run(a.avra, verb, d)
                clean = clean or (verb == "check" and code == 0)
                why = verdict(code, out)
                with out_lock:
                    if a.show:
                        print("== %s (%s) exit %d\n%s" % (n, verb, code, out.strip()))
                    if why:
                        bad.append((n, why))
                        print("defects: %s (%s) — %s" % (n, verb, why))
                        print("    " + "\n    ".join(out.strip().split("\n")[:6]))

    with tempfile.TemporaryDirectory(prefix="avra-defects-") as root:
        dirs = [os.path.join(root, str(i)) for i in range(jobs)]
        threads = [threading.Thread(target=attack, args=(d,)) for d in dirs]
        for t in threads:
            t.start()
        for t in threads:
            t.join()
    print("defects: %d worker(s), %.0fs" % (jobs, time.time() - started))
    print("defects: %d program(s) examined, %d answered with a defect voice or a trap" % (len(work), len({n for n, _ in bad})))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
