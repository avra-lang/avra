# The seed

`seed.ll` is the compiler, emitted. It exists so the self-hosting
chain cannot be lost: `build/avra` is built by the `build/avra` that
is already there, and nothing else can build it any more.

## Why bs2 cannot

The bootstrap compiler was the cold path until the tree outgrew its
dialect. It cannot lex a raw `"""` block, and every feature's grammar
was one; since `grammar { … }` landed, 30 feature manifests use a
construct bs2 has never heard of. Replaying the chain by hand needs
one binary per language change — bs2 → 551259c → 26c11fe → today the
day this was written — which is knowledge that lives nowhere.

The seed replaces that ladder with one artifact.

## Rebuilding from cold

    make bootstrap

which links `seed.ll` against the runtime and the LLVM wrapper, then
uses the result to build the compiler from source. Needs clang and
LLVM 21 (`LLVM_PREFIX`), the same as any build here.

## Refreshing it

    make seed

THE RULE: refresh whenever the compiler's own source starts using a
construct the current seed does not understand. A seed that cannot
compile HEAD is not a seed — it is a fossil, which is exactly what
the bs2 path became. `make bootstrap` is how you find out; run it
when you add a construct and dogfood it in `packages/`.

The seed is generated, so it is regenerable and never edited. It
carries a target triple: it is a seed for THIS platform, and a new
platform makes its own with `make seed` from a working compiler.
