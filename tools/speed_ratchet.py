#!/usr/bin/env python3
"""THE HARD PER-PHASE SPEED RATCHET.

The soft note (tools/speed_note.sh) compares whole JOB times and warns;
a sum of small per-phase regressions slips under its 25% and never shows.
This holds each PHASE of the compiler's own build and check against a
recorded ceiling in `tools/speed.budget`, and REFUSES past it — a
non-zero exit naming the phase, its ceiling and what it measured.

  speed_ratchet.py              measure, judge, refuse a regression
  speed_ratchet.py --accept     lower this host's ceilings to what was
                                measured; never raises one
  speed_ratchet.py --require    a host with no ceiling row is a refusal
                                rather than a note
  speed_ratchet.py --self-test  the rules on fixtures, no compiler
  speed_ratchet.py --raw <file> judge a measurement already taken
  speed_ratchet.py --warm --raw <file>
                                judge the DB 07 warm-edit gate: wall ms
                                for `check packages/cli`, unchanged and
                                after one body edit, against the ticket's
                                HARD ceilings (tools/warm_edit_bench.sh)
  speed_ratchet.py --wall --raw <file>
                                judge the wall-clock budget: a PR check's
                                per-job and whole wall time, as
                                `tools/ci_wall.sh` reads them from the run

The measurement itself is `tools/speed_measure.sh`: `packages/cli`, one
file edited, the `--time` phases of a build and a check, each round a
fresh edit, the LEAST of SPEED_ROUNDS per phase. It runs on the HOST the
keeper runs on; on macOS the lane's Sprite runs it (`tools/work run`), so
a loaded Mac never supplies a number.

THE WARM-EDIT GATE (`--warm`) is a SECOND family in the same budget
file, not a second budget: `<host> warm unchanged <ms>` and
`<host> warm edit <ms>` are the DB 07 acceptance's (avra-8sb5.57.176)
warm `check packages/cli`, measured and gated by
`tools/warm_edit_bench.sh`, whose judge is `--warm --raw`. The ticket's
GOAL is an unchanged check <= 60 ms and one body edit <= 300 ms (goal
150), but today's path is hundreds of times over it, so a row seeded at
the goal would refuse every run and nothing could land: THE ROWS ARE THE
MEASURED PRESENT, THE STARTING LINE, and the goal stands as a comment
beside them. A shared runner's warm figure is noisy — two same-commit
tree runs measured 1.62x apart — so the gate allows `WARM_RATIO` of the
row. `--warm --accept` may only LOWER a row to a faster real run, never
raise it, so the ceiling walks down toward the goal as the cost falls.

THE WALL-CLOCK GATE (`--wall`) is a THIRD family in the same budget file:
`ci-wall wall <job> <ms>` for each job a PR check ran, and
`ci-wall wall total <ms>` for the check whole, held HARD against the
owner's own target. Its measurement is `tools/ci_wall.sh`, which reads the
run's job clocks from GitHub — so the queue and the artifact hand-downs
count, and no step's own `date` arithmetic can see them. It is judged in
the `test` job of every PR run; a host with no row is measured and said
out loud, never passed in silence.

LIKE FOR LIKE: a ceiling row is keyed by `<platform>-<machine>-<cpu>`,
so a Mac, a Sprite and a runner are never compared. A host with no row
is measured, printed and NOT gated unless the caller asks (--require).

THE CEILING MAY ONLY FALL. `--accept` writes a measured value only when
it is LOWER than the ceiling already there; a phase that grew is left
standing, so the refusal stands too. Raising a ceiling is a human edit
of tools/speed.budget, and that diff is the review.
"""
import os
import platform
import re
import subprocess
import sys

import ratchet_rows as rows_lib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BUDGET = os.path.join(ROOT, "tools", "speed.budget")
MEASURE = "tools/speed_measure.sh"

# The phases the ratchet holds, per command. A phase measured that the
# budget does not name is a refusal (nothing records its ceiling); a
# budget row no round measured is a refusal too (a phase silently
# dropped from the measurement).
PHASES = {
    "build": ["analyze", "lower", "keep", "emit", "link"],
    "check": ["analyze", "lower", "keep"],
}
# The DB 07 warm-edit family: wall ms for `check packages/cli`, unchanged
# and after one body edit. Held to the ticket's HARD ceilings, never the
# phase family's ratio.
WARM_PHASES = ["unchanged", "edit"]
WARM_COMMAND = "warm"
# The ticket's stretch target, printed beside each measurement. The
# ENFORCED number is the budget row, which is the measured present.
WARM_GOAL = {"unchanged": 60, "edit": 150}
# A warm row is a MEASURED BASELINE, not a fixed target, and a shared CI
# runner's warm figure is noisy: two runs of one commit measured 1.62x
# apart (314ms vs 194ms unchanged). A ratchet that flakes is worse than
# none, so the gate allows this much of the row before it fires. A run
# must beat 2x the seeded present, which is a real regression rather than
# ordinary variance; `--accept` lowers the row and the allowance follows.
WARM_RATIO = 2.0
# The wall-clock family: a PR check's whole wall time and each job in it,
# as `tools/ci_wall.sh` reads them from the run. HARD ceilings, because
# these are the owner's target, not a noisy phase.
WALL_COMMAND = "wall"
WALL_TOTAL = "total"
ROW = re.compile(r"^(?P<cmd>build|check|warm|wall) (?P<phase>[a-z][a-z0-9_-]*) (?P<ms>[0-9]+)$")
HOST_ROW = re.compile(r"^host (?P<host>\S+)$")
BUDGET_ROW = re.compile(r"^(?P<host>[^#\s]+) (?P<cmd>build|check|warm|wall) (?P<phase>[a-z][a-z0-9_-]*) (?P<ms>[0-9]+)$")

