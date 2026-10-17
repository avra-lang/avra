#!/usr/bin/env python3
"""Packs package suites into shards of even weight.

    printf '%s\\n' <package>... | python3 tools/shards.py [<shards>]

Prints a JSON list of lists for the checks workflow's suite matrix. The
heaviest suite goes first, each into the lightest shard so far, so the
slowest shard — the wall — is as short as the heaviest suite allows.
Weights are measured seconds (.github/ci/suite-seconds.txt); a package with
no row weighs 5. Empty shards are dropped; no package at all is one empty
shard, which the workflow skips.

With `--split`, a package named in .github/ci/suite-splits.txt becomes one
item per listed path (`std-avrac/src/features`), each proved by `avra test` on
that path alone; a `cold` row runs first in a shard of its own among the cold
ones, since its scope refuses to run after another suite on a warm store.
`--check-splits` refuses a split package that carries a proof
outside every listed path, which would otherwise run nowhere.
"""
import json
import os
import sys

DEFAULT = 5


def weights(path):
    out = {}
    try:
        with open(path) as f:
            for line in f:
                parts = line.split("#")[0].split()
                if len(parts) == 2:
                    out[parts[0]] = int(parts[1])
    except FileNotFoundError:
        pass
    return out


def splits(path):
    """package -> the paths (under the package) its suite is proved by, and
    the items (`package/path`) that must run first in their shard."""
    out, cold = {}, set()
    try:
        with open(path) as f:
            for line in f:
                parts = line.split("#")[0].split()
                if len(parts) in (2, 3):
                    out.setdefault(parts[0], []).append(parts[1])
                    if parts[2:] == ["cold"]:
                        cold.add(f"{parts[0]}/{parts[1]}")
    except FileNotFoundError:
        pass
    return out, cold


def split_items(names, table):
    return [f"{n}/{p}" if p else n for n in names for p in (table.get(n) or [""])]


def is_proof(path):
    if path.endswith((".expected", ".refuses", ".verdict")):
        return True
    if not path.endswith(".av"):
        return False
    with open(path, errors="replace") as f:
        return any(l.lstrip().startswith("spec ") or l.lstrip().startswith("spec(") for l in f)


def unreached(root, table):
    """Proof files under a split package that no listed path holds."""
    gone = []
    for pkg, paths in table.items():
        base = os.path.join(root, "packages", pkg)
        for p in paths:
            if not os.path.isdir(os.path.join(base, p)):
                gone.append(f"{pkg}/{p} is not a directory")
        for d, _, files in os.walk(os.path.join(base, "src")):
            rel = os.path.relpath(d, base)
            if any(rel == p or rel.startswith(p.rstrip("/") + "/") for p in paths):
                continue
            gone += [os.path.join(rel, f) for f in files if is_proof(os.path.join(d, f))]
    return gone


def pack(names, n, w, cold=()):
    """Heaviest first into the lightest shard. A cold item takes a shard of its
    own among the cold ones and runs first there."""
    bins = [[] for _ in range(n)]
    load = [0] * n
    firsts = sorted((x for x in names if x in cold), key=lambda p: (-w.get(p, DEFAULT), p))
    assert len(firsts) <= n, f"{len(firsts)} cold items, {n} shards"
    for i, name in enumerate(firsts):
        bins[i].append(name)
        load[i] += w.get(name, DEFAULT)
    for name in sorted((x for x in names if x not in cold), key=lambda p: (-w.get(p, DEFAULT), p)):
        i = load.index(min(load))
        bins[i].append(name)
        load[i] += w.get(name, DEFAULT)
    # a shard runs its cold items, then its lightest suites first, so a long one never delays the short ones' verdicts
    return [sorted(b, key=lambda p: (p not in cold, w.get(p, DEFAULT), p)) for b in bins if b] or [[]]


def self_test():
    w = {"a": 100, "b": 60, "c": 50}
    assert pack(["x", "a", "c", "b", "y"], 2, w) == [["x", "y", "a"], ["c", "b"]]
    assert pack([], 4, w) == [[]]
    assert pack(["x"], 4, w) == [["x"]]
    got = pack([f"p{i}" for i in range(9)], 4, {})
    assert sorted(len(b) for b in got) == [2, 2, 2, 3] and sum(len(b) for b in got) == 9
    t = {"p": ["src/a", "src/b"]}
    assert split_items(["p", "q"], t) == ["p/src/a", "p/src/b", "q"]
    assert split_items([], t) == []
    got = pack(["a", "b", "c", "d"], 2, {"a": 9, "b": 1, "c": 1, "d": 1}, {"c", "d"})
    assert [g[0] for g in got] == ["c", "d"] and sorted(sum(got, [])) == ["a", "b", "c", "d"], got
    print("shards: self-test passed — 7 fixtures")


if __name__ == "__main__":
    if sys.argv[1:] == ["--self-test"]:
        self_test()
        sys.exit(0)
    here = os.path.dirname(os.path.abspath(__file__))
    root = os.path.join(here, "..")
    ci = os.path.join(root, ".github", "ci")
    table, cold = splits(os.path.join(ci, "suite-splits.txt"))
    if sys.argv[1:] == ["--check-splits"]:
        bad = unreached(root, table)
        for b in bad:
            print(f"shards: {b} — outside every path in .github/ci/suite-splits.txt, so no shard proves it")
        if not bad:
            print(f"shards: {len(table)} split package(s), every proof under a listed path")
        sys.exit(1 if bad else 0)
    split = "--split" in sys.argv[1:]
    args = [a for a in sys.argv[1:] if a != "--split"]
    n = int(args[0]) if args else 4
    names = [l.strip() for l in sys.stdin if l.strip()]
    if split:
        names = split_items(names, table)
    print(json.dumps(pack(names, n, weights(os.path.join(ci, "suite-seconds.txt")), cold)))
