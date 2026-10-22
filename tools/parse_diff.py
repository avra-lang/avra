#!/usr/bin/env python3
# tool-witness: --self-test
"""THE PARSER DIFFERENTIAL. Two compiler binaries, one corpus, byte-for-byte.

    python3 tools/parse_diff.py --a <binary> --b <binary> [--shard I/N]
        [--mutant-stride 16] [--mutant-every 50] [--check-every 4]
        [--work build/pdiff] [--report <dir>]
    python3 tools/parse_diff.py --self-test

Corpus:
  (i)  every .av under packages/ — `fmt --check FILE` (the parse verdict and
       the tree the printer projects) and nothing else.
  (ii) a deterministic mutation corpus over every --mutant-stride-th file:
       for every --mutant-every-th token, three mutants — truncated before the
       token, the token deleted, the token duplicated. Each mutant is a package
       of its own (avra.toml + src/main.av) under the work dir, checked with
       `fmt --check` and, for every --check-every-th mutant, with `check`.

There is no AST dump command in the CLI. The tree the parser built is compared
through `fmt --check` (the printer's projection of it); diagnostics are compared
through `check` stdout and stderr, in the order they were written.

Two-binary rule: all of A's units run, the store is cleared, then all of B's.
The store is `<tree>/.avra-cache` and `<work>/.avra-cache`, cleared between the
two binaries of every shard.

A check that examined nothing is not a pass: the run prints the counts and
exits 2 when files or mutants examined is zero. Exit 1 on any difference.
"""
import argparse
import glob
import json
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TOKEN = re.compile(r'[A-Za-z_][A-Za-z0-9_]*|\d+|"(?:[^"\\\n]|\\.)*"|\S')
NOISE = ("time:", "watch:", "job control")


def normalise(text):
    return "\n".join(l for l in text.split("\n") if not l.startswith(NOISE))


def run(binary, args, cwd):
    r = subprocess.run([binary] + args, cwd=cwd, capture_output=True, text=True)
    return {"rc": r.returncode, "out": normalise(r.stdout), "err": normalise(r.stderr)}


def clear_store(*dirs):
    for d in dirs:
        shutil.rmtree(os.path.join(d, ".avra-cache"), ignore_errors=True)


def tree_files(corpus):
    found = glob.glob(os.path.join(ROOT, corpus, "**", "*.av"), recursive=True)
    return sorted(os.path.relpath(p, ROOT) for p in found)


def mutants(text, every):
    """(name, mutated text) for every `every`-th token: truncate, delete, duplicate."""
    toks = list(TOKEN.finditer(text))
    for k in range(0, len(toks), every):
        t = toks[k]
        yield "k%d-trunc" % k, text[: t.start()]
        yield "k%d-del" % k, text[: t.start()] + text[t.end():]
        yield "k%d-dup" % k, text[: t.end()] + " " + t.group(0) + text[t.end():]


def units(args, work):
    """Every unit: ("fmt", path, None) for tree files, ("mut", index, (name, text)) for mutants.

    With --walk, the tree is one unit: `fmt --check packages`, one process over every file.
    """
    out = []
    files = tree_files(args.corpus)
    if args.walk:
        out.append(("walk", args.corpus, None))
    else:
        for f in files:
            out.append(("fmt", f, None))
    base = files[:: args.mutant_stride]
    index = 0
    for f in ([] if args.walk and not args.mutants else base):
        with open(os.path.join(ROOT, f), encoding="utf-8") as fh:
            text = fh.read()
        for name, mutated in mutants(text, args.mutant_every):
            out.append(("mut", index, (f, name, mutated)))
            index += 1
    return out


def shard_of(all_units, shard, n):
    return [u for i, u in enumerate(all_units) if i % n == shard]


def materialise(unit, work):
    """Write a mutant as its own package under work; return its package path (relative to ROOT)."""
    _, index, (src, name, text) = unit
    pkg = os.path.join(work, "m", str(index))
    os.makedirs(os.path.join(pkg, "src"), exist_ok=True)
    with open(os.path.join(pkg, "avra.toml"), "w", encoding="utf-8") as fh:
        fh.write('[package]\nname = "pdiff"\nversion = "0.1.0"\n')
    with open(os.path.join(pkg, "src", "main.av"), "w", encoding="utf-8") as fh:
        fh.write(text)
    return os.path.relpath(pkg, ROOT)


def plan(binary, todo, work, check_every):
    """Run one binary over the todo list; return {key: result}."""
    results = {}
    mutant_no = 0
    for u in todo:
        if u[0] == "walk":
            results[("walk", u[1])] = run(binary, ["fmt", "--check", u[1]], ROOT)
            continue
        if u[0] == "fmt":
            results[("fmt", u[1])] = run(binary, ["fmt", "--check", u[1]], ROOT)
            continue
        pkg = materialise(u, work)
        results[("fmt", "mut:%d" % u[1])] = run(binary, ["fmt", "--check", os.path.join(pkg, "src", "main.av")], ROOT)
        if mutant_no % check_every == 0:
            results[("check", "mut:%d" % u[1])] = run(binary, ["check", pkg], ROOT)
        mutant_no += 1
    return results


