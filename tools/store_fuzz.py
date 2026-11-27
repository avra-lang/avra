#!/usr/bin/env python3
# tool-witness: --self-test
"""THE STORE, FUZZED BY A MODEL: random edit sequences over a fixture, each step built warm over
the stores the step before left, and held to five invariants:

  - WARM == COLD, BYTE FOR BYTE: the warm build's exit, its words, its product and what it prints are
    a cold build's of the same tree, every store emptied, in the same place;
  - THE STORE IS CLEAN: `avra cache check` finds nothing in any store the build left;
  - THE WALK HOLDS: no frontier write's walk from the cut disagrees with the whole walk
    (AVRA_FRONTIER_WALK_CHECK);
  - A FRESH COPY BUILDS AS THE TREE DOES: the tree's sources copied beside it, no store of their own,
    built over the same machine store, exit and print as the warm build — what a step kept there under
    the tree's own keys is read by it;
  - NOTHING MOVED, NOTHING WORKED: the main package checked twice, the second check working out no
    answer (`queries_computed=0`); for a save beside the sources, its neighbour is checked on its own
    between the two, its store written beside the neighbour's files.

TWO FIXTURES. `packages` is a model program of int fns, a third of them methods of a type, over two
packages: `app` (its main prints what its root fns answer) and `lib`, which app depends on. Its edits:
a body, a rename (every caller and import with it), a fn added, one deleted (its calls with it), a
signature (a seat added, defaulted or filled by every caller), a method's defaulted seat (given, then
renamed), a broken edit, a revert (the model as it stood some steps back), a file moved between the
packages, and a save beside the sources. `board` is tools/ui-board, its hydrate main its main, as a
dev loop edits it: a fn appended to the board's file, one taken away, a broken edit, a revert, a save
beside. A BROKEN EDIT IS A DETOUR in both: a half-typed declaration, then the tree exactly as it
stood before it, so what the broken build kept is asked again under the good tree's keys.

An edit is an abstract op (its kind and a seed of its own) resolved against the model as it stands,
so a sequence shrunk by dropping ops still replays: an op whose target is gone is a no-op. A failing
seed is shrunk (ddmin over its ops) and said as one line that replays it. A fixture that fails to
build before any edit is the harness's fault, exit 2, never a find.

    python3 tools/store_fuzz.py --compiler build/avra --seeds 1-8 --steps 12
    python3 tools/store_fuzz.py --compiler build/avra --fixture board --seeds 7-8 --steps 3
    python3 tools/store_fuzz.py --compiler build/avra --replay 'seed=3 ops=body:11,rename:7,...'
    python3 tools/store_fuzz.py --self-test     # the model and the shrinker, no compiler
"""
import argparse
import hashlib
import os
import random
import re
import shutil
import subprocess
import sys
import tempfile

KINDS = ["body", "rename", "add", "delete", "signature", "seat", "broken", "revert", "move", "beside"]
# How often each kind is drawn: edits that change what is read the most, the rarer shapes less.
WEIGHTS = {"body": 5, "rename": 3, "add": 3, "delete": 2, "signature": 3, "seat": 4, "broken": 2, "revert": 2,
           "move": 1, "beside": 2}
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")


# ---- the model ------------------------------------------------------------------------------

class Fn:
    def __init__(self, name, seats, body, owner=None):
        # seats: [(name, default or None)]; owner: the type a method is of, None for a free fn
        self.name, self.seats, self.body, self.owner = name, seats, body, owner

    def copy(self):
        return Fn(self.name, list(self.seats), self.body, self.owner)


