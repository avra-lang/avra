use input::*;
use std::hint::black_box;
use std::time::Instant;

fn main() {
    let mut xs: Vec<String> = (0..200_000)
        .map(|i| {
            format!(
                "{}x{}",
                draw(SEED, i) % 1_000_000_000,
                draw(SEED + 1, i) % 10_000
            )
        })
        .collect();
    xs = black_box(xs);
    let t0 = Instant::now();
    xs.sort();
    let took = t0.elapsed();
    report("C6", fold_texts(black_box(&xs)), took);
}
