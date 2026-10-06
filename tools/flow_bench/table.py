"""The flow bench's table: raw lines `<engine> <key> <total> <count>`,
each engine's rounds printed side by side as `least (median)` per unit.
A row an engine could not finish carries its words instead.

    table.py <raw>
"""
import statistics
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
        if not isinstance(cell.get(engine), str):
            cell.setdefault(engine, []).append(int(nums[0]) / int(nums[1]))
    else:
        cell[engine] = rest.strip()


def one(key, v):
    unit = "ms" if key.startswith("parked_left_ms") else "B" if key.startswith("parked") else "ns"
    return f"{v:.1f} {unit}" if abs(v) < 100 else f"{v:.0f} {unit}"


def shown(key, v):
    if v is None:
        return "—"
    if isinstance(v, str):
        return v
    if len(v) == 1:
        return one(key, v[0])
    return f"{one(key, min(v))} ({one(key, statistics.median(v))})"


print("| row: least (median) | " + " | ".join(HEADS[e] for e in ENGINES) + " |")
print("|---|" + "---|" * len(ENGINES))
for key, cell in rows.items():
    print(f"| {key} | " + " | ".join(shown(key, cell.get(e)) for e in ENGINES) + " |")
