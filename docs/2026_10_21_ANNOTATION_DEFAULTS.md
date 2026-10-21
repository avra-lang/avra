# Annotation calls use trailing parameter defaults

Task: `avra-8sb5.10.151`. The commit adding this receipt is the fix head.
The wanting site is graph P01: bare `@model` and explicitly configured
`@model(quote { Semantics { ... } })` must use one annotation function.

The general compiler change has two parts:

1. Annotation checking admits the required-to-total seat range after the
   implicit declaration receiver. Missing required arguments, excess
   arguments and explicit wrong types remain refusals. An arity refusal
   names the range when defaults make it variable.
2. The annotation evaluator fills omitted trailing seats from their actual
   default declaration bodies, in the callee's source scope, using the same
   bounded crossing transport/heap as the receiver and written arguments.
   This includes computed defaults and quoted expressions. It does not
   reinterpret an unwritten argument as a caller expression.

No graph/model-specific branch, second annotation spelling, named-argument
extension or change to marker readers is included. Value-rule annotations
still use their ordinary generated calls and standard validation.

Verified on lane `avra-ux2` with a compiler rebuilt from source digest
`0363a970cdaedb46eb353784a242df853db8e204f5185153df67098b1e4a0ac1`
(Linux binary prefix `c234dad06e54`):

```sh
./build/avra test packages/std-avrac/src/features/annotations/tests/defaults_test.av
# 10/10: omitted/defaulted, explicit, partially supplied, computed,
# quoted declaring arguments, required/excess/type negative controls
./build/avra test packages/std-avrac/src/features/annotations/tests/default_seats
# eval == native == expected: 7 11 42 2
./build/avra test packages/std-avrac/src/features/annotations/tests
# 188/188 tests; 16 eval == native == expected programs
./build/avra test graph/src/tests
# 165/165 tests and both native graph proofs, using optional model metadata
./build/avra check --baseline tools/idioms.baseline graph
# exit 0, no baseline changes
```

The full annotation directory runs through CLI acceptance gate g1 via
`tasks verify --yes avra-8sb5.10.151`, together with the public re-export
regression and graph baseline check. The task tracker records its result;
do not confuse an open gate with a source fix landing on main.
The CLI gate completed successfully: 1 verified, 0 failed, 0 skipped;
473 seconds, at least 4986 MB available on the Sprite throughout.

The original direct consumer refusal was `annotation.seats`: `model` takes
one argument after the declaration, this writes zero. An initial new test
fixture accidentally used reserved identifier `bare`; its 0/10 result is
not treated as a clean red regression. That fixture was corrected before
the passing runs above.

A native macOS compiler was also rebuilt under `tools/watch.sh 3500 make avra`
(peak 2919 MB, exit 0). Its SHA-256 is
`c161918295005f9eb0b482b0aaa1eb85aa8525b3ee983e15f8894b1854ef20c8`;
the generated provenance stamp names the same source digest. The earlier
binary/stamp are preserved in `build/graph-compiler-before-defaults.yd07Dw/`.
Native graph/application verification is recorded in the P01 receipt.
