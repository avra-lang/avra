import subprocess,os,re,sys,collections,json
rows=[l.rstrip('\n').split('\t') for l in open('/work/split-601.tsv')][1:]
mm=[r for r in rows if 'type.mismatch' in r[2].split(',')]
os.makedirs('/tmp/sw',exist_ok=True)
env=dict(os.environ)
def run(src,old):
    open('/tmp/sw/x.av','w').write(src)
    e=dict(env); 
    if old: e['AVRA_PROGRAM']='0'
    else: e['AVRA_PROGRAM_NET']='0'
    try:
        o=subprocess.run(['/work/avra/build/avra-try','check','/tmp/sw/x.av'],capture_output=True,text=True,env=e,timeout=60)
        out=o.stdout+o.stderr
    except Exception as ex: out='avra: TIMEOUT'
    return sorted(re.findall(r'^(?:error|warning)\[([a-z_.]+)\]: (.*)$',out,re.M))+([('trap',l) for l in re.findall(r'^avra: (.*)$',out,re.M)])
left=[];closed=0
for r in mm:
    src=r[4].replace('\\n','\n').replace('\\t','\t').replace('\\\\','\\')
    o=run(src,True); n=run(src,False)
    om=[x for x in o if x[0]=='type.mismatch' and x not in n]
    if om: left.append(dict(src=src,old=o,new=n))
    else: closed+=1
json.dump(left,open('/tmp/sw/left.json','w'))
print('swept',len(mm),'closed at head',closed,'left',len(left))
g=lambda m: re.sub(r'\d+','N',re.sub(r'`[^`]*`','`_`',m))
c=collections.Counter(); ex={}
for p in left:
    for k,m in p['old']:
        if k=='type.mismatch' and (k,m) not in p['new']:
            key=(g(m),','.join(sorted(set(a for a,_ in p['new']))) or '-'); c[key]+=1; ex.setdefault(key,p['src']); break
for (m,nk),v in sorted(c.items(),key=lambda x:-x[1]): print(v,'|',m[:110],'| NEW:',nk,'|',repr(ex[(m,nk)])[:90])
