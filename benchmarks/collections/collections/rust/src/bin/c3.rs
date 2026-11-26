use input::*;
use std::hint::black_box;
use std::time::Instant;

fn main() {
    let xs = black_box(ints(SEED, 10_000_000, 1 << 20));
    let t0 = Instant::now();
    let ys: Vec<i64> = black_box(xs.into_iter().map(|x| x * 2 + 1).collect());
    let took = t0.elapsed();
    report("C3", fold_all(&ys), took);
}
