#!/usr/bin/env python3
"""Packs package suites into shards of even weight.

    printf '%s\\n' <package>... | python3 tools/shards.py [<shards>]

Prints a JSON list of lists for the checks workflow's suite matrix. The
heaviest suite goes first, each into the lightest shard so far, so the
slowest shard — the wall — is as short as the heaviest suite allows.
Weights are measured seconds (.github/ci/suite-seconds.txt); a package with
no row weighs 5. Empty shards are dropped; no package at all is one empty
shard, which the workflow skips.
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


def pack(names, n, w):
    bins = [[] for _ in range(n)]
    load = [0] * n
    for name in sorted(names, key=lambda p: (-w.get(p, DEFAULT), p)):
        i = load.index(min(load))
        bins[i].append(name)
        load[i] += w.get(name, DEFAULT)
    return [b for b in bins if b] or [[]]


def self_test():
    w = {"a": 100, "b": 60, "c": 50}
    assert pack(["x", "a", "c", "b", "y"], 2, w) == [["a", "x", "y"], ["b", "c"]]
    assert pack([], 4, w) == [[]]
    assert pack(["x"], 4, w) == [["x"]]
    got = pack([f"p{i}" for i in range(9)], 4, {})
    assert sorted(len(b) for b in got) == [2, 2, 2, 3] and sum(len(b) for b in got) == 9
    print("shards: self-test passed — 4 fixtures")


if __name__ == "__main__":
    if sys.argv[1:] == ["--self-test"]:
        self_test()
        sys.exit(0)
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 4
    here = os.path.dirname(os.path.abspath(__file__))
    names = [l.strip() for l in sys.stdin if l.strip()]
    print(json.dumps(pack(names, n, weights(os.path.join(here, "..", ".github", "ci", "suite-seconds.txt")))))
