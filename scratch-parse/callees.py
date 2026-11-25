import sys, re, collections
def dem(s):
    s = re.sub(r'\$([0-9A-F]{2})', lambda m: chr(int(m.group(1),16)), s)
    s = s.replace('av_@std.', '').replace('av_', '')
    return s.split('$^')[0].split('$')[0][:60]
targets = sys.argv[1:]
res = {t: collections.Counter() for t in targets}
tot = {t: 0 for t in targets}
n = 0; stack = []
def flush():
    global n
    if not stack: return
    n += 1
    fr = [dem(f) for f in stack]
    for t in targets:
        # innermost occurrence of t; its callee is the frame before it
        if t in fr:
            i = fr.index(t)
            tot[t] += 1
            res[t][fr[i-1] if i > 0 else '<self>'] += 1
for line in sys.stdin:
    line = line.rstrip('\n')
    if not line.strip():
        flush(); stack = []; continue
    if line[0] in ' \t':
        p = line.strip().split(None, 1)
        if len(p) == 2: stack.append(p[1].rsplit(' (', 1)[0].split('+0x')[0])
flush()
for t in targets:
    print('== %s %.1f%%' % (t, 100.0*tot[t]/n))
    for f, c in res[t].most_common(14): print('   %5.1f%% %s' % (100.0*c/n, f))
