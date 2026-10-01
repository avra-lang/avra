use input::*;
use std::hint::black_box;
use std::time::Instant;

fn sort_row(row: &str, mut xs: Vec<i64>) {
    xs = black_box(xs);
    let t0 = Instant::now();
    xs.sort_unstable();
    let took = t0.elapsed();
    report(row, fold_all(black_box(&xs)), took);
}

fn main() {
    let n = 1_000_000;
    sort_row("C5r", ints(SEED, n, 1 << 30));
    sort_row("C5s", (0..n).collect());
    sort_row("C5v", (0..n).map(|i| n - i).collect());
    sort_row("C5u", ints(SEED, n, 16));
}
