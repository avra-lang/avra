use input::*;
use std::hint::black_box;
use std::time::Instant;

struct Rec {
    key: i64,
    payload: i64,
}

fn main() {
    let mut rs: Vec<Rec> = (0..500_000)
        .map(|i| Rec {
            key: draw(SEED, i) % 100_000,
            payload: i,
        })
        .collect();
    rs = black_box(rs);
    let t0 = Instant::now();
    rs.sort_by_key(|r| r.key);
    let took = t0.elapsed();
    let h = black_box(&rs)
        .iter()
        .fold(rs.len() as i64, |h, r| folded(folded(h, r.key), r.payload));
    report("C7", h, took);
}
