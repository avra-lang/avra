import re, sys, collections
t=sys.argv[1]
names={}
for l in open(f'/work/out/census-{t}.names'):
    a,*n=l.split(); names[a]=(n[0] if n else a)
def dec(s):
    for a,b in [('$2F','/'),('$2E','.'),('$40','@'),('$24','$'),('$20',' '),('$3B',';')]: s=s.replace(a,b)
    return s
def part(f):
    if 'grammar/lexer.av' in f or 'grammar/bridge.av' in f: return 'lexer'
    if '@std/grammar/' in f or 'untold' in f: return 'parser'
    if 'node_scaffold' in f or 'build_row' in f or 'builders' in f: return 'builders'
    return None
cnt=collections.defaultdict(collections.Counter); top=collections.defaultdict(collections.Counter)
for l in open(f'/work/out/census-{t}.raw'):
    m=re.match(r'(\S+): site (0x[0-9a-f]+) (\d+)',l)
    if not m: continue
    f=dec(names.get(m.group(2),m.group(2))); p=part(f)
    if p: cnt[m.group(1)][p]+=int(m.group(3)); top[(m.group(1),p)][f]+=int(m.group(3))
tot=[l for l in open(f'/work/out/census-{t}.raw') if l.startswith('rc:') or l.startswith('alloc: ')]
print(''.join(tot))
for c in ['made','retain','push','append','empty']:
    print(c, dict(cnt[c]))
for p in ['lexer']:
    for c in ['made','retain']:
        print(' ', c, p, [(n, f.split('/')[-1][:60]) for f,n in top[(c,p)].most_common(6)])