DEFAULT_RATIO = 1.25
DEFAULT_SLACK_MS = 250


def host_key():
    """The measuring machine's key, from the one definition both languages ask (tools/host_key.sh)."""
    got = subprocess.run(["sh", os.path.join(os.path.dirname(os.path.abspath(__file__)), "host_key.sh")], capture_output=True, text=True)
    return got.stdout.strip()


def least_rows(text):
    """`<command> <phase> <ms>` lines -> {(cmd, phase): least ms}. A line that is not a row is read past:
    the measurement's own words are not rows."""
    return rows_lib.read(text, ROW, ["cmd", "phase"], "ms", least=True)


def measured_host(text):
    """The host the measurement ran on, as `speed_measure.sh` states it —
    a Mac's delegated round says the Sprite's host, so the number is keyed
    where it was taken, never where the keeper stands."""
    for line in text.splitlines():
        m = HOST_ROW.match(line.strip())
        if m:
            return m.group("host")
    return None


def skip_reason(text):
    """The skip marker `tools/warm_edit_bench.sh` writes to stdout when it
    cannot judge — `skip warm-edit` today, `skip cold-store` from the
    older spelling — or None. A SKIP IS NOT A PASS: the caller refuses it
    unless a human set `WARM_EDIT_SKIP`."""
    for line in text.splitlines():
        if line.strip() in ("skip warm-edit", "skip cold-store"):
            return line.strip()
    return None


def budget_rows(text):
    """`<host> <command> <phase> <ms>` -> {(host, cmd, phase): ms}."""
    return rows_lib.read(text, BUDGET_ROW, ["host", "cmd", "phase"], "ms")


def budget_text(rows):
    """The budget as it is written: a header, then one row per host and
    phase, sorted so a diff reads."""
    head = [
        "# THE SPEED RATCHET'S CEILINGS: the most each phase of `packages/cli`'s",
        "# own build and check may cost, in milliseconds, ONE MACHINE per row —",
        "# <platform>-<machine>-<cpu> <command> <phase> <ms>. Read by",
        "# `tools/speed_ratchet.py` (`make speed-ratchet`), whose measurement is",
        "# the LEAST of SPEED_ROUNDS warm one-edit rounds (`tools/speed_measure.sh`).",
        "#",
        "# A ceiling MAY ONLY FALL: `--accept` lowers a row to what it measured and",
        "# never raises it. A raise is a human edit of this file, and the diff is the",
        "# review. A machine with no row here is measured and printed, never gated.",
        "#",
        "# A `warm` row is the DB 07 warm-edit gate's (tools/warm_edit_bench.sh,",
        "# judged by speed_ratchet.py --warm): wall ms for a `check packages/cli`,",
        "# unchanged and after one body edit, on a warm store. THE TICKET'S GOAL",
        "# (avra-8sb5.57.176) is unchanged <= 60 ms, edit <= 300 ms (goal 150), and",
        "# it is a COMMENT, NEVER THE ENFORCED VALUE: today's warm path is hundreds",
        "# of times over it, so a row at the goal would refuse every run and nothing",
        "# could land. The rows below are the MEASURED PRESENT — the STARTING LINE —",
        "# and the gate allows WARM_RATIO of a row for a shared runner's variance",
        "# (two same-commit runs measured 1.62x apart). `--warm --accept` may only",
        "# LOWER a row to a faster real run, never raise one, so the ceiling walks",
        "# down toward the goal as the cost falls.",
        "#",
        "# The `ci-warm` rows are the CI keeper's: `keepers-a` runs",
        "# `tools/warm_edit_bench.sh` on the runner with the store prepare handed",
        "# down, and `SPEED_HOST=ci-warm` keys it to the one stable name — never to",
        "# whatever CPU the runner draws. The `linux-x86-64-amd-epyc` rows are the",
        "# lane Sprite's; each is seeded from what that machine measured, and each",
        "# may only fall.",
        "#",
        "# A `wall` row is the PR check's own clock (tools/ci_wall.sh, judged by",
        "# speed_ratchet.py --wall in the `test` job): `ci-wall wall <job> <ms>` and",
        "# `ci-wall wall total <ms>`, held HARD. `total` is the sum of the jobs'",
        "# own clocks, so no queue between them inflates it.",
        "#",
        "# The `ci-wall` ceilings are the FULL-GATE PR's: the merge queue is gone and",
        "# the PR itself is the gate (keepers, seed-check and the suites included), so",
        "# a PR that builds its own compiler costs ~16 min of `prepare` and ~70 min of",
        "# summed job clock. They were first set for the fast floor and refused every",
        "# PR; these are calibrated from the completed runs that measured the gate.",
    ]
    return "\n".join(head) + "\n" + rows_lib.lines(rows)


