use foldhash::HashMap;
use input::*;
use std::hint::black_box;
use std::time::Instant;

fn insert_row(row: &str, keys: Vec<String>) {
    let keys = black_box(keys);
    let t0 = Instant::now();
    let mut m: HashMap<&str, i64> = HashMap::default();
    for (i, k) in keys.iter().enumerate() {
        m.insert(k.as_str(), i as i64);
    }
    let took = t0.elapsed();
    let n = black_box(m.len() as i64);
    report(row, folded(n, fold_bytes(&keys)), took);
}

fn main() {
    insert_row("C10n", (0..100_000).map(|i| format!("k\0{i}")).collect());
    insert_row("C10f", fnv_colliding(10, 5));
}
