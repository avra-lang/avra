#!/usr/bin/env python3
"""RUNS ONE CI STEP AND RECORDS WHAT IT COST: the largest process's peak RSS (said), and the step's
user+sys CPU appended to speed.log as `speed cpu-<label>[-warm|-cold] <seconds>`.

    step_cpu.py [--state] <label> -- <command> [args...]

THE STATE RIDES THE NAME. A suite compiles its package held (a warm store: nearly all of `held N/M`
in its `--time` lines, or nearly all of its `time:` lines a `cache hit` where the compiler counts no `held`), from nothing (every N is 0) or between (`part`: a package the PR changed,
compiled beside held dependencies), and the three cost 2-100x apart for the same tree. A number is only comparable to a baseline taken in the SAME state, so the state is part of the
metric's name (tools/speed_note.sh compares like with like and says aloud when it cannot). A step
that prints no `held` line has no state and keeps the bare name; only a step asked with `--state`
reads one (a suite does; a keeper's own `held` lines are a different question).
"""
import os
import platform
import re
import resource
import subprocess
import sys

HELD = re.compile(r"\bheld (\d+)/(\d+)\b")


HIT = re.compile(r"\bcache hit\b")
PHASE = re.compile(r"\b(?:analyze|lower|keep|emit|link) (\d+)ms\b")


def state_of(text):
    """'warm' when nearly every derivation held (90% or more of them), 'cold' when none did, 'part' between
    (a package this run changed, compiled beside held dependencies), '' when no line said. A compiler that
    counts what it held says `held N/M`; one that holds nothing says only which `time:` lines were a
    `cache hit`, and the same three states are read from their share."""
    seen = [(int(m.group(1)), int(m.group(2))) for m in HELD.finditer(text)]
    if not seen:
        lines = [l for l in text.splitlines() if l.startswith("time:")]
        seen = [(1 if HIT.search(l) else 0, 1) for l in lines]
    if not seen:
        return ""
    held = sum(h for h, _ in seen)
    total = sum(t for _, t in seen)
    if held == 0:
        return "cold"
    return "warm" if held * 10 >= total * 9 else "part"


def cpu_tag(cpuinfo=None):
    """The runner's CPU model, short and name-safe (`epyc-7763`), or the machine word when none is read.
    A step's CPU seconds are only comparable on one model, so the model rides the metric's name."""
    if cpuinfo is None:
        try:
            with open("/proc/cpuinfo") as f:
                cpuinfo = f.read()
        except OSError:
            cpuinfo = ""
    line = next((l for l in cpuinfo.splitlines() if l.lower().startswith("model name")), "")
    words = re.findall(r"epyc|xeon|platinum|gold|silver|ryzen|neoverse|\d{3,5}[a-z]*", line.split(":", 1)[-1].lower())
    return "-".join(words[:3]) or platform.machine().lower() or "unknown"


def phases_of(text):
    """The compile's own seconds: analyze, lower, keep, emit and link, summed over every `time:` line. A suite
    that runs sockets spends the rest of its step waiting on them, which varies without the compiler moving."""
    return sum(int(m.group(1)) for l in text.splitlines() if l.startswith("time:") for m in PHASE.finditer(l)) // 1000


def metric(label, state, tag="", kind="cpu"):
    stem = re.sub("[^a-z0-9-]+", "-", label.lower()).strip("-")
    return "%s-%s%s%s" % (kind, tag + "-" if tag else "", stem, "-" + state if state else "")


def self_test():
    assert state_of("time: held 0/5, x\ntime: held 0/90, y") == "cold"
    assert state_of("time: held 0/5\ntime: held 1049/1170") == "part"
    assert state_of("time: held 1100/1170") == "warm"
    assert state_of("time: held 1053/1170") == "warm"
    assert state_of("time: held 5/5\ntime: held 1/90") == "part"
    assert state_of("no timing lines here") == ""
    assert state_of("time: suite · cache hit\ntime: suite · cache hit") == "warm"
    assert state_of("time: lower+emit · built\ntime: lower+emit · built") == "cold"
    assert state_of("time: suite · cache hit\ntime: parse 3ms, lower 5ms") == "part"
    assert state_of("time: check · cache hit — open 1us\ntime: held 0/5") == "cold"
    assert metric("std-avrac/@features-a", "cold") == "cpu-std-avrac-features-a-cold"
    assert metric("keepers-a1", "") == "cpu-keepers-a1"
    assert metric("std-path", "cold", "epyc-7763") == "cpu-epyc-7763-std-path-cold"
    assert cpu_tag("processor : 0\nmodel name\t: AMD EPYC 7763 64-Core Processor\n") == "epyc-7763"
    assert cpu_tag("model name : Intel(R) Xeon(R) Platinum 8272CL CPU @ 2.60GHz") == "xeon-platinum-8272cl"
    assert cpu_tag("nothing here") == platform.machine().lower()
    assert phases_of("time: ast 5ms, analyze 4022ms, lower 1490ms, keep 3976ms, emit 5364ms, link 66ms\nnoise\ntime: analyze 900ms") == 15
    assert phases_of("no time lines") == 0
    assert metric("std-ui_http", "cold", "epyc-7763", "phases") == "phases-epyc-7763-std-ui-http-cold"
    print("step_cpu: self-test passed — warm/cold/none read from the held lines, the state and the CPU model ride the name")
    return 0


def main(argv):
    if argv == ["--self-test"]:
        return self_test()
    stated = argv[:1] == ["--state"]
    if stated:
        argv = argv[1:]
    if len(argv) < 3 or argv[1] != "--":
        print("usage: step_cpu.py [--state] <label> -- <command>...", file=sys.stderr)
        return 2
    label, cmd = argv[0], argv[2:]
    proc = subprocess.Popen(cmd, stderr=subprocess.PIPE, text=True, errors="replace")
    seen = []
    for line in proc.stderr:
        sys.stderr.write(line)
        if "held " in line or line.startswith("time:"):
            seen.append(line)
    rc = proc.wait()
    u = resource.getrusage(resource.RUSAGE_CHILDREN)
    print("%s: peak %d KB max RSS" % (label, u.ru_maxrss))
    text = "".join(seen)
    state = state_of(text) if stated else ""
    with open("speed.log", "a") as f:
        f.write("speed %s %d\n" % (metric(label, state, cpu_tag()), u.ru_utime + u.ru_stime))
        if stated:
            f.write("speed %s %d\n" % (metric(label, state, cpu_tag(), "phases"), phases_of(text)))
    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
