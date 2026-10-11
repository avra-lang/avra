#!/usr/bin/env python3
"""THE CI STRUCTURE RATCHET: the invariants a green pull request could
otherwise break SILENTLY, held before it can merge.

A PR that removes the release fetch, reorders it after the build, or drops
a compiler-free keeper from the PR path is green on its own diff and only
fails a train — one train later, on someone else's change. Each check here
reads the SHAPE of `.github/workflows/checks.yml` and the Makefile's keeper
lists and refuses by name:

  release-order    the train's compiler comes from the release asset BEFORE
                   it is built, and the build runs only where the fetch
                   MISSED. A ref-scoped cache cannot cross merge refs, so
                   without this every train rebuilt the compiler (7–16 min).
  keeper-coverage  every keeper in `KEEPERS_STATIC` is invoked by a job the
                   `pull_request` event reaches, and every `*-static` target
                   is too — the pattern #543 and #551 added per keeper, so a
                   compiler-free keeper can never be silently PR-skipped.
  watcher-fixtures `tools/pr_watcher.py --self-test` is run by a keeper, so
                   a change to the watcher's decision refuses on the PR, not
                   one schedule pass later.
  warm-edit        WHERE the DB 07 warm-edit gate exists (Makefile target
                   `warm-edit`), it is one of `KEEPERS` and its measurement
                   skips with a word on a cold store — a claim with no gate
                   measured nothing. Absent, this check says so and passes.

SCOPE, STATED PLAINLY: this holds the STRUCTURE, never a keeper's inputs.
It cannot know that a diff touches a compiler-needing keeper's inputs, so
it does not claim to; what it guarantees is that the compiler-free floor
runs on every PR, and that the release path and the watcher's fixtures are
wired wherever the workflow stands. A keeper added to the train alone is a
review question, not a silent skip.

`--self-test` proves each rule against fixtures, no tree read.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAKEFILE = os.path.join(ROOT, "Makefile")
CHECKS = os.path.join(ROOT, ".github", "workflows", "checks.yml")

ALL_EVENTS = {"pull_request", "merge_group", "push", "workflow_dispatch"}


# ── reading the Makefile ─────────────────────────────────────────────────
def parse_make_vars(text):
    """`NAME = …` with backslash continuations -> {NAME: raw}."""
    vals = {}
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)\s*[:+?]?=\s*(.*)$", lines[i])
        if not m:
            i += 1
            continue
        name, rest = m.group(1), m.group(2)
        while rest.rstrip().endswith("\\") and i + 1 < len(lines):
            rest = rest.rstrip()[:-1] + " " + lines[i + 1]
            i += 1
        vals[name] = rest
        i += 1
    return vals


def _expand(vals, raw, seen):
    def repl(m):
        n = m.group(1)
        if n in seen:
            return ""
        return _expand(vals, vals.get(n, ""), seen | {n})

    return re.sub(r"\$\(([A-Za-z_][A-Za-z0-9_]*)\)", repl, raw)


def keeper_lists(text):
    """The Makefile's `KEEPERS*` variables, `$(…)` references expanded."""
    vals = parse_make_vars(text)
    out = {}
    for name, raw in vals.items():
        if not name.startswith("KEEPERS"):
            continue
        out[name] = set(_expand(vals, raw, {name}).split())
    return out


def make_targets(text):
    """{target: recipe text} — a target line, then its tab-indented recipe."""
    targets = {}
    cur = None
    for line in text.splitlines():
        m = re.match(r"^([A-Za-z0-9_.-]+)\s*:(?!=)", line)
        if m:
            cur = m.group(1)
            targets.setdefault(cur, "")
            continue
        if cur is not None and line.startswith("\t"):
            targets[cur] += line + "\n"
        elif line and not line[0].isspace():
            cur = None
    return targets


