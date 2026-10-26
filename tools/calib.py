#!/usr/bin/env python3
"""THE RUNNER'S OWN SPEED, measured: a fixed CPU workload, run three times, its least user+sys time
appended to speed.log as `speed calib-ms-<cpu> <milliseconds>`. The speed note reads the growth of this
row against main's as the runner's factor, so a step that grew only as much as the machine slowed gates
nothing, even in a job with too few CPU rows for a median of its own (tools/speed_note.sh).

    calib.py            measure, print, append to speed.log
    calib.py --self-test
"""
import hashlib
import os
import resource
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from step_cpu import cpu_tag

ROUNDS = 3
LINKS = 5000000


def work():
    h = b"avra"
    for _ in range(LINKS):
        h = hashlib.sha256(h).digest()
    return h


def cpu_ms():
    before = resource.getrusage(resource.RUSAGE_SELF)
    work()
    after = resource.getrusage(resource.RUSAGE_SELF)
    return int(((after.ru_utime + after.ru_stime) - (before.ru_utime + before.ru_stime)) * 1000)


def metric(tag):
    return "calib-ms-%s" % tag if tag else "calib-ms"


def self_test():
    global LINKS
    LINKS = 1000
    assert metric("epyc-7763") == "calib-ms-epyc-7763" and metric("") == "calib-ms"
    assert work() == work()
    assert cpu_ms() >= 0
    print("calib: self-test passed — the workload is deterministic, the metric rides the CPU's name")
    return 0


def main(argv):
    if argv == ["--self-test"]:
        return self_test()
    least = min(cpu_ms() for _ in range(ROUNDS))
    print("calib: %d ms (least of %d rounds)" % (least, ROUNDS))
    with open("speed.log", "a") as f:
        f.write("speed %s %d\n" % (metric(cpu_tag()), least))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
