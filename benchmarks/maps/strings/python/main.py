# STRING-KEYED MAP in Python: dict, insertion-ordered as Avra's map is.
# Prints build, hit, miss, walk and remove per operation at three sizes,
# the sum of one pass of hits and the entries left after removing all.
import os
import time


def env_int(name, fallback):
    try:
        return int(os.environ.get(name, ""))
    except ValueError:
        return fallback


def one_size(n, ops, rounds, tag, out):
    hit = [f"key{i}" for i in range(n)]
    miss = [f"nokey{i}" for i in range(n)]
    reps = max(1, ops // n)
    best = [float("inf")] * 5
    for _ in range(rounds):
        t = time.perf_counter_ns()
        ms = []
        for _ in range(reps):
            m = {}
            for i, k in enumerate(hit):
                m[k] = i
            ms.append(m)
        best[0] = min(best[0], time.perf_counter_ns() - t)
        m = ms[0]
        t = time.perf_counter_ns()
        s = 0
        for _ in range(reps):
            for k in hit:
                s += m[k]
        best[1] = min(best[1], time.perf_counter_ns() - t)
        if n == 100000:
            out["sum"] = s // reps
        t = time.perf_counter_ns()
        found = 0
        for _ in range(reps):
            for k in miss:
                if k in m:
                    found += 1
        best[2] = min(best[2], time.perf_counter_ns() - t)
        t = time.perf_counter_ns()
        w = 0
        for _ in range(reps):
            for _k, v in m.items():
                w += v
        best[3] = min(best[3], time.perf_counter_ns() - t)
        t = time.perf_counter_ns()
        for mm in ms:
            for k in hit:
                del mm[k]
        best[4] = min(best[4], time.perf_counter_ns() - t)
        if n == 100000:
            out["left"] = len(ms[0])
    per = reps * n
    for i, op in enumerate(["build", "hit", "miss", "walk", "remove"]):
        print(f"maps_{op}_{tag}_ns_per_op\t{best[i] / per:.1f}\tns\t{rounds}")


def main():
    ops = env_int("BENCH_OPS", 100000)
    rounds = env_int("BENCH_ROUNDS", 5)
    out = {"sum": 0, "left": 0}
    one_size(8, ops, rounds, "8", out)
    one_size(1000, ops, rounds, "1k", out)
    one_size(100000, ops, rounds, "100k", out)
    print(f"maps_hit_sum\t{out['sum']}\tops\t{rounds}")
    print(f"maps_left\t{out['left']}\tops\t{rounds}")


main()