# ── reading the workflow ─────────────────────────────────────────────────
def parse_jobs(text):
    """The `jobs:` mapping -> {job: block text}, by the 2-space job names."""
    jobs, cur, started = {}, None, False
    for line in text.splitlines():
        if re.match(r"^jobs:\s*$", line):
            started = True
            continue
        if not started:
            continue
        m = re.match(r"^  ([A-Za-z0-9_-]+):\s*$", line)
        if m:
            cur = m.group(1)
            jobs[cur] = []
            continue
        if cur is not None:
            jobs[cur].append(line)
    return {k: "\n".join(v) for k, v in jobs.items()}


def job_events(block):
    """The events a job's `if:` permits. No `if`, or an `if` that names no
    `github.event_name`, is every event the workflow fires on."""
    m = re.search(r"^    if:\s*(.+)$", block, re.M)
    if not m or "github.event_name" not in m.group(1):
        return set(ALL_EVENTS)
    cond = m.group(1)
    ev = {e for e in ALL_EVENTS if "github.event_name == '%s'" % e in cond}
    if "github.event_name != 'push'" in cond:
        ev |= {"pull_request", "merge_group", "workflow_dispatch"}
    return ev


def invoked_targets(block):
    """Every `make` target a job's run steps name, flags and assignments
    skipped. A comment line is not a step."""
    found = set()
    for line in block.splitlines():
        if line.lstrip().startswith("#"):
            continue
        for m in re.finditer(r"\bmake\b(.*)", line):
            rest = re.split(r"[;&|]", m.group(1))[0]
            for tok in rest.split():
                if tok.startswith("-"):
                    continue
                if re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", tok):
                    continue
                if re.match(r"^[A-Za-z0-9_.-]+$", tok):
                    found.add(tok)
    return found


def parse_steps(block):
    """A job's `steps:` list items (6-space `- `), split and kept whole."""
    if "\n      - " not in block:
        return []
    return block.split("\n      - ")[1:]


def step_if(item):
    """A step's own `if:`, read from its first line (a run block's `if`s
    live deeper and are not the step's)."""
    m = re.match(r"if:\s*(.+)", item.splitlines()[0])
    return m.group(1) if m else None


# ── the checks (pure; the fixtures prove them) ───────────────────────────
def check_release_order(jobs):
    """The prepare job fetches the release compiler BEFORE building, and
    builds only where the fetch missed. Answers (refusals, words)."""
    prepare = jobs.get("prepare", "")
    steps = parse_steps(prepare)
    fetch = next((i for i, s in enumerate(steps) if "compiler_release.py fetch" in s), None)
    build = next((i for i, s in enumerate(steps) if "make -s avra" in s or "make -s bootstrap" in s), None)
    if fetch is None:
        return ["no `prepare` step fetches the compiler from the release asset"], []
    if build is None:
        return ["no `prepare` step builds the compiler"], []
    if fetch > build:
        return ["the compiler is built (step %d) BEFORE the release fetch (step %d)"
                % (build, fetch)], []
    cond = step_if(steps[build]) or ""
    if "steps.release.outputs.hit" not in cond:
        return ["the compiler-build step is not conditional on the release fetch having MISSED"], []
    return [], ["release-order: fetch before build, build conditional on the fetch miss"]


