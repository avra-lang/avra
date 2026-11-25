python3 - <<'PY'
import subprocess,re,collections
def res(a):
    r=subprocess.run(["addr2line","-f","-e","build/avra.census",a],capture_output=True,text=True).stdout.split("\n")[0]
    return r if r and r!="??" else a
cut=collections.defaultdict(int)
for l in open("/tmp/cut_raw.err",errors="replace"):
    m=re.match(r"retain: site (0x[0-9a-f]+) (\d+)",l)
    if m: cut[res(m.group(1))]+=int(m.group(2))
tot=sum(cut.values())
print("listed total",tot)
for n,c in sorted(cut.items(),key=lambda x:-x[1])[:30]: print("%12d %s"%(c,n[:110]))
PY
