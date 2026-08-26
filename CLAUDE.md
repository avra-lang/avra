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
- A state struct's impl is its VOCABULARY: the small verbs that
  read or write its tables (`speak`, `bind`, `mint`, `give`) live
  as methods, so drivers read as prose. EXCEPTION (generic — any
  struct, any loop): a method call on a closure-captured local in a
  loop that also early-returns ICEs (#1377); there, use a free fn
  taking the state first (`eval_node(ev, cx, e)`). The pass
  visitors keep that shape uniformly.
- A long fn splits at its PHASE boundaries into named helpers, each
  with a one-line contract (`match_seq` matches, `built` builds;
  `printed_value` dispatches, `bool_word` branches). If a fn needs
  a paragraph comment mid-body, that paragraph is a helper's name.
- A projection is ONE match: nested patterns
  (`.Node(.NAlt(a)) -> a, _ -> null`), never an unwrap ladder.
- The third copy of a shape names the concept: shared walks and
  registries get ONE definition (`post_order`, `file_command`) and
  the copies die. Two copies may wait; three never do.

## Dogfooding is design

The compiler is Avra's first user. When its code WANTS a construct
the language lacks — a sugar, a projection, a rule — add the ask to
the ROADMAP's sugar backlog, naming the wanting site, as part of the
change that hit it. Request your own features: the backlog feeds the
spec.

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
- Grammar authoring: a greedy star cannot be told to stop early. An
  arm that could also START the star's required tail (`_` is a
  NAME; a keyword is a NAME) must be an ordered choice INSIDE the
  repeated slot, anchor-first — never a tail after the star. The
  builder then owns the law the grammar cannot state (exactly one,
  last).
- Grammar authoring: @recover converts a branch's break into a hole
  HIT, so it belongs only on branches anchored by a keyword no other
  branch can start with. A NAME-headed branch (assignment) must stay
  non-committing — recovery there swallows every expression line.
- A feature never matches ANOTHER feature's variants — nor
  re-extracts its OWN literal's payload inline: all literal reads
  go through core's value protocol (`truth_of`, `int_of`,
  `text_of`), one projection per value category. The protocol grows
  with value categories — a core event — never per feature. (N
  variants need N projections — payload types differ, and a unified
  return would be the parallel Value enum the doctrine refuses.)
- The IR is CLOSED vocabulary: features lower into it, never grow
  it. A new Ins variant is a core event — a new control shape, value
  category, or memory boundary. Value-producing runtime needs ride
  `CallRt`; the backend and memory pass are functions of the IR,
  dispatching on shapes, never on features.
- A feature is a directory: `mod.av` is the declarative manifest
  (component + tables), `builders.av` holds parse lowering,
  `semantics.av` holds its NodeSemantics impl (dispatch one-liners),
  and rule bodies live by concern — `check.av` for typing, `eval.av`
  for evaluation. Passes NEVER match feature nodes: `semantics_of`
  (THE one exhaustive map, no strings) returns the node's semantics
  directly; the trait impl forces every pass method at compile time.
- A pass CONTEXT carries the pass's STATE verbs only — walk, look
  up, record, emit, mint, slots — never a feature's rule. A
  feature-named fn on a cx (`check_mut`, `emit_loop`) is a rule
  body living in a driver; it moves home to the feature dir and
  reaches state through general verbs. contract.av changes only
  when a feature needs a verb NO feature has ever needed. The
  statement typing cx NESTS the whole expression vocabulary
  (`cx.expr: TypeCx`) rather than re-wiring its verbs.
- Keywords are never listed by hand: they derive from the assembled
  grammar's identifier-shaped literals (`Grammar.keywords()`) — a
  feature's gram fragment IS its keyword claim.
  A feature owning a STATEMENT kind also impls `StmtSemantics`
  (`stmt.av` or `semantics.av`) and joins `stmt_semantics_of` — the
  drivers' one statement loop reaches it there.
  Start a feature with `avra new feature <name>`; prove it with a
  corpus pair (`corpus/<name>.av` + `.expected`). `make gate` is
  the bar.

- The CLI: each subcommand is ONE file in
  `packages/cli/src/commands/`, exporting
  `<name>_command() -> Subcommand`; `cli/src/main.av` only composes
  the list. A new command is a new file plus one line.

## Vendored code — do not imitate

`packages/std-avrac/src/features/spec_test/` and `packages/std-cli/`
exist only because the bs2 toolchain requires them. They are NOT
reference code for anything — see spec_test's VENDORED.md.

