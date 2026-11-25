import sys, re, collections
raw = open(sys.argv[1]).read().splitlines()
rc = [l for l in raw if l.startswith('rc:')]
for l in rc: print(l)
rows = {}
for l in raw:
    m = re.match(r'rowname:\s+(\d+)\s+[\d.]+%\s+(\d+) B\s+(.*)$', l)
    if m: rows[m.group(3)] = int(m.group(1))
groups = collections.defaultdict(list)
for k, n in rows.items():
    for p in ('retain: ', 'release: ', 'cell: ', 'reuse: ', 'owned: '):
        if k.startswith(p): groups[p.strip(': ')].append((n, k[len(p):]))
G = 1e9
for g in ('retain', 'release', 'cell', 'reuse', 'owned'):
    tot = sum(n for n, _ in groups[g])
    print(f'\n{g}: {tot/G:.3f} G executed (labelled)')
    for n, k in sorted(groups[g], reverse=True): print(f'  {n/G:8.3f} G  {k}')
print('\ngeneric emitted: retain %.3f G, release %.3f G' % (rows.get('retain', 0)/G, rows.get('release', 0)/G))
print('\ntop row calls:')
for k, n in sorted(rows.items(), key=lambda x: -x[1])[:40]:
    if not re.match(r'(retain|release|cell|reuse|owned): ', k): print(f'  {n/G:8.3f} G  {k}')