class Model:
    """Files by (package, module), each an ordered list of fns; main's roots by name."""

    def __init__(self):
        self.files = {}
        self.roots = []
        self.serial = 0
        self.broken = None  # (package, module) a half-typed declaration stands at the end of
        self.owners = {}  # (package, module) -> the type its methods are of

    def copy(self):
        m = Model()
        m.files = {k: [f.copy() for f in fs] for k, fs in self.files.items()}
        m.roots, m.serial, m.broken = list(self.roots), self.serial, self.broken
        m.owners = dict(self.owners)
        return m

    def owner_of(self, key):
        """The type the methods of the file at `key` are of, made the first time it's asked."""
        if key not in self.owners:
            self.serial += 1
            self.owners[key] = f"T_{self.serial}"
        return self.owners[key]

    def fresh_name(self, stem):
        self.serial += 1
        return f"{stem}_{self.serial}"

    def where(self, name):
        for k, fs in self.files.items():
            for f in fs:
                if f.name == name:
                    return k, f
        return None, None

    def all_fns(self):
        return [(k, f) for k, fs in self.files.items() for f in fs]

    def callees(self, f):
        return set(re.findall(r"\b([a-z]+_\d+)\(", f.body))

    def reaches(self, a, b):
        """Whether `a` calls `b`, itself or through what it calls."""
        seen, todo = set(), [a]
        while todo:
            n = todo.pop()
            if n == b:
                return True
            if n in seen:
                continue
            seen.add(n)
            _, f = self.where(n)
            if f:
                todo += list(self.callees(f))
        return False

    def may_call(self, caller_key, callee_key):
        """lib never reads app."""
        return not (caller_key[0] == "lib" and callee_key[0] == "app")


def call_of(f, rng):
    args = []
    for _, d in f.seats:
        if d is None or rng.random() < 0.5:
            args.append(str(rng.randint(1, 9)))
    called = f"{f.name}({', '.join(args)})"
    return f"{f.owner} {{}}.{called}" if f.owner else called


def initial(seed):
    rng = random.Random(seed)
    m = Model()
    m.files = {("lib", "shapes"): [], ("lib", "util"): [], ("app", "main"): [], ("app", "more"): []}
    order = [("lib", "util"), ("lib", "shapes"), ("app", "more"), ("app", "main")]
    made = []
    for key in order:
        for _ in range(2):
            name = m.fresh_name("f")
            seats = [("x", None)]
            body = f"x + {rng.randint(1, 9)}"
            choices = [(k, g) for k, g in made if m.may_call(key, k)]
            if choices and rng.random() < 0.7:
                k, g = rng.choice(choices)
                body = f"{call_of(g, rng)} + x"
            f = Fn(name, seats, body, m.owner_of(key) if rng.random() < 0.35 else None)
            m.files[key].append(f)
            made.append((key, f))
    m.roots = [f.name for _, f in made[-3:]]
    return m


