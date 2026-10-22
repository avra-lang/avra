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
  light-draft      a draft's run is the light gate: only the jobs in LIGHT_JOBS
                   run unconditionally; every other leg the `test` aggregate
                   owes names `needs.prepare.outputs.full` in its `if:`, and
                   the aggregate refuses a light run by name.
  run-mode         a PR's run mode is read from the API at run time (tools/pr_mode.py),
                   never from the event payload; a light run whose compiler is not
                   the published one skips the gate and says so.
  compiler-route   a Sprite run's prep installs a published compiler (or the merge-base's)
                   before it builds one: the route rides the wire, the build branch
                   comes last, and a merge-base compiler too old to read the tree
                   falls back to the seed (`make bootstrap`).
  path-gate        `runtime-keep` and `layout-oracle` run on a PR only when prepare's path gate
                   (tools/ci_path_gate.py) says a path it reads changed; main's
                   push and a hand-run owe it always.
  race-split       a `labeled` run never shares its concurrency group with the other
                   pull_request runs, so the label and the open of one PR cannot
                   cancel each other; the run mode is read at run time, so the
                   runs that remain give one verdict.
  dup-run          a `labeled` run waits for the full run on its head and mirrors its verdict;
                   it never runs a second gate beside it (tools/ci_dup_run.py).
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
    build = next((i for i, s in enumerate(steps) if any(m in s for m in ("make -s avra", "make -s bootstrap", "make -s compiler"))), None)
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


# The legs a draft's light run still owes: the compiler (`prepare`), the
# compiler-free keepers, the changed-file gate and the codecs scan.
LIGHT_JOBS = ("prepare", "keepers-static", "gate", "codecs", "test")


GATED = (("runtime-keep", "runtime_keep"), ("layout-oracle", "layout_oracle"))


def check_path_gate(workflow_text):
    """Each path-gated job is conditioned on prepare's path-gate output, and that
    output is the path gate's own decision. Answers (refusals, words)."""
    jobs = parse_jobs(workflow_text)
    refusals = []
    for job, output in GATED:
        cond = re.search(r"^    if:\s*(.+)$", jobs.get(job, ""), re.M)
        if not cond or "needs.prepare.outputs.%s == '1'" % output not in cond.group(1):
            refusals.append("`%s` is not gated on `needs.prepare.outputs.%s`" % (job, output))
        if "tools/ci_path_gate.py %s" % job not in jobs.get("prepare", ""):
            refusals.append("`prepare` does not ask tools/ci_path_gate.py whether %s is owed" % job)
    if refusals:
        return refusals, []
    return [], ["path-gate: %s run on the path gate's decision" % ", ".join(job for job, _ in GATED)]


def check_race_split(workflow_text):
    """The concurrency group separates `labeled` runs from the others, and the
    run mode is read at run time. Answers (refusals, words)."""
    m = re.search(r"^concurrency:\s*\n\s*group: (.+)$", workflow_text, re.M)
    refusals = []
    if not m:
        refusals.append("the workflow names no concurrency group")
    elif "github.event.action == 'labeled'" not in m.group(1):
        refusals.append("the concurrency group does not split `labeled` runs: a label and an open cancel each other")
    if "tools/pr_mode.py" not in workflow_text:
        refusals.append("the run mode is not read at run time")
    if refusals:
        return refusals, []
    return [], ["race-split: a labeled run has its own concurrency group"]


def check_dup_run(workflow_text):
    """The labeled run asks tools/ci_dup_run.py for the verdict and mirrors it, and
    the test job's light and verdict steps stand down for a mirror. Answers (refusals, words)."""
    jobs = parse_jobs(workflow_text)
    refusals = []
    if "tools/ci_dup_run.py" not in jobs.get("prepare", ""):
        refusals.append("`prepare` does not ask tools/ci_dup_run.py whether a labeled run owes the gate")
    if "mirror: ${{ steps.plan.outputs.mirror }}" not in jobs.get("prepare", ""):
        refusals.append("`prepare` does not expose the mirror verdict")
    test = jobs.get("test", "")
    if "needs.prepare.outputs.mirror != ''" not in test:
        refusals.append("`test` does not mirror another run's verdict")
    if "needs.prepare.outputs.full == '0' && needs.prepare.outputs.mirror == ''" not in test:
        refusals.append("`test` names a light draft beside a mirrored verdict")
    if refusals:
        return refusals, []
    return [], ["dup-run: a labeled run mirrors the full run on its head"]


