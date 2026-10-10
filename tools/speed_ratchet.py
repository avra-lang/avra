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

The measurement itself is `tools/speed_measure.sh`: `packages/cli`, one
file edited, the `--time` phases of a build and a check, each round a
fresh edit, the LEAST of SPEED_ROUNDS per phase. It runs on the HOST the
keeper runs on; on macOS the lane's Sprite runs it (`tools/work run`), so
a loaded Mac never supplies a number.

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
ROW = re.compile(r"^(?P<cmd>build|check) (?P<phase>[a-z]+) (?P<ms>[0-9]+)$")
HOST_ROW = re.compile(r"^host (?P<host>\S+)$")
BUDGET_ROW = re.compile(r"^(?P<host>[^#\s]+) (?P<cmd>build|check) (?P<phase>[a-z]+) (?P<ms>[0-9]+)$")

DEFAULT_RATIO = 1.25
DEFAULT_SLACK_MS = 250


def cpu_token():
    """The measuring machine's CPU as a short key token, matching
    `speed_measure.sh`'s own — two x86_64 Linux machines are not one
    machine."""
    model = ""
    try:
        if os.path.exists("/proc/cpuinfo"):
            for line in open("/proc/cpuinfo"):
                if line.startswith("model name"):
                    model = line.split(":", 1)[1].strip()
                    break
        else:
            model = subprocess.run(
                ["sysctl", "-n", "machdep.cpu.brand_string"], capture_output=True, text=True
            ).stdout.strip()
    except Exception:
        model = ""
    return re.sub(r"[^a-z0-9]+", "-", model.lower()).strip("-")


def host_key():
    """`<platform>-<machine>-<cpu>`, lowercased and tokenized — the same
    spelling `speed_measure.sh` states, so a Mac and a Sprite (and two
    Linux machines) are never compared."""
    if os.environ.get("SPEED_HOST"):
        return os.environ["SPEED_HOST"]

    def token(text):
        return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")

    key = "%s-%s" % (token(platform.system()), token(platform.machine()))
    cpu = cpu_token()
    return "%s-%s" % (key, cpu) if cpu else key


def least_rows(text):
    """`<command> <phase> <ms>` lines -> {(cmd, phase): least ms}. A line
    that is not a row is read past: the measurement's own words are not
    rows."""
    rows = {}
    for line in text.splitlines():
        m = ROW.match(line.strip())
        if not m:
            continue
        key = (m.group("cmd"), m.group("phase"))
        ms = int(m.group("ms"))
        if key not in rows or ms < rows[key]:
            rows[key] = ms
    return rows


def measured_host(text):
    """The host the measurement ran on, as `speed_measure.sh` states it —
    a Mac's delegated round says the Sprite's host, so the number is keyed
    where it was taken, never where the keeper stands."""
    for line in text.splitlines():
        m = HOST_ROW.match(line.strip())
        if m:
            return m.group("host")
    return None


def budget_rows(text):
    """`<host> <command> <phase> <ms>` -> {(host, cmd, phase): ms}."""
    rows = {}
    for line in text.splitlines():
        m = BUDGET_ROW.match(line.strip())
        if m:
            rows[(m.group("host"), m.group("cmd"), m.group("phase"))] = int(m.group("ms"))
    return rows


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
    ]
    body = ["%s %s %s %d" % (h, c, p, rows[(h, c, p)]) for (h, c, p) in sorted(rows)]
    return "\n".join(head + body) + "\n"


def check(measured, accepted, host, ratio, slack, require):
    """What the gate holds. Answers (refusals, gated, words): the refusals
    are the phases past the ceiling; `gated` is how many phases had a
    ceiling here, which is the coverage the gate must state. A machine
    with no ceiling row refuses only when the caller asks (`--require`)."""
    refusals, gated, words = [], 0, []
    rows_here = {k: v for k, v in accepted.items() if k[0] == host}
    if not rows_here:
        words.append("NO CEILING ROW for %s — measured, not gated; `--accept` records it" % host)
        if require:
            refusals.append((host, "no ceiling row — refused by --require"))
        return refusals, gated, words
    # The budget's phases and the measurement's must name the same set: a
    # budget row no round measured is a verdict over nothing, and a phase
    # measured with no ceiling is unrecorded growth.
    held = {(c, p) for (h, c, p) in rows_here}
    seen = set(measured)
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
    # the round trip: what is written is what is read
    assert budget_rows(budget_text(base)) == base, budget_text(base)
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
    finally:
        BUDGET = keep
    print("speed_ratchet self-test: 13 fixture(s) held")
    return 0


def main(argv):
    if "--self-test" in argv:
        return self_test()
    ratio = float(os.environ.get("SPEED_RATCHET_RATIO", DEFAULT_RATIO))
    slack = int(os.environ.get("SPEED_RATCHET_SLACK_MS", DEFAULT_SLACK_MS))
    require = "--require" in argv
    if "--raw" in argv:
        raw = open(argv[argv.index("--raw") + 1]).read()
    else:
        raw = measure()
        if raw is None:
            print("speed: no Sprite bound to this worktree — not measured here (make speed-ratchet on a lane)")
            return 1 if require else 0
    measured = least_rows(raw)
    if not measured:
        if "skip cold-store" in raw:
            print("speed: no warm store on the measuring machine — not gated (make try, then re-run)")
            return 0
        print("speed: the measurement answered no phase — the compiler did not run", file=sys.stderr)
        return 1
    accepted = budget_rows(open(BUDGET).read()) if os.path.isfile(BUDGET) else {}
    here = measured_host(raw) or host_key()
    if "--accept" in argv:
        return accept(measured, accepted, here)
    return gate(measured, accepted, here, ratio, slack, require)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
