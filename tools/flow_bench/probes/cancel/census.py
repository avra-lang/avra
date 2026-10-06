#!/usr/bin/env python3
"""A census of the call sites a cancel test would follow, BY NAME: an
estimate, and an upper bound. A fn MAY REACH a cancel point when its
body parks (a seed) or calls a name that may; a method is matched by
its name alone, so two methods sharing a name share the fact. A call
through a fn value cannot be told from a call by name here: a call
whose name no package declares is counted apart, as one the compiler
would have to assume reaches. Prints per package: fns, fns that may
reach, call sites, call sites followed by a test; then the loops, and
those whose body holds no call that may reach."""
import re, sys, pathlib

SEEDS = re.compile(r'\b(avra_fiber_park_fd|avra_fiber_sleep|avra_fiber_yield|avra_wait_park|avra_task_join)\s*\(|\.await\b')
KEYWORDS = set("if while for match fn return let mut fail spawn defer errdefer within catch else in is use type enum impl trait extern export const once static component quote grammar table spec given then test rule".split())
CALL = re.compile(r'(?<![\w@])([a-z_][a-z0-9_]*)\s*\(')
FN = re.compile(r'^\s*(?:export\s+)?(?:mut\s+|once\s+|static\s+)?fn\s+([a-z_][a-z0-9_]*)')
LOOP = re.compile(r'^\s*(while|for)\b')


def stripped(text):
    """The text with strings and comments blanked, so a brace or a call inside one is not counted."""
    text = re.sub(r'//[^\n]*', '', text)
    return re.sub(r'"(?:\\.|[^"\\])*"', '""', text)


def block_after(lines, i):
    """The lines from `i` to the brace that closes the first one opened there, by nesting."""
    depth, opened, out = 0, False, []
    for line in lines[i:]:
        out.append(line)
        depth += line.count('{') - line.count('}')
        opened = opened or '{' in line
        if opened and depth <= 0:
            break
    return out


def census(roots):
    fns, externs = {}, set()
    per_file = {}
    for root in roots:
        for path in sorted(pathlib.Path(root).rglob('*.av')):
            if '/tests/' in str(path) or str(path).endswith('_test.av'):
                continue
            lines = stripped(path.read_text()).split('\n')
            per_file[path] = lines
            for i, line in enumerate(lines):
                m = FN.match(line)
                if not m:
                    continue
                if re.match(r'^\s*extern\b', line):
                    externs.add(m.group(1))
                    continue
                body = '\n'.join(block_after(lines, i)[0:]) if '{' in ''.join(lines[i:i + 3]) else ''
                fns.setdefault(m.group(1), []).append((path, body))
    reach = {n for n, defs in fns.items() if any(SEEDS.search(b) for _, b in defs)}
    grew = True
    while grew:
        grew = False
        for n, defs in fns.items():
            if n in reach:
                continue
            if any(c in reach for _, b in defs for c in CALL.findall(b.split('\n', 1)[1] if '\n' in b else '')):
                reach.add(n)
                grew = True
    return fns, externs, reach, per_file


def main():
    roots = sys.argv[1:]
    fns, externs, reach, per_file = census(roots)
    print(f"fns by name {len(fns)}; that may reach a cancel point {len(reach)} ({100 * len(reach) // max(len(fns), 1)}%)")
    rows = {}
    for path, lines in per_file.items():
        pkg = str(path).split('/src/')[0].split('/')[-1]
        r = rows.setdefault(pkg, dict(sites=0, tested=0, unknown=0, loops=0, bare=0, whiles=0, bare_whiles=0))
        for i, line in enumerate(lines):
            if FN.match(line):
                line = line.split(')', 1)[-1] if '{' in line else ''
            for c in CALL.findall(line):
                if c in KEYWORDS:
                    continue
                r['sites'] += 1
                if c in reach:
                    r['tested'] += 1
                elif c not in fns and c not in externs and not c.startswith('avra_'):
                    r['unknown'] += 1
            m = LOOP.match(line)
            if m:
                body = '\n'.join(block_after(lines, i))
                bare = not SEEDS.search(body) and not any(c in reach for c in CALL.findall(body))
                r['loops'] += 1
                r['bare'] += bare
                if m.group(1) == 'while':
                    r['whiles'] += 1
                    r['bare_whiles'] += bare
    print(f"{'package':<14} {'call sites':>10} {'tested':>7} {'%':>4} {'not declared here':>18} {'loops':>6} {'no cancel point':>16} {'while':>6} {'no cancel point':>16}")
    for pkg, r in sorted(rows.items()):
        print(f"{pkg:<14} {r['sites']:>10} {r['tested']:>7} {100 * r['tested'] // max(r['sites'], 1):>3}% {r['unknown']:>18} {r['loops']:>6} {r['bare']:>16} {r['whiles']:>6} {r['bare_whiles']:>16}")


main()
