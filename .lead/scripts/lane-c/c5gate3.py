import sys, re
kinds = set(l.strip() for l in open(sys.argv[2]) if l.strip())
text = open(sys.argv[1]).read()
blocks, cur = [], None
for line in text.split("\n"):
    m = re.match(r"^(warning|error)\[([a-z_.]+)\]", line)
    if m:
        if cur: blocks.append(cur)
        cur = [m.group(2), [line]]
    elif cur is not None:
        cur[1].append(line)
if cur: blocks.append(cur)
kept = ["\n".join(b[1]).rstrip("\n") for b in blocks if b[0] in kinds]
sys.stdout.write("\n\n".join(kept) + ("\n" if kept else ""))
