import re,collections,sys
F=250.0
def clean(s):
    for a,b in (('$2F','/'),('$2E','.'),('$40','@'),('$24','$'),('$20',' ')): s=s.replace(a,b)
    return s.replace('av_@std/','').replace('/src/','/')
pat=sys.argv[2]; top=int(sys.argv[3]) if len(sys.argv)>3 else 40
incl=collections.Counter(); selfc=collections.Counter(); n=0; stack=[]
def flush():
    global n
    if not stack: return
    i=[k for k,fr in enumerate(stack) if pat in fr]
    if not i: return
    n+=1; sub=stack[:i[-1]+1]
    selfc[sub[0]]+=1
    for fr in set(sub): incl[fr]+=1
for line in open(sys.argv[1]):
    if re.match(r'\s*\d+/\d+\s+[\d.]+:\s*$',line): flush(); stack=[]; continue
    m=re.match(r'\s+([0-9a-f]+)\s+(.*)',line)
    if m: stack.append(clean(m.group(2).strip()))
flush()
print('%s: %d samples = %.1f s'%(pat,n,n/F))
print('-- inclusive (within it)')
for k,v in incl.most_common(top): print('  %6.2f %6.2f self  %s'%(v/F,selfc[k]/F,k[:120]))
