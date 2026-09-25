import subprocess, sys, re, collections
def sizes(binary):
    out = subprocess.run(['nm', '-n', '--defined-only', binary], capture_output=True, text=True).stdout.split('\n')
    syms = []
    for l in out:
        parts = l.split(' ')
        if len(parts) >= 3 and parts[1] in ('T', 't'):
            syms.append((int(parts[0], 16), parts[2]))
    res = {}
    for (a, n), (b, _) in zip(syms, syms[1:]):
        res[n] = b - a
    return res
def group(n):
    # av_$40std$2Eavrac$2Efeatures$2Evalues... -> module
    m = re.match(r'_?av_\$40std\$2E([a-z_]+)\$2E([a-z_]+)', n)
    if m: return f'{m.group(1)}.{m.group(2)}'
    if n.startswith('_avra_') or n.startswith('avra_'): return 'runtime(C)'
    if n.startswith('_av_') or n.startswith('av_'): return 'program'
    return 'other'
a, b = sizes(sys.argv[1]), sizes(sys.argv[2])
ga, gb = collections.Counter(), collections.Counter()
for n, s in a.items(): ga[group(n)] += s
for n, s in b.items(): gb[group(n)] += s
print(f"text total: {sum(a.values())/1e6:.2f} MB -> {sum(b.values())/1e6:.2f} MB")
rows = sorted(set(ga) | set(gb), key=lambda g: -(gb[g] - ga[g]))
for g in rows[:12]:
    print(f"{gb[g]-ga[g]:+9d}  {ga[g]:9d} -> {gb[g]:9d}  {g}")
print('--- biggest symbol growths')
d = sorted(((b.get(n, 0) - a.get(n, 0), n) for n in set(a) | set(b)), reverse=True)
for dv, n in d[:12]: print(f"{dv:+8d}  {n[:100]}")
