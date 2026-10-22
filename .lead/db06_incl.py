import re,sys
from collections import defaultdict
path=sys.argv[1]
lines=open(path,errors='replace').read().split('\n')
s=[k for k,l in enumerate(lines) if l.startswith('Call graph:')][0]
e=[k for k,l in enumerate(lines) if l.startswith('Total number in stack')][0]
def dec(n): return re.sub(r'\$([0-9A-Fa-f]{2})',lambda m:chr(int(m.group(1),16)),n)
pat=re.compile(r'^(\s*(?:[+!:|] |  )*)(\d+) (\S+)')
nodes=[]
for l in lines[s+1:e]:
    m=pat.match(l)
    if m: nodes.append((len(m.group(1)),int(m.group(2)),dec(m.group(3))))
root=nodes[0][1]; 
incl=defaultdict(int); selfc=defaultdict(int)
stack=[]  # (depth,name,count,childsum)
chsum={}
# compute self per node
for i,(d,c,n) in enumerate(nodes):
    cs=0
    j=i+1
    while j<len(nodes) and nodes[j][0]>d:
        if nodes[j][0]==nodes[i+1][0] and j>i: pass
        j+=1
    # children = direct: first deeper depth after i
    kids=[]
    k=i+1
    if k<len(nodes) and nodes[k][0]>d:
        cd=nodes[k][0]
        while k<len(nodes) and nodes[k][0]>d:
            if nodes[k][0]==cd: kids.append(nodes[k][1])
            k+=1
    selfc[n]+=c-sum(kids)
st=[]
for d,c,n in nodes:
    while st and st[-1][0]>=d: st.pop()
    if n not in {x[1] for x in st}: incl[n]+=c
    st.append((d,n))
print("root",root)
def show(names,top):
    for n,c in sorted(incl.items(),key=lambda x:-x[1])[:top]:
        print("%5d %5.1f%% %s"%(c,100*c/root,n[:120]))
mode=sys.argv[2] if len(sys.argv)>2 else "top"
if mode=="top": show(None,int(sys.argv[3]) if len(sys.argv)>3 else 60)
else:
    for n,c in incl.items():
        if mode in n: print("%5d %5.1f%% %s"%(c,100*c/root,n[:140]))

if mode.startswith("under:"):
    target=mode[6:]
    sub=defaultdict(int); tot=0
    st=[]
    for d,c,n in nodes:
        while st and st[-1][0]>=d: st.pop()
        names=[x[1] for x in st]
        inside=[x for x in st if target in x[1]]
        if inside and target not in n and n not in {x[1] for x in st[[x[1] for x in st].index(inside[0][1]):]}:
            sub[n]+=c
        if target in n and not inside: tot+=c
        st.append((d,n))
    print("== under",target,"total",tot,"(%.1f%%)"%(100*tot/root))
    for n,c in sorted(sub.items(),key=lambda x:-x[1])[:int(sys.argv[3])]:
        print("%5d %5.1f%% (of run) %5.1f%% (of it) %s"%(c,100*c/root,100*c/max(tot,1),n[:110]))
