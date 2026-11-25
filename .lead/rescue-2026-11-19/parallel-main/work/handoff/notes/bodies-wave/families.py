#!/usr/bin/env python3
# families.py <build log> : the bodies wave's engine clock summed over its cores, every family in ms,
# then grouped. Reads the `core N: ... time: <family> <own>ms / <whole>ms (<asks>)` lines that the
# measure patch's spoken_ms() prints under AVRA_QUERY_TIMES=1. Edit `family()` to regroup.
import re,sys,collections
own=collections.Counter(); whole=collections.Counter(); asks=collections.Counter()
for l in open(sys.argv[1],errors='replace'):
    if not l.startswith('core ') or 'law_findings' not in l: continue
    body=l.split('time:',1)[1].split('; split:')[0]
    for q,a,b,c in re.findall(r'\s*([^,;]+?) (\d+)ms / (\d+)ms \((\d+)\)',body):
        q=q.strip(); own[q]+=int(a); whole[q]+=int(b); asks[q]+=int(c)
def family(q):
    if q.endswith('(reused)'): return 'store/memo reads of kept answers'
    if q=='law_findings': return 'laws: law_findings'
    if q.startswith(('item_','entry_')) or q=='registry_holes': return 'laws: per-item law queries'
    if q in ('lowered_under','lowered_method_under','body_facts'): return 'lowering'
    if q in ('typed_fn','method_body_typed','written_typed'): return 'typing'
    if 'signature' in q or q.startswith('impl') or q in ('resolved','callee_at','written_sites','receiver_use','surveyed','const_settlement'): return 'signatures, resolution, impls'
    return 'other'
T=sum(own.values()); g=collections.Counter(); ga=collections.Counter()
for q,v in own.items(): g[family(q)]+=v; ga[family(q)]+=asks[q]
print('families %d, own total %.1f CPU-s'%(len(own),T/1000))
for f,v in g.most_common(): print('  %-36s %6.2f CPU-s %5.1f%%  asks %8d'%(f,v/1000,100*v/max(T,1),ga[f]))
print('-- top families')
for q,v in own.most_common(int(sys.argv[2]) if len(sys.argv)>2 else 30): print('  %-40s own %6.2f  whole %6.2f  asks %8d'%(q[:40],v/1000,whole[q]/1000,asks[q]))
