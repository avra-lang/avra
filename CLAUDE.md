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

## Style

- Inline single-use values. A `let` earns its place only when the
  name carries meaning the expression lacks, the value is read more
  than once, or the subset REQUIRES a pin (early-return generic
  constructions, sibling-field-only N-evidence, struct literals in
  argument lists). Empty literals (`[]`, `{}`) infer inline in
  constructor fields — never bind them to a throwaway name. When a
  pin seems needed, probe before assuming.

## Rules

- `core/` is infrastructure only. Features never import features.
- Layering is one-way: core -> grammar -> features -> language.
  `grammar/` is the language-agnostic engine; `language/` is the
  driver and the ONE definition of Avra (feature order is branch
  order is the language).
- No string tags or string-matching to detect behavior.
- No `_ ->` catch-alls in DISPATCH matches over our own enums —
  wherever arms decide different behavior, a new variant must break
  the site at compile time (`or`-runs keep that affordable). A
  PROJECTION — one variant's payload, every other arm the same
  absence or rejection — uses `_ ->`: its contract already pins the
  answer for variants that do not exist yet.
- Node facts (spans included) live in side tables keyed by typed ids,
  never on nodes.
- Every module has `spec`/`given`/`then` tests in `tests/` beside it.
- Passes are pure queries with ONE standard signature:
  `pass(p: ParsedProgram, ...upstream Facts) -> Facts` — the program
  first, prior passes' facts next, its own Facts (which OWN its
  diagnostics) out. A pass OWNS its fact tables — NodeStore is
  parse-owned and never accretes pass facts. `analyze` is the only
  place pass order exists; consumers hold ONE Analysis. A source is
  ONE value (`SourceFile`: name + text + line index) — never a loose
  (file, text) pair.
- Queries own granularity and caching; features own the per-variant
  logic a query's body dispatches to.
