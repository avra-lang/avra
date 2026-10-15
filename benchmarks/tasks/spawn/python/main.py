# SPAWN COST in Python: one threading.Thread per task, joined one at a time
# and every task alive at once. Prints ns per task and the sum.
import os
import threading
import time


def env_int(name, fallback):
    try:
        return int(os.environ.get(name, ""))
    except ValueError:
        return fallback


def square(n):
    return n * n


def one_at_a_time(n, rounds):
    best = None
    summary = 0
    for _ in range(rounds):
        t0 = time.perf_counter_ns()
        s = 0
        for i in range(n):
            box = []

            def run(i=i, box=box):
                box.append(square(i))

            t = threading.Thread(target=run)
            t.start()
            t.join()
            s += box[0]
        spent = time.perf_counter_ns() - t0
        if best is None or spent < best:
            best = spent
        summary = s
    return best, summary


def all_at_once(n, rounds):
    best = None
    summary = 0
    for _ in range(rounds):
        out = [0] * n
        threads = []
        t0 = time.perf_counter_ns()
        for i in range(n):
            def run(i=i, out=out):
                out[i] = square(i)

            t = threading.Thread(target=run)
            t.start()
            threads.append(t)
        for t in threads:
            t.join()
        s = sum(out)
        spent = time.perf_counter_ns() - t0
        if best is None or spent < best:
            best = spent
        summary = s
    return best, summary


def main():
    n = env_int("BENCH_N", 10000)
    rounds = env_int("BENCH_ROUNDS", 5)
    one, sum1 = one_at_a_time(n, rounds)
    all_, _ = all_at_once(n, rounds)
    print(f"spawn_one\t{one / n:.3f}\tns\t{rounds}")
    print(f"spawn_alive\t{all_ / n:.3f}\tns\t{rounds}")
    print(f"spawn_sum\t{sum1}\tops\t{rounds}")


main()
