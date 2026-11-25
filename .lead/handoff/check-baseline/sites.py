import json,re,sys
ids={r["id"] for r in json.load(open(sys.argv[1]))}
root=sys.argv[3] if len(sys.argv)>3 else "/work/avra/"
out=set();kind=None
for line in open(sys.argv[2]):
    m=re.match(r'^(warning|error)\[([^\]]+)\]',line)
    if m: kind=m.group(2); continue
    m=re.search(r'╭─\[([^\]]+):(\d+):\d+\]',line)
    if m and kind:
        if kind in ids: out.add(f"{m.group(1).replace(root,'')}:{m.group(2)}:{kind}")
        kind=None
for s in sorted(out): print(s)
