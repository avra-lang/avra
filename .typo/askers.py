import re,sys,collections
names=[]
src=open('packages/std-avrac/src/compiler/families/families.av').read()
for m in re.finditer(r'@family\([^\n]*\)\ntype (\w+) = \{\}',src): names.append(m.group(1))
names=sorted(names)
fam={i:n for i,n in enumerate(names)}
lines=open(sys.argv[1],errors='replace').read().split("\n")
by=collections.defaultdict(list)
for l in lines:
    p=l.split("\t")
    if len(p)>=6 and p[0]=="G":
        fam_id=int(p[2]); arg=p[3]
        deps=p[5].split(" ") if p[5] else []
        for d in deps:
            f,a=d.split(":")
            if fam.get(int(f))=="Parsed":
                by[fam.get(fam_id)].append((arg,a))
for k,v in sorted(by.items(), key=lambda x:-len(x[1])):
    print(k, len(v), "reads of Parsed args", sorted(set(a for _,a in v)))
