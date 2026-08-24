# Avra

The Avra compiler. Front end first: lexing and parsing through an
extensible grammar, producing an AST for later passes. The language is
assembled from `LanguageFeature` components — each feature declares its
own syntax, docs, and pass hooks; the compiler derives the rest.

Design sources of truth (in `../forge-crafting-intepreters`):
- `docs/2026_04_18_FULL_SPEC.md` — the language spec
- `docs/2026_06_14_AST_SOURCE_OF_TRUTH_EPIC.md` — node model, typed ids,
  spans in side tables, error-tolerant parsing
- `bootstrap/docs/2026_08_19_STANDARDIZATION.md` — front-end shape

## Toolchain

Built and tested with the bootstrap compiler `bs2`
(`../forge-crafting-intepreters/bootstrap/build/bs2`):

```sh
make test    # run spec tests
make clean   # remove build artifacts and toolchain droppings
```

There is no binary yet; the library is exercised by its tests.

## Layout

```
packages/std-avrac/src/
  core/       shared vocabulary (span, token, ast, diag)
  grammar/    the grammar engine
  features/   LanguageFeature components, one directory per feature
  parse/      the text -> AST seam
```

bs2 fixes parts of this layout: package entries resolve at
`packages/<scope>-<name>/src/<name>.av`, the test runner loads from
`packages/std-avrac/src/features/spec_test/` (vendored — see its
VENDORED.md), and `packages/std-cli/src/cli.av` must exist for package
root detection. Build byproducts (`*.avra-sha256`, `*.av.ll`, `build/`)
are never committed.

Known toolchain rent is tracked in TECH_DEBT.md.
