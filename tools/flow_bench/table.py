"""The flow bench's table: raw lines `<engine> <key> <total> <count>`,
each engine's rounds printed side by side as `least (median)` per unit.
A row an engine could not finish carries its words instead.

    table.py <raw>            every row, side by side
    table.py <raw> --gates    the G1 rows: Avra against Go, gate 2x time,
                              3x memory, the rows that cannot run, named
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


def full_table():
    print("| row: least (median) | " + " | ".join(HEADS[e] for e in ENGINES) + " |")
    print("|---|" + "---|" * len(ENGINES))
    for key, cell in rows.items():
        print(f"| {key} | " + " | ".join(shown(key, cell.get(e)) for e in ENGINES) + " |")


# ── G1: Avra beside Go, each row a gate (owner 2026-10-06) ──────
#
# A time row passes at 2x Go's best (GOMAXPROCS=1 and default, whichever
# is faster); a memory row sums resident set and page tables and passes
# at 3x. The twin prints the SAME key as its Go program, so the raw table
# already stands them side by side; this view adds the ratio and verdict.
TIME_GATE = 2.0
MEM_GATE = 3.0

# (row, avra key, go key) — the keys differ nowhere today; the map is
# written out so a twin that has to move names itself here.
TIME_ROWS = [
    ("ping-pong round trip (rendezvous)", "pingpong_rendezvous", "pingpong_rendezvous"),
    ("spawn + join, one at a time", "spawn_one", "spawn_one"),
    ("10k tasks alive, cold", "spawn_alive_cold", "spawn_alive_cold"),
    ("10k tasks alive, warm", "spawn_alive_warm", "spawn_alive_warm"),
    ("10k tasks alive and parked, cold", "spawn_parked_cold", "spawn_parked_cold"),
    ("10k tasks alive and parked, warm", "spawn_parked_warm", "spawn_parked_warm"),
]

# Rows the harness has a Go twin for and no Avra twin yet, with the
# slice that makes each writable.
BLOCKED_ROWS = [
    ("ping-pong over a buffered channel", "channels — slice 05 (FLOW 05, avra-8sb5.34.53.6)"),
    ("fan-in, N producers to one consumer", "channels — slice 05 (FLOW 05, avra-8sb5.34.53.6)"),
    ("select over N sources (2, 8, 64)", "select — slice 04 (FLOW 04, avra-8sb5.34.53.4)"),
    ("cancel a tree of tasks", "cancel — slice 03 (FLOW 03, avra-8sb5.34.53.3)"),
]


def least_of(key, engine):
    v = rows.get(key, {}).get(engine)
    return min(v) if isinstance(v, list) and v else None


def ratio(v, go):
    return f"{v / go:.2f}x" if go else "—"


def verdict(v, go1, goN, gate):
    best = min([g for g in (go1, goN) if g is not None] or [None]) if (go1 or goN) else None
    if v is None or best is None:
        return "n/a"
    return "PASS" if v <= gate * best else "FAIL"


def gate_table():
    print("| G1 row | Go, 1 proc | Go, default | Avra | ratio vs best Go | gate | verdict |")
    print("|---|---|---|---|---|---|---|")
    for label, ak, gk in TIME_ROWS:
        avra, go1, goN = least_of(ak, "avra"), least_of(gk, "go1"), least_of(gk, "goN")
        best = min([g for g in (go1, goN) if g is not None] or [None]) if (go1 or goN) else None
        print(
            f"| {label} | {one(gk, go1) if go1 is not None else '—'} | {one(gk, goN) if goN is not None else '—'} "
            f"| {one(ak, avra) if avra is not None else '—'} | {ratio(avra, best) if avra is not None else '—'} "
            f"| ≤ {TIME_GATE:.0f}x | {verdict(avra, go1, goN, TIME_GATE)} |"
        )
    for key in sorted(k for k in rows if k.startswith("parked_rss_")):
        n = key[len("parked_rss_") :]
        mem = lambda e: sum(x for x in (least_of(f"parked_rss_{n}", e), least_of(f"parked_pte_{n}", e)) if x is not None)
        avra, go1, goN = mem("avra") or None, mem("go1") or None, mem("goN") or None
        best = min([g for g in (go1, goN) if g is not None] or [None]) if (go1 or goN) else None
        print(
            f"| parked bytes a task, N={n} | {one(key, go1) if go1 is not None else '—'} "
            f"| {one(key, goN) if goN is not None else '—'} | {one(key, avra) if avra is not None else '—'} "
            f"| {ratio(avra, best) if avra is not None else '—'} | ≤ {MEM_GATE:.0f}x | {verdict(avra, go1, goN, MEM_GATE)} |"
        )
    print()
    print("| G1 row that cannot run yet | blocker |")
    print("|---|---|")
    for label, why in BLOCKED_ROWS:
        print(f"| {label} | {why} |")


if "--gates" in sys.argv[1:]:
    gate_table()
else:
    full_table()