def check_ready_race(pr_mode_mod):
    """#701's race: a PR readied while its update runs. Its mode is the PR's state at
    run time, so the ready run and the synchronize run both read full. Answers (refusals, words)."""
    refusals = []
    if pr_mode_mod.mode('{"draft": false, "labels": []}') != "full":
        refusals.append("a readied PR is not read as full, so a run queued before the ready event would stay light")
    if pr_mode_mod.mode('{"draft": true, "labels": []}') != "light":
        refusals.append("a draft without the label is not read as light")
    if refusals:
        return refusals, []
    return [], ["ready-race: a readied PR's run is full whichever event started it"]


def check_run_mode(workflow_text):
    """The run mode is decided by tools/pr_mode.py on the PR's API answer, not by
    the event payload, and a light gate on an unpublished compiler is skipped.
    Answers (refusals, words)."""
    jobs = parse_jobs(workflow_text)
    refusals = []
    plan = jobs.get("prepare", "")
    if "tools/pr_mode.py" not in plan:
        refusals.append("`prepare` does not read the PR's mode through tools/pr_mode.py")
    if "github.event.pull_request.draft" in plan:
        refusals.append("`prepare` decides the run mode from the event payload's draft flag")
    if "compiler_source: ${{ steps.release.outputs.source }}" not in plan:
        refusals.append("`prepare` does not expose the compiler's source")
    gate = jobs.get("gate", "")
    if "needs.prepare.outputs.compiler_source == 'latest'" not in gate:
        refusals.append("`gate` runs on a light run whose compiler is not the published one")
    if "light gate: compiler steps skipped" not in jobs.get("test", ""):
        refusals.append("`test` does not say why a light gate's compiler steps were skipped")
    if refusals:
        return refusals, []
    return [], ["run-mode: the PR's mode is read from the API; the light gate skips an unpublished compiler"]
def check_compiler_route(work_text, remote_text):
    """The run's compiler route rides the wire, the Sprite's prep takes a
    published compiler before it builds one, and a merge-base compiler too old
    to read the tree falls back to the seed. Answers (refusals, words)."""
    refusals = []
    if 'wire="$wire@$route"' not in work_text or "compiler_route" not in work_text:
        refusals.append("`tools/work run` does not put the compiler route on the wire")
    published = remote_text.find('"${route%%:*}" = published')
    merged = remote_text.find('"${route%%:*}" = mergebase')
    build = remote_text.find("building this tree's compiler")
    seed = remote_text.find("bootstrapped from the seed")
    if min(published, merged) < 0:
        refusals.append("the Sprite's prep does not install a published compiler for a route")
    elif build < 0 or build < max(published, merged):
        refusals.append("the Sprite's prep builds before it tries the published compiler")
    if merged >= 0 and (seed < merged or (build >= 0 and seed > build)):
        refusals.append("a merge-base compiler that cannot read the tree does not fall back to the seed")
    if refusals:
        return refusals, []
    return [], ["compiler-route: a published compiler is installed before a build; a merge-base miss falls back to the seed"]


def check_hold_label(auto_merge_text):
    """auto-merge.yml honours the `hold` label as it honours the DO NOT MERGE title: it reads the
    labels fresh from the PR (not the event payload), runs again when a label is added, and a held
    PR is disarmed. Answers (refusals, words)."""
    bad = []
    if not re.search(r"types:\s*\[[^\]]*\blabeled\b", auto_merge_text):
        bad.append("auto-merge.yml does not run on `labeled`, so a label added after creation never disarms")
    if "gh pr view" not in auto_merge_text or "labels" not in auto_merge_text or "' hold '" not in auto_merge_text:
        bad.append("auto-merge.yml does not read the PR's `hold` label fresh")
    if "--disable-auto" not in auto_merge_text:
        bad.append("auto-merge.yml never disarms a held PR")
    if "github.event.pull_request.labels" in auto_merge_text:
        bad.append("auto-merge.yml judges labels from the event payload, which a later label misses")
    return bad, ([] if bad else ["hold-label: auto-merge reads the label fresh, reruns on `labeled`, and disarms"])
