# PING-PONG in Python: two threads alternate over two one-slot queues.
# Prints ns per round trip and the round-trip count.
import os
import queue
import threading
import time


def env_int(name, fallback):
    try:
        return int(os.environ.get(name, ""))
    except ValueError:
        return fallback


def rally(n):
    to_pong = queue.Queue(maxsize=1)
    to_ping = queue.Queue(maxsize=1)

    def ponger():
        for _ in range(n):
            to_pong.get()
            to_ping.put(1)

    t = threading.Thread(target=ponger)
    t.start()
    t0 = time.perf_counter_ns()
    for _ in range(n):
        to_pong.put(1)
        to_ping.get()
    spent = time.perf_counter_ns() - t0
    t.join()
    return spent


def main():
    n = env_int("BENCH_N", 100000)
    rounds = env_int("BENCH_ROUNDS", 5)
    best = None
    for _ in range(rounds):
        s = rally(n)
        if best is None or s < best:
            best = s
    print(f"pingpong_ns\t{best / n:.3f}\tns\t{rounds}")
    print(f"pingpong_rounds\t{n}\tops\t{rounds}")


main()
