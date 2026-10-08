#!/usr/bin/env python3
"""EVERY BLOCKING CALL IN C HOLDS THE WORLD, or says why it is no wait.

A virtual clock moves only when every task waits on time; a call that
blocks the thread on the world — a poll, a sleep, a reap — must hold the
clock across it, or every deadline read around it stands still. This
reads every C source the runtime and the packages own and finds each
call that can block: `poll`, `ppoll`, `select`, `pselect`, `nanosleep`,
`usleep`, `sleep`, `kevent`, `epoll_wait`, `waitpid`.

A call is HELD when `avra_clock_hold(1)` stands within three lines above
it and `avra_clock_hold(-1)` within three lines below. A call that cannot
wait on time says so on the line above: `// the clock: <why>`. Anything
else is refused, by file and line.

    clock_holds.py          the tree
    clock_holds.py --self   the fixtures alone
"""
import glob
import re
import sys

CALL = re.compile(r"(?<![A-Za-z_0-9.>])(poll|ppoll|select|pselect|nanosleep|usleep|sleep|kevent|epoll_wait|waitpid)\s*\(")
REACH = 3


def code_of(lines):
    """Each line with its comments taken out: `//` to the end, and every
    `/* … */`, which may span lines."""
    out, inside = [], False
    for line in lines:
        kept, i = "", 0
        while i < len(line):
            if inside:
                end = line.find("*/", i)
                if end < 0:
                    i = len(line)
                    continue
                inside, i = False, end + 2
            elif line.startswith("/*", i):
                inside, i = True, i + 2
            elif line.startswith("//", i):
                break
            else:
                kept += line[i]
                i += 1
        out.append(kept)
    return out


def faults(path, lines):
    """Each blocking call in `lines` neither held nor excused."""
    out = []
    for i, code in enumerate(code_of(lines)):
        if not CALL.search(code):
            continue
        before = lines[max(0, i - REACH):i]
        after = lines[i + 1:i + 1 + REACH]
        if any("// the clock:" in b for b in before[-1:]):
            continue
        if any("avra_clock_hold(1)" in b for b in before) and any("avra_clock_hold(-1)" in a for a in after):
            continue
        out.append(f"{path}:{i + 1}: `{CALL.search(code).group(1)}` blocks without holding the clock — wrap it in avra_clock_hold(1)/(-1), or say `// the clock: <why>` above it")
    return out


def proved():
    """The keeper's own cases: a held call and an excused one pass, a bare
    one, a half-held one and an excuse two lines up are refused."""
    cases = [
        ("held", ["avra_clock_hold(1);", "int r = poll(fds, n, ms);", "avra_clock_hold(-1);"], 0),
        ("excused", ["// the clock: a zero timeout", "int n = kevent(fd, NULL, 0, evs, 8, &now);"], 0),
        ("bare", ["nanosleep(&ts, NULL);"], 1),
        ("half held", ["avra_clock_hold(1);", "waitpid(pid, &st, 0);"], 1),
        ("excused too far up", ["// the clock: far", "int x = 0;", "usleep(10);"], 1),
        ("a method named alike", ["w->sleep(3);", "self.poll(1);"], 0),
        ("a comment", ["// poll(fds) would block", "/* sleep(1) */"], 0),
        ("a comment over lines", ["/* a server", "   may select (one) */", "x = 1;"], 0),
        ("code after a closed comment", ["/* note */ usleep(5);"], 1),
    ]
    bad = [name for name, lines, want in cases if len(faults("fixture", lines)) != want]
    return len(cases), bad


def main():
    n, bad = proved()
    if bad:
        print("clock-holds: the keeper fails its own cases: " + ", ".join(bad))
        return 1
    if "--self" in sys.argv:
        print(f"clock-holds: {n} of the keeper's own cases hold")
        return 0
    sources = sorted(glob.glob("runtime/*.c") + glob.glob("packages/*/src/c/*.c"))
    found, calls = [], 0
    for path in sources:
        lines = open(path, encoding="utf-8", errors="replace").read().split("\n")
        calls += sum(1 for c in code_of(lines) if CALL.search(c))
        found += faults(path, lines)
    for f in found:
        print(f)
    print(f"clock-holds: {len(sources)} C source(s) read, {calls} blocking call(s), {len(found)} unheld; {n} of the keeper's own cases hold")
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main())
