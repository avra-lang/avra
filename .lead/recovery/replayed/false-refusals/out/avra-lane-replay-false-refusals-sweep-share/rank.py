# THE SOUNDNESS SWEEP'S RANKING: every results TSV named (one.sh's lines), merged, each fixture once
# (the last line for a path wins), ranked: soundness candidates first, then wrong words.
# usage: python3 rank.py [rows to show per category] results-A.tsv results-B.tsv ...
import sys, collections
show=int(sys.argv[1]) if len(sys.argv)>1 and sys.argv[1].isdigit() else 400
files=[a for a in sys.argv[1:] if not a.isdigit()] or ['/tmp/claude-0/sweep/results.tsv']
byp={}
for f in files:
    for l in open(f):
        if l.count('\t')==6:
            r=l.rstrip('\n').split('\t'); byp[r[0]]=r
rows=list(byp.values())
cats=collections.defaultdict(list)
for path,oe,of,oerr,ne,nf,nerr in rows:
    oe,ne=int(oe),int(ne)
    if oe==124 or ne==124: cats['timeout'].append((path,oe,ne,oerr,nerr)); continue
    oref = oe!=0 and oerr!=''
    nref = ne!=0 and nerr!=''
    if oref and ne==0: cats['1 soundness: old refuses, layer accepts'].append((path,oerr))
    elif oref and ne!=0 and nerr=='': cats['1b old refuses, layer fails with no diagnostic'].append((path,oerr,ne))
    elif oref and nref and oerr!=nerr: cats['2 wrong words: both refuse, first error differs'].append((path,oerr,nerr))
    elif oe==0 and nref: cats['3 false refusal: layer refuses, old accepts'].append((path,nerr))
    elif oe==0 and ne!=0: cats['4 layer fails without a diagnostic, old accepts'].append((path,ne))
    elif oe!=0 and not oref and ne==0: cats['5 old fails without a diagnostic, layer accepts'].append((path,oe))
    else: cats['agree'].append(path)
for k in sorted(cats):
    v=cats[k]; print(f"== {k}: {len(v)}")
    if k!='agree':
        for x in v[:show]: print('   ', *x, sep='\t')