- Every diagnostic names a registered kind (its F-code is the
  registry's projection), carries help or a structured fix where
  expressible, and has a golden rendering test.
- Map iteration order never reaches output — iterate an ordered
  source.
- A feature is a directory: `mod.av` is the declarative manifest
  (component + tables), `builders.av` holds parse lowering,
  `semantics.av` holds its NodeSemantics impl (dispatch one-liners),
  and rule bodies live by concern — `check.av` for typing, `eval.av`
  for evaluation. Passes NEVER match feature nodes: `semantics_of`
  (THE one exhaustive map, no strings) returns the node's semantics
  directly; the trait impl forces every pass method at compile time.

## Vendored code — do not imitate

`packages/std-avrac/src/features/spec_test/` and `packages/std-cli/`
exist only because the bs2 toolchain requires them. They are NOT
reference code for anything — see spec_test's VENDORED.md.

## bs2 subset notes

Discovered gaps between the spec and the bootstrap compiler. Verify
against these before writing; probe in scratch when unsure.

- Function types are spelled `fn(int) -> bool`, not `(int) -> bool`.
- `ref`, `none`, `shape`, and `table` are reserved words — including
  as variable and method names.
- `contains`/`index_of` compare non-string elements by IDENTITY —
  enum/struct values in lists need a semantic `==` scan (enumerate +
  compare); only string elements get value equality. `==` between two
  LISTS is not value equality either — assert length + per-element.
- No `mut` parameters — in-place-mutating helpers are inexpressible.
- Generics infer ONLY from direct call arguments: not sibling fields,
  not return types. Pin with typed constructor fns
  (`captured_absent<N>()`) or explicit `f<N>(...)`. Constructions under
  a typed let now infer (mono threads expected types through match
  arms, list elements, if-branches — fixed upstream), but a call whose
  N-evidence rides inside a struct argument still needs explicit `<N>`,
  as does any generic call made from inside a generic fn's body.
- Table literals carry their row type explicitly: `table<Row> { ... }`
  — the only form ALL compile modes accept (lib-mode never threads a
  typed let's row type, F1042).
- `it` binds at the nearest enclosing METHOD call and survives call
  wrappers and bare-argument use (`cases.all(count(it.src) == it.n)`,
  `ns.any(is_even(it))`); a nested method call in the body starts its
  own `it` scope. A top-level plain call never binds `it` (pipe RHS
  excepted: `x |> f(it + 1)` hands `f` a closure).
- Present-bind (`let x ->`) in expression-position match loses its
  binding at codegen inside mono-SPECIALIZED bodies (fine in plain
  fns) — restructure to `if k == null { } else { k! }`.
- Matching `null`/`let x ->` directly on a nullable fn call's result
  can mistype — bind to an annotated `let v: T? =` first.
- Or-patterns spell `or`, never `|`: `.A(_) or .B or .C(_) -> x` works
  (payload wildcards and unit variants alike); `.A | .B ->` does not
  parse. Bindings cannot ride an `or` arm — wildcards only.
- Struct destructuring in `let` (`let Sp { lo, hi } = s`) does not parse.
- Comprehensions iterate lists only, not ranges (struct literals inside
  them are fine), and cannot destructure — `[.. for (i, m) in
  xs.enumerate()]` fails to parse; use a loop.
- In a value match producing a list, put a populated arm FIRST — a
  leading `[] `arm pins `List<>` and the sibling arms then clash.
- Method calls on a `const` string fail at codegen.
- Rebuild bs2 with `make build`, never `build-quick` — its freshness
  check can silently skip rebuilds and leave a stale binary.
- Int-backed newtypes corrupt through generic/mono flows: a fn
  returning `Newtype?` comes back null once instances crossed mono'd
  code. Use single-field STRUCTS for typed ids (`{ index: int }`).
- `bs2 run` can serve stale library builds silently — trust `make
  test`, which rebuilds, over ad-hoc `bs2 run` debugging.
- `==` between a nullable string and a string is safe (null compares
  false).
- Maps reject `m["k"]` indexing — use `.get(key)`, which returns `T?`.
- `xs[i] = v` is an invalid assignment target; `xs.set(i, v)` works.
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
  SILENT NULL. Bind, then return the name. Instantiation in
  metadata-compiled TEST files fails resolve entirely — tests build
  feature values through an in-package factory plus `with`.
- Fn-typed arguments carry no `T`-evidence (F1002), and an explicit
  `<T>` pin over one corrupts scalar payloads through mono — never
  thread fn args through generics.
- Statement-position match arms with `{}` bodies parse as empty MAP
  literals and the arms then type-clash — restructure to a
  value-producing match under a typed let, plus an `if`.
- `@comptime` folds only scalar int/bool bodies; struct/list-heavy code
  fails to fold. (Compile-time seed validation waits on our own
  compiler.)
- Trait DEFAULT method bodies typecheck but ICE at codegen
  ("undefined method") — traits carry mandatory methods only.
- Module-level `let` values work within their file but do NOT resolve
  through imports — constants cross modules only as fns.
- `dyn` boxing happens ONLY under a typed let. A config-list
  assignment does not box, and a match ARM tail boxes with the WRONG
  vtable (silent mis-dispatch!) — box every impl under
  `let x: dyn T = Impl { }` first, then select among the lets.
- A trait method must not return a GENERIC enum (`Result<...>`)
  through `dyn` dispatch — mono never instantiates trait-meta return
  types ("unknown enum `Result`"). Return the value and record errors
  through a capability fn on the context instead.
- An `impl Trait for X` block holds ONLY the trait's methods — extra
  methods live in a separate `impl X` block or free fns.
- Working and dogfooded: traits + `impl Trait for`, subjectless `when`
  (with `_` arm), list comprehensions `[x for x in xs if p]`, pipe
  `|>`, typed table literals, `with` on generics, cross-file `impl`,
  the native list scans (`find`/`any`/`all`/`first`/`last`/`is_empty`,
  in `<N>`-generic bodies too), and `?.` field projection with `??`
  (fields only — mapping a present value through a fn stays a match).
