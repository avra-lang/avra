// STRING-KEYED MAP in Rust: std::collections::HashMap<String, u64> with
// its default hasher (SipHash-1-3). Prints build, hit, miss, walk and
// remove per operation at three sizes, the sum of one pass of hits and
// the entries left after removing all.
use std::collections::HashMap;
use std::hint::black_box;
use std::time::Instant;

fn env_int(name: &str, fallback: usize) -> usize {
    std::env::var(name).ok().and_then(|v| v.parse().ok()).unwrap_or(fallback)
}

fn one_size(n: usize, ops: usize, rounds: usize, tag: &str, sum: &mut u64, left: &mut usize) {
    let hit: Vec<String> = (0..n).map(|i| format!("key{}", i)).collect();
    let miss: Vec<String> = (0..n).map(|i| format!("nokey{}", i)).collect();
    let reps = (ops / n).max(1);
    let mut best = [f64::MAX; 5];
    for _ in 0..rounds {
        let t = Instant::now();
        let mut ms: Vec<HashMap<String, u64>> = Vec::with_capacity(reps);
        for _ in 0..reps {
            let mut m = HashMap::new();
            for (i, k) in hit.iter().enumerate() { m.insert(k.clone(), i as u64); }
            ms.push(m);
        }
        best[0] = best[0].min(t.elapsed().as_nanos() as f64);
        let m = &ms[0];
        let t = Instant::now();
        let mut s = 0u64;
        for _ in 0..reps { for k in hit.iter() { s = s.wrapping_add(*m.get(k).unwrap()); } }
        best[1] = best[1].min(t.elapsed().as_nanos() as f64);
        if n == 100000 { *sum = s / reps as u64; }
        let t = Instant::now();
        let mut found = 0usize;
        for _ in 0..reps { for k in miss.iter() { if m.contains_key(k) { found += 1; } } }
        best[2] = best[2].min(t.elapsed().as_nanos() as f64);
        black_box(found);
        let t = Instant::now();
        let mut w = 0u64;
        for _ in 0..reps { for (_k, v) in m.iter() { w = w.wrapping_add(*v); } }
        best[3] = best[3].min(t.elapsed().as_nanos() as f64);
        black_box(w);
        let t = Instant::now();
        for m in ms.iter_mut() { for k in hit.iter() { m.remove(k); } }
        best[4] = best[4].min(t.elapsed().as_nanos() as f64);
        if n == 100000 { *left = ms[0].len(); }
    }
    let per = (reps * n) as f64;
    for (i, op) in ["build", "hit", "miss", "walk", "remove"].iter().enumerate() {
        println!("maps_{}_{}_ns_per_op\t{:.1}\tns\t{}", op, tag, best[i] / per, rounds);
    }
}

fn main() {
    let ops = env_int("BENCH_OPS", 100000);
    let rounds = env_int("BENCH_ROUNDS", 5);
    let (mut sum, mut left) = (0u64, 0usize);
    one_size(8, ops, rounds, "8", &mut sum, &mut left);
    one_size(1000, ops, rounds, "1k", &mut sum, &mut left);
    one_size(100000, ops, rounds, "100k", &mut sum, &mut left);
    println!("maps_hit_sum\t{}\tops\t{}", sum, rounds);
    println!("maps_left\t{}\tops\t{}", left, rounds);
}