def check_ladder(workflow_text):
    """A run's rungs reach the compiler step, and the seed check speaks when they do: `prepare` reads the
    rungs, the compiler step builds them through tools/ladder.sh before HEAD, and `seed-check` says it
    skipped (spoken), never silently. Answers (refusals, words)."""
    jobs = parse_jobs(workflow_text)
    bad = []
    if "steps.rungs.outputs.list" not in jobs.get("prepare", "") or "tools/rungs.sh" not in jobs.get("prepare", ""):
        bad.append("`prepare` does not read the run's rungs (tools/rungs.sh)")
    comp = re.search(r"name: compiler\n        id: compiler\n.*?(?=\n      - |\n  [a-z])", jobs.get("prepare", ""), re.S)
    if not comp or "tools/ladder.sh" not in comp.group(0):
        bad.append("the compiler step does not build a run's rungs through tools/ladder.sh")
    seed = jobs.get("seed-check", "")
    if "needs.prepare.outputs.rungs" not in seed or "SKIPPED, SPOKEN" not in seed:
        bad.append("`seed-check` does not speak when the run carries rungs")
    if "rungs:" not in re.search(r"^    outputs:\n(.*?)^    steps:", jobs.get("prepare", ""), re.S | re.M).group(1):
        bad.append("`prepare` does not expose `rungs` as an output")
    return bad, ([] if bad else ["ladder: rungs are read, built through tools/ladder.sh before HEAD, and the seed check says it skipped"])


