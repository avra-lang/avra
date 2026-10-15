# BOUNDED-CHANNEL DRAIN in Python: a producer thread pushes n items into a
# queue of capacity cap while this thread drains them. Prints the per-item
# cost at two sizes, their ratio, the throughput, the bytes moved, and the
# sum of every item.
import os
import queue
import threading
import time


def env_int(name, fallback):
    try:
        return int(os.environ.get(name, ""))
    except ValueError:
        return fallback


def drain_once(n, cap):
    ch = queue.Queue(maxsize=cap)

    def producer():
        for i in range(n):
            ch.put(i)

    p = threading.Thread(target=producer)
    p.start()
    t0 = time.perf_counter_ns()
    s = 0
    for _ in range(n):
        s += ch.get()
    spent = time.perf_counter_ns() - t0
    p.join()
    return spent, s


def least(n, cap, rounds):
    best = None
    summary = 0
    for _ in range(rounds):
        d, s = drain_once(n, cap)
        if best is None or d < best:
            best = d
        summary = s
    return best, summary


def main():
    small = env_int("BENCH_SMALL", 1000)
    n = env_int("BENCH_N", 10000)
    cap = env_int("BENCH_CAP", 64)
    rounds = env_int("BENCH_ROUNDS", 5)
    d1, _ = least(small, cap, rounds)
    d2, summary = least(n, cap, rounds)
    per1 = d1 / small
    per2 = d2 / n
    print(f"drain_1k_ns_per_op\t{per1:.4f}\tns\t{rounds}")
    print(f"drain_10k_ns_per_op\t{per2:.4f}\tns\t{rounds}")
    print(f"drain_scale\t{per2 / per1:.4f}\tx\t{rounds}")
    print(f"drain_ops_per_s\t{n / (d2 / 1e9):.0f}\tops\t{rounds}")
    print(f"drain_bytes\t{n * 8}\tbytes\t{rounds}")
    print(f"drain_sum\t{summary}\tops\t{rounds}")


main()
