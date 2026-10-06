"""Runs a command and watches the machine while it runs: the largest
resident process at each look, by its command, and the least memory the
machine had available. Ends the command before the machine's floor.

    memwatch.py <label> <log> <command>...
"""
import os
import signal
import subprocess
import sys
import time

label, log, command = sys.argv[1], sys.argv[2], sys.argv[3:]


def available_mb():
    for line in open("/proc/meminfo"):
        if line.startswith("MemAvailable"):
            return int(line.split()[1]) // 1024
    return 0


started = time.time()
child = subprocess.Popen(command, stdout=open(log, "w"), stderr=subprocess.STDOUT, start_new_session=True)
peaks, least, ended = {}, available_mb(), "ran to its end"
while child.poll() is None:
    time.sleep(1)
    least = min(least, available_mb())
    rows = subprocess.run(["ps", "-eo", "rss,args", "--sort=-rss"], capture_output=True, text=True).stdout.splitlines()[1:4]
    for row in rows:
        rss, args = row.split(None, 1)
        words = args.split()
        name = " ".join(os.path.basename(w) for w in words[:3])[:60]
        peaks[name] = max(peaks.get(name, 0), int(rss) // 1024)
    if least < 1100:
        os.killpg(child.pid, signal.SIGKILL)
        ended = "ENDED EARLY at 1100 MB available"
        break
child.wait()
print(f"{label}: wall {time.time() - started:.1f} s, {ended}, exit {child.returncode}, least available {least} MB")
for name, mb in sorted(peaks.items(), key=lambda kv: -kv[1])[:6]:
    print(f"  {mb:6d} MB  {name}")
