import sys,re,collections
from diffs import parse
FAM='type.mismatch type.binding type.list_element type.struct_fields type.propagate type.catch type.fail type.coalesce type.return type.named type.alias type.applied type.type_value type.list_scalar type.map_value type.infer_result type.force type.method'.split()
d=[]
for f in sys.argv[1:]:
    if f.startswith('-'): continue
    d+=parse(f)
seen=set(); dd=[]
for p in d:
    if p['src'] not in seen: seen.add(p['src']); dd.append(p)
print(len(dd),'distinct programs')
g=lambda m: re.sub(r'\d+','N',re.sub(r'`[^`]*`','`_`',m.split('\n')[0]))
c=collections.Counter(); ex={}
for p in dd:
    keys=set()
    for k,msg in p['old']:
        if k in FAM and (k,msg) not in p['new']:
            keys.add(('OLD '+k,g(msg),','.join(sorted(set(k2 for k2,_ in p['new']))) or '-'))
    for k,msg in p['new']:
        if k in FAM and (k,msg) not in p['old'] and not any(k2 in FAM for k2,_ in p['old']):
            keys.add(('NEWONLY '+k,g(msg),'old:'+(','.join(sorted(set(k2 for k2,_ in p['old']))) or '-')))
    for key in keys: c[key]+=1; ex.setdefault(key,p['src'])
for key,v in sorted(c.items(),key=lambda x:(x[0][0],-x[1])):
    print(v,'|',' | '.join(key), '| e.g.', repr(ex[key])[:110] if '-x' in sys.argv else '')
