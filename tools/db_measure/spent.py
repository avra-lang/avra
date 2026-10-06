#!/usr/bin/env python3
"""Wall, user CPU and peak of one command, with the compiler's own `time:` line.

    python3 tools/db_measure/spent.py <log file> <command...>
"""
import resource
import subprocess
import sys
import time

log = sys.argv[1]
began = time.time()
with open(log, "w") as f:
    status = subprocess.call(sys.argv[2:], stdout=f, stderr=subprocess.STDOUT)
used = resource.getrusage(resource.RUSAGE_CHILDREN)
timed = [line.strip() for line in open(log, errors="replace") if line.startswith("time:")]
print(
    f"wall_ms={int((time.time() - began) * 1000)}\tuser_ms={int(used.ru_utime * 1000)}"
    f"\tpeak_mb={used.ru_maxrss // 1024}\tstatus={status}\t{timed[-1] if timed else ''}"
)
