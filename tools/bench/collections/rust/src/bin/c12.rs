use input::*;
use std::hint::black_box;
use std::time::Instant;

fn found(n: i64, hit: i64) -> i64 {
    (0..n).find(|&i| i >= hit).unwrap_or(-1)
}

fn search_row(row: &str, n: i64) {
    let hit = 1000 + draw(SEED, 0) % 7;
    let t0 = Instant::now();
    let h = (0..10).fold(0, |h, r| folded(h, found(black_box(n), black_box(hit + r))));
    report(row, black_box(h), t0.elapsed());
}

fn main() {
    search_row("C12l1", 1_000_000);
    search_row("C12l10", 10_000_000);
    search_row("C12c1", 1_000_000);
    search_row("C12c10", 10_000_000);
}
