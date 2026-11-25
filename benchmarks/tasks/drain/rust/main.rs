// BOUNDED-CHANNEL DRAIN in Rust: a producer thread pushes n items into a
// sync_channel of capacity cap while this thread drains them. Prints the
// per-item cost at two sizes, their ratio, the throughput, the bytes
// moved, and the sum of every item.
use std::env;
use std::sync::mpsc::sync_channel;
use std::thread;
use std::time::Instant;

fn env_int(name: &str, fallback: u64) -> u64 {
    env::var(name).ok().and_then(|v| v.parse().ok()).unwrap_or(fallback)
}

fn drain_once(n: u64, cap: usize) -> (f64, u64) {
    let (tx, rx) = sync_channel::<u64>(cap);
    let h = thread::spawn(move || {
        for i in 0..n {
            tx.send(i).unwrap();
        }
    });
    let t0 = Instant::now();
    let mut s = 0u64;
    for _ in 0..n {
        s += rx.recv().unwrap();
    }
    let spent = t0.elapsed().as_nanos() as f64;
    h.join().unwrap();
    (spent, s)
}

fn least(n: u64, cap: usize, rounds: u64) -> (f64, u64) {
    let mut best = f64::MAX;
    let mut sum = 0u64;
    for _ in 0..rounds {
        let (d, s) = drain_once(n, cap);
        if d < best {
            best = d;
        }
        sum = s;
    }
    (best, sum)
}

fn main() {
    let small = env_int("BENCH_SMALL", 1000);
    let n = env_int("BENCH_N", 10000);
    let cap = env_int("BENCH_CAP", 64) as usize;
    let rounds = env_int("BENCH_ROUNDS", 5);
    let (d1, _) = least(small, cap, rounds);
    let (d2, sum) = least(n, cap, rounds);
    let per1 = d1 / small as f64;
    let per2 = d2 / n as f64;
    println!("drain_1k_ns_per_op\t{:.4}\tns\t{}", per1, rounds);
    println!("drain_10k_ns_per_op\t{:.4}\tns\t{}", per2, rounds);
    println!("drain_scale\t{:.4}\tx\t{}", per2 / per1, rounds);
    println!("drain_ops_per_s\t{:.0}\tops\t{}", n as f64 / (d2 / 1e9), rounds);
    println!("drain_bytes\t{}\tbytes\t{}", n * 8, rounds);
    println!("drain_sum\t{}\tops\t{}", sum, rounds);
}
