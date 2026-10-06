#!/usr/bin/env python3
"""Rewrites a program's LLVM IR to carry the cancel slice's tests, so
their price is measured on the code Avra emits. Two rewrites:

  after  one test after every call that MAY REACH a cancel point: a
         direct call to a fn that parks or calls one that may (a
         fixpoint over the module's own call graph), and every call
         through a register. A CALL THROUGH A REGISTER MAY REACH
         ANYTHING, so the fn making one may reach too — `byte` (one
         global byte) and `task` (the current task's record, then its
         byte) hold that rule. `known` is the floor: the test still
         follows a call through a register, but the fn making it is not
         taken to reach, as if every fn value said whether it waits.
  edge   one test before every branch back to an earlier block: a loop's
         back-edge, as the emitter lays blocks out.
  go     the owner's D5 and the lead's ruling together: a `while`
         back-edge is a cancel point, so a fn whose source holds a
         `while` (whiles.py's list) may reach, its callers are tested
         after the call, and its back-edges carry the tick's test. The
         emitter lays a `for` and a `while` out alike, so every
         back-edge of such a fn is tested: an upper bound.

The taken side is cold and out of line. Prints the census it rewrote by.
usage: rewrite.py <in.ll> <out.ll> plain|byte|task|known|edge|go [<whiles.txt>]"""
import re, sys

PARKS = re.compile(r'^@avra_(task_join|task_settle\w*|tasks_\w+|fiber_sleep|fiber_yield|fiber_park_fd|wait_park)$')
CALL = re.compile(r'\bcall\b.*?\s(@"[^"]+"|@[\w.$-]+|%[\w.$-]+)\(')
DEFINE = re.compile(r'^define\b.*?(@"[^"]+"|@[\w.$-]+)\(')
LABEL = re.compile(r'^("[^"]+"|[\w.$-]+):')
PHI_FROM = re.compile(r', %("[^"]+"|[\w.$-]+) \]')
TARGET = re.compile(r'label %("[^"]+"|[\w.$-]+)')


def functions(lines):
    """Each definition as (name, first body line, the closing brace's line)."""
    out, i = [], 0
    while i < len(lines):
        m = DEFINE.match(lines[i])
        if m:
            end = i
            while lines[end] != '}':
                end += 1
            out.append((m.group(1), i + 1, end))
            i = end
        i += 1
    return out


def source_name(symbol):
    """An emitted symbol as its source name: unmangled, with no instantiation or lambda suffix."""
    name = re.sub(r'\$([0-9A-F]{2})', lambda m: chr(int(m.group(1), 16)), symbol.strip('@"'))
    return name.removeprefix('av_').split('$')[0]


def reaching(lines, fns, through_registers, spinning=frozenset()):
    """The fns that may reach a cancel point: those that park, those that
    call through a register when `through_registers`, and their callers."""
    callees = {}
    for name, lo, hi in fns:
        callees[name] = {m.group(1) for line in lines[lo:hi] for m in [CALL.search(line)] if m}
    reach = {n for n, cs in callees.items() if n in spinning or any(PARKS.match(c) or (through_registers and c.startswith('%')) for c in cs)}
    grew = True
    while grew:
        grew = False
        for n, cs in callees.items():
            if n not in reach and cs & reach:
                reach.add(n)
                grew = True
    return reach


def tested(line, reach):
    m = CALL.search(line)
    if not m or 'musttail' in line:
        return False
    callee = m.group(1)
    return callee.startswith('%') or callee in reach or bool(PARKS.match(callee))


def load_of(mode, n):
    if mode == 'task':
        return [f'  %uw.t{n} = load ptr, ptr @avra_probe_task, align 8', f'  %uw.p{n} = getelementptr inbounds i8, ptr %uw.t{n}, i64 64', f'  %uw.b{n} = load i8, ptr %uw.p{n}, align 1']
    return [f'  %uw.b{n} = load i8, ptr @avra_probe_byte, align 1']


def rewritten(lines, mode, whiles=frozenset()):
    fns = functions(lines)
    spinning = {n for n, _, _ in fns if source_name(n) in whiles} if mode == 'go' else set()
    reach = reaching(lines, fns, mode != 'known', spinning)
    stats = dict(fns=len(fns), reach=len(reach), calls=0, tested=0, indirect=0, edges=0, blocks=0, spinning=len(spinning))
    out, at, n = [], 0, 0
    for name, lo, hi in fns:
        out += lines[at:lo]
        body, final, order, label, cold = [], {}, {}, None, []
        for line in lines[lo:hi]:
            m = LABEL.match(line)
            if m:
                label = m.group(1)
                order[label] = len(order)
                stats['blocks'] += 1
        label = None
        for line in lines[lo:hi]:
            m = LABEL.match(line)
            if m:
                label = m.group(1)
            call = CALL.search(line)
            if call:
                stats['calls'] += 1
                stats['indirect'] += call.group(1).startswith('%')
            if mode in ('byte', 'task', 'known', 'go') and tested(line, reach):
                n += 1
                stats['tested'] += 1
                body.append(line)
                body += load_of(mode, n) + [f'  %uw.c{n} = icmp ne i8 %uw.b{n}, 0', f'  br i1 %uw.c{n}, label %uw.exit, label %uw.k{n}, !prof !987654', '', f'uw.k{n}:']
                final[label] = f'uw.k{n}'
                if not cold:
                    cold = ['', 'uw.exit:', '  call void @avra_probe_unwound()', '  unreachable']
                continue
            back = (mode == 'edge' or name in spinning) and line.startswith('  br ') and label is not None and any(order.get(t, 1 << 30) <= order[label] for t in TARGET.findall(line))
            if back:
                n += 1
                stats['edges'] += 1
                body += [f'  %tk.b{n} = load i8, ptr @avra_probe_tick, align 1', f'  %tk.c{n} = icmp ne i8 %tk.b{n}, 0', f'  br i1 %tk.c{n}, label %tk.cold{n}, label %tk.k{n}, !prof !987654', '', f'tk.k{n}:', line]
                cold += ['', f'tk.cold{n}:', '  call void @avra_probe_preempted()', f'  br label %tk.k{n}']
                final[label] = f'tk.k{n}'
                continue
            body.append(line)
        if final:
            body = [PHI_FROM.sub(lambda m: f', %{final.get(m.group(1), m.group(1))} ]', l) if ' phi ' in l else l for l in body]
        out += body + cold
        at = hi
    out += lines[at:]
    out += ['', '@avra_probe_byte = external global i8', '@avra_probe_tick = external global i8', '@avra_probe_task = external global ptr', 'declare void @avra_probe_unwound() cold noreturn', 'declare void @avra_probe_preempted() cold', '!987654 = !{!"branch_weights", i32 1, i32 1048575}']
    return out, stats


def main():
    src, dst, mode = sys.argv[1:4]
    whiles = frozenset(open(sys.argv[4]).read().split()) if len(sys.argv) > 4 else frozenset()
    lines = open(src).read().split('\n')
    out, s = rewritten(lines, mode, whiles)
    open(dst, 'w').write('\n'.join(out))
    print(f"{mode}: fns {s['fns']}, may reach a cancel point {s['reach']}; calls {s['calls']} (through a register {s['indirect']}), tested {s['tested']}; blocks {s['blocks']}, back-edges tested {s['edges']}; fns holding a `while` {s['spinning']}")


main()
