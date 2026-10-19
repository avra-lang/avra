#!/usr/bin/env python3
"""Packs package suites into shards of even weight.

    printf '%s\\n' <package>... | python3 tools/shards.py [<shards>]

Prints a JSON list of lists for the checks workflow's suite matrix. The
heaviest suite goes first, each into the lightest shard so far, so the
slowest shard — the wall — is as short as the heaviest suite allows.
Weights are measured seconds (.github/ci/suite-seconds.txt); a package with
no row weighs 5. Empty shards are dropped; no package at all is one empty
shard, which the workflow skips.

Weights come from two layers, the later winning per row: the committed seed
(.github/ci/suite-seconds.txt) and the MEASURED rows main's own runs keep
(.github/ci/suite-seconds.measured, restored from a cache by `prepare`).
`--merge-times <dir>` makes the measured rows: it reads every `suite-times.txt`
the suites jobs wrote (`<path> <seconds> [first]`), takes a shard's first suite
less COLD seconds (it also paid the runner's cold start), and averages each
row with its prior measured value, so one noisy run moves a weight half way.

With `--split`, a package named in .github/ci/suite-splits.txt becomes one
item per listed path (`std-avrac/src/features`), each proved by `avra test` on
that path alone; a `cold` row runs first in a shard of its own among the cold
ones, since its scope refuses to run after another suite on a warm store.
`--check-splits` refuses a split package that carries a proof
outside every listed path, which would otherwise run nowhere.
"""
import json
import os
import re
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


# The seconds a shard's first suite pays that no later one does: a runner's cold store.
COLD = 100


def layered_weights(paths):
    out = {}
    for p in paths:
        out.update(weights(p))
    return out


def merge_times(root, prior):
    """Rows measured by a run -> the new weights. `prior`: path -> seconds, the
    measured weights so far; a path not timed this run keeps its prior row."""
    out = dict(prior)
    seen = {}
    for dirpath, _, files in os.walk(root):
        for f in files:
            if f != "suite-times.txt":
                continue
            with open(os.path.join(dirpath, f)) as fh:
                for line in fh:
                    parts = line.split()
                    if len(parts) in (2, 3) and parts[1].isdigit():
                        n = int(parts[1])
                        warm = max(n - COLD, 1) if parts[2:] == ["first"] else n
                        seen[parts[0]] = max(seen.get(parts[0], 0), warm)
    for path, warm in seen.items():
        out[path] = warm if path not in prior else (prior[path] + warm + 1) // 2
    return out


def splits(path):
    """package -> the items its suite is proved by (a path under the package, or an `@group`),
    the items (`package/item`) that must run first in their shard, and each group's paths.
    A row is `<package> <path> [cold]` or `<package> @<group> <path>... [cold]`."""
    out, cold, groups = {}, set(), {}
    try:
        with open(path) as f:
            for line in f:
                parts = line.split("#")[0].split()
                if len(parts) < 2:
                    continue
                if parts[-1] == "cold":
                    cold.add(f"{parts[0]}/{parts[1]}")
                    parts = parts[:-1]
                out.setdefault(parts[0], []).append(parts[1])
                if parts[1].startswith("@"):
                    groups[f"{parts[0]}/{parts[1]}"] = parts[2:]
    except FileNotFoundError:
        pass
    return out, cold, groups


STRIDE = re.compile(r"^(?P<dir>.+)%(?P<k>\d+)/(?P<n>\d+)$")


def stride_files(base, d, k, n):
    """A directory's proof files, dealt round-robin in name order into `n` hands: hand `k`."""
    here = os.path.join(base, d)
    names = sorted(f for f in os.listdir(here) if os.path.isfile(os.path.join(here, f)) and is_proof(os.path.join(here, f)))
    return [os.path.join(d, f) for i, f in enumerate(names) if i % n == k]


def item_paths(item, groups, root="."):
    """The `packages/...` paths one packed item is proved by: a package, a path under it, or
    every path of a group. A path `dir%k/n` is hand `k` of `n` of the proof files directly in
    `dir`, named one by one. A path `!file` is a file that only LOOKS like a proof (a spec inside
    a string): the check holds it covered and no shard runs it."""
    pkg, _, rest = item.partition("/")
    if not rest.startswith("@"):
        return [f"packages/{item}"]
    out = []
    for p in groups[item]:
        m = STRIDE.match(p)
        if p.startswith("!"):
            continue
        if m:
            out += [f"packages/{pkg}/{f}" for f in stride_files(os.path.join(root, "packages", pkg), m["dir"], int(m["k"]), int(m["n"]))]
        else:
            out.append(f"packages/{pkg}/{p}")
    return out


def split_items(names, table):
    return [f"{n}/{p}" if p else n for n in names for p in (table.get(n) or [""])]


def is_proof(path):
    if path.endswith((".expected", ".refuses", ".verdict")):
        return True
    if not path.endswith(".av"):
        return False
    with open(path, errors="replace") as f:
        return any(l.lstrip().startswith("spec ") or l.lstrip().startswith("spec(") for l in f)


