import sys, re, collections
def dem(s):
    s = re.sub(r'\$([0-9A-F]{2})', lambda m: chr(int(m.group(1),16)), s)
    s = s.replace('av_@std.', '').replace('av_', '')
    s = s.split('$^')[0].split('$')[0]
    return s[:70]
RT = re.compile(r'^(avra_|array_|box_|buf_|str_|_int_|__|malloc|free|cfree|map_|hdr|slot_|cell_|\[unknown\]|note_)')
incl = collections.Counter(); selfc = collections.Counter(); attr = collections.Counter()
leafcaller = collections.defaultdict(collections.Counter)
n = 0
stack = []
def flush():
    global n
    if not stack: return
    n += 1
    fr = [dem(f) for f in stack]
    selfc[fr[0]] += 1
    for f in set(fr): incl[f] += 1
    # first non-runtime frame
    owner = next((f for f in fr if not RT.match(f)), '?')
    attr[owner] += 1
    if RT.match(fr[0]): leafcaller[fr[0]][owner] += 1
for line in sys.stdin:
    line = line.rstrip('\n')
    if not line.strip():
        flush(); stack = []; continue
    if line.startswith('\t') or line.startswith(' '):
        parts = line.strip().split(None, 1)
        if len(parts) == 2:
            sym = parts[1].rsplit(' (', 1)[0]
            sym = sym.split('+0x')[0]
            stack.append(sym)
flush()
pct = lambda c: '%5.1f%%' % (100.0*c/n)
print('samples', n)
print('== inclusive'); [print(pct(c), f) for f, c in incl.most_common(int(sys.argv[1]) if len(sys.argv)>1 else 60)]
print('== self+runtime attributed to first avra caller'); [print(pct(c), f) for f, c in attr.most_common(45)]
print('== runtime leaf callers')
for leaf, _ in selfc.most_common(14):
    if leaf in leafcaller:
        print(pct(selfc[leaf]), leaf, ' <- ', ', '.join('%s %s' % (f, pct(c)) for f, c in leafcaller[leaf].most_common(5)))
