import subprocess, os, re, sys, collections, json
# Warning-only differences between the old path and the program layer, by kind.
# usage: python3 warn.py <tsv with a `source` column> <out.json>
src_file, out = sys.argv[1], sys.argv[2]
rows = [l.rstrip('\n').split('\t') for l in open(src_file)]
head, rows = rows[0], rows[1:]
col = head.index('source')
os.makedirs('/tmp/ww', exist_ok=True)

import shutil
def materialize(src):
    root = '/tmp/ww/pkg'
    shutil.rmtree(root, ignore_errors=True)
    if not src.startswith('// /w/'):
        os.makedirs(root, exist_ok=True); open(root + '/x.av', 'w').write(src); return root + '/x.av'
    cur = None; parts = {}
    for line in src.split('\n'):
        if line.startswith('// /w/'): cur = line[len('// /w/'):].strip(); parts[cur] = []
        elif cur is not None: parts[cur].append(line)
    for p, lines in parts.items():
        path = os.path.join(root, p); os.makedirs(os.path.dirname(path), exist_ok=True)
        open(path, 'w').write('\n'.join(lines))
    for m in re.findall(r'path = "vendor/([a-z_-]+)"', src):
        held = os.path.join(root, 'vendor', m)
        if os.path.exists(held): continue
        for cand in ('/work/avra/packages/std-' + m, '/work/avra/packages/' + m):
            if os.path.exists(cand + '/avra.toml'):
                os.makedirs(os.path.join(root, 'vendor'), exist_ok=True); os.symlink(cand, held); break
    return root

def run(src, old):
    target = materialize(src)
    e = dict(os.environ)
    if old: e['AVRA_PROGRAM'] = '0'
    else: e['AVRA_PROGRAM_NET'] = '0'
    try:
        o = subprocess.run(['/work/avra/build/avra-try', 'check', target], capture_output=True, text=True, env=e, timeout=90)
        txt = o.stdout + o.stderr
    except Exception:
        txt = 'avra: TIMEOUT'
    return re.findall(r'^warning\[([a-z_.]+)\]: (.*)$', txt, re.M)

def unesc(s): return s.replace('\\n', '\n').replace('\\t', '\t').replace('\\\\', '\\')

layer_only = collections.Counter(); old_only = collections.Counter()
progs_layer = collections.Counter(); progs_old = collections.Counter()
examples = {}; per = []
for r in rows:
    src = unesc(r[col])
    o = run(src, True); n = run(src, False)
    oc = collections.Counter(o); nc = collections.Counter(n)
    lo = nc - oc; oo = oc - nc
    for (k, m), c in lo.items(): layer_only[k] += c; examples.setdefault(('layer', k), (src, m))
    for (k, m), c in oo.items(): old_only[k] += c; examples.setdefault(('old', k), (src, m))
    for k in {k for k, _ in lo}: progs_layer[k] += 1
    for k in {k for k, _ in oo}: progs_old[k] += 1
    if lo or oo: per.append({'src': src, 'layer_only': list(lo.elements()), 'old_only': list(oo.elements())})
json.dump({'per': per, 'examples': {f'{a}|{k}': v for (a, k), v in examples.items()}}, open(out, 'w'))
print('programs', len(rows), 'with a warning difference', len(per))
print('LAYER-ONLY warnings (kind, diagnostics, programs):')
for k, v in layer_only.most_common(): print(f'  {v:4d} {progs_layer[k]:4d}  {k}   e.g. {examples[("layer", k)][1][:90]}')
print('OLD-ONLY warnings (kind, diagnostics, programs):')
for k, v in old_only.most_common(): print(f'  {v:4d} {progs_old[k]:4d}  {k}   e.g. {examples[("old", k)][1][:90]}')
