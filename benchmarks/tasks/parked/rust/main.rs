// MEMORY PER PARKED TASK in Rust: n threads block on their own rendezvous
// channel, the resident set is read from the process's own status, then
// the threads are released and joined. Prints bytes per parked task.
use std::env;
use std::sync::mpsc::sync_channel;
use std::thread;
use std::time::Duration;

fn env_int(name: &str, fallback: u64) -> u64 {
    env::var(name).ok().and_then(|v| v.parse().ok()).unwrap_or(fallback)
}

fn rss_bytes() -> u64 {
    if let Ok(text) = std::fs::read_to_string("/proc/self/status") {
        for line in text.lines() {
            if let Some(rest) = line.strip_prefix("VmRSS:") {
                if let Some(kb) = rest.split_whitespace().next() {
                    return kb.parse::<u64>().unwrap_or(0) * 1024;
                }
            }
        }
    }
    0
}

fn main() {
    let n = env_int("BENCH_N", 10000) as usize;
    let before = rss_bytes();
    let mut senders = Vec::with_capacity(n);
    let mut handles = Vec::with_capacity(n);
    for _ in 0..n {
        let (tx, rx) = sync_channel::<u64>(0);
        senders.push(tx);
        handles.push(thread::spawn(move || {
            let _ = rx.recv();
        }));
    }
    thread::sleep(Duration::from_millis(50));
    let after = rss_bytes();
    for tx in &senders {
        let _ = tx.send(1);
    }
    for h in handles {
        h.join().unwrap();
    }
    let per = if n > 0 { (after.saturating_sub(before)) / n as u64 } else { 0 };
    println!("parked_bytes\t{}\tbytes\t1", per);
    println!("parked_n\t{}\tops\t1", n);
}
