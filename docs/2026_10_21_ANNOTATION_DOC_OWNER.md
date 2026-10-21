# Leading docs belong to the annotation owner

Task `avra-8sb5.11.389`; the commit adding this receipt is the fix head.

Graph P01's real application proof exposed the bug: typed bindings arrived,
but every model with `@model(quote { ... })` lost its description. The bare
Organization model kept its prose. The unchanged expected proof output
`true true true` instead became `false true true` on Linux and macOS.

`compiler/program.av` first picked the nearest statement after a doc anchor,
then asked whether it owned the annotation. A statement INSIDE the quoted
argument came before the declaration and defeated that check. The fix finds
the actual annotation owner by its exact recorded annotation offset. Ordinary
keyword anchors retain their old path; a field mark without an annotation
owner remains an orphan remark. No comments were moved around annotations.

CLI-verified gate g1 (`tasks verify --yes avra-8sb5.11.389`) on `avra-ux2`:

```sh
./build/avra test packages/std-avrac/src/compiler/tests/docs_annotation_quote_test.av
# 6/6: types, functions, methods, stacked annotations, ordinary and orphan docs
./build/avra test packages/std-avrac/src/compiler/tests/doc_test.av
# 13/13
./build/avra test packages/std-avrac/src/compiler/tests/docs_adversarial_test.av
# 10/10
./build/avra test graph/acceptance/app/src/tests
# 14/14 and people_models eval == native == expected
./build/avra check --baseline tools/idioms.baseline graph/acceptance/app
# exit 0, no baseline changes
```

Gate result: 1 verified, 0 failed, 0 skipped; 551 seconds, at least 2942 MB
available throughout. Compiler source digest:
`686b02fa4f6fd75eb2259f7312359c0a258d0ab0acc5957e795bcd0a840ce1ca`;
Linux binary prefix `509b5f7fc061`.

The same source was rebuilt natively on macOS under the unchanged 3500 MB
guard (peak 3187 MB). Its SHA-256 is
`3349aa2f8cdb3d96f2bfcb3017941dc06910846aa24fda54d7ecbf32cd2854ab`.
`build/graph-compiler-before-doc-owner.NSy3Id/` preserves its predecessor.
Native graph/application suites, baseline checks, CLI/HTTP smoke and store
durability all pass; see `graph/P01-HANDOFF.md` and the bounded local log
`build/graph-p01-verify.log` for that integration receipt.