def check(measured, accepted, host, ratio, slack, require):
    """What the gate holds. Answers (refusals, gated, words): the refusals
    are the phases past the ceiling; `gated` is how many phases had a
    ceiling here, which is the coverage the gate must state. A machine
    with no ceiling row refuses only when the caller asks (`--require`)."""
    refusals, gated, words = [], 0, []
    rows_here = {k: v for k, v in accepted.items() if k[0] == host and k[1] in PHASES}
    if not rows_here:
        words.append("NO CEILING ROW for %s — measured, not gated; `--accept` records it" % host)
        if require:
            refusals.append((host, "no ceiling row — refused by --require"))
        return refusals, gated, words
    # The budget's phases and the measurement's must name the same set: a
    # budget row no round measured is a verdict over nothing, and a phase
    # measured with no ceiling is unrecorded growth.
    held = {(c, p) for (h, c, p) in rows_here}
    seen = {k for k in measured if k[0] in PHASES}
    for c, p in sorted(held - seen):
        refusals.append(("%s %s" % (c, p), "no round measured it — the ceiling has nothing to judge"))
    for c, p in sorted(seen - held):
        refusals.append(("%s %s" % (c, p), "measured %dms with no ceiling row — record it with --accept" % measured[(c, p)]))
    for c in sorted(PHASES):
        for p in PHASES[c]:
            key = (c, p)
            if key not in measured or (host, c, p) not in accepted:
                continue
            now, was = measured[key], accepted[(host, c, p)]
            gated += 1
            limit = was * ratio + slack
            line = "%dms vs ceiling %dms (limit %.0fms)" % (now, was, limit)
            print("speed: %s: %s %s: %s" % ("PASS" if now <= limit else "FAIL", c, p, line))
            if now > limit:
                refusals.append(("%s %s" % (c, p), line))
    return refusals, gated, words


def on_ci():
    return os.environ.get("GITHUB_ACTIONS") == "true" or os.environ.get("CI") == "true"


def check_warm(measured, accepted, host, require, report_only=False):
    """The DB 07 warm-edit gate. Answers (refusals, gated, words), the
    same shape as `check`. A warm row is the MEASURED PRESENT with
    `WARM_RATIO` of slack for a shared runner's variance — the ticket's
    60/300 ms target stands as a comment, never as the enforced value,
    because a row at the goal would refuse every run and nothing could
    land. A machine with no warm row refuses only when the caller asks
    (`--require`). With `report_only` (a shared CI runner) the clock is
    printed with its ceiling and limit and a `::warning::` past the limit,
    and never refuses: the exact work counters (tools/work_ratchet.py) are
    the failing gate there."""
    refusals, gated, words = [], 0, []
    rows_here = {k: v for k, v in accepted.items() if k[0] == host and k[1] == WARM_COMMAND}
    if not rows_here:
        words.append("NO WARM CEILING ROW for %s — measured, not gated" % host)
        if require:
            refusals.append((host, "no warm ceiling row — refused by --require"))
        return refusals, gated, words
    # The budget's warm scenarios and the measurement's must name the same
    # set, exactly as the phase gate holds `PHASES`.
    held = {(c, p) for (h, c, p) in rows_here}
    seen = {k for k in measured if k[0] == WARM_COMMAND}
    for c, p in sorted(held - seen):
        refusals.append(("%s %s" % (c, p), "no round measured it — the ceiling has nothing to judge"))
    for c, p in sorted(seen - held):
        refusals.append(("%s %s" % (c, p), "measured %dms with no ceiling row — record it in tools/speed.budget" % measured[(c, p)]))
    for p in WARM_PHASES:
        key = (WARM_COMMAND, p)
        if key not in measured or (host, WARM_COMMAND, p) not in accepted:
            continue
        now, ceiling = measured[key], accepted[(host, WARM_COMMAND, p)]
        gated += 1
        limit = ceiling * WARM_RATIO
        goal = WARM_GOAL.get(p)
        stretch = ", goal %dms" % goal if goal else ""
        line = "%dms vs ceiling %dms (limit %.0fms)%s" % (now, ceiling, limit, stretch)
        verdict = "PASS" if now <= limit else ("WARN" if report_only else "FAIL")
        print("speed: %s: warm %s: %s%s"
              % (verdict, p, line,
                 "" if now <= limit else " (over by %.0fms)" % (now - limit)))
        if now > limit and report_only:
            print("::warning::speed: warm %s: %s (over by %.0fms) — reported, not gated on CI"
                  % (p, line, now - limit))
        elif now > limit:
            refusals.append(("warm %s" % p, "%s (over by %.0fms)" % (line, now - limit)))
    return refusals, gated, words


