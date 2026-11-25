//! The collection bench's inputs and checksum, bit for bit as
//! `../input/src/input.av`, so a twin and its Avra program read the same
//! numbers and must print the same sums.
use std::time::Duration;

/// The seed every workload's input is drawn from.
pub const SEED: i64 = 24301;

const GOLDEN: u64 = 0x9e3779b97f4a7c15;

/// FNV-1a 64's offset basis and prime: the map hash before it was keyed.
const FNV_OFFSET: u64 = 0xcbf29ce484222325;
const FNV_PRIME: u64 = 0x100000001b3;

/// The index bits an adversarial key set shares under FNV-1a.
pub const SHARED_BITS: u64 = (1 << 18) - 1;

fn mixed(x: u64) -> u64 {
    let a = (x ^ (x >> 30)).wrapping_mul(0xbf58476d1ce4e5b9);
    let b = (a ^ (a >> 27)).wrapping_mul(0x94d049bb133111eb);
    b ^ (b >> 31)
}

/// The `i`th draw of the stream `seed` names, non-negative.
pub fn draw(seed: i64, i: i64) -> i64 {
    (mixed((seed as u64).wrapping_add((i as u64).wrapping_add(1).wrapping_mul(GOLDEN))) >> 1) as i64
}

/// `n` draws, each below `bound`.
pub fn ints(seed: i64, n: i64, bound: i64) -> Vec<i64> {
    (0..n).map(|i| draw(seed, i) % bound).collect()
}

/// One more value into an order-sensitive checksum.
pub fn folded(h: i64, x: i64) -> i64 {
    ((h ^ x) as u64).wrapping_mul(FNV_PRIME) as i64
}

/// A list's checksum: its length, then every element in order.
pub fn fold_all(xs: &[i64]) -> i64 {
    xs.iter().fold(xs.len() as i64, |h, &x| folded(h, x))
}

/// A text list's checksum: each text's length and its first and last
/// bytes, in order.
pub fn fold_texts<S: AsRef<str>>(xs: &[S]) -> i64 {
    xs.iter().fold(xs.len() as i64, |h, s| {
        let b = s.as_ref().as_bytes();
        folded(
            folded(folded(h, b.len() as i64), b[0] as i64),
            b[b.len() - 1] as i64,
        )
    })
}

/// A text list's checksum over every byte of every text, in order.
pub fn fold_bytes(xs: &[String]) -> i64 {
    xs.iter().fold(xs.len() as i64, |h, s| {
        s.bytes().fold(h, |h, b| folded(h, b as i64))
    })
}

/// One result line: the row, the checksum, the nanoseconds it took.
pub fn report(row: &str, sum: i64, took: Duration) {
    println!("{row} {sum} {}", took.as_nanos());
}

fn alnum(d: u64) -> u8 {
    match d {
        0..=9 => 48 + d as u8,
        10..=35 => 55 + d as u8,
        _ => 61 + d as u8,
    }
}

const PLACES: [u64; 4] = [1, 62, 3844, 238328];

fn block_bytes(j: u64) -> Vec<u8> {
    PLACES.iter().map(|p| alnum(j / p % 62)).collect()
}

/// FNV-1a's state after `bytes`, from the state `h`.
pub fn fnv(h: u64, bytes: &[u8]) -> u64 {
    bytes
        .iter()
        .fold(h, |s, &b| (s ^ b as u64).wrapping_mul(FNV_PRIME))
}

/// `per`^`stages` distinct keys whose FNV-1a hashes share their low 18
/// bits; checked here, so a twin cannot run over a set that fails to.
pub fn fnv_colliding(per: usize, stages: usize) -> Vec<String> {
    let mut h = FNV_OFFSET;
    let mut keys = vec![String::new()];
    for _ in 0..stages {
        let next = fnv(h, &block_bytes(0));
        let blocks: Vec<String> = (0u64..)
            .filter(|&j| (fnv(h, &block_bytes(j)) ^ next) & SHARED_BITS == 0)
            .take(per)
            .map(|j| String::from_utf8(block_bytes(j)).unwrap())
            .collect();
        keys = keys
            .iter()
            .flat_map(|k| blocks.iter().map(move |b| format!("{k}{b}")))
            .collect();
        h = next;
    }
    let low = fnv(FNV_OFFSET, keys[0].as_bytes()) & SHARED_BITS;
    assert!(keys
        .iter()
        .all(|k| fnv(FNV_OFFSET, k.as_bytes()) & SHARED_BITS == low));
    keys
}
