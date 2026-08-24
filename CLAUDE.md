# Avra — clean-room compiler

## AVRA PRINCIPLES

The spec's Part 0 frames every decision (full text: spec, Part 0).
Above all: **P6, paradox collapse** — binary choices are usually false
dichotomies; find the design where both sides win. When a trade-off
feels forced, the model is wrong, not the requirements.

- P1  LLM-first: correct on first generation is the success metric
- P2  substrate for autonomous services
- P3  gloriously declarative, zero ceremony
- P4  Rust-level performance or better
- P5  full-stack vertical integration
- P6  paradox collapse
- P7  visible magic — always inspectable
- P8  escape hatches everywhere
- P9  boundaries are contracts
- P10 the compiler holds semantic knowledge no other tool has
- P11 machine-readability is the substrate, human-readability the projection
- P12 one source of truth, many projections
- P13 collapse dev/ops/infra
- P14 no runtime, no framework, no container
- P17 composability over featurefulness

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
- Passes are pure queries: explicit inputs, value + diagnostics
  returned together. A pass OWNS its fact tables — NodeStore is
  parse-owned and never accretes pass facts.
- Queries own granularity and caching; features own the per-variant
  logic a query's body dispatches to.
- Every diagnostic carries a registered stable code, help or a
  structured fix where expressible, and a golden rendering test.
- Map iteration order never reaches output — iterate an ordered
  source.
- A feature is a directory: `mod.av` is the declarative manifest
  (component + tables), and implementation fns live in sibling files
  by concern — `builders.av` for parse lowering; `check.av`,
  `resolve.av`, … as passes arrive.

## Vendored code — do not imitate

`packages/std-avrac/src/features/spec_test/` and `packages/std-cli/`
exist only because the bs2 toolchain requires them. They are NOT
reference code for anything — see spec_test's VENDORED.md.

## bs2 subset notes

Discovered gaps between the spec and the bootstrap compiler. Verify
against these before writing; probe in scratch when unsure.

- Function types are spelled `fn(int) -> bool`, not `(int) -> bool`.
- `ref`, `none`, and `shape` are reserved words.
- No `mut` parameters — in-place-mutating helpers are inexpressible.
- Generics infer ONLY from direct call arguments: not sibling fields,
  not return types. Pin with typed constructor fns
  (`captured_absent<N>()`) or explicit `f<N>(...)`. Constructions under
  a typed let now infer (mono threads expected types through match
  arms, list elements, if-branches — fixed upstream), but a call whose
  N-evidence rides inside a struct argument still needs explicit `<N>`,
  as does any generic call made from inside a generic fn's body.
- Table literals need a declared row type (`let x: List<Row> = table`)
  — field position and component config pairs do not thread it
  (F1042); the typed let is required.
- `it` fails to infer in complex filter/map bodies — use an annotated
  closure param.
- Present-bind (`let x ->`) in expression-position match loses its
  binding at codegen inside mono-SPECIALIZED bodies (fine in plain
  fns) — restructure to `if k == null { } else { k! }`.
- Matching `null`/`let x ->` directly on a nullable fn call's result
  can mistype — bind to an annotated `let v: T? =` first.
- Or-patterns (`.A | .B ->`) do not parse, despite being documented.
- Struct destructuring in `let` (`let Sp { lo, hi } = s`) does not parse.
- Comprehensions iterate lists only, not ranges (struct literals inside
  them are fine).
- Method calls on a `const` string fail at codegen.
- Rebuild bs2 with `make build`, never `build-quick` — its freshness
  check can silently skip rebuilds and leave a stale binary.
- Int-backed newtypes corrupt through generic/mono flows: a fn
  returning `Newtype?` comes back null once instances crossed mono'd
  code. Use single-field STRUCTS for typed ids (`{ index: int }`).
- `bs2 run` can serve stale library builds silently — trust `make
  test`, which rebuilds, over ad-hoc `bs2 run` debugging.
- `==` between a nullable string and a string SEGFAULTS when null —
  check `!= null` and unwrap before comparing.
- Maps reject `m["k"]` indexing — use `.get(key)`, which returns `T?`.
- A struct literal directly in a call's argument list fails to parse —
  bind it to a `let` first.
- Components work: `component Name { config { field: T = default } }`;
  instantiate with `component Name inst { key = expr }` — bs2's
  "keyword-prefixed instantiation", an instance NOT a definition.
  The bare form (`Name inst {}`) needs the definition registered in
  the SAME parse, which never holds across sibling module files
  (probed: parse order does not save it) — so the keyword prefix is
  rent, not choice. Pairs NEWLINE-separated. Instantiation is a
  STATEMENT binding `inst`; in expression position it compiles to a
  SILENT NULL. Bind, then return the name.
- Fn-typed arguments carry no `T`-evidence (F1002), and an explicit
  `<T>` pin over one corrupts scalar payloads through mono — never
  thread fn args through generics.
- Statement-position match arms with `{}` bodies parse as empty MAP
  literals and the arms then type-clash — restructure to a
  value-producing match under a typed let, plus an `if`.
- `@comptime` folds only scalar int/bool bodies; struct/list-heavy code
  fails to fold. (Compile-time seed validation waits on our own
  compiler.)
- Working and dogfooded: traits + `impl Trait for`, subjectless `when`
  (with `_` arm), list comprehensions `[x for x in xs if p]`, pipe
  `|>`, typed table literals, `with` on generics, cross-file `impl`.