def apply(m, op):
    """The model `op` makes of `m`, and whether it changed any source. An op that can't apply
    is a no-op."""
    kind, seed = op
    rng = random.Random(seed * 7919 + KINDS.index(kind))
    m = m.copy()
    if m.broken is not None:  # a broken edit is taken back by the step after it
        m.broken = None
    fns = m.all_fns()
    if kind == "body" and fns:
        k, f = rng.choice(fns)
        targets = [(k2, g) for k2, g in fns if g is not f and m.may_call(k, k2) and not m.reaches(g.name, f.name)]
        if targets and rng.random() < 0.5:
            _, g = rng.choice(targets)
            f.body = f"{call_of(g, rng)} + {f.seats[0][0]}"
        else:
            f.body = f"{f.seats[0][0]} * {rng.randint(2, 9)} + {rng.randint(0, 9)}"
        return m, True
    if kind == "rename" and fns:
        k, f = rng.choice(fns)
        old, new = f.name, m.fresh_name("f")
        for _, g in m.all_fns():
            g.body = re.sub(r"\b%s\(" % old, new + "(", g.body)
        f.name = new
        m.roots = [new if r == old else r for r in m.roots]
        return m, True
    if kind == "add":
        key = rng.choice(sorted(m.files))
        f = Fn(m.fresh_name("f"), [("x", None)], f"x + {rng.randint(1, 9)}",
               m.owner_of(key) if rng.random() < 0.35 else None)
        m.files[key].append(f)
        if rng.random() < 0.5 and key[0] == "app":
            m.roots.append(f.name)
        return m, True
    if kind == "delete" and len(fns) > 3:
        k, f = rng.choice(fns)
        for _, g in m.all_fns():
            g.body = re.sub(r"\b%s\([^()]*\)" % f.name, str(rng.randint(1, 9)), g.body)
        m.files[k].remove(f)
        m.roots = [r for r in m.roots if r != f.name] or [m.all_fns()[0][1].name]
        return m, True
    if kind == "signature" and fns:
        k, f = rng.choice(fns)
        seat = f"s{len(f.seats)}"
        defaulted = rng.random() < 0.5
        f.seats.append((seat, "0" if defaulted else None))
        f.body = f"{f.body} + {seat}"
        if not defaulted:
            for _, g in m.all_fns():
                g.body = re.sub(r"\b%s\(([^()]*)\)" % f.name, lambda c: f"{f.name}({c.group(1)}, {rng.randint(1, 9)})", g.body)
        return m, True
    if kind == "seat":
        # A METHOD'S DEFAULTED SEAT, the shape a lowered seat default is asked again in: renamed
        # where a method has one, the body that reads it with it, else given to a method, so draws of
        # this kind walk a seat added, then renamed and renamed again
        methods = [f for _, f in fns if f.owner]
        defaulted = [f for f in methods if any(d is not None for _, d in f.seats[1:])]
        if defaulted:
            f = rng.choice(defaulted)
            i = rng.choice([k for k in range(1, len(f.seats)) if f.seats[k][1] is not None])
            old, default = f.seats[i]
            new = m.fresh_name("s")
            f.seats[i] = (new, default)
            f.body = re.sub(r"\b%s\b" % re.escape(old), new, f.body)
            return m, True
        if not methods:
            return m, False
        f = rng.choice(methods)
        seat = m.fresh_name("s")
        f.seats.append((seat, str(rng.randint(0, 9))))
        f.body = f"{f.body} + {seat}"
        return m, True
    if kind == "broken":
        m.broken = rng.choice(sorted(m.files))
        return m, True
    if kind == "move":
        def calls_of(k):
            return {m.where(c)[0] for f in m.files[k] for c in m.callees(f)} - {None, k}
        # to lib: every call it makes lands in lib or in itself; back to app: no other lib file calls it
        to_lib = [k for k in sorted(m.files) if k[0] == "app" and k[1] != "main"
                  and all(c[0] == "lib" for c in calls_of(k)) and ("lib", k[1]) not in m.files]
        to_app = [k for k in sorted(m.files) if k[0] == "lib" and k[1] != "lib" and ("app", k[1]) not in m.files
                  and not any(k in calls_of(o) for o in m.files if o[0] == "lib" and o != k)]
        choices = [(k, ("lib", k[1])) for k in to_lib] + [(k, ("app", k[1])) for k in to_app]
        if not choices:
            return m, False
        src, dst = rng.choice(choices)
        m.files[dst] = m.files.pop(src)
        return m, True
    if kind == "beside":
        return m, False
    return m, False


def replayed(seed, ops, fixture=None):
    """The models a sequence makes, one per step, each with whether a source moved, the op's kind
    and which op it is; a revert resolves against the models before it. A BROKEN EDIT IS A DETOUR:
    the half-typed declaration, then the tree exactly as it stood before it, so whatever the broken
    build kept is asked again under the good tree's own keys."""
    fixture = fixture or PACKAGES
    m = fixture.initial(seed)
    out = []
    history = [m]
    for index, op in enumerate(ops):
        kind, s = op
        if kind == "revert":
            if len(history) > 1:
                back = random.Random(s).randint(1, min(4, len(history) - 1))
                m = history[-1 - back].copy()
                m.broken = None
                moved = True
            else:
                moved = False
        elif kind == "broken":
            before = m
            m, moved = fixture.apply(m, op)
            history.append(m)
            out.append((m, moved, kind, index))
            m, moved, kind = before.copy(), True, "fixed"
        else:
            m, moved = fixture.apply(m, op)
        history.append(m)
        out.append((m, moved, kind, index))
    return out


# ---- the program a model is -----------------------------------------------------------------

