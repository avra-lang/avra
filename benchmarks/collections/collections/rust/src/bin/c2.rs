use input::*;
use std::hint::black_box;
use std::time::Instant;

fn main() {
    let xs = black_box(ints(SEED, 10_000_000, 1 << 20));
    let t0 = Instant::now();
    let ys: Vec<i64> = black_box(xs.iter().map(|&x| x * 2 + 1).collect());
    let took = t0.elapsed();
    report("C2", folded(fold_all(&ys), xs.len() as i64), took);
}