def unreached(root, table, groups=None):
    """Proof files under a split package that no listed path holds."""
    gone = []
    for pkg, listed in table.items():
        listed_paths = [q for p in listed for q in ((groups or {})[f"{pkg}/{p}"] if p.startswith("@") else [p])]
        base = os.path.join(root, "packages", pkg)
        paths, hands = [], {}
        for p in listed_paths:
            m = STRIDE.match(p)
            if m:
                hands.setdefault((m["dir"], int(m["n"])), set()).add(int(m["k"]))
            else:
                paths.append(p)
        held = set()
        for (d, n), ks in hands.items():
            if not os.path.isdir(os.path.join(base, d)):
                gone.append(f"{pkg}/{d} is not a directory")
            elif ks != set(range(n)):
                gone.append(f"{pkg}/{d} is dealt in {n} hands and {sorted(set(range(n)) - ks)} are not listed")
            else:
                held |= {f for k in ks for f in stride_files(base, d, k, n)}
        for p in paths:
            if p.startswith("!"):
                held.add(p[1:])
            elif os.path.isfile(os.path.join(base, p)):
                held.add(p)
            elif not os.path.isdir(os.path.join(base, p)):
                gone.append(f"{pkg}/{p} is not a directory or a file")
        for d, _, files in os.walk(os.path.join(base, "src")):
            rel = os.path.relpath(d, base)
            if any(rel == p or rel.startswith(p.rstrip("/") + "/") for p in paths):
                continue
            gone += [os.path.join(rel, f) for f in files if is_proof(os.path.join(d, f)) and os.path.join(rel, f) not in held]
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
    import tempfile
    with tempfile.TemporaryDirectory() as d:
        os.makedirs(os.path.join(d, "a"))
        with open(os.path.join(d, "a", "suite-times.txt"), "w") as f:
            f.write("cli 400 first\nstd-http 120\nstd-ui 30\n")
        got = merge_times(d, {"cli": 100, "std-http": 140, "old": 7})
        assert got == {"cli": 200, "std-http": 130, "std-ui": 30, "old": 7}, got
        assert merge_times(d, {})["cli"] == 300, "a first suite is less its cold start"
        with open(os.path.join(d, "seed"), "w") as f:
            f.write("cli 120\nstd-ui 5\n")
        with open(os.path.join(d, "measured"), "w") as f:
            f.write("cli 300\n")
        assert layered_weights([os.path.join(d, "seed"), os.path.join(d, "measured"), os.path.join(d, "none")]) == {"cli": 300, "std-ui": 5}
    with tempfile.TemporaryDirectory() as d:
        f = os.path.join(d, "splits")
        with open(f, "w") as fh:
            fh.write("p src/a cold\np @g src/b src/c  # a group\np src/d\n")
        table, cold, groups = splits(f)
        assert table == {"p": ["src/a", "@g", "src/d"]} and cold == {"p/src/a"} and groups == {"p/@g": ["src/b", "src/c"]}, (table, cold, groups)
        assert item_paths("p/@g", groups) == ["packages/p/src/b", "packages/p/src/c"]
        assert item_paths("p/src/d", groups) == ["packages/p/src/d"] and item_paths("cli", groups) == ["packages/cli"]
        for n in ("a_test.av", "b_test.av", "c_test.av"):
            os.makedirs(os.path.join(d, "packages", "p", "src", "t"), exist_ok=True)
            with open(os.path.join(d, "packages", "p", "src", "t", n), "w") as fh:
                fh.write("spec x {\n}\n")
        g = {"p/@a": ["src/t%0/2"], "p/@b": ["src/t%1/2"]}
        assert item_paths("p/@a", g, d) == ["packages/p/src/t/a_test.av", "packages/p/src/t/c_test.av"]
        assert item_paths("p/@b", g, d) == ["packages/p/src/t/b_test.av"]
        assert unreached(d, {"p": ["@a", "@b"]}, g) == [], "two hands cover the directory"
        assert any("not listed" in x for x in unreached(d, {"p": ["@a"]}, g)), "a missing hand is named"
    print("shards: self-test passed — 14 fixtures")


if __name__ == "__main__":
    if sys.argv[1:] == ["--self-test"]:
        self_test()
        sys.exit(0)
    here = os.path.dirname(os.path.abspath(__file__))
    root = os.path.join(here, "..")
    ci = os.path.join(root, ".github", "ci")
    table, cold, groups = splits(os.path.join(ci, "suite-splits.txt"))
    if sys.argv[1:2] == ["--paths"]:
        print(" ".join(item_paths(sys.argv[2], groups, root)))
        sys.exit(0)
    if sys.argv[1:] == ["--check-splits"]:
        bad = unreached(root, table, groups)
        for b in bad:
            print(f"shards: {b} — outside every path in .github/ci/suite-splits.txt, so no shard proves it")
        if not bad:
            print(f"shards: {len(table)} split package(s), every proof under a listed path")
        sys.exit(1 if bad else 0)
    measured = os.path.join(ci, "suite-seconds.measured")
    if sys.argv[1:2] == ["--merge-times"]:
        rows = merge_times(sys.argv[2], weights(measured))
        print("# Suite seconds measured on main's own runs (tools/shards.py --merge-times).")
        for k in sorted(rows):
            print(f"{k} {rows[k]}")
        sys.exit(0)
    split = "--split" in sys.argv[1:]
    args = [a for a in sys.argv[1:] if a != "--split"]
    n = int(args[0]) if args else 4
    names = [l.strip() for l in sys.stdin if l.strip()]
    if split:
        names = split_items(names, table)
    print(json.dumps(pack(names, n, layered_weights([os.path.join(ci, "suite-seconds.txt"), measured]), cold)))