def source_of(m, key):
    pkg, module = key
    fns = m.files[key]
    lines = []
    imports = {}

    def imported(name):
        """What a file takes to call `name`: the fn itself, or the type a method is of."""
        k, f = m.where(name)
        if k and k != key:
            imports.setdefault(k, set()).add(f.owner or f.name)

    for f in fns:
        for c in sorted(m.callees(f)):
            imported(c)
    if key == ("app", "main"):
        for r in m.roots:
            imported(r)
    for k in sorted(imports):
        path = f"@f.lib.{k[1]}" if k[0] == "lib" and pkg == "app" else k[1]
        lines.append(f"use {path}.{{{', '.join(sorted(imports[k]))}}}")
    if lines:
        lines.append("")

    def declared(f, indent, receiver):
        seats = ", ".join(f"{n}: int" + (f" = {d}" if d is not None else "") for n, d in f.seats)
        word = "fn" if receiver else "export fn"
        return f"{indent}{word} {f.name}({seats}) -> int {{ {f.body} }}"

    for f in fns:
        if f.owner is None:
            lines.append(declared(f, "", None))
            lines.append("")
    for owner in sorted({f.owner for f in fns if f.owner}):
        lines.append(f"export type {owner} = {{}}")
        lines.append("")
        lines.append(f"impl {owner} {{")
        lines += [declared(f, "    ", "self") for f in fns if f.owner == owner]
        lines.append("}")
        lines.append("")
    if key == ("app", "main"):
        said = []
        for i, r in enumerate(m.roots):
            _, f = m.where(r)
            if f:
                lines.append(f"let root_{i} = {call_of(f, random.Random(len(r)))}")
                said.append("${root_%d}" % i)
        lines.append(f'println("{" ".join(said)}")')
    if m.broken == key:
        lines.append("fn broken( {")
    return "\n".join(lines) + "\n"


def written(m, where):
    """The model's two packages laid under `where`: every file the model holds, none it doesn't."""
    for pkg in ("lib", "app"):
        src = os.path.join(where, pkg, "src")
        os.makedirs(src, exist_ok=True)
        for name in os.listdir(src):
            if name.endswith(".av") and (pkg, name[:-3]) not in m.files:
                os.remove(os.path.join(src, name))
    toml = {"lib": '[package]\nname = "@f/lib"\nversion = "0.0.1"\n',
            "app": '[package]\nname = "app"\nversion = "0.0.1"\n\n[dependencies]\n"@f/lib" = { path = "../lib" }\n'}
    for pkg, text in toml.items():
        with open(os.path.join(where, pkg, "avra.toml"), "w") as out:
            out.write(text)
    if ("lib", "lib") not in m.files:
        m.files.setdefault(("lib", "lib"), [])
    for key in m.files:
        path = os.path.join(where, key[0], "src", key[1] + ".av")
        text = source_of(m, key)
        if not os.path.exists(path) or open(path).read() != text:
            with open(path, "w") as out:
                out.write(text)


# ---- the oracles ----------------------------------------------------------------------------

class HarnessFailed(Exception):
    """The harness can't hold a step to its invariants: its fault, never a find."""


