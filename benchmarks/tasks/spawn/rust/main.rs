// SPAWN COST in Rust: std::thread::spawn and join — an OS thread per
// task, once one at a time and once every task alive at once. Rust's std
// has threads and no fiber runtime, so its analogue is the thread twin:
// prints `spawn_thread`/`spawn_thread_alive` ns per task and `spawn_sum`.
use std::env;
use std::thread;
use std::time::Instant;

fn env_int(name: &str, fallback: u64) -> u64 {
    env::var(name).ok().and_then(|v| v.parse().ok()).unwrap_or(fallback)
}

fn square(n: u64) -> u64 {
    n * n
}

fn one_at_a_time(n: u64, rounds: u64) -> (f64, u64) {
    let mut best = f64::MAX;
    let mut sum = 0u64;
    for _ in 0..rounds {
        let t0 = Instant::now();
        let mut s = 0u64;
        for i in 0..n {
            let h = thread::spawn(move || square(i));
            s += h.join().unwrap();
        }
        let spent = t0.elapsed().as_nanos() as f64;
        if spent < best {
            best = spent;
        }
        sum = s;
    }
    (best, sum)
}

fn all_at_once(n: u64, rounds: u64) -> (f64, u64) {
    let mut best = f64::MAX;
    let mut sum = 0u64;
    for _ in 0..rounds {
        let t0 = Instant::now();
        let mut handles = Vec::with_capacity(n as usize);
        for i in 0..n {
            handles.push(thread::spawn(move || square(i)));
        }
        let mut s = 0u64;
        for h in handles {
            s += h.join().unwrap();
        }
        let spent = t0.elapsed().as_nanos() as f64;
        if spent < best {
            best = spent;
        }
        sum = s;
    }
    (best, sum)
}

fn main() {
    let n = env_int("BENCH_N", 10000);
    let rounds = env_int("BENCH_ROUNDS", 5);
    let (one, sum1) = one_at_a_time(n, rounds);
    let (all, _sum2) = all_at_once(n, rounds);
    println!("spawn_thread\t{:.3}\tns\t{}", one / n as f64, rounds);
    println!("spawn_thread_alive\t{:.3}\tns\t{}", all / n as f64, rounds);
    println!("spawn_sum\t{}\tops\t{}", sum1, rounds);
}
