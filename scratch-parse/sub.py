import sys, re, collections
def dem(s):
    s = re.sub(r'\$([0-9A-F]{2})', lambda m: chr(int(m.group(1),16)), s)
    s = s.replace('av_@std.', '').replace('av_', '')
    return s.split('$^')[0].split('$')[0][:60]
RT = re.compile(r'^(avra_|array_|box_|buf_|str_|_int_|__|malloc|free|cfree|map_|hdr|slot_|cell_|\[unknown\]|note_|push_grown|realloc|read$|memcpy|memset|tcache|unlink_chunk)')
root = sys.argv[1]
n = 0; sub = 0; attr = collections.Counter(); leafs = collections.Counter(); incl = collections.Counter()
stack = []
def flush():
    global n, sub
    if not stack: return
    n += 1
    fr = [dem(f) for f in stack]
    if root not in fr: return
    sub += 1
    fr = fr[:fr.index(root)+1]
    owner = next((f for f in fr if not RT.match(f)), '?')
    attr[owner] += 1
    if RT.match(fr[0]): leafs[fr[0]] += 1
    for f in set(fr): incl[f] += 1
for line in sys.stdin:
    line = line.rstrip('\n')
    if not line.strip():
        flush(); stack = []; continue
    if line[0] in ' \t':
        p = line.strip().split(None, 1)
        if len(p) == 2: stack.append(p[1].rsplit(' (', 1)[0].split('+0x')[0])
flush()
print('total', n, 'under', root, sub, '%.1f%%' % (100.0*sub/n))
print('== inclusive within root (% of root)')
for f, c in incl.most_common(int(sys.argv[2])): print('  %5.1f%% %s' % (100.0*c/sub, f))
print('== self incl runtime leaves, by first avra frame (% of root)')
for f, c in attr.most_common(int(sys.argv[2])): print('  %5.1f%% %s' % (100.0*c/sub, f))
print('== runtime leaves (% of root)')
for f, c in leafs.most_common(15): print('  %5.1f%% %s' % (100.0*c/sub, f))
