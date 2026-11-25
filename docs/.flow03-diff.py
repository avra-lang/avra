import re, sys
d = {}
for s in ('before', 'after'):
    for w in ('cli', 'std-http'):
        cur = d.setdefault((s, w), {})
        try:
            lines = open('build/census-%s-%s.out' % (s, w)).read().split('\n')
        except OSError as e:
            print('missing', s, w, e); continue
        for l in lines:
            m = re.match(r'(\w+): (\S+) (\d+)$', l.strip())
            if m:
                name = re.sub(r'\$([0-9A-F]{2})', lambda x: chr(int(x.group(1), 16)), m.group(2))
                name = re.sub(r'\^S~\S*', '<..>', name)[:100]
                cur[(m.group(1), name)] = cur.get((m.group(1), name), 0) + int(m.group(3))
for w in ('cli', 'std-http'):
    b, a = d.get(('before', w), {}), d.get(('after', w), {})
    print('==', w, len(b), len(a))
    for k in sorted(set(a) | set(b), key=lambda k: -abs(a.get(k, 0) - b.get(k, 0)))[:16]:
        print('%+12d %12d -> %12d  %s %s' % (a.get(k, 0) - b.get(k, 0), b.get(k, 0), a.get(k, 0), k[0], k[1]))
