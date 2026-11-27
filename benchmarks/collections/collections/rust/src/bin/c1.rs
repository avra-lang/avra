use input::*;
use std::hint::black_box;
use std::time::Instant;

fn main() {
    let xs = black_box(ints(SEED, 10_000_000, 1 << 20));
    let t0 = Instant::now();
    let sum: i64 = black_box(xs.iter().filter(|&&x| x % 3 == 0).map(|&x| x * 2).sum());
    let took = t0.elapsed();
    report("C1", sum, took);
}