class Run:
    def __init__(self, compiler, where, fixture=None):
        self.compiler, self.where = os.path.abspath(compiler), where
        self.fixture = fixture or PACKAGES
        self.machine = os.path.join(where, "machine")
        self.trips = os.path.join(where, "walk-trips")
        os.makedirs(self.machine, exist_ok=True)

    def env(self):
        e = dict(os.environ)
        e.update({"AVRA_CACHE_DIR": self.machine, "AVRA_PROGRAM": "1", "AVRA_STORE_KEPT_HERE": "1",
                  "AVRA_PROGRAM_NET": "0", "AVRA_FRONTIER_WALK_CHECK": self.trips,
                  "AVRA_PROGRAM_MODE": "link=whole"})
        return e

    def stores(self):
        return [os.path.join(self.where, p, ".avra-cache") for p in self.fixture.stored] + [self.machine]

    def built(self, pkg=None):
        pkg = pkg or self.fixture.main
        """The build's exit, its words with the paths of this run made one word, its product's hash,
        and the answers it worked out, where it says."""
        done = subprocess.run([self.compiler, "build", os.path.join(self.where, pkg)], capture_output=True,
                              text=True, env=self.env(), timeout=900)
        words = (done.stdout + done.stderr).replace(self.where, "<run>")
        worked = [int(n) for n in re.findall(r"worked: (\d+) answers", words)]
        words = "\n".join(l for l in words.split("\n") if not re.match(r"\s*(worked:|program:|\[time\]|.* ms\b)", l))
        product = os.path.join(self.where, pkg, "src", "main")
        digest = hashlib.sha256(open(product, "rb").read()).hexdigest() if done.returncode == 0 and os.path.exists(product) else ""
        printed = ""
        if digest:
            printed = subprocess.run([product], capture_output=True, text=True, timeout=60).stdout
        return {"exit": done.returncode, "words": words, "product": digest, "printed": printed,
                "worked": worked[-1] if worked else None}

    def cold(self):
        """The same tree built cold, in the same place, every store set aside and put back after."""
        aside = os.path.join(self.where, "aside")
        shutil.rmtree(aside, ignore_errors=True)
        os.makedirs(aside)
        for i, s in enumerate(self.stores()):
            if os.path.exists(s):
                shutil.move(s, os.path.join(aside, str(i)))
        os.makedirs(self.machine, exist_ok=True)
        trips = self.trips
        self.trips = os.path.join(self.where, "cold-trips")
        try:
            return self.built()
        finally:
            self.trips = trips
            for i, s in enumerate(self.stores()):
                shutil.rmtree(s, ignore_errors=True)
                if os.path.exists(os.path.join(aside, str(i))):
                    shutil.move(os.path.join(aside, str(i)), s)
            shutil.rmtree(aside, ignore_errors=True)

    def store_faults(self):
        out = []
        for s in self.stores():
            for d, _, names in os.walk(s):
                if any(n.startswith("frontier-") for n in names):
                    done = subprocess.run([self.compiler, "cache", "check", d], capture_output=True, text=True,
                                          env=self.env(), timeout=300)
                    said = (done.stderr or done.stdout).replace(self.where, "<run>").strip()
                    if done.returncode != 0 and "avra cache check:" not in said:
                        # no `cache check` in this compiler: the harness can't hold the store at all
                        raise HarnessFailed(f"`avra cache check` isn't this compiler's: {said[:200]}")
                    if done.returncode != 0:
                        out.append(said)
        return out

    def computed(self, pkg):
        """How many answers a check of `pkg` worked out, inputs aside; None where it didn't say."""
        done = subprocess.run([self.compiler, "check", "--counts", os.path.join(self.where, pkg)],
                              capture_output=True, text=True, env=self.env(), timeout=900)
        found = re.findall(r"\bqueries_computed=(\d+)", done.stdout + done.stderr)
        return int(found[-1]) if found else None

    def fresh_failure(self, warm):
        """A FRESH COPY BUILDS AS THE TREE DOES: the tree's sources copied beside it, no store of
        their own, built over the same machine store — what any answer this run kept there under the
        tree's keys is read by. Said where its exit or what it prints isn't the warm build's."""
        fresh = os.path.join(self.where, "fresh")
        shutil.rmtree(fresh, ignore_errors=True)
        for p in [p for p in self.fixture.stored if "/" not in p]:
            shutil.copytree(os.path.join(self.where, p), os.path.join(fresh, p),
                            ignore=shutil.ignore_patterns(".avra-cache", "main", "*.o"))
        copy = Run(self.compiler, fresh, self.fixture)
        copy.machine, copy.trips = self.machine, self.trips
        try:
            got = copy.built()
        finally:
            shutil.rmtree(fresh, ignore_errors=True)
        for field in ("exit", "printed"):
            if got[field] != warm[field]:
                return f"a fresh copy over the same machine store differs in its {field}: copy {got[field]!r:.200} tree {warm[field]!r:.200} {got['words'][-300:]!r}"
        return None

    def work_failure(self, beside):
        """NOTHING MOVED, NOTHING WORKED: the main package checked, then — for a save beside the
        sources — its neighbour checked on its own, its store written beside its files; then the main
        package checked again, which works nothing out, since no source moved. Said where it does."""
        main, neighbour = self.fixture.main, self.fixture.neighbour
        self.computed(main)
        if beside:
            self.computed(neighbour)
        again = self.computed(main)
        if again:
            said = f"after a save beside {neighbour}'s sources" if beside else "checked again with nothing moved"
            return f"{main} {said} worked {again} answer(s) out again"
        return None

    def walk_trips(self):
        return open(self.trips).read().strip() if os.path.exists(self.trips) else ""


def step_failure(run, warm, moved, kind, cold):
    """The first oracle a step breaks, said; none where it holds them all."""
    for field in ("exit", "words", "product", "printed"):
        if warm[field] != cold[field]:
            return f"warm != cold in its {field}: warm {warm[field]!r:.300} cold {cold[field]!r:.300}"
    trips = run.walk_trips()
    if trips:
        return f"the frontier walk tripped: {trips[:300]}"
    faults = run.store_faults()
    if faults:
        return f"the store holds what no write may leave: {faults[0][:400]}"
    return None


