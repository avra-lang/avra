import sys,re
# usage: hunk.py file show | hunk.py file resolve N mode   (mode: ours|theirs|both|theirsboth|file:path)
f=sys.argv[1]; lines=open(f).read().split('\n')
hunks=[];i=0
while i<len(lines):
    if lines[i].startswith('<<<<<<< '):
        s=i; b=next(j for j in range(i,len(lines)) if lines[j].startswith('||||||| '))
        m=next(j for j in range(b,len(lines)) if lines[j]=='=======')
        e=next(j for j in range(m,len(lines)) if lines[j].startswith('>>>>>>> '))
        hunks.append((s,b,m,e)); i=e
    i+=1
if sys.argv[2]=='show':
    for n,(s,b,m,e) in enumerate(hunks):
        print(f"##### HUNK {n} line {s+1}: ours {b-s-1} base {m-b-1} theirs {e-m-1}")
        if len(sys.argv)>3 and str(n) not in sys.argv[3].split(','): continue
        for k in range(max(0,s-4),e+1): print(f"{k+1:5} {lines[k]}")
else:
    n=int(sys.argv[3]); mode=sys.argv[4]; s,b,m,e=hunks[n]
    o=lines[s+1:b]; t=lines[m+1:e]
    if mode=='ours': r=o
    elif mode=='theirs': r=t
    elif mode=='both': r=o+t
    elif mode=='theirsboth': r=t+o
    elif mode.startswith('file:'): r=open(mode[5:]).read().rstrip('\n').split('\n')
    lines[s:e+1]=r
    open(f,'w').write('\n'.join(lines))
