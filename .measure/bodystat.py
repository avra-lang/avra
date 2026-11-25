import sys, collections

def varint(b, i):
    v = 0; k = 0
    while True:
        o = b[i]; i += 1
        v |= (o & 127) << (7 * k); k += 1
        if o < 128: return v, i

def zint(b, i):
    z, i = varint(b, i)
    return (z >> 1) ^ -(z & 1), i

def octets(b, i):
    n, i = varint(b, i)
    return b[i:i + n], i + n

def head(b):
    payload, i = octets(b, 0)
    _chk, base = octets(b, i)
    j = 0
    magic, j = octets(payload, j)
    ver, j = zint(payload, j)
    rev, j = zint(payload, j)
    valrev, j = zint(payload, j)
    below = 0
    if ver >= 7:
        below, j = zint(payload, j)
    pr, j = octets(payload, j)
    count, j = zint(payload, j)
    places = []
    for _ in range(8 if ver >= 8 else 6):
        at, j = zint(payload, j); ln, j = zint(payload, j); ck, j = octets(payload, j)
        places.append((at, ln))
    return dict(ver=ver, rev=rev, valrev=valrev, below=below, count=count, base=base, places=places, print=pr)

NAMES = ["index", "slots", "names", "sets", "reverse", "rows"]

def analyze(path):
    b = open(path, 'rb').read()
    h = head(b)
    base = h['base']
    if h['ver'] >= 8:
        names8 = ["index", "slots", "families", "names", "reads", "sets", "holders", "rows"]
        return h, {names8[k]: h['places'][k][1] for k in range(8)}, len(b), 0, 0, 0, 0, {}, {}, 0
    out = {NAMES[k]: h['places'][k][1] for k in range(6)}
    rows_at, rows_len = h['places'][5]
    rb = b[base + rows_at: base + rows_at + rows_len]
    fam = collections.Counter(); famlen = 0; keylen = 0; diglen = 0; i = 0; n = 0
    keyshape = collections.Counter()
    while i < len(rb):
        payload, i = octets(rb, i)
        _ck, i = octets(rb, i)
        j = 0
        f, j = octets(payload, j); k, j = octets(payload, j); d, j = octets(payload, j)
        fam[f.decode().split(' ')[0]] += 1; famlen += len(f); keylen += len(k); diglen += len(d); n += 1
        ks = k.decode(errors='replace')
        keyshape['hex64' if len(ks) == 64 and all(c in '0123456789abcdef' for c in ks) else 'other'] += 1
    nb = b[base + h['places'][2][0]: base + h['places'][2][0] + h['places'][2][1]]
    cnt, j = varint(nb, 0)
    return h, out, len(b), n, famlen, keylen, diglen, fam, keyshape, cnt

for p in ([] if sys.argv[1:2] == ['--families'] else sys.argv[1:]):
    h, out, size, n, famlen, keylen, diglen, fam, keyshape, names = analyze(p)
    print(f"{p}: v{h['ver']} rev {h['rev']} val {h['valrev']} below {h['below']} rows {h['count']} size {size} B/row {size / max(1, h['count']):.0f}")
    print("  sections:", {k: v for k, v in out.items()}, "names:", names)
    print(f"  rows: family bytes {famlen} key {keylen} digest {diglen} per row fam {famlen / max(1, n):.0f} key {keylen / max(1, n):.0f} dig {diglen / max(1, n):.0f}")
    print("  families:", dict(fam), "keys:", dict(keyshape))

def reverse_stats(path):
    b = open(path, 'rb').read(); h = head(b); base = h['base']
    at, ln = h['places'][4]; rb = b[base + at: base + at + ln]
    n, i = varint(rb, 0); txt = 0; ords = 0; runbytes = 0
    for _ in range(n):
        t, i = octets(rb, i); txt += len(t)
        run, i = octets(rb, i); runbytes += len(run)
        c, j = varint(run, 0); ords += c
    at, ln = h['places'][3]; sb = b[base + at: base + at + ln]
    ns, i = varint(sb, 0); mem = 0
    for _ in range(ns):
        c, i = varint(sb, i); mem += c
        for _ in range(c): _, i = varint(sb, i)
    print(f"  reverse: names {n} text {txt} ordinals {ords} runbytes {runbytes}; sets {ns} members {mem}")


def v8_family_values(path):
    """Per family: rows and value bytes, from a v8 body's rows and slots."""
    b = open(path, 'rb').read(); h = head(b); base = h['base']
    if h['ver'] < 8: return
    pl = h['places']
    sec = lambda k: b[base + pl[k][0]: base + pl[k][0] + pl[k][1]]
    slots = {}
    sb = sec(1)
    for k in range(len(sb) // 42):
        line = sb[k * 42:(k + 1) * 42]
        slots[line[:32].hex()] = int.from_bytes(line[38:42], 'big')
    fb = sec(2); n, i = varint(fb, 0); fams = []
    for _ in range(n):
        t, i = octets(fb, i); fams.append(t.decode().split(' ')[0])
    rb = sec(7); i = 0; per = {}
    def dig(p, j):
        tag = p[j]; j += 1
        if tag == 0: return p[j:j + 32].hex(), j + 32
        t, j = octets(p, j); return t.decode(errors='replace'), j
    while i < len(rb):
        payload, i = octets(rb, i); i += 8
        f, j = varint(payload, 0); _k, j = dig(payload, j); d, j = dig(payload, j)
        r = per.setdefault(fams[f], [0, 0]); r[0] += 1; r[1] += slots.get(d, 0)
    for f, (rows, vb) in sorted(per.items()):
        print(f"  family {f}: rows {rows} value bytes {vb} per row {vb // max(1, rows)}")

if len(sys.argv) > 1 and sys.argv[1] == '--families':
    for p in sys.argv[2:]: v8_family_values(p)
