"""The collection bench's table, from run.sh's raw lines
`<engine> <row> <checksum> <ns>`. Exits 1 when the engines disagree on
a checksum or a row is missing from either."""
import statistics
import sys

# id, workload, target: a ratio to Rust, "per key" (against C9i's per-key
# cost, both Avra), "constant" (10M against 1M), or None for a reference row.
# C8m's Rust time is C8's: Rust has one spelling.
ROWS = [
    ("C1", "`filter(p).map(f).sum()`, 10M ints", 1.2),
    ("C2", "`map(f)` to a list, 10M ints, source kept", 1.3),
    ("C3", "`map(f)` to a list, 10M ints, source dying", 1.2),
    ("C4", "`flat_map`, 1M ints × 4", 1.5),
    ("C5r", "`sorted()`, 1M ints, random", 1.3),
    ("C5s", "`sorted()`, 1M ints, sorted", 1.3),
    ("C5v", "`sorted()`, 1M ints, reversed", 1.3),
    ("C5u", "`sorted()`, 1M ints, 16 values", 1.3),
    ("C6", "`sorted()`, 200k strings", 1.5),
    ("C7", "`sorted_by(it.key)`, 500k records", 1.5),
    ("C8", "`group_by`, 1M ints to 1k keys: key to slot", 1.5),
    ("C8m", "`group_by`, 1M ints to 1k keys: map of lists, `concat`", 1.5),
    ("C9", "map, 1M inserts + 1M hits + 1M misses", 1.5),
    ("C9i", "map, 1M inserts alone", None),
    ("C10n", "map, 100k inserts sharing a NUL prefix", "per key"),
    ("C10f", "map, 100k inserts colliding under FNV-1a", "per key"),
    ("C11", "`join`, 1M strings", 1.2),
    ("C12l", "`(0..n).find(p)`, early hit, ×10, n = 10M: loop", "constant"),
    ("C12c", "`(0..n).find(p)`, early hit, ×10, n = 10M: comprehension", "constant"),
]
SIZES = {"C9i": 1_000_000, "C10n": 100_000, "C10f": 100_000}


def read(path):
    times, sums = {}, {}
    for line in open(path):
        engine, row, total, ns = line.split()
        times.setdefault((engine, row), []).append(int(ns))
        sums.setdefault(row, set()).add(total)
    return times, sums


def secs(ns):
    return f"{ns / 1e9:.3g}"


def main():
    times, sums = read(sys.argv[1])
    bad = [f"{row}: {sorted(s)}" for row, s in sorted(sums.items()) if len(s) != 1]
    wanted = {k for row, _, target in ROWS for k in ([row + "1", row + "10"] if target == "constant" else [row])}
    rows = {row for _, row in times}
    missing = sorted(r for r in wanted if ("avra", r) not in times or ("rust", r) not in times)
    unknown = sorted(rows - wanted)
    for b in bad:
        print(f"checksum mismatch, {b}", file=sys.stderr)
    for m in missing:
        print(f"row {m} missing from an engine", file=sys.stderr)
    for u in unknown:
        print(f"row {u} is not in the table", file=sys.stderr)
    if bad or missing or unknown:
        sys.exit(1)
    med = {k: statistics.median(v) for k, v in times.items()}
    print("| id | workload | Avra s | Rust s | ratio | target | verdict |")
    print("|---|---|---:|---:|---:|---|---|")
    for row, what, target in ROWS:
        key = row + "10" if target == "constant" else row
        a, r = med[("avra", key)], med[("rust", key)]
        ratio = a / r
        if target is None:
            goal, verdict = "—", "reference"
        elif target == "per key":
            k = (a / SIZES[row]) / (med[("avra", "C9i")] / SIZES["C9i"])
            goal, verdict = "≤2x C9i per key", f"{'met' if k <= 2 else 'over'} ({k:.2f}x)"
        elif target == "constant":
            k = a / med[("avra", row + "1")]
            goal, verdict = "constant", f"{'constant' if k <= 2 else 'linear'} (10M/1M {k:.1f}x)"
        else:
            goal, verdict = f"≤{target}x", "met" if ratio <= target else "over"
        print(f"| {row} | {what} | {secs(a)} | {secs(r)} | {ratio:.2f}x | {goal} | {verdict} |")


main()
