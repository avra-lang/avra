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

`--generate N` adds N mutants of the tree's own program tests (token
deleted, swapped, duplicated, or the program cut at a statement
boundary), chosen by `--seed`: the same seed is the same set. A mutant is
a user's malformed program like any other, but its `run` is judged by
voices alone — a mutant's own runtime trap or loop is the program's — and
happens only where every std package it imports is a pure one.

usage: defects.py [--avra PATH] [--only NAME] [--list] [--show]
                  [--generate N] [--seed S]
"""
import argparse
import glob
import os
import random
import re
import signal
import subprocess
import sys
import tempfile
import threading
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CORPUS = os.path.join(ROOT, "tools", "defects", "corpus.txt")
BAD = re.compile(
    r"language\.defect|survived typing|out of bounds|Segmentation|internal error|panicked",
    re.M,
)
TIMEOUT = 60
# a mutant is linked one in this many: a link costs seconds, and check has lowered it already
BUILD_EVERY = 4
# @mutate adds the case's mutations; @check runs only `check` — a program
# whose own run traps by the language's law (an index past the end);
# @manifest makes the case's text the package's avra.toml, beside a one-line program
FLAGS = {"@mutate", "@check", "@manifest"}
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


TOKENS = re.compile(r'"(?:[^"\\\n]|\\.)*"|\w+|[^\w\s]')
VOICES = re.compile(r"language\.defect|survived typing")


PURE = {"text", "json", "errors", "meta", "path", "prelude", "testing", "numbers"}
IMPORT = re.compile(r"^\s*use\s+@std\.(\w+)", re.M)


def runnable(text):
    """Whether evaluating a program touches nothing outside itself: every
    std package it imports is a pure one."""
    return all(m in PURE for m in IMPORT.findall(text))


def program_tests():
    """The tree's single-file program tests, in path order — but not the
    ones that import the compiler itself, a dependency a check of takes
    minutes to read."""
    found = glob.glob(os.path.join(ROOT, "packages", "**", "tests", "*", "*.av"), recursive=True)
    return sorted(
        f
        for f in found
        if os.path.basename(os.path.dirname(f)) == os.path.basename(f)[:-3]
        and "@std.avrac" not in open(f, encoding="utf-8").read()
    )


def token_mutants(text, rng, tag):
    """One mutant of `text`: an operator and a position drawn from rng."""
    toks = list(TOKENS.finditer(text))
    if not toks:
        return None
    op = rng.choice(["delete", "swap", "dup", "cut", "name", "lit"])
    i = rng.randrange(len(toks))
    if op == "cut":
        stops = [m.end() for m in re.finditer(r"\n(?=\S)", text)]
        if not stops:
            return None
        return "%s~cut%d" % (tag, len(stops)), text[: rng.choice(stops)] + "\n"
    t = toks[i]
    if op == "name":
        words = sorted({m.group(0) for m in toks if re.fullmatch(r"[A-Za-z_]\w*", m.group(0))})
        if not re.fullmatch(r"[A-Za-z_]\w*", t.group(0)):
            return None
        w = rng.choice(words)
        return "%s~name%d" % (tag, i), text[: t.start()] + w + text[t.end() :]
    if op == "lit":
        if not (t.group(0).isdigit() or t.group(0).startswith('"')):
            return None
        w = rng.choice(["null", "true", "[]", "{}", '"x"', "0", "-1", "99999999999"])
        return "%s~lit%d" % (tag, i), text[: t.start()] + w + text[t.end() :]
    if op == "delete":
        return "%s~del%d" % (tag, i), text[: t.start()] + text[t.end() :]
    if op == "dup":
        return "%s~dup%d" % (tag, i), text[: t.end()] + " " + t.group(0) + text[t.end() :]
    if i + 1 >= len(toks):
        return None
    u = toks[i + 1]
    swapped = text[: t.start()] + u.group(0) + text[t.end() : u.start()] + t.group(0) + text[u.end() :]
    return "%s~swap%d" % (tag, i), swapped


def generated(n, seed):
    """n mutants of the program tests, deterministic in seed."""
    rng = random.Random(seed)
    files = program_tests()
    texts = {}
    out = []
    while files and len(out) < n:
        f = rng.choice(files)
        if f not in texts:
            texts[f] = open(f, encoding="utf-8").read()
        made = token_mutants(texts[f], rng, "gen:" + os.path.relpath(f, ROOT))
        if made and made[1] != texts[f]:
            out.append(("%s#%d" % (made[0], len(out)), made[1]))
    return out


# One watchdog holds the whole keeper, so each compile skips the shim's
# per-run lock (`AVRA_WATCH_HELD`) and the cases run side by side.
WORKERS = int(os.environ.get("AVRA_DEFECT_WORKERS", "4"))
ENV = dict(os.environ, AVRA_WATCH_HELD="1")


def run(avra, verb, package):
    """(exit, output); a run past the clock is killed with everything it
    started, and answers 124."""
    p = subprocess.Popen(
        [avra, verb, package],
        env=ENV,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        start_new_session=True,
    )
    try:
        out, _ = p.communicate(timeout=TIMEOUT)
    except subprocess.TimeoutExpired:
        os.killpg(p.pid, signal.SIGKILL)
        p.communicate()
        return 124, "timed out after %ds" % TIMEOUT
    return p.returncode, out.decode("utf-8", "replace")


# The compile limiter's own queue notice is no voice of the compiler.
WAITING = re.compile(r"^avra: waiting for a compile slot.*$", re.M)


def verdict(code, out, lenient=False):
    """The reason a run is refused, or None. A lenient run is a mutant's
    own: only the compiler's voices count."""
    if lenient:
        hit = VOICES.search(out)
        return "voice %r" % hit.group(0) if hit else None
    if code > 1:
        return "exit %d" % code
    hit = BAD.search(WAITING.sub("", out))
    return "voice %r" % hit.group(0).strip() if hit else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--avra", default=os.path.join(ROOT, "avra"))
    ap.add_argument("--only")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--generate", type=int, default=0, metavar="N")
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--dump", metavar="NAME", help="print one program's text and stop")
    ap.add_argument("--progress", type=int, default=0, metavar="K", help="say where it is every K programs")
    ap.add_argument("--show", action="store_true", help="print every run's output")
    a = ap.parse_args()
    all_cases = cases(open(CORPUS, encoding="utf-8").read())
    work = []
    for name, flags, body in all_cases:
        verbs = ["check"] if "@check" in flags else ["check", "run"]
        work.append((name, verbs, body, "@manifest" in flags))
        if "@mutate" in flags:
            work.extend((n, verbs, b, "@manifest" in flags) for n, b in mutants(name, body))
    work = [(n, v, b, False, m) for n, v, b, m in work]
    work += [
        (n, ["check", "run"] if runnable(b) else ["check"], b, True, False)
        for n, b in generated(a.generate, a.seed)
    ]
    if a.only:
        work = [w for w in work if w[0].startswith(a.only)]
    if a.dump:
        print("".join(b for n, _, b, _, _ in work if n == a.dump), end="")
        return 0
    if a.list:
        for n, _, _, _, _ in work:
            print(n)
        return 0
    if not work:
        print("defects: examined nothing")
        return 1
    bad = []
    started = time.time()
    jobs = max(1, min(WORKERS, len(work)))
    lock = threading.Lock()
    queue = list(reversed(list(enumerate(work))))

    def attack(d):
        os.makedirs(os.path.join(d, "src"))
        while True:
            with lock:
                if not queue:
                    return
                k, (n, verbs, body, mutant, as_manifest) = queue.pop()
                if a.progress and k % a.progress == 0:
                    print("defects: %d/%d" % (k, len(work)), flush=True)
            for name, text in (("avra.toml", body if as_manifest else MANIFEST), ("src/main.av", "1\n" if as_manifest else body)):
                with open(os.path.join(d, name), "w", encoding="utf-8") as f:
                    f.write(text)
            clean = False
            for verb in verbs + ["build"]:
                if verb == "build" and not (clean and (not mutant or k % BUILD_EVERY == 0)):
                    continue
                t0 = time.time()
                code, out = run(a.avra, verb, d)
                clean = clean or (verb == "check" and code == 0)
                why = verdict(code, out, lenient=mutant and verb == "run")
                with lock:
                    if a.progress and time.time() - t0 > 10:
                        print("defects: slow %s (%s) %ds" % (n, verb, time.time() - t0), flush=True)
                    if a.show:
                        print("== %s (%s) exit %d\n%s" % (n, verb, code, out.strip()))
                    if why:
                        bad.append((n, why))
                        print("defects: %s (%s) — %s" % (n, verb, why), flush=True)
                        print("    " + "\n    ".join(out.strip().split("\n")[:6]), flush=True)

    with tempfile.TemporaryDirectory(prefix="avra-defects-") as root:
        threads = [threading.Thread(target=attack, args=(os.path.join(root, str(i)),)) for i in range(jobs)]
        for t in threads:
            t.start()
        for t in threads:
            t.join()
    print("defects: %d worker(s), %.0fs" % (jobs, time.time() - started))
    print("defects: %d program(s) examined, %d answered with a defect voice or a trap" % (len(work), len({n for n, _ in bad})))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
