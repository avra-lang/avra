# Avra — clean-room compiler

Clean restart of the Avra compiler, built slowly, one reviewed file at a
time. Front end first: an extensible grammar assembled from
LanguageFeature components, producing an AST for later passes.
Toolchain: the bootstrap `bs2` binary (see README.md).

Design sources of truth (in `../forge-crafting-intepreters`):
- `docs/2026_04_18_FULL_SPEC.md` — the language
- `docs/2026_06_14_AST_SOURCE_OF_TRUTH_EPIC.md` — node model, spans, error tolerance
- `bootstrap/docs/2026_08_19_STANDARDIZATION.md` — front-end shape

Follow the old tree's *documented designs*, never its code habits.

## Comments

Never write comments about specific situations, tickets, approaches, or
points in time. Comments are evergreen: always relevant, or absent.
Keep them very terse, in plain language. State what a thing is or the
invariant it holds — no narration, no self-justification, no history.

## Rules

- `core/` is infrastructure only. Features never import features.
- No string tags or string-matching to detect behavior.
- No `_ ->` catch-alls over our own enums.
- Node facts (spans included) live in side tables keyed by typed ids,
  never on nodes.
- Every module has `spec`/`given`/`then` tests in `tests/` beside it.

## Vendored code — do not imitate

`packages/std-avrac/src/features/spec_test/` and `packages/std-cli/`
exist only because the bs2 toolchain requires them. They are NOT
reference code for anything — see spec_test's VENDORED.md.
