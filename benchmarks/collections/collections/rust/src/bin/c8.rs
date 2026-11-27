use foldhash::HashMap;
use input::*;
use std::hint::black_box;
use std::time::Instant;

fn main() {
    let xs = black_box(ints(SEED, 1_000_000, 1 << 20));
    let t0 = Instant::now();
    let mut m: HashMap<String, Vec<i64>> = HashMap::default();
    for &x in &xs {
        m.entry((x % 1000).to_string()).or_default().push(x);
    }
    let took = t0.elapsed();
    let m = black_box(m);
    let h = (0..1000).fold(0, |h, k| folded(h, fold_all(&m[&k.to_string()])));
    report("C8", h, took);
    report("C8m", h, took);
}
