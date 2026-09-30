//! The Rust reference for tools/bench/validate: the same Signup, the
//! same payloads, read the way a Rust service reads them — serde_json
//! straight into the struct, then garde over it. Each line is
//! nanoseconds per payload over `n` reads.
use garde::Validate;
use serde::Deserialize;
use std::hint::black_box;
use std::time::Instant;

fn slug(s: &str, _: &()) -> garde::Result {
    let ok = !s.starts_with('-')
        && !s.ends_with('-')
        && s.bytes().all(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || c == b'-');
    if ok { Ok(()) } else { Err(garde::Error::new("must be a valid slug")) }
}

fn a_plan(s: &str, _: &()) -> garde::Result {
    if ["free", "pro"].contains(&s) { Ok(()) } else { Err(garde::Error::new("must be one of \"free\", \"pro\"")) }
}

fn an_interest(s: &str, _: &()) -> garde::Result {
    if ["music", "maths", "code"].contains(&s) {
        Ok(())
    } else {
        Err(garde::Error::new("must be one of \"music\", \"maths\", \"code\""))
    }
}

#[derive(Deserialize, Validate)]
#[garde(transparent)]
#[serde(transparent)]
struct Username(#[garde(length(chars, min = 3, max = 32), custom(slug))] String);

#[derive(Deserialize, Validate)]
#[garde(transparent)]
#[serde(transparent)]
struct Interest(#[garde(custom(an_interest))] String);

fn free() -> String { "free".to_string() }

#[derive(Deserialize, Validate)]
#[serde(deny_unknown_fields)]
struct Signup {
    #[garde(email)]
    email: String,
    #[garde(range(min = 13, max = 130))]
    age: i64,
    #[garde(dive)]
    username: Username,
    #[garde(length(chars, min = 12))]
    password: String,
    #[garde(matches(password))]
    confirm: String,
    #[serde(default = "free")]
    #[garde(custom(a_plan))]
    plan: String,
    #[serde(default)]
    #[garde(dive)]
    interests: Vec<Interest>,
    #[serde(default)]
    #[garde(dive)]
    referrer: Option<Username>,
}

/// The same record without `deny_unknown_fields`, so a refused payload
/// reaches garde and every rule's issue is built — the work Avra's
/// refusal path does.
#[derive(Deserialize, Validate)]
struct SignupOpen {
    #[garde(email)]
    email: String,
    #[garde(range(min = 13, max = 130))]
    age: i64,
    #[garde(dive)]
    username: Username,
    #[garde(length(chars, min = 12))]
    password: String,
    #[garde(matches(password))]
    confirm: String,
    #[serde(default = "free")]
    #[garde(custom(a_plan))]
    plan: String,
    #[serde(default)]
    #[garde(dive)]
    interests: Vec<Interest>,
    #[serde(default)]
    #[garde(dive)]
    referrer: Option<Username>,
}

fn issues<T: for<'a> Deserialize<'a> + Validate<Context = ()>>(text: &str) -> usize {
    match serde_json::from_str::<T>(text) {
        Err(_) => 1,
        Ok(s) => match s.validate() {
            Ok(()) => 0,
            Err(r) => r.iter().count(),
        },
    }
}

fn timed(label: &str, n: u32, f: impl Fn() -> usize) -> usize {
    let mut sink = 0;
    for _ in 0..n / 10 { sink += f(); }
    let t = Instant::now();
    for _ in 0..n { sink += black_box(f()); }
    println!("{label}: {} ns/payload", t.elapsed().as_nanos() / n as u128);
    sink
}

fn main() {
    let good = std::fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/../payloads/valid.json")).unwrap();
    let bad = std::fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/../payloads/refused.json")).unwrap();
    let n = 200_000;
    let mut sink = 0;
    sink += timed("parse only (valid)", n, || serde_json::from_str::<serde_json::Value>(black_box(&good)).is_ok() as usize);
    sink += timed("decode only (valid)", n, || serde_json::from_str::<Signup>(black_box(&good)).is_ok() as usize);
    sink += timed("decode + rules (valid)", n, || issues::<Signup>(black_box(&good)));
    sink += timed("decode + rules (refused, first issue)", n, || issues::<Signup>(black_box(&bad)));
    sink += timed("decode + rules (refused, every rule)", n, || issues::<SignupOpen>(black_box(&bad)));
    eprintln!("issues on the refused payload: {}", issues::<SignupOpen>(&bad));
    black_box(sink);
}
