# The build cache — design

Terse. Goal: Avra's builds incremental, fast, and **small**.

## Measured

`./avra build packages/cli` — the compiler's own build:

| | user CPU | wall |
|---|---|---|
| no cache | 150.5 s | 190 s |
| whole-program cache, hit | 12.2 s | 51 s |

**12.4×.** What a hit skips: `resolve 80.7s · bodies 75.9s · parse 5.7s · sigs 3.3s`.
Analysis dominates; the link is most of the remaining 12 s.

**Disk: 16 MB per cache key** — two builds = 31 MB. Every edit adds another 16 MB.
This is Rust's disease and it must be fixed before landing.

## The thesis

**Cache size must scale with DISTINCT CONTENT, not with NUMBER OF BUILDS.**

## Why Rust's `target/` explodes

Coarse units × no dedup × no compression × no GC × keys that wobble for irrelevant
reasons (flags, timestamps, paths).

## Five moves

1. **Fine units + content addressing.** The unit becomes one declaration's lowered IR
   (`lowered(id)` — already a query). ~2 KB each. Identical units share ONE blob, across
   builds *and across programs*. The stdlib's units are immutable and shared, so the bulk
   of the cache is a small fixed set and an edit adds KB, not MB.
2. **Pack + compress.** One append-only pack + index, not millions of files. LLVM IR is
   *text*: ~8× under zstd. Also kills the 4 KB-per-file floor and directory scans.
3. **GC: mark-sweep from build roots + a byte cap.** Roots = the unit manifests of recent
   builds. Rust has neither, so `target/` never shrinks. This makes growth **bounded by
   construction**.
4. **Per-unit object files + incremental link.** Emitting ONE giant `.ll` is the worst
   case for the linker. One `.o` per unit gives: unchanged units reused from the CAS,
   changed units recompiled, **codegen parallel across cores**, incremental link.
5. **Binary patching: no for machine code, yes for IR.** Patching a binary in place needs
   fixed addresses and no inlining — that is live-patching, not building. The safe form is
   real: edit one unit → splice its IR → one object changes → **the linker patches**.

## The macOS lever

APFS `clonefile()` (`cp -c`): placing a cached artifact is a copy-on-write clone — ~0 s,
~0 bytes. Caching the linked binary then costs nothing, which is the one place speed and
disk stop trading.

## Correctness laws (non-negotiable)

- **A key must cover the WHOLE value it certifies.** `parsed` cuts off on structural
  fingerprints while its value carries text and every span; a reindent leaves later spans
  stale and *certified fresh*. A reused stale artifact is a silently wrong binary, so a
  wrong reuse must be impossible **by construction**, not unlikely.
- **The key and the stored name are ONE derivation.** No second stamp to fall out of step.
- **A cutoff per consumer** — what a dependent READ decides which fingerprint may cut it off.
- **The invalidation witness must FAIL FIRST.** Witness (passing): unchanged→HIT;
  semantic edit→MISS; **whitespace-only→MISS**; comment-only→MISS; revert-to-same-bytes→HIT.
  Under the structural `program_hash`, rows 3–4 would have been HITs.
- **The link plan is part of the artifact.** A hit has no analyzed workspace, and
  `link_words` reads the packages a `use` admits; a plan rebuilt on a hit linked against an
  empty dependency closure (undefined `avra_proc_*`, `avra_ffi_arm`).
- **Compose with the seed fast path.** `bootstrap/seed.sources` + `tools/sources_hash.sh`
  already answer "is this tree the seed's source" — whole-tree, ~20 s `make recover`. Do not
  re-derive it. The cache is the FINE path **under** it: the seed is the degenerate case
  where every unit matches. (Recorded trigger: `parsed`'s cutoff is sound only while
  compiles are one-shot — a live host or daemon is this campaign's deadline.)

## Order

- (a) per-unit objects + parallel codegen — biggest win, enables the rest
- (b) pack + compress + GC
- (c) clonefile the binary

## Placement

All of it in `@std.avrac`. The CLI points at a file or package and stays thin.

## Measure honestly

Wall clock on this machine is meaningless — three other campaigns hold load ~11 on 8
cores. **User CPU, or the census.** (Same lesson as the ROADMAP's LANE A.)