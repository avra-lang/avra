import sys,re,json,collections
def parse(path):
    txt=open(path,errors='replace').read()
    out=[];seen=set()
    for m in re.finditer(r'=====DIFF\n--SRC\n(.*?)\n--OLDK\n(.*?)\n?--NEWK\n(.*?)\n?--OLDRUN\n(.*?)\n--NEWRUN\n(.*?)\n=====END',txt,re.S):
        src,o,n,orun,nrun=m.groups()
        if src in seen: continue
        seen.add(src)
        def ds(s):
            r=[]
            for l in s.split('\n'):
                mm=re.match(r'^([a-z_]+\.[a-z_]+): (.*)$',l)
                if mm: r.append((mm.group(1),mm.group(2)))
                elif r: r[-1]=(r[-1][0],r[-1][1]+'\n'+l)
            return r
        out.append(dict(src=src,old=ds(o),new=ds(n),orun=orun,nrun=nrun))
    return out
if __name__=='__main__':
    d=parse(sys.argv[1]); print(len(d),'distinct')
    fam=sys.argv[2] if len(sys.argv)>2 else 'type.mismatch'
    c=collections.Counter()
    for p in d:
        ok=[k for k,_ in p['old']]; nk=[k for k,_ in p['new']]
        for k,msg in p['old']:
            if k==fam and (k,msg) not in p['new']:
                # generalize message
                g=re.sub(r'`[^`]*`','`_`',msg.split('\n')[0])
                c[(g, ','.join(sorted(set(nk))) or '-')]+=1
    for (g,nk),v in sorted(c.items(),key=lambda x:-x[1]): print(v,'|',g,'| NEW:',nk)
