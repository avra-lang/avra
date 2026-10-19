#!/usr/bin/env python3
"""RUNS ONE CI STEP AND RECORDS WHAT IT COST: the largest process's peak RSS (said), and the step's
user+sys CPU appended to speed.log as `speed cpu-<label>[-warm|-cold] <seconds>`.

    step_cpu.py [--state] <label> -- <command> [args...]

THE STATE RIDES THE NAME. A suite compiles its package held (a warm store: `held N/M` with N > 0 in
its `--time` lines) or from nothing (every N is 0), and the two cost 2-100x apart for the same
tree. A number is only comparable to a baseline taken in the SAME state, so the state is part of the
metric's name (tools/speed_note.sh compares like with like and says aloud when it cannot). A step
that prints no `held` line has no state and keeps the bare name; only a step asked with `--state`
reads one (a suite does; a keeper's own `held` lines are a different question).
"""
import os
import re
import resource
import subprocess
import sys

HELD = re.compile(r"\bheld (\d+)/(\d+)\b")


def state_of(text):
    """'warm' when any derivation held a file, 'cold' when the lines said none did, '' when no line said."""
    seen = [int(m.group(1)) for m in HELD.finditer(text)]
    if not seen:
        return ""
    return "warm" if any(n > 0 for n in seen) else "cold"


def metric(label, state):
    stem = re.sub("[^a-z0-9-]+", "-", label.lower()).strip("-")
    return "cpu-%s%s" % (stem, "-" + state if state else "")


def self_test():
    assert state_of("time: held 0/5, x\ntime: held 0/90, y") == "cold"
    assert state_of("time: held 0/5\ntime: held 1049/1170") == "warm"
    assert state_of("no timing lines here") == ""
    assert metric("std-avrac/@features-a", "cold") == "cpu-std-avrac-features-a-cold"
    assert metric("keepers-a1", "") == "cpu-keepers-a1"
    print("step_cpu: self-test passed — warm/cold/none read from the held lines, the state rides the name")
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
        if "held " in line:
            seen.append(line)
    rc = proc.wait()
    u = resource.getrusage(resource.RUSAGE_CHILDREN)
    print("%s: peak %d KB max RSS" % (label, u.ru_maxrss))
    with open("speed.log", "a") as f:
        f.write("speed %s %d\n" % (metric(label, state_of("".join(seen)) if stated else ""), u.ru_utime + u.ru_stime))
    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
