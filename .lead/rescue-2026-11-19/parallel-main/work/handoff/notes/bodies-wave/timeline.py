import sys,collections
rows=[l.split() for l in open(sys.argv[1])]
# t pid comm state ticks R
byt=collections.OrderedDict()
for r in rows:
    try: t=float(r[0]); pid=int(r[1]); ticks=int(r[-2])
    except: continue
    comm=' '.join(r[2:-3])
    byt.setdefault(t,{})[pid]=(comm,ticks)
ts=list(byt)
main=min(p for t in ts for p in byt[t] if byt[t][p][0].startswith('avra'))
step=float(sys.argv[2]) if len(sys.argv)>2 else 1.0
prev=None;acc=collections.Counter();t_start=ts[0];last={}
out=[]
for t in ts:
    for p,(c,k) in byt[t].items():
        d=k-last.get(p,k if p in last else 0)
        if p not in last: d=0
        last[p]=k
        key='MAIN' if p==main else ('core' if c.startswith('avra') else c)
        acc[key]+=d
    if t-t_start>=step:
        out.append((t_start,t,dict(acc)));acc=collections.Counter();t_start=t
out.append((t_start,ts[-1],dict(acc)))
for a,b,d in out:
    tot=sum(d.values())/100.0
    print("%5.1f-%5.1f busy=%.2f  %s"%(a,b,tot/(b-a) if b>a else 0,' '.join('%s=%.2f'%(k,v/100.0) for k,v in sorted(d.items()) if v)))