def check_light_draft(workflow_text):
    """Every heavy leg `test` owes is gated on the full flag, and `test`
    refuses a light run. Answers (refusals, words)."""
    jobs = parse_jobs(workflow_text)
    owed = re.search(r"^    needs:\s*\[(.*?)\]", jobs.get("test", ""), re.M)
    if not owed:
        return ["the `test` aggregate names no `needs:` list"], []
    refusals = []
    if "outputs.full" not in jobs.get("prepare", "") and "full:" not in jobs.get("prepare", ""):
        refusals.append("`prepare` does not expose the `full` output a light draft is judged by")
    for leg in (n.strip() for n in owed.group(1).split(",")):
        if leg in LIGHT_JOBS:
            continue
        cond = re.search(r"^    if:\s*(.+)$", jobs.get(leg, ""), re.M)
        if not cond or "needs.prepare.outputs.full" not in cond.group(1):
            refusals.append("`%s` is owed by `test` but is not gated on `needs.prepare.outputs.full`" % leg)
    compiler = re.search(r"^      - if: (.+)\n        name: compiler$", jobs.get("prepare", ""), re.M)
    if not compiler or "steps.plan.outputs.full == '1'" not in compiler.group(1):
        refusals.append("`prepare` builds a compiler on a light run the published one could serve")
    if "needs.prepare.outputs.full == '0'" not in jobs.get("test", ""):
        refusals.append("`test` does not refuse a light draft's run")
    if refusals:
        return refusals, []
    heavy = [n for n in (x.strip() for x in owed.group(1).split(",")) if n not in LIGHT_JOBS]
    return [], ["light-draft: %d heavy leg(s) gated on the full flag" % len(heavy)]


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
    measurement is judged, and a run that CANNOT judge FAILS — a skip is
    not a pass, and the only opt-out is the hand-set `WARM_EDIT_SKIP`. Absent,
    this says so and passes. `bench`/`ratchet` default to the tree's; a
    fixture passes its own, so the rule never reads the tree it is proving."""
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
    else:
        text = open(bench, encoding="utf-8").read()
        # A SKIP IS A FAILURE. The bench names the marker the ratchet reads,
        # the one hand-set opt-out, and a named FAILURE; the silent `exit 0`
        # this invariant was written against is exactly the defect it refuses.
        for needle, why in (
            ("skip warm-edit", "the skip marker the ratchet reads (no `skip warm-edit`)"),
            ("WARM_EDIT_SKIP", "the one hand-set opt-out (`WARM_EDIT_SKIP`)"),
            ("FAILURE", "a named FAILURE for a run that cannot judge"),
        ):
            if needle not in text:
                refusals.append("tools/warm_edit_bench.sh has no %s — a run that cannot "
                                "judge could stand green" % why)
    if not os.path.isfile(ratchet):
        refusals.append("`warm-edit` is wired but tools/speed_ratchet.py does not exist")
    else:
        text = open(ratchet, encoding="utf-8").read()
        if "--warm" not in text:
            refusals.append("tools/speed_ratchet.py does not judge `--warm`")
        elif "skip warm-edit" not in text and "skip cold-store" not in text:
            refusals.append("tools/speed_ratchet.py does not refuse the warm-edit skip marker")
    if not refusals:
        return [], ["warm-edit: `make warm-edit` is a keeper, self-tested, and a run that cannot judge "
                    "FAILS (only WARM_EDIT_SKIP stands it down)"]
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
                  lambda: check_light_draft(workflow_text),
                  lambda: check_hold_label(open(os.path.join(ROOT, ".github", "workflows", "auto-merge.yml"), encoding="utf-8").read()),
                  lambda: check_ladder(workflow_text),
                  lambda: check_run_mode(workflow_text),
                  lambda: check_race_split(workflow_text),
                  lambda: check_compiler_route(
                      open(os.path.join(ROOT, "tools", "work"), encoding="utf-8").read(),
                      open(os.path.join(ROOT, "tools", "sprite-remote.sh"), encoding="utf-8").read()),
                  lambda: check_path_gate(workflow_text),
                  lambda: check_dup_run(workflow_text),
                  lambda: check_ready_race(__import__("pr_mode")),
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
        # the shape the law wants: the marker, the one opt-out, a FAILURE
        open(good_bench, "w").write(
            '[ -d .avra-cache ] || { echo "this is a FAILURE"; echo "skip warm-edit"; '
            '[ -z "${WARM_EDIT_SKIP:-}" ] || exit 0; exit 1; }\n')
        open(good_ratchet, "w").write('print("--warm skip warm-edit WARM_EDIT_SKIP")\n')
        good = (make.replace("KEEPERS_B = fingerprints vocab rt-header",
                             "KEEPERS_B = fingerprints vocab rt-header warm-edit")
                + "warm-edit:\n\t@python3 tools/speed_ratchet.py --self-test\n\t@sh tools/warm_edit_bench.sh\n")
        assert check_warm_edit(good, good_bench, good_ratchet)[0] == [], \
            check_warm_edit(good, good_bench, good_ratchet)
        # the target exists but is not a keeper: refused
        bad = make + "warm-edit:\n\t@sh tools/warm_edit_bench.sh\n"
        assert any("KEEPERS" in x for x in check_warm_edit(bad, good_bench, good_ratchet)[0]), \
            check_warm_edit(bad, good_bench, good_ratchet)
        # a bench with no skip marker is refused
        silent = os.path.join(d, "silent.sh")
        open(silent, "w").write('echo measured\n')
        assert any("skip warm-edit" in x for x in check_warm_edit(good, silent, good_ratchet)[0]), \
            check_warm_edit(good, silent, good_ratchet)
        # a bench that names the marker but still exits 0 is the silent pass
        # this invariant exists to refuse: no FAILURE, no opt-out
        green = os.path.join(d, "green.sh")
        open(green, "w").write('echo "skip warm-edit"; exit 0\n')
        assert any("FAILURE" in x for x in check_warm_edit(good, green, good_ratchet)[0]), \
            check_warm_edit(good, green, good_ratchet)
        # a missing bench, once the target is a keeper, is refused
        assert any("does not exist" in x for x in
                   check_warm_edit(good, os.path.join(d, "nope.sh"), good_ratchet)[0]), \
            check_warm_edit(good, os.path.join(d, "nope.sh"), good_ratchet)
        # a ratchet that does not judge --warm is refused
        assert any("--warm" in x for x in check_warm_edit(good, good_bench, good_bench)[0]), \
            check_warm_edit(good, good_bench, good_bench)

    # ── light draft: the real workflow passes; a heavy leg the aggregate owes
    # with no full gate is refused by name; a `test` that never refuses a
    # light run is refused ──
    real = open(CHECKS, encoding="utf-8").read()
    assert check_light_draft(real)[0] == [], check_light_draft(real)
    am = open(os.path.join(ROOT, ".github", "workflows", "auto-merge.yml"), encoding="utf-8").read()
    assert check_hold_label(am)[0] == [], check_hold_label(am)
    assert any("`labeled`" in x for x in check_hold_label(am.replace(", labeled]", "]"))[0])
    assert any("never disarms" in x for x in check_hold_label(am.replace("--disable-auto", ""))[0])
    assert any("payload" in x for x in check_hold_label(am + "\n# ${{ github.event.pull_request.labels }}")[0])
    assert check_ladder(real)[0] == [], check_ladder(real)
    assert any("tools/ladder.sh" in x for x in check_ladder(real.replace("tools/ladder.sh", "tools/other.sh"))[0])
    assert any("seed-check" in x for x in check_ladder(real.replace("SKIPPED, SPOKEN", "skipped"))[0])
    assert any("rungs" in x for x in check_ladder(real.replace("tools/rungs.sh", "tools/none.sh"))[0])
    ungated = real.replace("    if: needs.prepare.outputs.cache == '1' && needs.prepare.outputs.full == '1'",
                           "    if: needs.prepare.outputs.cache == '1'")
    assert ungated != real
    assert any("cache-attacks" in x for x in check_light_draft(ungated)[0]), check_light_draft(ungated)
    silent = real.replace("if: needs.prepare.outputs.full == '0'", "if: false")
    assert any("does not refuse" in x for x in check_light_draft(silent)[0]), check_light_draft(silent)

    # a light run that builds a compiler the published one could serve is refused
    built = real.replace(" && (steps.plan.outputs.full == '1' || steps.release.outputs.source == 'none')", "")
    assert built != real
    assert any("builds a compiler" in x for x in check_light_draft(built)[0]), check_light_draft(built)

    real_wf = open(CHECKS, encoding="utf-8").read()
    assert check_run_mode(real_wf)[0] == [], check_run_mode(real_wf)
    payload = real_wf.replace("tools/pr_mode.py", "tools/mode_by_hand.py")
    assert payload != real_wf
    assert any("tools/pr_mode.py" in x for x in check_run_mode(payload)[0]), check_run_mode(payload)
    ungated_gate = real_wf.replace(" && !(needs.prepare.outputs.full == '0' && needs.prepare.outputs.compiler_source == 'latest')", "")
    assert ungated_gate != real_wf
    assert any("`gate`" in x for x in check_run_mode(ungated_gate)[0]), check_run_mode(ungated_gate)

    real_wf = open(CHECKS, encoding="utf-8").read()
    assert check_path_gate(real_wf)[0] == [], check_path_gate(real_wf)
    ungated_rk = real_wf.replace("    if: needs.prepare.outputs.runtime_keep == '1' && needs.prepare.outputs.build == '1' && needs.prepare.outputs.full == '1'",
                                 "    if: needs.prepare.outputs.build == '1' && needs.prepare.outputs.full == '1'")
    assert ungated_rk != real_wf
    assert any("runtime-keep" in x for x in check_path_gate(ungated_rk)[0]), check_path_gate(ungated_rk)
    ungated_lo = real_wf.replace("    if: needs.prepare.outputs.layout_oracle == '1' && needs.prepare.outputs.build == '1' && needs.prepare.outputs.full == '1'",
                                 "    if: needs.prepare.outputs.build == '1' && needs.prepare.outputs.full == '1'")
    assert ungated_lo != real_wf
    assert any("layout-oracle" in x for x in check_path_gate(ungated_lo)[0]), check_path_gate(ungated_lo)

    real_dup = open(CHECKS, encoding="utf-8").read()
    assert check_dup_run(real_dup)[0] == [], check_dup_run(real_dup)
    unmirrored = real_dup.replace("needs.prepare.outputs.mirror != ''", "needs.prepare.outputs.mirror == ''", 1)
    assert unmirrored != real_dup
    assert any("mirror" in x for x in check_dup_run(unmirrored)[0]), check_dup_run(unmirrored)
    import pr_mode as _pm
    assert check_ready_race(_pm)[0] == [], check_ready_race(_pm)

    # ── compiler route: the real prep passes; a wire with no route, a prep that
    # builds before it fetches, and a merge-base compiler with no seed behind it
    # are each refused by name ──
    real_work = open(os.path.join(ROOT, "tools", "work"), encoding="utf-8").read()
    real_remote = open(os.path.join(ROOT, "tools", "sprite-remote.sh"), encoding="utf-8").read()
    assert check_compiler_route(real_work, real_remote)[0] == [], check_compiler_route(real_work, real_remote)
    no_wire = real_work.replace('wire="$wire@$route"', 'wire="$wire"', 1)
    assert no_wire != real_work
    assert any("wire" in x for x in check_compiler_route(no_wire, real_remote)[0]), check_compiler_route(no_wire, real_remote)
    published_gone = real_remote.replace('"${route%%:*}" = published', '"${route%%:*}" = never', 1)
    assert published_gone != real_remote
    assert any("published" in x for x in check_compiler_route(real_work, published_gone)[0]), check_compiler_route(real_work, published_gone)
    no_seed = real_remote.replace("bootstrapped from the seed", "built anyway", 1)
    assert no_seed != real_remote
    assert any("seed" in x for x in check_compiler_route(real_work, no_seed)[0]), check_compiler_route(real_work, no_seed)

    print("ci_invariants self-test: release-order, keeper-coverage, watcher-fixtures, "
          "light-draft, run-mode, race-split, compiler-route, path-gate, dup-run, ready-race, warm-edit held on fixtures")
    return 0


def main(argv):
    if "--self-test" in argv:
        return self_test()
    return run()


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
