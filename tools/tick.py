#!/usr/bin/env python3
"""The tick's two keepers.

`object` — the hosted source object (`runtime/host/avra_tick.c`, built as
build/avra_tick.o) may call its sleep, its pipe and the scheduler's three
shared bytes, and NOTHING ELSE. A fork in a two-thread process can
inherit a libc lock another thread held at the fork; a thread body that
allocates or takes a lock can be that thread, so its undefined symbols
are held to the no-lock set. This is a property of the THREAD, and the
object's symbol list is the closest the linker can see: every extra name
here is a new place a forked child could inherit a lock.

`threads` — the scheduler's own `runtime/*.c` names no thread and no
thread-local (the footprint door D7). A thread lives in its own object,
never in the scheduler, so a kernel with no threads still builds it.

The two are separate verbs because one reads a built object and the
other reads the tree; the train runs both (`KEEPERS_B`), and a PR runs
`threads` with the keepers that need no compiler.
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OBJECT = os.path.join(ROOT, "build", "avra_tick.o")

# What the source object may name, each with why it is here. Anything
# else is refused by name.
ALLOWED = {
    "nanosleep": "the period it sleeps",
    "clock_nanosleep": "the same on a monotonic clock",
    "poll": "the park on the wake pipe",
    "read": "draining the wake pipe",
    "write": "waking a parked source",
    "pipe": "the wake pipe itself",
    "fcntl": "the wake pipe's non-blocking read end",
    "close": "dropping a forked parent's pipe",
    "pthread_create": "starting the thread, on the scheduler's own thread",
    "getpid": "telling a forked child from its parent",
    "avra_tick": "the byte the source sets",
    "avra_tick_wanted": "what the scheduler stores for the source to read",
    "avra_tick_us": "the period the scheduler read once",
}

# A thread in the scheduler's own files is the door D7 closes.
THREAD = re.compile(r"\b(pthread_|thrd_|__thread\b|_Thread_local\b|thread_local\b)")

NM = ["nm", "-u"]


def undefined(path):
    out = subprocess.run(NM + [path], capture_output=True, text=True)
    if out.returncode != 0:
        return None
    names = []
    for line in out.stdout.splitlines():
        parts = line.split()
        if not parts or parts[0] != "U":
            continue
        name = parts[-1].lstrip("_")
        names.append(name)
    return names


def refused(names):
    """The undefined names the object may not carry. `nm` marks a symbol
    with a leading underscore on Mach-O; the list is in C's spelling."""
    return sorted({n.lstrip("_") for n in names if n.lstrip("_") not in ALLOWED})


def object_check(path):
    names = undefined(path)
    if names is None:
        print(f"tick-object: no object at {path} — build the runtime first")
        return 1
    bad = refused(names)
    if bad:
        print("tick-object: the source names what it may not — "
              + ", ".join(f"`{n}`" for n in bad))
        return 1
    print(f"tick-object: clean — {len(set(names))} undefined symbol(s), all in the no-lock set")
    return 0


def source_files():
    at = os.path.join(ROOT, "runtime")
    return sorted(
        os.path.join(at, f) for f in os.listdir(at)
        if f.endswith(".c")
    )


def threads_check():
    hits = []
    for path in source_files():
        for i, line in enumerate(open(path), 1):
            if THREAD.search(line):
                hits.append(f"{os.path.relpath(path, ROOT)}:{i}: {line.strip()}")
    if hits:
        print("no-threads: the scheduler's own files name a thread — " + "; ".join(hits))
        return 1
    print(f"no-threads: clean — {len(source_files())} runtime/*.c file(s), no thread and no thread-local")
    return 0


def self_test():
    ok = True
    def check(what, got, want):
        nonlocal ok
        if got != want:
            ok = False
            print(f"tick self-test: {what} — got {got!r}, wanted {want!r}")
    # The allow-list is read by the refusal, and a name outside it refuses.
    check("an unknown call is refused", refused(["_nanosleep", "_malloc", "_write"]), ["malloc"])
    check("the no-lock set is accepted", refused(["_" + n for n in ALLOWED]), [])
    # The thread regex reads names, not comments.
    check("pthread is a thread", bool(THREAD.search("pthread_create(&t, 0, f, 0)")), True)
    check("__thread is a thread", bool(THREAD.search("static __thread int x;")), True)
    check("a word containing thread is not", bool(THREAD.search("a threadsafe name")), False)
    if not ok:
        return 1
    print("tick self-test: 5 fixture(s) held")
    return 0


def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        return 64
    if "--self-test" in args:
        if self_test() != 0:
            return 1
    verb = args[0]
    if verb == "object":
        return object_check(OBJECT)
    if verb == "threads":
        return threads_check()
    print(f"tick: no verb `{verb}`")
    return 64


if __name__ == "__main__":
    sys.exit(main())
