import collections,sys
rows=[l.split() for l in open(sys.argv[1])]
f={};l={};k={};comm={}
for r in rows:
    try: t=float(r[0]); p=int(r[1]); tk=int(r[-2])
    except: continue
    f.setdefault(p,t); l[p]=t; k[p]=tk; comm[p]=r[2]
avra=[p for p in f if comm[p].startswith('avra')]
main=min(avra)
kids=sorted([p for p in avra if p!=main], key=lambda p:f[p])
# cluster by birth
waves=[]
for p in kids:
    if waves and f[p]-waves[-1][0][1] < 0.6: waves[-1][1].append(p)
    else: waves.append(((p,f[p]),[p]))
# main cpu per time from samples
ticks=collections.defaultdict(list)
for r in rows:
    try: t=float(r[0]); p=int(r[1]); tk=int(r[-2])
    except: continue
    ticks[p].append((t,tk))
def cpu_between(p,a,b):
    s=[(t,x) for t,x in ticks[p] if a<=t<=b]
    return (s[-1][1]-s[0][1])/100 if len(s)>1 else 0
T0=f[main]; T1=l[main]
print('build %.1f s, main %.1f CPU-s'%(T1-T0,k[main]/100))
prev=T0; tot_idle=0
for i,(head,ps) in enumerate(waves):
    a=min(f[p] for p in ps); b=max(l[p] for p in ps)
    gap_main=cpu_between(main,prev,a)
    if a-prev>0.3:
        idle=4*(a-prev)-gap_main- sum(cpu_between(q,prev,a) for q in kids if q not in ps)
        print('  serial  %5.1f-%5.1f  %4.1f s  main %4.1f CPU  idle %5.1f core-s'%(prev-T0,a-T0,a-prev,gap_main,idle)); tot_idle+=idle
    cpu=sum(k[p] for p in ps)/100; mcpu=cpu_between(main,a,b)
    ends=sorted(l[p] for p in ps); strag=sum(b-e for e in ends)
    idle=4*(b-a)-cpu-mcpu
    print('  wave %2d %5.1f-%5.1f  %4.1f s  %d procs  cpu %5.1f  main %4.1f  idle %5.1f core-s (stragglers %4.1f; spread of ends %.1f s)'%(i,a-T0,b-T0,b-a,len(ps),cpu,mcpu,idle,strag,ends[-1]-ends[0])); tot_idle+=idle
    prev=b
if T1-prev>0.3:
    m=cpu_between(main,prev,T1); idle=4*(T1-prev)-m
    print('  serial  %5.1f-%5.1f  %4.1f s  main %4.1f CPU  idle %5.1f core-s'%(prev-T0,T1-T0,T1-prev,m,idle)); tot_idle+=idle
print('idle total %.1f core-s = %.1f s of 4-core wall'%(tot_idle,tot_idle/4))