def ran(compiler, seed, ops, keep=False, fixture=None):
    """The sequence run from a fresh tree: the step that failed and how, or None."""
    where = tempfile.mkdtemp(prefix=f"avra-store-fuzz-{seed}-")
    try:
        fixture = fixture or PACKAGES
        run = Run(compiler, where, fixture)
        m0 = fixture.initial(seed)
        fixture.written(m0, where)
        first = run.built()
        if first["exit"] != 0:
            return (-1, f"the first cold build failed: {first['words'][-400:]}")
        try:
            return stepped(run, fixture, seed, ops, where)
        except HarnessFailed as e:
            return (-1, str(e))
    finally:
        if not keep:
            shutil.rmtree(where, ignore_errors=True)


def stepped(run, fixture, seed, ops, where):
    """Each step of the sequence built and held to the invariants: the step that failed and how, or
    None."""
    for m, moved, kind, index in replayed(seed, ops, fixture):
        fixture.written(m, where)
        warm = run.built()
        cold = run.cold()
        failed = (step_failure(run, warm, moved, kind, cold) or run.fresh_failure(warm) or
                  run.work_failure(kind == "beside"))
        if failed:
            return (index, f"{kind}: {failed}")
    return None


def drawn(seed, steps, fixture=None):
    fixture = fixture or PACKAGES
    rng = random.Random(seed)
    kinds = [k for k in fixture.kinds for _ in range(fixture.weights[k])]
    return [(rng.choice(kinds), rng.randint(1, 10**6)) for _ in range(steps)]


