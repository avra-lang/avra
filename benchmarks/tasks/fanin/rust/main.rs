// FAN-IN in Rust: n_producers threads push values into one sync_channel
// while this thread drains it until every sender is dropped. Prints the
// per-value cost and the received/dropped counts.
use std::env;
use std::sync::mpsc::sync_channel;
use std::thread;
use std::time::Instant;

fn env_int(name: &str, fallback: u64) -> u64 {
    env::var(name).ok().and_then(|v| v.parse().ok()).unwrap_or(fallback)
}

fn fanin_once(producers: u64, per: u64, cap: usize) -> (f64, u64, u64) {
    let (tx, rx) = sync_channel::<u64>(cap);
    let t0 = Instant::now();
    let mut handles = Vec::new();
    for p in 0..producers {
        let tx = tx.clone();
        handles.push(thread::spawn(move || {
            for j in 0..per {
                tx.send(p * per + j).unwrap();
            }
        }));
    }
    drop(tx);
    let mut s = 0u64;
    let mut got = 0u64;
    for v in rx {
        s += v;
        got += 1;
    }
    for h in handles {
        h.join().unwrap();
    }
    let spent = t0.elapsed().as_nanos() as f64;
    (spent, s, got)
}

fn main() {
    let producers = env_int("BENCH_PRODUCERS", 8);
    let per = env_int("BENCH_PER", 6250);
    let cap = env_int("BENCH_CAP", 64) as usize;
    let rounds = env_int("BENCH_ROUNDS", 5);
    let total = producers * per;
    let mut best = f64::MAX;
    let mut got = 0u64;
    for _ in 0..rounds {
        let (d, _, g) = fanin_once(producers, per, cap);
        if d < best {
            best = d;
        }
        got = g;
    }
    println!("fanin_ns_per_op\t{:.4}\tns\t{}", best / total as f64, rounds);
    println!("fanin_received\t{}\tops\t{}", got, rounds);
    println!("fanin_dropped\t{}\tops\t{}", total - got, rounds);
}