def gate_warm(measured, accepted, host, require):
    print("speed: warm-edit host %s" % host)
    fail, gated, words = check_warm(measured, accepted, host, require, on_ci())
    seen = len({k for k in measured if k[0] == WARM_COMMAND})
    print("speed: %d warm scenario(s) measured, %d gated here" % (seen, gated))
    for why in words:
        print("speed: %s" % why)
    if fail:
        print("speed: REFUSED — %d warm scenario(s) past the ceiling or unjudged:" % len(fail))
        for name, why in fail:
            print("speed:   %s: %s" % (name, why))
        return 1
    if gated == 0:
        print("speed: NOT GATED — no warm ceiling row on this host, so nothing was compared")
        return 1 if require else 0
    print("speed: clean — %d warm scenario(s) within the ticket's ceiling" % gated)
    return 0


def check_wall(measured, accepted, host, require, report_only=False):
    """The wall-clock family: a PR check's whole wall time and each job
    in it, held against a ceiling in `tools/speed.budget`. Like the warm
    family a wall figure is HARD — no ratio, no slack — and `--accept`
    may only lower a ceiling. A job the event skipped has no clock and is
    simply absent, never a refusal; the `total` row is always judged,
    because a budget that measured no total judged nothing. With
    `report_only` (a shared CI runner, where the sum of job times scales
    with runner variance and batch size) a figure past its ceiling is
    printed with its number and a `::warning::`, never refused."""
    refusals, gated, words = [], 0, []
    rows_here = {k: v for k, v in accepted.items() if k[0] == host and k[1] == WALL_COMMAND}
    if not rows_here:
        words.append("NO WALL CEILING ROW for %s — measured, not gated; `--accept` records it" % host)
        if require:
            refusals.append((host, "no wall ceiling row — refused by --require"))
        return refusals, gated, words
    held = {(c, p) for (h, c, p) in rows_here}
    seen = {k for k in measured if k[0] == WALL_COMMAND}
    total = (WALL_COMMAND, WALL_TOTAL)
    if total in held and total not in seen:
        refusals.append(("wall total", "no total measured — the ceiling has nothing to judge"))
    for c, p in sorted(seen - held):
        why = "wall %s measured %dms with no ceiling row — record it with --accept" % (p, measured[(c, p)])
        if (c, p) == total:
            refusals.append(("wall total", why))
        else:
            words.append(why)
    for c, p in sorted(seen & held):
        now, ceiling = measured[(c, p)], accepted[(host, c, p)]
        gated += 1
        over = now - ceiling
        print("speed: %s: wall %s: %dms vs ceiling %dms%s"
              % ("PASS" if now <= ceiling else ("WARN" if report_only else "FAIL"), p, now, ceiling,
                 "" if now <= ceiling else " (over by %dms)" % over))
        if now > ceiling and report_only:
            print("::warning::speed: wall %s: %dms vs ceiling %dms (over by %dms) — reported, not gated on CI"
                  % (p, now, ceiling, over))
        elif now > ceiling:
            refusals.append(("wall %s" % p, "%dms vs ceiling %dms (over by %dms)" % (now, ceiling, over)))
    return refusals, gated, words


def gate_wall(measured, accepted, host, require):
    print("speed: wall-clock host %s" % host)
    fail, gated, words = check_wall(measured, accepted, host, require, on_ci())
    seen = len({k for k in measured if k[0] == WALL_COMMAND})
    print("speed: %d wall row(s) measured, %d gated here" % (seen, gated))
    for why in words:
        print("speed: %s" % why)
    if fail:
        print("speed: REFUSED — %d wall row(s) past the ceiling or unjudged:" % len(fail))
        for name, why in fail:
            print("speed:   %s: %s" % (name, why))
        return 1
    if gated == 0:
        print("speed: NOT GATED — no wall ceiling row on this host, so nothing was compared")
        return 1 if require else 0
    print("speed: clean — %d wall row(s) within the ceiling" % gated)
    return 0


