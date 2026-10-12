# The seed

`seed.ll` is the compiler, emitted. It exists so the self-hosting
chain cannot be lost: `build/avra` is built by the `build/avra` that
is already there, and the seed is the only other thing that can make
one.

## Rebuilding from cold

    make bootstrap

which links `seed.ll` against the runtime and the LLVM wrapper, then
uses the result to build the compiler from source. Needs clang and
LLVM 21 (`LLVM_PREFIX`), the same as any build here. `./avra` runs it
by itself when `build/avra` is missing.

### Why two builds, and the one case that takes none

A change to lowering or memory reaches the compiler's own body only
when a compiler already carrying it compiles that body. So a seed whose
source LAGS the tree pays TWO self-compiles: the source compiled by the
seed (gen-1), then that result compiling the source again (gen-2).
Gen-1's own body was laid out by the seed's older codegen; gen-2's by
the source's own. Measured on a Sprite (cold, no cache): `recover` 57 s,
gen-1 880 s, gen-2 856 s — and gen-1 and gen-2 differ in 11,644,429
bytes. Gen-2 is a different compiler, and it is the one this source
emits; there is no safe way to skip it while the seed's codegen may lag.

When the seed IS the tree — `bootstrap/seed.sources` equals
`tools/sources_hash.sh` — there is nothing to advance: the seed was
emitted from exactly this source, so linking it (the `recover` half) is
the whole compiler, and a self-compile only rebuilds it. Measured on a
Sprite: a fixed-point rebuild is BYTE-IDENTICAL to the compiler it
rebuilt (whole-file SHA-256 and `.text` SHA-256 both match), and
`make bootstrap` on a matching seed prints "the seed IS this tree" and
finishes in the `recover` step alone (57–110 s, no self-compile).
`tools/seed_is_tree.sh` makes the decision; `make seed` refreshes the
recorded hash.

The same law, in the reuse direction: a compiler whose source is the
tree's needs NO build at all — the CI exact-key cache
(`tools/compiler_paths.sh --key`, which leaves tests out) and `work`'s
`.avra-compiler-hash` warm check both do this. Only the seed records a
coarse hash (it includes tests), so the `make bootstrap` fast path fires
less often than the source-key reuse does. A stale seed still pays both
builds — that is the generation law, not slack.

## Refreshing it

    make seed

THE RULE: refresh whenever the compiler's own source starts using a
construct the current seed does not understand. A seed that cannot
compile HEAD is not a seed — it is a fossil, and a fossil is
discovered only on the day it is needed. `make bootstrap` is how you
find out; the day to run it is the day a construct lands and gets
dogfooded into `packages/`.

The seed is generated, so it is regenerable and never edited. It
carries a target triple: it is a seed for THIS platform, and a new
platform makes its own with `make seed` from a working compiler.

Why the emitted `.ll` and not the binary — it is portable to any host
with clang and LLVM 21, it is inspectable, and it is smaller
compressed.