def check_keeper_coverage(make_text, workflow_text):
    """Every KEEPERS_STATIC member is invoked by a pull_request job, and
    every `*-static` target is too. Answers (refusals, words)."""
    lists = keeper_lists(make_text)
    keepers = lists.get("KEEPERS", set())
    static = lists.get("KEEPERS_STATIC", set())
    make_pr = lists.get("KEEPERS_PR", set())
    targets = make_targets(make_text)
    refusals = []
    for name in ("KEEPERS_STATIC", "KEEPERS_PR"):
        missing = lists.get(name, set()) - keepers
        if missing:
            refusals.append("%s names %s, which is not in KEEPERS — the train would not hold it"
                            % (name, ", ".join(sorted(missing))))
    for k in sorted(static):
        if k not in targets:
            refusals.append("KEEPERS_STATIC names `%s`, which is no Makefile target" % k)

    jobs = parse_jobs(workflow_text)
    groups = {
        "keepers": keepers,
        "keepers-a": lists.get("KEEPERS_A", set()),
        "keepers-b": lists.get("KEEPERS_B", set()),
        "keepers-alone": lists.get("KEEPERS_ALONE", set()),
        "keepers-static": static,
        "keepers-pr": make_pr,
    }
    pr_reached, pr_targets = set(), set()
    for block in jobs.values():
        if "pull_request" not in job_events(block):
            continue
        named = invoked_targets(block)
        pr_targets |= named
        for t in named:
            if t in groups:
                pr_reached |= groups[t]
            elif t in keepers:
                pr_reached.add(t)

    skipped = static - pr_reached
    if skipped:
        refusals.append("no pull_request job runs %s — a compiler-free keeper is silently PR-skipped"
                        % ", ".join(sorted(skipped)))
    static_targets = {t for t in targets if t.endswith("-static")}
    for t in sorted(static_targets - pr_targets):
        refusals.append("`make %s` is a compiler-free half no pull_request job runs" % t)
    if not refusals:
        return [], ["keeper-coverage: %d compiler-free keeper(s) reachable on a PR, %d `-static` target(s)"
                    % (len(static & pr_reached), len(static_targets & pr_targets))]
    return refusals, []


def check_watcher_wired(make_text):
    """`tools/pr_watcher.py --self-test` runs in a keeper. Answers
    (refusals, words)."""
    keepers = keeper_lists(make_text).get("KEEPERS", set())
    for name, recipe in make_targets(make_text).items():
        if name in keepers and "tools/pr_watcher.py --self-test" in recipe:
            return [], ["watcher-fixtures: `make %s` runs the watcher's self-test" % name]
    return ["no keeper runs `python3 tools/pr_watcher.py --self-test` — the watcher's "
            "decision is guarded by nothing the gate holds"], []


def check_warm_edit(make_text, bench=None, ratchet=None):
    """WHERE the DB 07 warm-edit gate exists: its target is a keeper, its
    measurement is judged, and a cold store SKIPS WITH A WORD. Absent, this
    says so and passes. `bench`/`ratchet` default to the tree's; a fixture
    passes its own, so the rule never reads the tree it is proving."""
    if bench is None:
        bench = os.path.join(ROOT, "tools", "warm_edit_bench.sh")
    if ratchet is None:
        ratchet = os.path.join(ROOT, "tools", "speed_ratchet.py")
    targets = make_targets(make_text)
    if "warm-edit" not in targets:
        return [], ["warm-edit: no `warm-edit` target — the DB 07 gate is not wired here; nothing to guard"]
    keepers = keeper_lists(make_text).get("KEEPERS", set())
    refusals = []
    if "warm-edit" not in keepers:
        refusals.append("`warm-edit` is a Makefile target but not one of KEEPERS — the train would not hold it")
    if "speed_ratchet.py --self-test" not in targets["warm-edit"]:
        refusals.append("`make warm-edit` does not run `tools/speed_ratchet.py --self-test` before it measures")
    if not os.path.isfile(bench):
        refusals.append("`warm-edit` is wired but tools/warm_edit_bench.sh does not exist")
    elif "skip cold-store" not in open(bench, encoding="utf-8").read():
        refusals.append("tools/warm_edit_bench.sh does not SKIP WITH A WORD on a cold store "
                        "(no `skip cold-store`) — it could silently pass an unmeasured claim")
    if not os.path.isfile(ratchet):
        refusals.append("`warm-edit` is wired but tools/speed_ratchet.py does not exist")
    else:
        text = open(ratchet, encoding="utf-8").read()
        if "--warm" not in text or "skip cold-store" not in text:
            refusals.append("tools/speed_ratchet.py does not judge `--warm` and honour "
                            "the cold-store skip word")
    if not refusals:
        return [], ["warm-edit: `make warm-edit` is a keeper, self-tested, and a cold store skips with a word"]
    return refusals, []


