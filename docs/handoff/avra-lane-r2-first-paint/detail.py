import json, sys, collections, re
S = sys.argv[1]
rows = json.load(open(f"{S}/census/rows.json"))
def grp(r):
    if r["name"].startswith("avra_ui_"): return "avra @std/ui", "host fns (avra_ui_*)"
    if r["name"] == "avra_main": return "avra @ui/board", "avra_main (program entry)"
    m = r["mod"]
    if r["origin"].startswith("avra @std/ui"): m = "/".join(m.split("/")[:2]) if "/" in m else m
    return r["origin"], m
by = collections.defaultdict(collections.Counter)
for r in rows:
    o, m = grp(r); by[o][m] += r["size"]
for o in ["avra @std/ui", "libc", "C runtime", "avra @ui/board", "avra @std/json", "unknown"]:
    print("==", o, sum(by[o].values()))
    for k, v in by[o].most_common(14): print(f"   {v:7d}  {k}")