def measure():
    """The raw measurement, run on this host — or, on macOS, on the lane's
    Sprite. Answers the text, or None when no Sprite can be reached (the
    caller prints and skips: a Mac with no Sprite has no machine to
    judge)."""
    if platform.system() == "Darwin" and os.environ.get("SPEED_LOCAL") != "1":
        sprite = bound_sprite()
        if not sprite:
            return None
        out = subprocess.run(
            ["sh", "tools/work", "run", "sh " + MEASURE],
            cwd=ROOT, capture_output=True, text=True, timeout=1800,
        )
        return out.stdout + "\n" + out.stderr
    out = subprocess.run(["sh", MEASURE], cwd=ROOT, capture_output=True, text=True, timeout=1800)
    sys.stderr.write(out.stderr)
    return out.stdout


def bound_sprite():
    """The Sprite this worktree's git dir names, if any (`tools/work`'s own
    binding file)."""
    try:
        gitdir = subprocess.run(
            ["git", "rev-parse", "--absolute-git-dir"], cwd=ROOT, capture_output=True, text=True
        ).stdout.strip()
    except Exception:
        return None
    try:
        name = open(os.path.join(gitdir, "avra-sprite")).read().strip()
    except OSError:
        return None
    return name or None


def gate(measured, accepted, host, ratio, slack, require):
    print("speed: host %s, ratio %.2fx + %dms" % (host, ratio, slack))
    fail, gated, words = check(measured, accepted, host, ratio, slack, require)
    print("speed: %d phase(s) measured, %d gated here" % (len(measured), gated))
    for why in words:
        print("speed: %s" % why)
    if fail:
        print("speed: REFUSED — %d phase(s) past the ceiling or unjudged:" % len(fail))
        for name, why in fail:
            print("speed:   %s: %s" % (name, why))
        return 1
    if gated == 0:
        print("speed: NOT GATED — no ceiling row on this host, so nothing was compared")
        return 1 if require else 0
    print("speed: clean — %d phase(s) within the ceiling" % gated)
    return 0


def accept(measured, rows, host):
    """Lower this host's ceilings to what was measured; never raise one.
    A measured phase over its ceiling is LEFT STANDING and answers 1, the
    same refusal the gate would speak — a register is never kept green
    while a regression stands."""
    lowered, standing, over = 0, 0, 0
    for (c, p), ms in sorted(measured.items()):
        key = (host, c, p)
        if key not in rows:
            rows[key] = ms
            lowered += 1
        elif ms < rows[key]:
            print("speed: %s %s lowered %dms -> %dms" % (c, p, rows[key], ms))
            rows[key] = ms
            lowered += 1
        else:
            if ms > rows[key]:
                over += 1
            print("speed: %s %s measured %dms, ceiling %dms stands" % (c, p, ms, rows[key]))
            standing += 1
    open(BUDGET, "w").write(budget_text(rows))
    print("speed: %d ceiling(s) lowered or recorded, %d left standing in %s" % (lowered, standing, BUDGET))
    return 1 if over else 0


# ── the rules on fixtures, no compiler ──

