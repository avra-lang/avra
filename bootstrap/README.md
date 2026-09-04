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
