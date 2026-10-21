# P01 receipt: model-declared semantic bindings

Base: `503b5780`; the commit adding this receipt is the task head.
Requires the annotation-default fix in that base and the doc-owner fix
tracked as `avra-8sb5.11.389`, recorded separately in this branch.

Implemented: typed optional `Semantics` on generated `Model` descriptors,
supplied by `@model(quote { Semantics { ... } })`. Bare `@model` retains empty
bindings. Identity namespaces/normalizers, directed relationship endpoints
and phrases, valid-time representations and quantity/unit/scale bindings
are declared in source, projected into the catalog and shape-checked before
catalog admission. All participate in catalog identity. Paths cross embedded
records only; unknown paths, inappropriate shapes and conflicting bindings
are refused. No property/model-name convention or ontology handler is added.

Fixture contact keys, family vocabulary/direction and validity paths are
now actual model metadata in `acceptance/app/src/models/people.av`, not just
prose. An unrelated instrument/calibration ontology exercises the same API,
including quantity units, without engine changes. Ordinary `std.validate`
decoders and field/record rules remain authoritative for actual values.

Verification on native macOS, using this worktree's rebuilt `./build/avra`:

```sh
sh tools/watch.sh 3500 ./build/avra test graph/src/tests
# 165/165, including 14 semantic-binding tests; 2 eval/native proofs
sh tools/watch.sh 3500 ./build/avra test graph/acceptance/app/src/tests
# 14/14; people_models eval == native == expected
sh tools/watch.sh 3500 ./build/avra check --baseline tools/idioms.baseline graph
sh tools/watch.sh 3500 ./build/avra check --baseline tools/idioms.baseline graph/acceptance/app
sh tools/watch.sh 3500 ./build/avra check --baseline tools/idioms.baseline graph/tests/unrelated
sh tools/watch.sh 3500 ./build/avra build graph
python3 graph/tests/smoke.py
python3 graph/tests/durability.py
# all exit 0; no baseline edits
```

The bounded combined log is `build/graph-p01-verify.log`. Tests peak at
1038 MB (graph) and 948 MB (application). Compiler source digest:
`686b02fa4f6fd75eb2259f7312359c0a258d0ab0acc5957e795bcd0a840ce1ca`;
native binary SHA-256:
`3349aa2f8cdb3d96f2bfcb3017941dc06910846aa24fda54d7ecbf32cd2854ab`.
The guarded compiler rebuild peaked at 3187 MB, exit 0. Its predecessor is
preserved in `build/graph-compiler-before-doc-owner.NSy3Id/`.

An earlier cross-package proof correctly failed (`false true true`) on both
Linux and Mac: quoted annotation arguments stole declaration descriptions.
The binding data itself was correct. That became a compiler issue/fix, not
a moved-comment workaround or an expected-output change. The corrected
proof still expects `true true true` and now checks both descriptions and
machine-readable identity/direction data. The temporary diagnostic entry
point was removed; no alternate fixture startup was retained.

Scope: metadata, not extraction, identity resolution, time evaluation,
derived arithmetic or automatic publication. L01 can now consume declared
keys; P02 still requires Q01 before declaring executable read policies.
E00 remains necessary before qualified extraction evidence can be stored.
L01 must also test the source-revision gap: current alias reads deliberately
hide stale input support. A temporary absence during reprocessing must not
by itself manufacture another identity, nor make stale contact data current.
The catalog descriptor's `semantics.version` is 1. No engine table changed;
old interpretations become stale under the existing conservative schema
policy rather than having their metadata silently reinterpreted.
