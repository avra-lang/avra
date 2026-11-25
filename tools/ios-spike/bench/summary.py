"""The bench's runs summarized: `python3 -I tools/ios-spike/bench/summary.py <label>…` over
build/ios-spike/bench/<label>-<n>.out — medians, ranges, and Avra's phases per kind of paint."""
import glob, re, statistics as st, sys, os

def runs(label):
    out = []
    for f in sorted(glob.glob(os.path.join("build/ios-spike/bench", f"{label}-*.out"))):
        t = open(f).read().replace("\r", "")
        g = lambda p: (lambda m: float(m.group(1)) if m else None)(re.search(p, t))
        kv = lambda pre: [dict((k, int(float(v))) for k, v in re.findall(r"(\w+)=(-?[\d.]+)", l)) for l in t.splitlines() if l.startswith(pre)]
        out.append(dict(cold=g(r"cold start to first frame drawn: ([\d.]+)"), mem1=g(r"after first frame: ([\d.]+)"),
                        tog=g(r"toggle to frame drawn: ([\d.]+)"), frames=g(r"fling: (\d+) frames"), longest=g(r"longest gap ([\d.]+)"),
                        o16=g(r"fling: .*over 16.7 ms (\d+)"), sframes=g(r"slow scroll: (\d+) frames"), slongest=g(r"slow scroll: .*longest gap ([\d.]+)"), so16=g(r"slow scroll: .*over 16.7 ms (\d+)"), mem2=g(r"after the fling: ([\d.]+)"), paints=kv("spike: paint"), applies=kv("spike: host apply")))
    return out

def m(xs, f="{:.1f}"):
    xs = [x for x in xs if x is not None]
    return "—" if not xs else (f + " ({}–{})").format(st.median(xs), f.format(min(xs)), f.format(max(xs)))

for lab in sys.argv[1:]:
    r = runs(lab)
    print(f"{lab}: {len(r)} runs | cold {m([x['cold'] for x in r])} | mem {m([x['mem1'] for x in r])} | toggle {m([x['tog'] for x in r])} | fling frames {m([x['frames'] for x in r], '{:.0f}')} longest {m([x['longest'] for x in r])} over16 {m([x['o16'] for x in r], '{:.0f}')} | mem after {m([x['mem2'] for x in r])} | slow scroll frames {m([x['sframes'] for x in r], '{:.0f}')} longest {m([x['slongest'] for x in r])} over16 {m([x['so16'] for x in r], '{:.0f}')}")
    ps = [p for x in r for p in x["paints"][1:]]
    slow = [l for x in r for l in x.get("slow_paints", [])]
    for name, sel in [("toggle paints", lambda p: p["patches"] <= 3), ("window paints", lambda p: p["patches"] > 3)]:
        s = [p for p in ps if sel(p)]
        if s:
            print(f"  {name} (n={len(s)}): " + " ".join(f"{k}={st.median([p.get(k, 0) for p in s]):.0f}" for k in s[0] if k != "live_bytes_delta"))
    ap = [a for x in r for a in x["applies"][1:]]
    if ap:
        print(f"  later applies (n={len(ap)}): " + " ".join(f"{k}={st.median([a.get(k, 0) for a in ap]):.0f}" for k in ap[0]))