def self_test():
    base = {
        ("linux-x86_64", "build", "analyze"): 2000,
        ("linux-x86_64", "build", "lower"): 3000,
        ("linux-x86_64", "build", "keep"): 7000,
        ("linux-x86_64", "build", "emit"): 950,
        ("linux-x86_64", "build", "link"): 2200,
        ("linux-x86_64", "check", "analyze"): 1900,
        ("linux-x86_64", "check", "lower"): 2800,
        ("linux-x86_64", "check", "keep"): 7200,
    }
    under = (
        "build analyze 1500\nbuild lower 2500\nbuild keep 6800\nbuild emit 800\nbuild link 1900\n"
        "check analyze 1700\ncheck lower 2600\ncheck keep 6900\n"
    )
    host = "linux-x86_64"
    # every phase under its ceiling passes, and all eight are gated
    measured = least_rows(under)
    fail, gated, _ = check(measured, base, host, 1.25, 200, False)
    assert fail == [] and gated == 8, (fail, gated)
    # the least of the rounds is the price, never the first or the mean
    noisy = under + "build keep 9000\nbuild keep 7100\n"
    assert least_rows(noisy)[("build", "keep")] == 6800, least_rows(noisy)
    # a phase past its ceiling names itself, with its ceiling and its price
    over = least_rows(under.replace("build keep 6800", "build keep 44000"))
    fail, gated, _ = check(over, base, host, 1.25, 200, False)
    assert [r for r, _ in fail] == ["build keep"], fail
    assert gated == 8 and "44000ms vs ceiling 7000ms" in fail[0][1], fail
    # at the limit passes: the gate is `>`, never `>=` (7000*1.25+200 = 8950)
    edge = least_rows(under.replace("build keep 6800", "build keep 8950"))
    assert check(edge, base, host, 1.25, 200, False)[0] == []
    # a budget row no round measured is a verdict over nothing
    short = least_rows(under.replace("check lower 2600\n", ""))
    fail, _, _ = check(short, base, host, 1.25, 200, False)
    assert [r for r, _ in fail] == ["check lower"], fail
    # a measured phase with no ceiling is unrecorded growth
    extra = least_rows(under.replace("build emit 800", "build emit 800\nbuild place 5"))
    fail, _, _ = check(extra, base, host, 1.25, 200, False)
    assert [r for r, _ in fail] == ["build place"], fail
    # another machine's row is not this machine's: measured, not gated
    mac = {("darwin-arm64", "build", p): 1 for p in PHASES["build"]}
    fail, gated, words = check(measured, mac, host, 1.25, 200, False)
    assert fail == [] and gated == 0 and any("NO CEILING ROW" in w for w in words), (fail, gated, words)
    fail, _, _ = check(measured, mac, host, 1.25, 200, True)
    assert len(fail) == 1 and "refused by --require" in fail[0][1], fail
    # ── the warm-edit family: a MEASURED BASELINE with a runner's slack ──
    warm_base = {
        (host, "warm", "unchanged"): 60,
        (host, "warm", "edit"): 300,
    }
    warm_under = "host %s\nwarm unchanged 40\nwarm edit 250\n" % host
    wm = least_rows(warm_under)
    fail, gated, _ = check_warm(wm, warm_base, host, False)
    assert fail == [] and gated == 2, (fail, gated)
    # a warm wall figure spends WARM_RATIO of the row: 60*2 = 120, so 121
    # fails, and it names the limit it crossed
    w_over = least_rows(warm_under.replace("warm unchanged 40", "warm unchanged 121"))
    fail, gated, _ = check_warm(w_over, warm_base, host, False)
    assert [r for r, _ in fail] == ["warm unchanged"], fail
    assert "limit 120ms" in fail[0][1] and "over by 1ms" in fail[0][1], fail
    # at the limit passes: the warm gate is `>`, never `>=`
    edge = least_rows(warm_under.replace("warm edit 250", "warm edit 600"))
    assert check_warm(edge, warm_base, host, False)[0] == []
    # a warm row no round measured is a verdict over nothing; a warm
    # scenario with no ceiling is unrecorded, each named
    w_short = least_rows(warm_under.replace("warm edit 250\n", ""))
    assert [r for r, _ in check_warm(w_short, warm_base, host, False)[0]] == ["warm edit"]
    w_extra = least_rows(warm_under + "warm place 5\n")
    assert [r for r, _ in check_warm(w_extra, warm_base, host, False)[0]] == ["warm place"]
    # the two families share ONE budget but never judge each other
    mixed_base = dict(base)
    mixed_base.update(warm_base)
    mixed = least_rows(under + "warm unchanged 40\nwarm edit 250\n")
    assert check(mixed, mixed_base, host, 1.25, 200, False)[0] == [], "warm rows are not phases"
    assert check_warm(mixed, mixed_base, host, False)[1] == 2, "phase rows are not warm"
    # a host with no warm ceiling is a word, and --require refuses
    elsewhere = {("darwin-arm64", "warm", "unchanged"): 60}
    fail, gated, words = check_warm(wm, elsewhere, host, False)
    assert fail == [] and gated == 0 and any("NO WARM CEILING ROW" in w for w in words), (fail, gated, words)
    fail, _, _ = check_warm(wm, elsewhere, host, True)
    assert len(fail) == 1 and "refused by --require" in fail[0][1], fail
    # a skip is not a pass: the marker is read, and only a hand-set opt-out
    # (main's own WARM_EDIT_SKIP policy) lets it stand
    assert skip_reason("host h\nskip warm-edit\n") == "skip warm-edit"
    assert skip_reason("host h\nskip cold-store\n") == "skip cold-store"
    assert skip_reason("host h\nwarm unchanged 40\nwarm edit 250\n") is None
    # ── the wall-clock family: HARD, per job and whole ──
    wall_base = {
        (host, "wall", "prepare"): 180000,
        (host, "wall", "gate"): 120000,
        (host, "wall", "total"): 300000,
    }
    wall_under = "host %s\nwall prepare 90000\nwall gate 60000\nwall total 200000\n" % host
    ww = least_rows(wall_under)
    fail, gated, _ = check_wall(ww, wall_base, host, False)
    assert fail == [] and gated == 3, (fail, gated)
    # a job or the whole check past its ceiling names itself, with the overage
    w_over = least_rows(wall_under.replace("wall total 200000", "wall total 400000"))
    fail, gated, _ = check_wall(w_over, wall_base, host, False)
    assert [r for r, _ in fail] == ["wall total"], fail
    assert "over by 100000ms" in fail[0][1], fail
    # on CI the wall is reported, never refused; an unmeasured total still refuses
    fail, gated, _ = check_wall(w_over, wall_base, host, False, True)
    assert fail == [] and gated == 3, (fail, gated)
    ci_no_total = least_rows("host %s\nwall prepare 90000\nwall gate 60000\n" % host)
    assert [r for r, _ in check_wall(ci_no_total, wall_base, host, False, True)[0]] == ["wall total"]
    keep_env = dict(os.environ)
    try:
        os.environ.pop("GITHUB_ACTIONS", None)
        os.environ["CI"] = "true"
        assert gate_wall(w_over, wall_base, host, False) == 0
        os.environ.pop("CI")
        assert gate_wall(w_over, wall_base, host, False) == 1
    finally:
        os.environ.clear()
        os.environ.update(keep_env)
    # a skipped job is absent, never a refusal; an unregistered job is a word
    skip = least_rows("host %s\nwall prepare 90000\nwall total 200000\n" % host)
    fail, gated, _ = check_wall(skip, wall_base, host, False)
    assert fail == [] and gated == 2, (fail, gated)
    w_extra = least_rows(wall_under + "wall codecs 5000\n")
    fail, _, words = check_wall(w_extra, wall_base, host, False)
    assert fail == [] and any("codecs" in w for w in words), (fail, words)
    # a total ceiling with no total measured is a verdict over nothing
    no_total = least_rows("host %s\nwall prepare 90000\n" % host)
    fail, _, _ = check_wall(no_total, wall_base, host, False)
    assert [r for r, _ in fail] == ["wall total"], fail
    # a total measured with no ceiling row is unrecorded growth
    w_no_total = {k: v for k, v in wall_base.items() if k[2] != "total"}
    fail, _, _ = check_wall(ww, w_no_total, host, False)
    assert [r for r, _ in fail] == ["wall total"], fail
    # no wall ceiling is a word, and --require refuses
    fail, gated, words = check_wall(ww, {("darwin-arm64", "wall", "total"): 1}, host, False)
    assert fail == [] and gated == 0 and any("NO WALL CEILING ROW" in w for w in words), (fail, gated, words)
    fail, _, _ = check_wall(ww, {("darwin-arm64", "wall", "total"): 1}, host, True)
    assert len(fail) == 1 and "refused by --require" in fail[0][1], fail
    # the three families share ONE budget but never judge each other
    all_base = dict(base)
    all_base.update(warm_base)
    all_base.update(wall_base)
    all_rows = least_rows(under + "warm unchanged 40\nwarm edit 250\n" + wall_under)
    assert check(all_rows, all_base, host, 1.25, 200, False)[0] == []
    assert check_warm(all_rows, all_base, host, False)[1] == 2
    assert check_wall(all_rows, all_base, host, False)[1] == 3
    # the round trip carries warm rows in the one budget
    assert budget_rows(budget_text(mixed_base)) == mixed_base, budget_text(mixed_base)
    assert budget_rows(budget_text(all_base)) == all_base, budget_text(all_base)
    # --accept lowers, records a new host, and never raises
    global BUDGET
    keep = BUDGET
    try:
        import tempfile
        with tempfile.TemporaryDirectory() as d:
            BUDGET = os.path.join(d, "speed.budget")
            rows = dict(base)
            assert accept({("build", "keep"): 6000, ("check", "keep"): 9000}, rows, host) == 1
            assert rows[(host, "build", "keep")] == 6000, rows   # lowered 7000 -> 6000
            assert rows[(host, "check", "keep")] == 7200, rows   # 9000 never raised it
            written = budget_rows(open(BUDGET).read())
            assert written[(host, "build", "keep")] == 6000, written
            assert written[(host, "check", "keep")] == 7200, written
            assert accept({("build", "keep"): 3}, rows, "new-host") == 0
            assert rows[("new-host", "build", "keep")] == 3, rows
            # a wall ceiling too may only fall
            wrows = dict(wall_base)
            assert accept({("wall", "total"): 200000}, wrows, host) == 0
            assert wrows[(host, "wall", "total")] == 200000, wrows
            assert accept({("wall", "total"): 400000}, wrows, host) == 1
            assert wrows[(host, "wall", "total")] == 200000, wrows
            # a warm ceiling too: lowered to a faster real run, never raised
            wmrows = dict(warm_base)
            assert accept({("warm", "unchanged"): 50}, wmrows, host) == 0
            assert wmrows[(host, "warm", "unchanged")] == 50, wmrows
            assert accept({("warm", "unchanged"): 70}, wmrows, host) == 1
            assert wmrows[(host, "warm", "unchanged")] == 50, wmrows
    finally:
        BUDGET = keep
    # on CI the clock is reported, never refused; a non-clock refusal still stands
    ci_over = dict(wm)
    ci_over[("warm", "unchanged")] = 10 ** 6
    fail, gated, _ = check_warm(ci_over, warm_base, host, False, True)
    assert fail == [] and gated == 2, (fail, gated)
    assert [r for r, _ in check_warm(ci_over, warm_base, host, False)[0]] == ["warm unchanged"]
    ci_short = {k: v for k, v in ci_over.items() if k != ("warm", "edit")}
    assert [r for r, _ in check_warm(ci_short, warm_base, host, False, True)[0]] == ["warm edit"]
    keep_env = dict(os.environ)
    try:
        os.environ.pop("GITHUB_ACTIONS", None)
        os.environ["CI"] = "true"
        assert gate_warm(ci_over, warm_base, host, False) == 0
        os.environ.pop("CI")
        assert gate_warm(ci_over, warm_base, host, False) == 1
    finally:
        os.environ.clear()
        os.environ.update(keep_env)
    print("speed_ratchet self-test: 36 fixture(s) held")
    return 0


