import json, re, sys, collections
S = sys.argv[1]
syms = json.load(open(f"{S}/census/syms.json"))
def dec(n): return re.sub(r"\$([0-9A-F]{2})", lambda m: chr(int(m.group(1), 16)), n)
rows = []
for line in open(f"{S}/census/funcs.tsv"):
    i, size, name = line.rstrip("\n").split("\t")
    size = int(size)
    if name.startswith("av_"):
        d = dec(name[3:])
        m = re.match(r"(@[^/]+/[^/]+)/src/(.*?\.av)", d)
        if m: pkg, mod = m.group(1), m.group(2)
        else:
            m2 = re.match(r"([^.$]+)", d); pkg, mod = "avra:" + (m2.group(1) if m2 else d), ""
        origin = "avra " + pkg
    else:
        o = syms.get(name)
        if o is None: origin, mod = "unknown", name
        else:
            lib, _, member = o.partition(":")
            origin = {"runtime": "C runtime", "pkgC": "package C", "libc": "libc", "compiler-rt": "compiler-rt"}.get(lib, lib)
            mod = member
        pkg = origin
    rows.append(dict(i=int(i), size=size, name=name, origin=origin, mod=mod, d=dec(name[3:]) if name.startswith("av_") else name))
json.dump(rows, open(f"{S}/census/rows.json", "w"))
by = collections.Counter(); cnt = collections.Counter()
for r in rows: by[r["origin"]] += r["size"]; cnt[r["origin"]] += 1
tot = sum(by.values())
for k, v in by.most_common(): print(f"{v:8d} {100*v/tot:5.1f}% {cnt[k]:4d}  {k}")
print(tot)
print("--- unknown:", [r["name"] for r in rows if r["origin"] == "unknown"][:30])
