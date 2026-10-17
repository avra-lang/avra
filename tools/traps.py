#!/usr/bin/env python3
"""THE TRAPS COLUMN'S KEEPER.

`RtSig.traps` (packages/std-avrac/src/core/runtime_api.av) says whether a
runtime row can raise a trap a guard catches. A row marked `traps: false`
is declared `nounwind`, so a call of it is given no unwind edge and the
cleanups of the frame around it are skipped when it traps. A WRONG MARK IS
THEREFORE SILENT: the trap is still caught, and the frame's deferred
calls never run.

So the column has two readers — the backend, which trusts it, and this
keeper, which holds it to the C. For each row marked false it walks the
C body and every C fn that body reaches (the runtime's own, inlined leaves
included) and lists each call of `avra_trap` or a sibling it can arrive
at. The fn that makes such a call must be excused in `tools/traps.allow`:

    <fn that calls the trap>   # why this trap is fatal by design

— an allocation that ran out of memory, a header that is not ours, a
memory ceiling: a DEFECT or a limit of the process, never a trap the
language raises. Anything else is refused with the chain that reaches it,
and the fix is `traps: true` on the row. An allow line that no marked row
reaches is refused too, so the file cannot outlive what it excuses.
"""
import re, sys, glob, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SINKS = re.compile(r"^(avra_trap\w*|abort|exit|_exit)$")
KEYWORDS = {"if", "while", "for", "switch", "return", "sizeof", "defined", "__builtin_expect",
            "__builtin_unreachable", "__builtin_offsetof", "_Static_assert", "typeof", "__typeof__"}


def marked_rows():
    text = open(os.path.join(ROOT, "packages/std-avrac/src/core/runtime_api.av")).read()
    out = []
    for m in re.finditer(r'name:\s*"(avra_\w+)",(.*?)\n\s{8}\},', text, re.S):
        if re.search(r"\btraps:\s*false\b", m.group(2)):
            out.append(m.group(1))
    return out


def c_bodies():
    """fn name -> (file, body text), over the runtime's C and headers."""
    bodies = {}
    paths = sorted(glob.glob(os.path.join(ROOT, "runtime", "*.c")) + glob.glob(os.path.join(ROOT, "runtime", "*.h")))
    head = re.compile(r"^[A-Za-z_][\w\s\*]*?\b(\w+)\s*\([^;{}]*\)[^;{}]*\{", re.M)
    for path in paths:
        text = open(path).read()
        for m in head.finditer(text):
            name = m.group(1)
            if name in KEYWORDS:
                continue
            depth, i = 1, m.end()
            while i < len(text) and depth:
                depth += (text[i] == "{") - (text[i] == "}")
                i += 1
            bodies.setdefault(name, (os.path.relpath(path, ROOT), text[m.end():i]))
    return bodies


def calls_in(body):
    body = re.sub(r"//[^\n]*|/\*.*?\*/", "", body, flags=re.S)
    return [c for c in re.findall(r"\b([A-Za-z_]\w*)\s*\(", body) if c not in KEYWORDS]


def reaches(row, bodies):
    """Every (fn that calls a sink, chain from the row) the row reaches."""
    found, seen = {}, set()
    stack = [(row, [row])]
    while stack:
        fn, chain = stack.pop()
        if fn in seen or fn not in bodies:
            continue
        seen.add(fn)
        for callee in calls_in(bodies[fn][1]):
            if SINKS.match(callee):
                found.setdefault(fn, chain + [callee])
            elif callee in bodies and callee not in seen:
                stack.append((callee, chain + [callee]))
    return found


def allowed():
    out = {}
    path = os.path.join(ROOT, "tools", "traps.allow")
    if os.path.exists(path):
        for line in open(path):
            line = line.split("#")[0].split()
            if len(line) == 1:
                out[line[0]] = False
    return out


def selftest():
    """The keeper's own cases, on a synthetic C: a direct trap is found, a
    chain through a helper is found with its path, a clean body is quiet."""
    synthetic = {
        "row_direct": ("x.c", "if (i < 0) avra_trap_bounds(i, n);"),
        "row_chain": ("x.c", "return helper(a);"),
        "helper": ("x.c", "if (!a) abort();"),
        "row_clean": ("x.c", "return a->len;"),
    }
    assert reaches("row_direct", synthetic) == {"row_direct": ["row_direct", "avra_trap_bounds"]}
    assert reaches("row_chain", synthetic) == {"helper": ["row_chain", "helper", "abort"]}
    assert reaches("row_clean", synthetic) == {}
    return 3


def main():
    cases = selftest()
    rows, bodies, allow = marked_rows(), c_bodies(), allowed()
    refused = []
    for row in rows:
        if row not in bodies:
            refused.append(f"traps: {row} is marked `traps: false` and has no C body this keeper can read")
            continue
        for caller, chain in reaches(row, bodies).items():
            if caller in allow:
                allow[caller] = True
            else:
                refused.append(f"traps: {row} is marked `traps: false` but reaches a trap: " + " -> ".join(chain)
                               + f"\n  (a trap the language raises needs `traps: true`; a defect or limit of the process is excused in tools/traps.allow as `{caller}`)")
    for caller, used in sorted(allow.items()):
        if not used:
            refused.append(f"traps: tools/traps.allow excuses `{caller}` and no marked row reaches it")
    if refused:
        print("\n".join(refused))
        print(f"traps: {len(refused)} refusal(s)")
        sys.exit(1)
    print(f"traps: {len(rows)} row(s) marked `traps: false` reach only the traps tools/traps.allow excuses ({len(allow)} excuse(s), {len(bodies)} C fn(s) read, {cases} of the keeper\'s own cases hold)")


if __name__ == "__main__":
    main()
