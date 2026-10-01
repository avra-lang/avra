use foldhash::HashMap;
use input::*;
use std::hint::black_box;
use std::time::Instant;

fn main() {
    let n = 1_000_000;
    let keys: Vec<String> = (0..n)
        .map(|i| format!("key:{}:{i}", draw(SEED, i)))
        .collect();
    let absent: Vec<String> = (0..n)
        .map(|i| format!("miss:{}:{i}", draw(SEED, i)))
        .collect();
    let (keys, absent) = black_box((keys, absent));
    let t0 = Instant::now();
    let mut m: HashMap<&str, i64> = HashMap::default();
    for (i, k) in keys.iter().enumerate() {
        m.insert(k.as_str(), i as i64);
    }
    let inserted = t0.elapsed();
    let mut found = 0;
    for k in keys.iter().chain(absent.iter()) {
        found += m.get(k.as_str()).copied().unwrap_or(-1);
    }
    let found = black_box(found);
    let took = t0.elapsed();
    report("C9i", black_box(m.len() as i64), inserted);
    report("C9", folded(m.len() as i64, found), took);
}