def shrunk(compiler, seed, ops, failing_at, fixture=None):
    """The fewest ops that still fail, by ddmin: chunks dropped while the sequence still fails."""
    ops = ops[:failing_at + 1]
    n = 2
    while len(ops) >= 2:
        chunk = max(1, len(ops) // n)
        dropped = False
        for start in range(0, len(ops), chunk):
            trial = ops[:start] + ops[start + chunk:]
            if trial and ran(compiler, seed, trial, fixture=fixture) is not None:
                ops, n, dropped = trial, max(n - 1, 2), True
                break
        if not dropped:
            if chunk == 1:
                break
            n = min(len(ops), n * 2)
    return ops


def said(seed, ops):
    return f"seed={seed} ops=" + ",".join(f"{k}:{s}" for k, s in ops)


def parsed(line):
    seed = int(re.search(r"seed=(\d+)", line).group(1))
    ops = [(k, int(s)) for k, s in (p.split(":") for p in re.search(r"ops=(\S*)", line).group(1).split(",") if p)]
    return seed, ops


def selftest():
    """The model holds its own laws, with no compiler: every model a sequence makes is a program
    whose calls resolve, lib never reads app, no fn calls itself through another, a dropped op
    still replays, and a said sequence parses back."""
    for seed in range(1, 40):
        ops = drawn(seed, 30)
        for m, moved, kind, _ in replayed(seed, ops):
            names = {f.name for _, f in m.all_fns()}
            for k, f in m.all_fns():
                for c in m.callees(f):
                    assert c in names, f"seed {seed}: {f.name} calls {c}, which no file holds"
                    ck, _ = m.where(c)
                    assert m.may_call(k, ck), f"seed {seed}: lib's {f.name} reads app's {c}"
                assert not any(m.reaches(c, f.name) for c in m.callees(f)), f"seed {seed}: {f.name} goes round"
            assert all(r in names for r in m.roots), f"seed {seed}: a root no file holds"
            for key in m.files:
                source_of(m, key)
        assert replayed(seed, ops[1:]) is not None
        assert parsed(said(seed, ops)) == (seed, ops)
    print("store_fuzz: self-test passed — 39 seeds of 30 ops, every model a program that resolves")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--compiler", default=os.path.join(ROOT, "build", "avra"))
    ap.add_argument("--seeds", default="1-4")
    ap.add_argument("--steps", type=int, default=10)
    ap.add_argument("--replay")
    ap.add_argument("--no-shrink", action="store_true")
    ap.add_argument("--self-test", action="store_true")
    ap.add_argument("--fixture", choices=sorted(FIXTURES), default="packages")
    a = ap.parse_args()
    fixture = FIXTURES[a.fixture]
    if a.self_test:
        return selftest()
    if a.replay:
        seed, ops = parsed(a.replay)
        failed = ran(a.compiler, seed, ops, keep=True, fixture=fixture)
        print(f"store_fuzz: {said(seed, ops)} — " + ("holds" if failed is None else f"fails at step {failed[0] + 1}: {failed[1]}"))
        sys.exit(0 if failed is None else 1)
    lo, _, hi = a.seeds.partition("-")
    seeds = range(int(lo), int(hi or lo) + 1)
    bad = 0
    broken = 0
    for seed in seeds:
        ops = drawn(seed, a.steps, fixture)
        failed = ran(a.compiler, seed, ops, fixture=fixture)
        if failed is None:
            print(f"store_fuzz: seed {seed}, {a.steps} steps — holds")
            continue
        at, why = failed
        if at < 0:
            # the fixture didn't build, or the compiler can't check a store: the harness's fault, never a find
            broken += 1
            print(f"store_fuzz: seed {seed} — the harness failed: {why}")
            continue
        bad += 1
        least = ops[:at + 1] if a.no_shrink else shrunk(a.compiler, seed, ops, at, fixture)
        print(f"store_fuzz: seed {seed} FAILS at step {at + 1}: {why}")
        print(f"store_fuzz:   shrunk to {len(least)} op(s), replay with --fixture {a.fixture} --replay '{said(seed, least)}'")
    sys.exit(2 if broken else 1 if bad else 0)


# ---- the board ------------------------------------------------------------------------------
# THE UI BOARD AS A FIXTURE: tools/ui-board, its hydrate main as its main, as a dev loop edits it —
# a fn appended to the board's file, one taken away, a declaration half typed (a detour, as ever), a
# revert, and a save beside its sources (its model package checked on its own).

BOARD = os.path.join(ROOT, "tools", "ui-board")


class BoardModel:
    def __init__(self):
        self.added, self.serial, self.broken = [], 0, None

    def copy(self):
        m = BoardModel()
        m.added, m.serial, m.broken = list(self.added), self.serial, self.broken
        return m


def board_initial(_seed):
    return BoardModel()


def board_apply(m, op):
    kind, seed = op
    rng = random.Random(seed * 7919 + len(kind))
    m = m.copy()
    m.broken = None
    if kind == "add":
        m.serial += 1
        m.added.append(f"fn added_{m.serial}() -> int {{ {rng.randint(1, 99)} }}")
        return m, True
    if kind == "delete" and m.added:
        m.added.pop(rng.randrange(len(m.added)))
        return m, True
    if kind == "broken":
        m.broken = True
        return m, True
    return m, False


def board_written(m, where):
    """The board laid at `where/board`: copied once, its hydrate main its main, then its file as the
    model says."""
    board = os.path.join(where, "board")
    if not os.path.exists(board):
        shutil.copytree(BOARD, board, ignore=shutil.ignore_patterns(".avra-cache", "node_modules"))
        shutil.copy(os.path.join(board, "hydrate", "main.av"), os.path.join(board, "src", "main.av"))
        shutil.copy(os.path.join(board, "src", "board.av"), os.path.join(where, "board.av.orig"))
    text = open(os.path.join(where, "board.av.orig")).read()
    text += "".join(f"\n{f}\n" for f in m.added)
    if m.broken:
        text += "\nfn half_typed( {\n"
    path = os.path.join(board, "src", "board.av")
    if open(path).read() != text:
        with open(path, "w") as out:
            out.write(text)


class Fixture:
    def __init__(self, initial, apply, written, kinds, weights, main, neighbour, stored):
        self.initial, self.apply, self.written = initial, apply, written
        self.kinds, self.weights = kinds, weights
        self.main, self.neighbour, self.stored = main, neighbour, stored


PACKAGES = Fixture(initial, apply, written, KINDS, WEIGHTS, "app", "lib", ["app", "lib"])
BOARD_FIXTURE = Fixture(board_initial, board_apply, board_written, ["add", "delete", "broken", "revert", "beside"],
                        {"add": 3, "delete": 2, "broken": 3, "revert": 2, "beside": 1}, "board", "board/model",
                        ["board", "board/model"])
FIXTURES = {"packages": PACKAGES, "board": BOARD_FIXTURE}


if __name__ == "__main__":
    main()