## bs2 subset notes

Discovered gaps between the spec and the bootstrap compiler. Verify
against these before writing; probe in scratch when unsure.

- Function types are spelled `fn(int) -> bool`, not `(int) -> bool`.
- Multi-line fn signatures parse fine (probed) — stacked params with
  a trailing comma, or aligned continuation lines. Wrap wide ones.
- `ref`, `none`, `shape`, and `table` are reserved words — including
  as variable and method names; `then` refuses as a struct/enum
  field name.
- `.reverse()` mutates IN PLACE and returns the SAME aliased list
  (probed: the source list's order changes too) — never treat it as
  a copy; assume `.sort()` matches. A safe reversed copy stays
  hand-rolled.
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
  excepted: `x |> f(it + 1)` hands `f` a closure). The pronoun
  detector misses `is`-expressions — `xs.filter(it is .A)` fails to
  bind; use an explicit param there.
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
  xs.enumerate()]` fails to parse; use a loop. The `if` FILTER takes
  a simple predicate only — `||` or `!` inside it fails to parse
  ("expected `]` after list"); use a loop there too.
- In a value match producing a list, put a populated arm FIRST — a
  leading `[] `arm pins `List<>` and the sibling arms then clash.
- Method calls on a `const` string fail at codegen.
- Rebuild bs2 with `make build`, never `build-quick` — its freshness
  check can silently skip rebuilds and leave a stale binary.
- Int-backed newtypes corrupt through generic/mono flows: a fn
  returning `Newtype?` comes back null once instances crossed mono'd
  code. Use single-field STRUCTS for typed ids (`{ index: int }`).
- A nullable GENERIC struct local (`mut x: Thing<N>? = null`)
  corrupts through lib-mode mono — carry presence in a bool flag
  beside non-generic pieces and reconstruct after the loop.
- `bs2 run` can serve stale library builds silently — the
  `.avra-sha256` sidecars are its freshness truth, and they go stale
  against edited sources. `make test` is immune (metadata mode);
  `bs2 run` of the CLI is not. `./avra <cmd>` is the front door — it
  clears the sidecars itself; never invoke the CLI through raw
  `bs2 run`. When lib-mode still lags, `make clean`.
- `==` between a nullable string and a string is safe (null compares
  false) — for a VARIABLE operand only: a call result compared
  directly (`f() == s`) misses the null guard and SIGSEGVs (#1376).
  Bind to a `let tn: string? =` first.
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
- Fns share ONE namespace per module across sibling files: a private
  fn in one file shadows a same-name import for the WHOLE module
  (arity clashes, F1001, at unrelated call sites). Check for the
  name before writing a helper.
- Package resolution is convention, not manifest: `use @scope.name`
  resolves to `packages/scope-name/src/name.av` (else `mod.av`).
  And THE staleness trap, root-caused: `bs2 run`'s cache keys the
  unit by the ENTRY FILE'S BYTES ALONE — `[dependencies]` entries,
  sidecar deletion, and package-cache purges all fail to reach that
  key, so edits to dependency packages serve a STALE binary
  silently: phantom bugs, vanishing grammar branches, segfaults.
  The cure is `./avra`, which generates a stamped entry
  (main_stamped.av — a content hash of every package source in the
  first line) so the key is truthful and caches stay warm. Debug
  probes get fresh bytes by being new files, which is why a probe
  can pass while the CLI fails — NEVER trust that split as
  evidence of a compiler bug before touching the entry's bytes. A
  runnable ENTRY file gets a local module tree only through `mod x`
  declarations: `mod commands` loads sibling `commands.av` or
  `commands/mod.av`, and the directory's other files join the
  module. A bare `use commands.{..}` without the `mod` stub is
  F3101.
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
  in `<N>`-generic bodies too), `?.` field projection with `??`
  (fields only — mapping a present value through a fn stays a match),
  NESTED match patterns (`.Node(.NExpr(id)) -> id` — generic-payload
  enums included), and if-else as a comprehension ELEMENT — in plain
  fns only: inside a generic body it types as `List<void>` (F1000);
  loop there instead.
- A match on a NULLABLE enum takes only `null` and `let x ->` arms —
  variant arms on `T?` refuse as non-exhaustive (F9001); unwrap
  first, then match variants.
- A METHOD call on a closure-captured local inside a loop that also
  contains an early `return` ICEs at codegen ("Referring to an
  instruction in another function", #1377) — any struct, any loop.
  Use a free fn taking the struct first.
