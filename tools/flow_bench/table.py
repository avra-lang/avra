"""The flow bench's table: raw lines `<engine> <key> <total> <count>`,
the least per-unit value of each engine's rounds printed side by side.
A row an engine could not finish carries its words instead.

    table.py <raw>
"""
import sys
from collections import OrderedDict

ENGINES = ["avra", "go1", "goN", "c"]
HEADS = {"avra": "Avra (compiled)", "go1": "Go, GOMAXPROCS=1", "goN": "Go, default", "c": "runtime rows from C"}

rows = OrderedDict()
for line in open(sys.argv[1]):
    parts = line.split(None, 2)
    if len(parts) < 3:
        continue
    engine, key, rest = parts
    cell = rows.setdefault(key, {})
    nums = rest.split()
    if len(nums) == 2 and all(n.lstrip("-").isdigit() for n in nums) and int(nums[1]) > 0:
        per = int(nums[0]) / int(nums[1])
        if not isinstance(cell.get(engine), str):
            cell[engine] = min(per, cell.get(engine, per))
    else:
        cell[engine] = rest.strip()


def shown(key, v):
    if v is None:
        return "—"
    if isinstance(v, str):
        return v
    unit = "B" if key.startswith("parked") else "ns"
    return f"{v:.1f} {unit}" if v < 100 else f"{v:.0f} {unit}"


print("| row | " + " | ".join(HEADS[e] for e in ENGINES) + " |")
print("|---|" + "---|" * len(ENGINES))
for key, cell in rows.items():
    print(f"| {key} | " + " | ".join(shown(key, cell.get(e)) for e in ENGINES) + " |")
