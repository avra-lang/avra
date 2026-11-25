import sys,re
f=sys.argv[1]; L=open(f).read().split('\n'); out=[]; i=0; left=[]
def alts(line):
    m=re.match(r'^(\s*)(.*?) -> (.*)$', line)
    return m
def toks(s): return [t.strip() for t in s.split(' or ')]
def union_line(o,b,t):
    mo,mb,mt=alts(o),alts(b),alts(t)
    if not (mo and mb and mt): return None
    if mo.group(3)!=mb.group(3) or mt.group(3)!=mb.group(3):
        # arm bodies differ: allowed only if one side keeps base body
        if mt.group(3)==mb.group(3): body=mo.group(3)
        elif mo.group(3)==mb.group(3): body=mt.group(3)
        else: return None
    else: body=mb.group(3)
    TO,TB,TT=toks(mo.group(2)),toks(mb.group(2)),toks(mt.group(2))
    res=list(TT)+[x for x in TO if x not in TB and x not in TT]
    return mt.group(1)+' or '.join(res)+' -> '+body
while i<len(L):
    if L[i].startswith('<<<<<<< '):
        b=next(j for j in range(i,len(L)) if L[j].startswith('||||||| '))
        m=next(j for j in range(b,len(L)) if L[j]=='=======')
        e=next(j for j in range(m,len(L)) if L[j].startswith('>>>>>>> '))
        o,ba,t=L[i+1:b],L[b+1:m],L[m+1:e]
        res=None
        if len(o)==len(ba)==len(t):
            r=[union_line(x,y,z) for x,y,z in zip(o,ba,t)]
            if all(x is not None for x in r): res=r
        if res is None: left.append(len(out)+1); out.extend(L[i:e+1])
        else: out.extend(res)
        i=e+1; continue
    out.append(L[i]); i+=1
open(f,'w').write('\n'.join(out)); print("left at",left)
