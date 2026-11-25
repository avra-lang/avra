use input::*;
use std::hint::black_box;
use std::time::Instant;

fn main() {
    let xs = black_box(ints(SEED, 1_000_000, 1 << 20));
    let t0 = Instant::now();
    let ys: Vec<i64> = black_box(xs.iter().flat_map(|&x| [x, x + 1, x * 2, x ^ 5]).collect());
    let took = t0.elapsed();
    report("C4", fold_all(&ys), took);
}
