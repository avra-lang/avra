import re,sys,collections
names=sorted(m.group(1) for m in re.finditer(r'@family\([^\n]*\)\ntype (\w+) = \{\}',open('packages/std-avrac/src/compiler/families/families.av').read()))
fam={i:n for i,n in enumerate(names)}
readers=collections.defaultdict(set)   # (family,arg) -> askers (family,arg)
for l in open(sys.argv[1],errors='replace').read().split("\n"):
    p=l.split("\t")
    if len(p)>=6 and p[0]=="G":
        me=(fam.get(int(p[2])),p[3])
        for d in (p[5].split(" ") if p[5] else []):
            f,a=d.split(":"); readers[(fam.get(int(f)),a)].add(me)
def up(k,depth,seen):
    out=[]
    for r in sorted(readers.get(k,[])):
        if r in seen: continue
        seen.add(r); out.append("  "*depth+"%s:%s"%r)
        if depth<3: out+=up(r,depth+1,seen)
    return out
for f in ["Visible","Resolved"]:
    for a in ["1","2","3","4"]:
        k=(f,a); r=readers.get(k)
        if r: print("== %s:%s read by"%k); print("\n".join(up(k,1,set())[:14]))