def compare(a, b):
    diffs = []
    for key in sorted(set(a) | set(b)):
        if a.get(key) != b.get(key):
            diffs.append((key, a.get(key), b.get(key)))
    return diffs


def first_difference(x, y):
    if x is None or y is None:
        return "missing on one side"
    for field in ("rc", "out", "err"):
        if x[field] != y[field]:
            xs, ys = str(x[field]).split("\n"), str(y[field]).split("\n")
            for i, (p, q) in enumerate(zip(xs, ys)):
                if p != q:
                    return "%s line %d: A=%r B=%r" % (field, i + 1, p[:160], q[:160])
            return "%s: length differs" % field
    return "identical"


def run_shard(args, binary_a, binary_b):
    work = os.path.abspath(args.work)
    os.makedirs(work, exist_ok=True)
    shard, n = (int(x) for x in args.shard.split("/"))
    selected = shard_of(units(args, work), shard, n)
    clear_store(ROOT, work)
    res_a = plan(binary_a, selected, work, args.check_every)
    clear_store(ROOT, work)
    res_b = plan(binary_b, selected, work, args.check_every)
    clear_store(ROOT, work)
    diffs = compare(res_a, res_b)
    files = sum(1 for u in selected if u[0] in ("fmt", "walk"))
    muts = sum(1 for u in selected if u[0] == "mut")
    checks = sum(1 for k in res_a if k[0] == "check")
    print("shard %s: files examined %d, mutants examined %d, check runs %d, differences %d"
          % (args.shard, files, muts, checks, len(diffs)))
    for key, x, y in diffs[: args.show]:
        print("DIFF %s %s: %s" % (key[0], key[1], first_difference(x, y)))
    if args.report:
        os.makedirs(args.report, exist_ok=True)
        with open(os.path.join(args.report, "shard-%d-of-%d.json" % (shard, n)), "w", encoding="utf-8") as fh:
            json.dump({"files": files, "mutants": muts, "checks": checks, "diffs": len(diffs)}, fh)
    if files + muts == 0:
        return 2
    return 1 if diffs else 0


def self_test():
    """Two scripted fake binaries: identical -> 0 differences; one token changed -> differences."""
    import tempfile
    tmp = tempfile.mkdtemp(prefix="pdiff-self-")
    same = os.path.join(tmp, "same.sh")
    other = os.path.join(tmp, "other.sh")
    body = '#!/bin/sh\necho "fake $*"\nif [ "$2" = "--check" ]; then cat "$3" | wc -c; fi\n'
    with open(same, "w") as fh:
        fh.write(body)
    with open(other, "w") as fh:
        fh.write(body.replace('echo "fake $*"', 'echo "fake $* B"'))
    for f in (same, other):
        os.chmod(f, 0o755)
    ns = argparse.Namespace(a=same, b=same, shard="0/1", mutant_stride=400, mutant_every=50,
                            check_every=10**9, work=os.path.join(tmp, "work"), report=None, show=5,
                            walk=False, mutants=False, corpus="packages/std-prelude")
    equal = run_shard(ns, same, same)
    ns.shard = "0/1"
    unequal = run_shard(ns, same, other)
    print("self-test: identical binaries exit %d (want 0); differing binaries exit %d (want 1)"
          % (equal, unequal))
    shutil.rmtree(tmp, ignore_errors=True)
    return 0 if equal == 0 and unequal == 1 else 1


def main(argv):
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--a")
    p.add_argument("--b")
    p.add_argument("--shard", default="0/1")
    p.add_argument("--mutant-stride", type=int, default=16)
    p.add_argument("--mutant-every", type=int, default=50)
    p.add_argument("--check-every", type=int, default=4)
    p.add_argument("--work", default=os.path.join(ROOT, "build", "pdiff"))
    p.add_argument("--report")
    p.add_argument("--show", type=int, default=10)
    p.add_argument("--corpus", default="packages", help="the directory under the tree the corpus is read from")
    p.add_argument("--walk", action="store_true", help="the tree as one fmt --check walk, not per file")
    p.add_argument("--mutants", action="store_true", help="with --walk, also the mutants")
    p.add_argument("--self-test", action="store_true")
    args = p.parse_args(argv)
    if args.self_test:
        return self_test()
    if not args.a or not args.b:
        p.error("--a and --b are required")
    return run_shard(args, os.path.abspath(args.a), os.path.abspath(args.b))


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
