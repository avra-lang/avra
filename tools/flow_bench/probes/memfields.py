"""Runs a command and, at the moment the machine had least memory
available, says where the memory was: the kernel's own ledger, the
largest processes, and how many processes stood.

    memfields.py <label> <log> <command>...
"""
import os
import signal
import subprocess
import sys
import time

label, log, command = sys.argv[1], sys.argv[2], sys.argv[3:]
KEYS = ["MemAvailable", "MemFree", "AnonPages", "Cached", "Dirty", "Shmem", "Slab", "SUnreclaim", "PageTables", "KernelStack", "Mapped", "Committed_AS"]


def ledger():
    out = {}
    for line in open("/proc/meminfo"):
        k, v = line.split(":")
        if k in KEYS:
            out[k] = int(v.split()[0]) // 1024
    return out


started = time.time()
child = subprocess.Popen(command, stdout=open(log, "w"), stderr=subprocess.STDOUT, start_new_session=True)
low, at_low, procs_low, ended = ledger(), "", 0, "ran to its end"
before = dict(low)
while child.poll() is None:
    time.sleep(0.5)
    now = ledger()
    if now["MemAvailable"] < low["MemAvailable"]:
        low = now
        rows = subprocess.run(["ps", "-eo", "rss,vsz,nlwp,args", "--sort=-rss"], capture_output=True, text=True).stdout.splitlines()[1:]
        procs_low = len(rows)
        at_low = "; ".join(f"{int(r.split()[0]) // 1024} MB rss / {int(r.split()[1]) // 1024} MB virt {os.path.basename(r.split()[3])}" for r in rows[:3])
    if now["MemAvailable"] < 640:
        os.killpg(child.pid, signal.SIGKILL)
        ended = "ENDED EARLY at 640 MB available"
        break
child.wait()
print(f"{label}: wall {time.time() - started:.1f} s, {ended}, exit {child.returncode}")
print("  before: " + ", ".join(f"{k} {before[k]}" for k in KEYS))
print("  lowest: " + ", ".join(f"{k} {low[k]}" for k in KEYS))
print(f"  at the lowest: {procs_low} processes; {at_low}")