def main(argv):
    if "--self-test" in argv:
        return self_test()
    ratio = float(os.environ.get("SPEED_RATCHET_RATIO", DEFAULT_RATIO))
    slack = int(os.environ.get("SPEED_RATCHET_SLACK_MS", DEFAULT_SLACK_MS))
    require = "--require" in argv
    if "--wall" in argv:
        # `tools/ci_wall.sh` reads a PR check's per-job and total wall time
        # from the run; the budget and its reader live in this one file.
        if "--raw" not in argv:
            print("speed: --wall needs `--raw <file>` — tools/ci_wall.sh writes it", file=sys.stderr)
            return 64
        raw = open(argv[argv.index("--raw") + 1]).read()
        measured = least_rows(raw)
        if not measured:
            print("speed: the wall measurement answered no row — the collector did not run", file=sys.stderr)
            return 1
        accepted = budget_rows(open(BUDGET).read()) if os.path.isfile(BUDGET) else {}
        here = measured_host(raw) or host_key()
        if "--accept" in argv:
            return accept(measured, accepted, here)
        return gate_wall(measured, accepted, here, require)
    if "--warm" in argv:
        # `tools/warm_edit_bench.sh` measures and hands its raw stream here;
        # the budget and its reader live in this one file.
        if "--raw" not in argv:
            print("speed: --warm needs `--raw <file>` — tools/warm_edit_bench.sh writes it", file=sys.stderr)
            return 64
        raw = open(argv[argv.index("--raw") + 1]).read()
        # A SKIP IS NOT A PASS. The bench writes `skip warm-edit` when it
        # cannot judge; only a hand-set `WARM_EDIT_SKIP` (the workflow's
        # `warm_skip` input, which says so loudly) lets it stand.
        skipped = skip_reason(raw)
        if skipped:
            if os.environ.get("WARM_EDIT_SKIP"):
                print("speed: warm-edit SKIPPED BY REQUEST (WARM_EDIT_SKIP=%s) — not gated"
                      % os.environ["WARM_EDIT_SKIP"])
                return 0
            print("speed: REFUSED — the warm-edit measurement was skipped (%s), and a skip is not a pass; "
                  "set WARM_EDIT_SKIP=1 by hand only to skip" % skipped, file=sys.stderr)
            return 1
        measured = least_rows(raw)
        if not measured:
            print("speed: the measurement answered no scenario — the compiler did not run", file=sys.stderr)
            return 1
        accepted = budget_rows(open(BUDGET).read()) if os.path.isfile(BUDGET) else {}
        here = measured_host(raw) or host_key()
        if "--accept" in argv:
            return accept(measured, accepted, here)
        return gate_warm(measured, accepted, here, require)
    if "--raw" in argv:
        raw = open(argv[argv.index("--raw") + 1]).read()
    else:
        raw = measure()
        if raw is None:
            print("speed: no Sprite bound to this worktree — not measured here (make speed-ratchet on a lane)")
            return 1 if require else 0
    measured = least_rows(raw)
    if not measured:
        skipped = skip_reason(raw)
        if skipped:
            if os.environ.get("WARM_EDIT_SKIP"):
                print("speed: SKIPPED BY REQUEST (WARM_EDIT_SKIP=%s) — not gated" % os.environ["WARM_EDIT_SKIP"])
                return 0
            print("speed: REFUSED — the measurement was skipped (%s), and a skip is not a pass; "
                  "set WARM_EDIT_SKIP=1 by hand only to skip" % skipped, file=sys.stderr)
            return 1
        print("speed: the measurement answered no phase — the compiler did not run", file=sys.stderr)
        return 1
    accepted = budget_rows(open(BUDGET).read()) if os.path.isfile(BUDGET) else {}
    here = measured_host(raw) or host_key()
    if "--accept" in argv:
        return accept(measured, accepted, here)
    return gate(measured, accepted, here, ratio, slack, require)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
