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

usage: defects.py [--avra PATH] [--only NAME] [--keep] [--list]
"""
import argparse
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CORPUS = os.path.join(ROOT, "tools", "defects", "corpus.txt")
BAD = re.compile(
    r"language\.defect|survived typing|^avra: |out of bounds|Segmentation|internal error|panicked",
    re.M,
)
TIMEOUT = 60
# check examines and lowers; run evaluates what check let through
VERBS = ["check", "run"]
MANIFEST = '[package]\nname = "probe"\nversion = "0.1.0"\n\n[bin]\npath = "src/main.av"\n'


def cases(text):
    """(name, mutate, body) for each `### name` case, in file order."""
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
    mutate = bool(body) and body[0] == "@mutate"
    if mutate:
        body = body[1:]
    while body and body[-1] == "":
        body = body[:-1]
    return name, mutate, "\n".join(body) + ("\n" if body else "")


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


def run(avra, verb, package):
    try:
        p = subprocess.run(
            [avra, verb, package],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=TIMEOUT,
        )
    except subprocess.TimeoutExpired:
        return 124, "timed out after %ds" % TIMEOUT
    return p.returncode, p.stdout.decode("utf-8", "replace")


def verdict(code, out):
    """The reason a run is refused, or None."""
    if code > 1:
        return "exit %d" % code
    hit = BAD.search(out)
    return "voice %r" % hit.group(0).strip() if hit else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--avra", default=os.path.join(ROOT, "avra"))
    ap.add_argument("--only")
    ap.add_argument("--keep", action="store_true")
    ap.add_argument("--list", action="store_true")
    a = ap.parse_args()
    all_cases = cases(open(CORPUS, encoding="utf-8").read())
    work = []
    for name, mutate, body in all_cases:
        work.append((name, body))
        if mutate:
            work.extend(mutants(name, body))
    if a.only:
        work = [w for w in work if w[0].startswith(a.only)]
    if a.list:
        for n, _ in work:
            print(n)
        return 0
    if not work:
        print("defects: examined nothing")
        return 1
    bad = []
    with tempfile.TemporaryDirectory(prefix="avra-defects-") as d:
        os.makedirs(os.path.join(d, "src"))
        with open(os.path.join(d, "avra.toml"), "w", encoding="utf-8") as f:
            f.write(MANIFEST)
        for n, body in work:
            with open(os.path.join(d, "src", "main.av"), "w", encoding="utf-8") as f:
                f.write(body)
            for verb in VERBS:
                code, out = run(a.avra, verb, d)
                why = verdict(code, out)
                if why:
                    bad.append((n, why))
                    print("defects: %s (%s) — %s" % (n, verb, why))
                    print("    " + "\n    ".join(out.strip().split("\n")[:6]))
    print("defects: %d program(s) examined, %d answered with a defect voice or a trap" % (len(work), len({n for n, _ in bad})))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
