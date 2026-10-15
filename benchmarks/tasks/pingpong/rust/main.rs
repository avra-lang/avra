// PING-PONG in Rust: two threads alternate over two rendezvous channels.
// Prints `pingpong_ns` per round trip and `pingpong_rounds`.
use std::env;
use std::sync::mpsc::{sync_channel, Receiver, SyncSender};
use std::thread;
use std::time::Instant;

fn env_int(name: &str, fallback: u64) -> u64 {
    env::var(name).ok().and_then(|v| v.parse().ok()).unwrap_or(fallback)
}

fn rally(n: u64) -> f64 {
    let (to_pong, from_ping): (SyncSender<u64>, Receiver<u64>) = sync_channel(0);
    let (to_ping, from_pong): (SyncSender<u64>, Receiver<u64>) = sync_channel(0);
    let h = thread::spawn(move || {
        for _ in 0..n {
            from_ping.recv().unwrap();
            to_ping.send(1).unwrap();
        }
    });
    let t0 = Instant::now();
    for _ in 0..n {
        to_pong.send(1).unwrap();
        from_pong.recv().unwrap();
    }
    let spent = t0.elapsed().as_nanos() as f64;
    h.join().unwrap();
    spent
}

fn main() {
    let n = env_int("BENCH_N", 100000);
    let rounds = env_int("BENCH_ROUNDS", 5);
    let mut best = f64::MAX;
    for _ in 0..rounds {
        let s = rally(n);
        if s < best {
            best = s;
        }
    }
    println!("pingpong_ns\t{:.3}\tns\t{}", best / n as f64, rounds);
    println!("pingpong_rounds\t{}\tops\t{}", n, rounds);
}
