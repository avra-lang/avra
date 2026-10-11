#!/usr/bin/env python3
"""EVERY BLOCKING CALL HOLDS THE WORLD, or says why it is no wait on time.

A virtual clock moves only when every task waits on time; a call that
blocks the thread on the world must hold the clock across it, or every
deadline read around it stands still. Two doors reach C, and both are
read:

  - C the runtime and the packages own (`runtime/*.c`,
    `runtime/host/*.c`, `packages/*/src/c/*.c`): a call of a BLOCKING
    name;
  - an `extern fn` an `.av` file declares with a BLOCKING name: Avra
    calls the library straight, so no C of ours stands between to hold.

THE BLOCKING NAMES: waits (`poll` `ppoll` `select` `pselect` `kevent`
`epoll_wait`), sleeps (`nanosleep` `usleep` `sleep`), reaps (`waitpid`),
the read family (`read` `recv` `recvfrom` `recvmsg` `accept` `accept4`
`connect`), the disk (`fsync` `fdatasync` `flock`), the resolver
(`getaddrinfo`), and a database that sleeps in its busy handler
(`sqlite3_step` `sqlite3_exec`). NOT READ, and why: writes and sends
(`write` `send` …) — they wait on a reader's room, a wait no deadline
around them is written against today; and VENDORED C
(`packages/*/vendor`), counted below — compression, hashing and TLS
block on nothing, and sqlite's waits are taken at its door, the
`extern fn` above.

A call is HELD when, in code with comments taken out, `avra_clock_hold(1)`
stands within three lines above it and `avra_clock_hold(-1)` within three
lines below. PROXIMITY CANNOT TELL a hold inside an `if` from one on the
call's own path, nor a hold given back early on another branch: those are
the reader's to see. A call that cannot wait on time, or is knowingly not
held, says so on the line above: `// the clock: <why>`, with a reason of
three words at least. Anything else is refused, by file and line.

    clock_holds.py          the tree
    clock_holds.py --self   the fixtures alone
"""
import glob
import re
import sys

BLOCKING = ("poll|ppoll|select|pselect|kevent|epoll_wait|nanosleep|usleep|sleep|waitpid|"
            "read|recv|recvfrom|recvmsg|accept|accept4|connect|fsync|fdatasync|flock|"
            "getaddrinfo|sqlite3_step|sqlite3_exec")
CALL = re.compile(r"(?<![A-Za-z_0-9.>])(" + BLOCKING + r")\s*\(")
EXTERN = re.compile(r"^\s*(?:export\s+)?extern\s+fn\s+(" + BLOCKING + r")\s*\(")
EXCUSE = re.compile(r"//\s*the clock:\s*(.*)$")
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


def excused(line):
    """Whether `line` excuses the call under it: a reason, not a bare mark."""
    m = EXCUSE.search(line)
    return bool(m) and len(m.group(1).split()) >= 3


def faults(path, lines, pattern=CALL):
    """Each blocking call in `lines` neither held nor excused."""
    out = []
    code = code_of(lines) if pattern is CALL else lines
    for i, c in enumerate(code):
        hit = pattern.search(c)
        if not hit:
            continue
        if i > 0 and excused(lines[i - 1]):
            continue
        before = code[max(0, i - REACH):i]
        after = code[i + 1:i + 1 + REACH]
        if any("avra_clock_hold(1)" in b for b in before) and any("avra_clock_hold(-1)" in a for a in after):
            continue
        out.append(f"{path}:{i + 1}: `{hit.group(1)}` blocks without holding the clock — wrap it in avra_clock_hold(1)/(-1), or say `// the clock: <why>` above it")
    return out


def proved():
    """The keeper's own cases, each a hole it once had or a shape it must
    accept."""
    c = [
        ("held", ["avra_clock_hold(1);", "int r = poll(fds, n, ms);", "avra_clock_hold(-1);"], 0),
        ("excused", ["// the clock: a zero timeout", "int n = kevent(fd, NULL, 0, evs, 8, &now);"], 0),
        ("bare", ["nanosleep(&ts, NULL);"], 1),
        ("half held", ["avra_clock_hold(1);", "waitpid(pid, &st, 0);"], 1),
        ("excused too far up", ["// the clock: far away here", "int x = 0;", "usleep(10);"], 1),
        ("a method named alike", ["w->sleep(3);", "self.poll(1);"], 0),
        ("a comment", ["// poll(fds) would block", "/* sleep(1) */"], 0),
        ("a comment over lines", ["/* a server", "   may select (one) */", "x = 1;"], 0),
        ("code after a closed comment", ["/* note */ usleep(5);"], 1),
        ("a hold commented out", ["// avra_clock_hold(1);", "poll(fds, n, ms);", "// avra_clock_hold(-1);"], 1),
        ("an excuse with no reason", ["// the clock:", "fsync(fd);"], 1),
        ("an excuse of one word", ["// the clock: fine", "fsync(fd);"], 1),
        ("the resolver", ["int rc = getaddrinfo(host, service, &hints, out);"], 1),
        ("a read", ["ssize_t got = read(fd, buf, n);"], 1),
        ("a database step", ["int rc = sqlite3_step(stmt);"], 1),
    ]
    av = [
        ("an extern to a step", ["export extern fn sqlite3_step(stmt: ptr?) -> i32"], 1),
        ("an extern excused", ["// the clock: not held, a reason here", "extern fn sqlite3_step(s: ptr?) -> i32"], 0),
        ("an extern of another name", ["extern fn sqlite3_reset(s: ptr?) -> i32"], 0),
    ]
    bad = [name for name, lines, want in c if len(faults("fixture", lines)) != want]
    bad += [name for name, lines, want in av if len(faults("fixture", lines, EXTERN)) != want]
    return len(c) + len(av), bad


def main():
    n, bad = proved()
    if bad:
        print("clock-holds: the keeper fails its own cases: " + ", ".join(bad))
        return 1
    if "--self" in sys.argv:
        print(f"clock-holds: {n} of the keeper's own cases hold")
        return 0
    sources = sorted(glob.glob("runtime/*.c") + glob.glob("runtime/host/*.c")
                      + glob.glob("packages/*/src/c/*.c"))
    declaring = sorted(p for p in glob.glob("packages/**/*.av", recursive=True) if "/tests/" not in p)
    vendored = sorted(glob.glob("packages/*/vendor/**/*.c", recursive=True))
    found, calls, externs = [], 0, 0
    for path in sources:
        lines = open(path, encoding="utf-8", errors="replace").read().split("\n")
        calls += sum(1 for c in code_of(lines) if CALL.search(c))
        found += faults(path, lines)
    for path in declaring:
        lines = open(path, encoding="utf-8", errors="replace").read().split("\n")
        externs += sum(1 for l in lines if EXTERN.search(l))
        found += faults(path, lines, EXTERN)
    for f in found:
        print(f)
    print(f"clock-holds: {len(sources)} C source(s) read, {calls} blocking call(s); {len(declaring)} .av file(s) read, {externs} blocking extern(s); {len(vendored)} vendored C file(s) not read; {len(found)} unheld; {n} of the keeper's own cases hold")
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main())
