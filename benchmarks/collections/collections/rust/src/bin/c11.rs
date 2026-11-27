use input::*;
use std::hint::black_box;
use std::time::Instant;

fn main() {
    let xs: Vec<String> = black_box(
        (0..1_000_000)
            .map(|i| (draw(SEED, i) % 100_000).to_string())
            .collect(),
    );
    let t0 = Instant::now();
    let s = black_box(xs.join(","));
    let took = t0.elapsed();
    let b = s.as_bytes();
    report(
        "C11",
        folded(
            folded(b.len() as i64, b[b.len() / 2] as i64),
            b[b.len() - 1] as i64,
        ),
        took,
    );
}
