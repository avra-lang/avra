# FAN-IN in Python: n_producers threads push values into one bounded queue
# while this thread drains it until every producer has sent a sentinel.
# Prints the per-value cost and the received/dropped counts.
import os
import queue
import threading
import time


def env_int(name, fallback):
    try:
        return int(os.environ.get(name, ""))
    except ValueError:
        return fallback


def fanin_once(producers, per, cap):
    ch = queue.Queue(maxsize=cap)
    sentinel = -1

    def producer(p):
        for j in range(per):
            ch.put(p * per + j)
        ch.put(sentinel)

    threads = [threading.Thread(target=producer, args=(p,)) for p in range(producers)]
    t0 = time.perf_counter_ns()
    for t in threads:
        t.start()
    s = 0
    got = 0
    done = 0
    while done < producers:
        v = ch.get()
        if v == sentinel:
            done += 1
        else:
            s += v
            got += 1
    for t in threads:
        t.join()
    return time.perf_counter_ns() - t0, s, got


def main():
    producers = env_int("BENCH_PRODUCERS", 8)
    per = env_int("BENCH_PER", 6250)
    cap = env_int("BENCH_CAP", 64)
    rounds = env_int("BENCH_ROUNDS", 5)
    total = producers * per
    best = None
    got = 0
    for _ in range(rounds):
        d, _, g = fanin_once(producers, per, cap)
        if best is None or d < best:
            best = d
        got = g
    print(f"fanin_ns_per_op\t{best / total:.4f}\tns\t{rounds}")
    print(f"fanin_received\t{got}\tops\t{rounds}")
    print(f"fanin_dropped\t{total - got}\tops\t{rounds}")


main()