def run(make_text=None, workflow_text=None):
    """Every check over the real tree. Answers the number of refusals."""
    if make_text is None:
        make_text = open(MAKEFILE, encoding="utf-8").read()
    if workflow_text is None:
        workflow_text = open(CHECKS, encoding="utf-8").read()
    refusals, words = [], []
    for check in (lambda: check_release_order(parse_jobs(workflow_text)),
                  lambda: check_keeper_coverage(make_text, workflow_text),
                  lambda: check_watcher_wired(make_text),
                  lambda: check_warm_edit(make_text)):
        r, w = check()
        refusals += r
        words += w
    for w in words:
        print("ci-invariants: %s" % w)
    if refusals:
        print("ci-invariants: REFUSED — %d structural invariant(s) broken:" % len(refusals))
        for r in refusals:
            print("ci-invariants:   %s" % r)
        return 1
    print("ci-invariants: clean — %d invariant(s) hold" % len(words))
    return 0


# ── the rules on fixtures, no tree read ──────────────────────────────────
def self_test():
    # a minimal workflow with one prepare job: the fetch, then the build.
    def prepare(fetch_if, build_if):
        return """name: checks
on: [pull_request]
jobs:
  prepare:
    outputs:
      build: x
    steps:
      - uses: actions/checkout@v4
      - if: %s
        id: release
        name: compiler from release
        run: python3 tools/compiler_release.py fetch key build/avra
      - if: %s
        name: compiler
        run: make -s avra
""" % (fetch_if, build_if)

    good = prepare("steps.plan.outputs.build == '1'",
                   "steps.plan.outputs.build == '1' && steps.cache.outputs.cache-hit != 'true' "
                   "&& steps.release.outputs.hit != 'true'")
    assert check_release_order(parse_jobs(good))[0] == [], check_release_order(parse_jobs(good))
    # the build WITHOUT the release-miss condition is refused
    bad_cond = prepare("steps.plan.outputs.build == '1'", "steps.plan.outputs.build == '1'")
    assert any("MISSED" in r for r in check_release_order(parse_jobs(bad_cond))[0]), \
        check_release_order(parse_jobs(bad_cond))
    # a build BEFORE the fetch is refused
    order = """jobs:
  prepare:
    steps:
      - if: x
        name: compiler
        run: make -s avra
      - if: y
        id: release
        run: python3 tools/compiler_release.py fetch key build/avra
"""
    assert any("BEFORE" in r for r in check_release_order(parse_jobs(order))[0]), \
        check_release_order(parse_jobs(order))
    # no fetch at all is refused
    nofetch = """jobs:
  prepare:
    steps:
      - name: compiler
        run: make -s avra
"""
    assert any("release asset" in r for r in check_release_order(parse_jobs(nofetch))[0]), \
        check_release_order(parse_jobs(nofetch))

    # ── keeper coverage ──
    make = """KEEPERS_ALONE = runtime-tests
KEEPERS_A = heavy
KEEPERS_B = fingerprints vocab rt-header
KEEPERS = clock-holds $(KEEPERS_ALONE) $(KEEPERS_A) $(KEEPERS_B)
KEEPERS_STATIC = fingerprints vocab
KEEPERS_PR = rt-header
heavy:
\t@true
fingerprints:
\t@true
vocab:
\t@true
clock-holds:
\t@true
runtime-tests:
\t@true
rt-header:
\t@true
"""
    cover = """jobs:
  prepare:
    steps:
      - run: make -s keepers-static
  train:
    if: github.event_name == 'merge_group'
    steps:
      - run: make -s keepers-a
"""
    assert check_keeper_coverage(make, cover)[0] == [], check_keeper_coverage(make, cover)
    # a compiler-free keeper no PR job runs is refused, and named
    bare = """jobs:
  prepare:
    steps:
      - run: echo hi
  train:
    if: github.event_name == 'merge_group'
    steps:
      - run: make -s keepers-a
"""
    r = check_keeper_coverage(make, bare)[0]
    assert any("fingerprints" in x and "vocab" in x for x in r), r
    # a keeper named in KEEPERS_STATIC but not in KEEPERS is refused
    misdeclared = make.replace("KEEPERS_STATIC = fingerprints vocab",
                               "KEEPERS_STATIC = fingerprints vocab ghost")
    misdeclared += "ghost:\n\t@true\n"
    assert any("ghost" in x for x in check_keeper_coverage(misdeclared, cover)[0]), \
        check_keeper_coverage(misdeclared, cover)
    # a `-static` target no PR job runs is refused
    static_target = make + "codecs-static:\n\t@python3 tools/codecs.py\n"
    assert any("codecs-static" in x for x in check_keeper_coverage(static_target, cover)[0]), \
        check_keeper_coverage(static_target, cover)

    # ── watcher wiring ──
    wired = make + "pr-watcher:\n\t@python3 tools/pr_watcher.py --self-test\n"
    wired = wired.replace("KEEPERS_B = fingerprints vocab rt-header",
                          "KEEPERS_B = fingerprints vocab rt-header pr-watcher")
    assert check_watcher_wired(wired)[0] == [], check_watcher_wired(wired)
    assert check_watcher_wired(make)[0], "an unwired watcher must be refused"

    # ── warm-edit: absent is a spoken pass; a wired one is held, and the
    # fixture brings its own bench and ratchet so the rule never reads the
    # tree it is proving ──
    assert check_warm_edit(make)[0] == [] and check_warm_edit(make)[1], check_warm_edit(make)
    import tempfile
    with tempfile.TemporaryDirectory() as d:
        good_bench = os.path.join(d, "bench.sh")
        good_ratchet = os.path.join(d, "ratchet.py")
        open(good_bench, "w").write('echo "skip cold-store"\n')
        open(good_ratchet, "w").write('print("--warm skip cold-store")\n')
        good = (make.replace("KEEPERS_B = fingerprints vocab rt-header",
                             "KEEPERS_B = fingerprints vocab rt-header warm-edit")
                + "warm-edit:\n\t@python3 tools/speed_ratchet.py --self-test\n\t@sh tools/warm_edit_bench.sh\n")
        assert check_warm_edit(good, good_bench, good_ratchet)[0] == [], \
            check_warm_edit(good, good_bench, good_ratchet)
        # the target exists but is not a keeper: refused
        bad = make + "warm-edit:\n\t@sh tools/warm_edit_bench.sh\n"
        assert any("KEEPERS" in x for x in check_warm_edit(bad, good_bench, good_ratchet)[0]), \
            check_warm_edit(bad, good_bench, good_ratchet)
        # a bench with no skip word is refused
        silent = os.path.join(d, "silent.sh")
        open(silent, "w").write('echo measured\n')
        assert any("SKIP WITH A WORD" in x for x in check_warm_edit(good, silent, good_ratchet)[0]), \
            check_warm_edit(good, silent, good_ratchet)
        # a missing bench, once the target is a keeper, is refused
        assert any("does not exist" in x for x in
                   check_warm_edit(good, os.path.join(d, "nope.sh"), good_ratchet)[0]), \
            check_warm_edit(good, os.path.join(d, "nope.sh"), good_ratchet)
        # a ratchet that does not judge --warm is refused
        assert any("--warm" in x for x in check_warm_edit(good, good_bench, good_bench)[0]), \
            check_warm_edit(good, good_bench, good_bench)

    print("ci_invariants self-test: release-order, keeper-coverage, watcher-fixtures, "
          "warm-edit held on fixtures")
    return 0


def main(argv):
    if "--self-test" in argv:
        return self_test()
    return run()


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
