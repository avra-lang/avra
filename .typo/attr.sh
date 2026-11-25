cp /tmp/main_census.out /tmp/main_keep.out
sh tools/census.sh check --counts packages/cli > /tmp/cut_try.out 2>&1
ls -la build/avra.census
mv .avra-cache .avra-cache.aside.$(date +%s) 2>/dev/null
AVRA_MEM_STATS=1 AVRA_CENSUS_SITES=1 AVRA_CENSUS_TYPES=1 build/avra.census check --counts packages/cli 2>/tmp/cut_raw.err >/dev/null
python3 - <<'PY'
import subprocess,re,collections
def res(a):
    r=subprocess.run(["addr2line","-f","-e","build/avra.census",a],capture_output=True,text=True).stdout.split("\n")[0]
    return r if r and r!="??" else a
cut=collections.defaultdict(dict)
for l in open("/tmp/cut_raw.err",errors="replace"):
    m=re.match(r"(retain|push|copy|list_read|list_write|release): site (0x[0-9a-f]+) (\d+)",l)
    if m: cut[m.group(1)][res(m.group(2))]=cut[m.group(1)].get(res(m.group(2)),0)+int(m.group(3))
main=collections.defaultdict(dict)
for l in open("/tmp/main_keep.out",errors="replace"):
    m=re.match(r"(retain|push|copy): (\S+) (\d+)",l)
    if m: main[m.group(1)][m.group(2)]=main[m.group(1)].get(m.group(2),0)+int(m.group(3))
for k in ("retain","push"):
    print("==",k)
    names=set(cut[k])|set(main[k])
    d=sorted(((cut[k].get(n,0)-main[k].get(n,0),n) for n in names),reverse=True)[:14]
    for x,n in d: print("%12d  cut %12d main %12d  %s"%(x,cut[k].get(n,0),main[k].get(n,0),n[:100]))
PY
grep -a "^rc:\|^mem: peak" /tmp/cut_raw.err
