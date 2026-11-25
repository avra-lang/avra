import re,collections,sys
F=250.0
def clean(s):
    for a,b in (('$2F','/'),('$2E','.'),('$40','@'),('$24','$'),('$20',' ')): s=s.replace(a,b)
    return s.replace('av_@std/','').replace('/src/','/')
def avra(fr): return fr.startswith(('avrac/','program/','cli/','av_cli','text/','io/','meta/','relation/','hash/','json/'))
def engine_role(fr):
    if any(k in fr for k in ('.written_into','.saved_bytes','SavedLayoutWriter','saved_layout_writer','slot_written')): return 'answers: encode'
    if any(k in fr for k in ('.read_from','saved_fields','SavedRecord.','SavedList.','SavedSlots.','record_within','label_at','word_at','_in_place','octets_at')): return 'answers: decode'
    if any(k in fr for k in ('content_hash','blake3','hash_text','digest')): return 'answers: hash'
    if any(k in fr for k in ('.folded_into','KeyLane','key_fold')): return 'question keys: fold'
    if fr.startswith('program/'):
        if any(k in fr for k in ('disk_store','layered_store','pack_collection')): return 'store: packs/lookups'
        if any(k in fr for k in ('hash_keyed_table','interned','read_memo','bounded_cache','dense_window')): return 'engine: memo tables'
        if any(k in fr for k in ('frontier','answer_record','query_engine','query_times','worked_ahead','address','sorted','source_facts','input_stamps')): return 'engine: records/reads/frontier'
        return 'engine: other ('+fr.split('.av')[0]+')'
    return None
FAM={}
for q in ['law_findings']: FAM[q]='laws: law_findings'
def family(q):
    if q=='law_findings': return 'laws: law_findings'
    if q.startswith('item_') or q.startswith('entry_') or q=='registry_holes': return 'laws: per-item law queries'
    if q in ('lowered_under','lowered_method_under','body_facts'): return 'lowering'
    if q in ('typed_fn','method_body_typed','written_typed'): return 'typing'
    return 'signatures/resolution/other queries'
samples=[]; stack=[]; pid=None
for line in open(sys.argv[1]):
    m=re.match(r'\s*(\d+)/(\d+)\s+[\d.]+:\s*$',line)
    if m:
        if stack: samples.append((pid,stack))
        pid=int(m.group(1)); stack=[]; continue
    m=re.match(r'\s+([0-9a-f]+)\s+(.*)',line)
    if m: stack.append(clean(m.group(2).strip()))
if stack: samples.append((pid,stack))
bp={p for p,s in samples if any('law_findings' in x for x in s)}
bp.discard(min(p for p,s in samples))
cat=collections.Counter(); alloc=collections.Counter(); n=0; byq=collections.Counter()
for p,s in samples:
    if p not in bp: continue
    n+=1
    first=next((fr for fr in s if avra(fr)),None)
    l=s[0].lower(); al=any(x in l for x in ('slab','malloc','free','release','retain','alloc','_int_','array_cells','dead','memmove','memcpy'))
    role=engine_role(first) if first else None
    if role is None and first:
        # compute: the query whose compute encloses it
        q=next((re.search(r'\.([a-z_0-9]+)_compute$',fr).group(1) for fr in s if re.search(r'\.([a-z_0-9]+)_compute$',fr)),None)
        role='compute: '+(family(q) if q else 'outside any query')
        if q: byq[q]+=1
    if role is None: role='no Avra frame'
    cat[role]+=1
    if al: alloc[role]+=1
print('bodies-wave processes %d, %.1f CPU-s sampled'%(len(bp),n/F))
for c,v in cat.most_common(): print('  %-44s %6.2f CPU-s %5.1f%%  (alloc/free/copy leaves %.2f)'%(c,v/F,100*v/n,alloc[c]/F))
print('-- compute by query (top 14)')
for q,v in byq.most_common(14): print('  %-30s %5.2f'%(q,v/F))
