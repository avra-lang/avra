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

## The idiom bar — BEFORE writing any fn

First drafts are written idiomatic, not cleaned up later. Before
the body exists, answer:

1. Is any loop a MAP/FILTER/FLAT-MAP? Comprehension (`?` works in
   element and iterable; predicates hoist into named fns).
2. Building head-plus-tail? `concat`/`flatten`, never push-ceremony.
3. Is a projection being spelled twice? The second spelling names a
   verb (`cx.int_at`, `expr_fps`) or uses the existing one.
4. Does absence read straight? (`?? `, `?.`, if-null early return —
   never a two-arm null match without payload logic on both arms.)
5. Scanning for one element? `find`/`any`/`index_of`, not a flag
   loop.
6. Unsure a shape compiles in the subset? PROBE in scratch first —
   fear of traps is how ugly-but-safe drafts happen, and every
   probe result gets recorded so the fear shrinks.

DOGFOODING.md is the full rulebook; `make idioms` FAILS the gate on
any NEW violation — the baseline lists sites, never counts, and no
tool path can add to it. Two honest exits: write the idiomatic
form, or annotate `// LICENSED I<n>: reason` AT the site. Debt is
zero; keep it there. A new idiom lands in DOGFOODING's registry AT
DISCOVERY **with its matcher** (or an UNRATCHETED reason — the tool
refuses a registry entry that has neither).

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
- A LAW never assembles PROSE: every refusal is a NAMED VOICE fn
  (its whole body the one `spoken`/`emit`), in a voices section at
  the file's tail or shared where features share words. Rule
  bodies read as guard + verb (I28; enums/check.av is the
  exemplar).
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
spec. The same discipline runs one level down: a PATTERN discovered
while writing (a beautiful form, a smell, a licensed exception) is
an IDIOM — it lands in DOGFOODING.md's registry at discovery, and
the greppable ones grow ratchet rules in tools/idioms.sh. The
registry is the idiom engine's spec, written by dogfooding.

## Rules

- `core/` is infrastructure only. Features never import features.
- Layering is one-way: core -> query -> grammar -> features -> language.
  `query/` is the memo kernel — infrastructure, language-agnostic.
  `grammar/` is the language-agnostic engine; `language/` is the
  driver and the ONE definition of Avra (feature order is branch
  order is the language).
- No string tags or string-matching to detect behavior.
- `_ ->` over our own enums is decided by COUNTING THE ANSWERING
  ARMS. One arm answers -> a PROJECTION, and the catch-all is
  honest: its contract pins the answer for variants that do not
  exist yet. TWO OR MORE answer -> a REGISTRY, and a catch-all there
  silently forgets the next variant (`let_name` dropped For's
  counter exactly so; `type_decl_name` would have swallowed the next
  type-declaring statement). Registries spell every arm — `or`-runs
  keep that affordable. Ratcheted as I22; the two licensed shapes
  are a feature matching its own variants (it cannot enumerate other
  features') and a loop that DELEGATES the rest to an exhaustive
  dispatch — both written at the site.
- THE EXEMPTION LAW, which the above is one instance of: a doctrine
  exemption that is not written AT THE SITE is an unbounded amnesty.
  Prose exemptions are invisible to tooling and to the next reader,
  so they rot into the default. Every licensed deviation carries
  `// LICENSED I<n>: <reason>` where the code is — that is what
  makes `make idioms` able to demand a decision instead of guessing
  which deviations were once approved.
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
- Grammar authoring: `@expect` attaches only at a sequence's (or a
  repeated group's) TAIL. A MID-sequence `@expect` fails the DSL
  parse of the WHOLE assembly, and the symptom points everywhere
  but home: every feature cascades "references undefined rule
  `expression`" / "builder never called" defects, and the offending
  fragment is never named. (Probed landing `if let`.)
- Grammar authoring: a STATEMENT ends at `END`, never at `BREAK` —
  `END` is the engine's terminal for "a BREAK consumed, or a `}`
  left for the body that opened it", and `@recover(sync_to:
  "END")` stops before that `}` too. That is what lets every body
  (`( s:stmt | BREAK )*`) take a one-line form (`for v in xs {
  out.push(v) }`) with no second grammar; a tail spelled BREAK
  would refuse the one-liner and, with a recovering floor, eat the
  brace (the trap that once forced `"{" BREAK` anchors).
- Grammar authoring: an `@expect` is a HOLE-HIT, not a break — a
  branch that reaches its @expect'd item stands as matched (with a
  hole), and later alternatives are never tried. So an alternative
  meant to catch what an earlier branch cannot must be tried FIRST,
  or the earlier branch must require a distinguishing prefix before
  its @expect'd tail (the map requires `key :` before its `}`, so a
  block can follow as the fallback; the empty map is its own
  branch). And the LINE LAW lives in the lexer: breaks are dropped
  directly inside `(`/`[` and after a continuing operator — a
  grammar never spells `BREAK?` for those.
- Grammar authoring: @recover converts a COMMITTED miss into a HIT
  (a hole, synced to END), and a hit ends the ordered choice, while
  a plain break only DEFERS it — later alternatives still try. So
  among branches sharing an anchor keyword, ONLY THE LAST may
  recover; the earlier ones fail as breaks so the anchor's floor can
  try. `let _`, `let x? … else` and `let x` all anchor on `let`:
  recovery lives on the plain `let` alone (a `@recover` on the `_`
  branch swallowed every let line — 352 tests). And a NAME-headed
  branch (assignment) must stay non-committing — recovery there
  swallows every expression line.
- Grammar authoring: a rule's GRAM TEXT and its BUILDERS are one
  unit — a builder named in feature A's grammar registers in
  feature A, never in a feature that might be absent (a partial
  assembly refuses on the dangling name; the let_stmt tests parse
  with three features only). The NODE may still be another
  feature's to give meaning: semantics_of decides ownership of
  MEANING, the gram decides ownership of PARSE.
- Grammar authoring: a KEYWORD ANCHOR merges before every
  NAME-HEADED branch, not merely before the spine's bare `ident`.
  `fns` contributes `primary = NAME "(" args ")"`, so with `fns`
  ahead of `if_expr` the parser read `if (c) { }` as a CALL to a fn
  named `if` and reported "expected BREAK" — `if`, `match` and
  `while` all lost their parenthesised condition, the habit every
  C-shaped language teaches. `fns` now merges after the anchors.
- Grammar authoring: an EXPRESSION-HEADED statement branch before
  the floor (`t:expression "=" …`) parses every expression
  statement TWICE and leaks the failed attempt's nodes into the
  arena (node counts double, orphan exprs go untyped). An optional
  TAIL belongs AT the floor — `v:expression ( "=" a:expression )?
  BREAK` — and the floor's builder picks the node (assignment
  landed so; the Assign node is built by expr_stmt, given meaning
  by mutation).
- Grammar authoring: expr_stmt is the stmt rule's FLOOR — its
  recovering expression-line branch merges LAST in language_features,
  and every statement feature lands BEFORE it (a keyword line like
  `type P = ...` otherwise parses as ident-then-failed-BREAK and the
  floor's @recover commits the hole, stealing the line).
- A feature never matches ANOTHER feature's variants — nor
  re-extracts its OWN literal's payload inline: all literal reads
  go through core's value protocol (`truth_of`, `text_of`,
  `elems_of`) — one projection per category a feature reads WITHOUT
  its own dispatch. Int has none: its only reader binds it in its
  own dispatch match, so the projection was dead; add one at the
  second reader. The protocol grows with value categories — a core
  event — never per feature. (N variants need N projections —
  payload types differ, and a unified return would be the parallel
  Value enum the doctrine refuses.) A protocol read is NEVER `?? <a
  plausible default>`: the dispatch guaranteed that payload, so
  absence is a DEFECT — `lower_defect(cx, e, ...)`, or the compiler
  ships a silently wrong program.
- The IR is a CURATED vocabulary, not a frozen one. Features lower
  into it and never grow it; growth is a CORE event with a
  protocol. NEVER refuse a variant that buys real performance —
  P4 outranks minimalism — but obey the protocol:
  1. JUSTIFY: a new control shape, a new value category, a new
     memory boundary, or a MACHINE SHAPE the backend can exploit
     and cannot reliably infer (`SwitchStart` -> a jump table).
     Not justified when an existing shape says it: value-producing
     runtime needs ride `CallRt`.
  2. GENERALIZE BEFORE ADDING — the rule that keeps the vocabulary
     from becoming a cluster. `SwitchStart` reuses `ArmEnd`/`RegionEnd`,
     so N-arm regions and 2-arm ifs are ONE mechanism in every
     consumer; it did NOT add SwitchArm/SwitchEnd. Prefer the
     variant that makes an existing concept more general over one
     that adds a parallel concept.
  3. PAY THE SIX CONSUMERS, which the compiler lists for you
     because each dispatch is exhaustive: `dst_of` (core/ir.av),
     `step` (interp), `memory_ins`, `body_lines` (ir_text),
     `emit_ins` (llvm), `give` (lower.av — does the runtime
     registry validate it) — plus a corpus program proving
     eval == native and the IR golden that shows the shape.
  4. THE GUARANTEE: those six matches carry no `_ ->`, so a new
     variant breaks all six at compile time. The vocabulary
     cannot grow half-way, and a variant nobody implements cannot
     ship. Keep them catch-all free.
  The backend and memory pass stay functions of the IR, dispatching
  on shapes, never on features.
- THE VOCABULARY SEAM RULE — which shape a new vocabulary takes,
  decided by ONE question: is the item DATA or BEHAVIOR?
  DATA (a runtime fn: name, param kinds, ownership) -> a REGISTRY
  ROW: `rt_sigs()` is one table and five consumers QUERY it;
  adding is one row plus one C body, nothing dispatches.
  BEHAVIOR (an instruction: five different per-pass meanings) ->
  the ENUM plus exhaustive dispatch, because the exhaustive match
  IS the registration — the build refuses until every consumer
  answers, which no hand-written registry can enforce. Give that
  seam discoverability (name the consumers at the definition
  site), a scaffold (`avra new ins`), and a keeper (`make vocab`).
  Per-instruction spec files were measured and REFUSED (ROADMAP);
  re-measure at ~40 instructions, do not re-argue.
- A feature is a directory: `mod.av` is the declarative manifest
  (component + tables), `builders.av` holds parse lowering,
  `semantics.av` holds its NodeSemantics impl (dispatch one-liners),
  and rule bodies live by concern — `check.av` for typing,
  `lower.av` for MEANING (lowering is the one semantics; the IR
  interpreter and the backend both consume it). Passes NEVER match feature nodes: `semantics_of`
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
  the bar. A corpus program prints its LAST expression only, and
  an interpolation hole prints scalars and strings only — a list
  is shown through `join`, an index or `length`.

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
  In a STRUCT FIELD's fn type, a GENERIC parameter (`fn(List<T>)
  -> …`) and a NULLABLE answer (`-> T?`) both refuse ("expected
  field name" at the `>`/`?`); a generic ANSWER (`-> Result<A, B>`)
  is fine. Wrap the parameter in a struct, answer a list.
- Multi-line fn signatures parse fine (probed) — stacked params with
  a trailing comma, or aligned continuation lines. Wrap wide ones.
- `ref`, `none`, `shape`, `dyn`, `table`, `is`, `bare`, `mod`, and `where` are reserved words
  (`dyn` refuses as a FIELD name: "expected field name" at the decl) — including
  as variable and method names; `then`, `given` and `spec` refuse
  as struct/enum FIELD names ("expected field name" at the field)
  and as LOCALS (the spec DSL's words are lexed even in ordinary
  code: "expected variable name" at the `let` — `spec` bit during
  the mono worklist; all three bit the test-DSL rung as fields).
- `.reverse()` mutates IN PLACE and returns the SAME aliased list
  (probed: the source list's order changes too) — never treat it as
  a copy; assume `.sort()` matches. A safe reversed copy stays
  hand-rolled.
- `contains`/`index_of` compare non-string elements by IDENTITY —
  enum/struct values in lists need a semantic `==` scan (enumerate +
  compare); only string elements get value equality. `==` between two
  LISTS is not value equality either — assert length + per-element.
- No `mut` parameters — but in-place-mutating helpers ARE
  expressible, because LISTS ALIAS: a helper takes `out: List<T>`,
  rebinds `mut inner = out`, and pushes; the caller sees it (probed —
  the non-mutating control traps on `xs[0]`, the mutating one does
  not). We do NOT use this: mutation invisible at the call site is
  worse than `out = concat(out, made())`, which the mut-local sites
  in memory.av and lower.av now spell. The shape is recorded because
  it also explains the TRAP: `mut x = thing.list` then `x.push(..)`
  mutates `thing`, so rewriting such a loop as `concat` silently
  drops the writes (two sites, LICENSED I3 at the code).
- An INDIRECT call (a fn-typed struct field or closure) takes at
  most THREE arguments: four ICEs at codegen ("indirect calls with
  4 args not yet supported"). A capability wanting more takes ONE
  struct instead — which reads better anyway.
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
  bind; use an explicit param there — and SELF-METHOD wrappers:
  `ids.any(self.rides(it))` ICEs at codegen (F1007 "cannot
  determine the type of lambda parameter `it`"); spell the scan.
- Present-bind (`let x ->`) in expression-position match loses its
  binding at codegen inside mono-SPECIALIZED bodies (fine in plain
  fns) — restructure to `if k == null { } else { k! }`.
- Matching `null`/`let x ->` directly on a nullable fn call's result
  can mistype — bind to an annotated `let v: T? =` first.
- A pattern's payload ARITY is NOT checked: `.A(_, _)` compiles
  against a three-payload variant and binds the wrong things,
  silently. Growing a node's payload therefore breaks NO site at
  compile time — `make idioms` (I25) is what enforces it.
- Or-patterns spell `or`, never `|`: `.A(_) or .B or .C(_) -> x` works
  (payload wildcards and unit variants alike; string literals too —
  probed); `.A | .B ->` does not parse. Bindings cannot ride an `or`
  arm — wildcards only.
- Struct destructuring in `let` (`let Sp { lo, hi } = s`) does not parse.
- A doc comment on a STRUCT FIELD does not parse ("expected field
  name") — enum VARIANTS take them fine. A doc comment BETWEEN a
  TRAIT's method sigs refuses too ("expected `type` or `fn` in
  trait body") — trait prose lives in the trait's own header. Field prose goes in the
  struct's own doc header.
- Comprehensions iterate lists only, not ranges (struct literals inside
  them are fine), and cannot destructure — `[.. for (i, m) in
  xs.enumerate()]` fails to parse; use a loop. The `if` FILTER takes
  a simple predicate only — `||` or `!` inside it fails to parse
  ("expected `]` after list"); use a loop there too.
- In a value match producing a list, put a populated arm FIRST — a
  leading `[] `arm pins `List<>` and the sibling arms then clash.
- A `map.get(k)` as a fn's TAIL (or `return`ed) never adopts a
  nullable STRUCT return (F1000 "returns `@pkg::T?`, but body
  produces `T?`" — qualified vs unqualified) — bind it under a
  typed let and return the name. Hit twice landing the DeclTable.
- A Python patch script that inserts before an anchor MUST NOT be
  re-run after a partial failure: the anchor is still there, and
  the insertion lands twice ("duplicate function" from bs2, with
  the fn defined ONCE per grep — grep -c, not -l, tells the truth).
- A list-typed fn TAIL from a bare enum-list literal or a `?? []`
  fallback never adopts the declared return (F1000 "body produces
  `List<>`") — bind it under a typed let and return the name.
- bs2 has NO `\$` escape (`"\$"` stays a backslash-dollar): a bs2
  test string that must CONTAIN `${` builds it by concatenation
  (`"a $" + "{x} b"`) — on BOTH sides of an assertion. (Avra
  itself escapes holes with `\$` — our lexer's rule, not bs2's.)
- `v!.field` inside a match ARM's expression fails to parse
  ("expected `}` after match arms") — the same read is fine in a
  plain fn body (`sig!.params` is everywhere). Hoist the projection
  into a named predicate and call it from the arm.
- `f(x)?.field` (Result-`?` then a field) is POISON: in plain code
  it refuses to parse ("expected `)` after arguments"), but inside
  a comprehension ELEMENT it parses and SILENTLY CORRUPTS the
  payload (garbage strings, null ids downstream — no error at all).
  Split it through a helper fn that `?`s first and projects second.
- Comprehensions DO carry `?` propagation — in the element AND the
  iterable (`[want(f(x), "…")? for x in as_list(v)?]` works,
  short-circuit included). The filter takes fn-call predicates,
  field access, `!= null`, and captured comparisons — hoist a
  complex predicate into a named fn instead of writing a loop.
- An early `return` of a GENERIC call's result (`return concat<T>(…)`)
  poisons the fn's TAIL type (F1000 qualified-vs-unqualified) —
  bind the call under a typed let and return the name.
- Method calls on a `const` string fail at codegen.
- Rebuild bs2 with `make build`, never `build-quick` — its freshness
  check can silently skip rebuilds and leave a stale binary.
  A bootstrap `make build` also plants ITS older `llvm_wrapper.o`
  with a fresh mtime — our Makefile reinstalls ours by content
  comparison, so run any `make` target here afterwards (a raw
  `./avra` right after a bootstrap rebuild links the stale wrapper:
  "Undefined symbols … _avra_llvm_add_case").
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
- `s.char_code(i)` SILENTLY IGNORES its index and answers index 0's
  code (`"hello".char_code(1)` is 104, `'h'`, not 101, `'e'`) — no
  error, just the wrong character. The runtime primitive takes the
  index (`avra_str_char_code(ptr, i64)`); the Avra method drops it.
  So indexed reads go through `s.substring(i, i + 1).char_code()`,
  which allocates a one-character string PER BYTE — what `code_at`
  spells, and why a scanner cannot read a character for free.
- A STRING's `.length` is `strlen` — O(length), EVERY time it is
  asked, so `while i < s.length` re-measures the whole string per
  iteration and the loop is quadratic. Hoist it (`let n = s.length`).
  A LIST's `.length` is a cheap field read; only strings bite.
  Ratcheted as I27; eight sites were found the day it was written,
  and fixing them took the front end from 6.8s to 1.6s at 8k lines.
- `is_empty()` is a LIST method only — on a string it ICEs at
  codegen ("string method `is_empty` not implemented"), so
  `s.length == 0` is the idiomatic emptiness test for text.
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
  through imports — constants cross modules only as fns. And a
  module-level `let` read from an `impl` METHOD crashes at runtime
  (23 specs crashed at once, no diagnostic) — the constant must stay
  a fn there, even for a hot per-name check.
- TYPES share one namespace per module across sibling files too: a
  `type Scope` in memory.av refused a second `Scope` in a new
  sibling file ("no field `fns` on type Scope" — the OTHER struct's
  fields). Grep the module for the name before declaring a type.
- A multi-line `use a.{x,\n  y}` statement: any tool that reads
  imports line by line sees `use a.{x,` — a truncated statement —
  and a consumer that scans "to the closing brace" then EATS the
  code after it (the split's headers lost fn heads this way).
  Join continuation lines first, or write imports on one line.
- An idempotent patch script checks `new in s` BEFORE `old in s`:
  when the new text CONTAINS the old (an `export` prefix, a doc
  comment), a re-run applies it twice (the doubled `export ///`
  parse error) — the same double-insert trap in a second costume.
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
  (with `_` arm), list comprehensions `[x for x in xs if p]` —
  including method-call elements (`self.expr_fingerprint(k)`),
  closure-field-call elements (`cx.value_at(k)`), and nested list
  literals as elements (`flatten([[a, b] for p in ps])`), pipe
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
- A RECURSIVE struct works (`type T = { args: List<T>, ... }`),
  built and walked by a recursive fn (probed).
- `.last()!` ALIASES the element, like indexing does: mutating
  through it changes the list (proved by converting the
  interpreter's frame reads — every register write still lands, and
  the corpus agrees eval == native).
- An early `return` inside a `while` scan works, including a method
  call on an indexed element (`maps[k].get(name)`) — probed; the
  #1377 ICE needs a CLOSURE-CAPTURED receiver, not any receiver. A
  reverse scan therefore stops at its hit instead of folding a flag.
- Zero-arg closures (`() -> expr`) work, as params and calls, and
  MUTATE captured locals correctly — bracket fns taking a `fn()`
  thunk (push/run/pop) are expressible (probed). BLOCK-bodied
  thunk arguments (`() -> { ... }`) capturing locals and returning
  single-field structs also work (probed — presence_region's shape).
- A match arm producing a bare struct literal unifies fine with a
  nullable sibling arm (probed: `.P(i) -> Reg { index: i }` beside
  `.D(s) -> maybe_reg(s)` under a `Reg?` return) — no typed-let
  pin needed. Pin ONLY where a documented trap requires it; when
  tempted to pin defensively, probe first.
- THE CLOSURE-FIELD-CALL DISCIPLINE (one rule, three traps): a
  fn-typed struct field's call result is consumed ONLY through an
  ANNOTATED let. (1) A match directly on it SKIPS exhaustiveness
  checking and ABORTS at runtime on an unlisted variant
  ("unmatched tag N — probable use-after-free"); the annotated
  bind restores the check (an untyped let does NOT). (2) `?`
  directly on it can corrupt. (3) A LAMBDA (capturing or not)
  returning a generic enum with a SCALAR payload through a fn
  field corrupts its answers at the call site (same unmatched-tag
  symptom) — register NAMED fns for Result-returning fields;
  pointer payloads (Captured) survive, pinned by the suite.
  Method calls, free-fn calls, and index subjects are all checked
  and `?` correctly (probed) — `?` works on method results, in
  argument position, and after the annotated bind.
- A METHOD call on a closure-captured local inside a loop that also
  contains an early `return` ICEs at codegen ("Referring to an
  instruction in another function", #1377) — any struct, any loop.
  Use a free fn taking the struct first.
- A GENERIC fn IMPORTED into a metadata-compiled TEST unit that
  WRITES through a list it was handed (`copy_into<T>`: `mut d = dst;
  d.set(i, v)`) loses its writes for EVERY instantiation as soon as
  that unit instantiates it at TWO element types (probed: strings
  alone alias; add an `int` instantiation to the same spec file and
  the string cases fail too; a standalone `bs2 run` aliases in all
  shapes) — and the UNIT is a hashed SHARD of several test files,
  not one file, so which specs share it is nobody's choice: the same
  spec passed in one file name and failed in another. Product code
  is unaffected (the fold's `absorb` runs `copy_into` at seven
  element types; typing_test's totality and the corpus prove it). A
  list-writing generic therefore has NO unit test — its proof is the
  product path, and that is written at the site.
- TEST code that READS a struct from ANOTHER PACKAGE through a
  field chain (`d.suggestions[0].edits[0]` — @std.errors' types)
  dies at codegen in some shards ("unknown struct
  `@std::errors::Suggestion`"), never in others. The product
  library projects it (`suggested(d)` -> strings); tests read that.
- TYPED IDS ARE INTERCHANGEABLE TO bs2: `DeclId`, `StmtId`, `ExprId`
  and `PatId` are all `{ index: int }`, and a call passing one where
  another is declared COMPILES. It surfaced as "index 1290 out of
  bounds (length 265)" deep in a whole-package check (a DeclId
  handed to a StmtId verb — fine in a lone file whose decl count is
  small, a crash once the package's table grew). Two rules: a verb
  that only needs a LOCATION takes the ExprId of the site that
  asked, never a declaration's stmt; and when a trap names an index
  far past the table, suspect a different id family before a
  missing bound.
- A CONSTRUCTION with the wrong payload count is not checked either:
  a test building `Stmt.EnumDecl(name, tparams, [param])` after
  the variant's payload became a `List<Variant>` compiled, corrupted
  memory, and SIGSEGV'd a DIFFERENT spec in the shard (the blame
  landed three specs away). When a node's payload changes shape,
  grep the tests for every constructor of it before trusting a
  crash's location.
- THE IR's BOOL LAW (ours, enforced by the evaluator): `&&`/`||`
  are never `Bin` over bool registers — they are lazy regions
  (`IfStart … ArmEnd … RegionEnd`); a `Bin(Or)` on bools is the
  defect "a non-equality op reached bool operands". And THE MINT
  LAW: a register is DEFINED in the order it was minted — mint
  operands first (`let tag = tag_of(cx, v)` before minting the
  constant it compares to), the answer last.
- A NESTED pattern with a sibling BINDING refuses to parse
  (`.Value(.Str(s), k) ->` fails at `k`; `.Value(.Str(s), _)` is
  fine) — bind the outer payload and match again. Enum variant
  payloads must be NAMED in declarations (`Str(s: string)`);
  construction and patterns stay positional.
- `split` DROPS a trailing empty segment (`"a.".split(".")` is one
  element) but keeps a leading one; `"".split(".")` is `[]`.
- Struct literals refuse only in FREE-FN argument lists — method
  and enum-constructor arguments take them (probed landing the
  TOML reader); the `let` pin is for free calls.
- An idiom-tool caveat with a house rule: the I25 payload-count
  check reads ONE VARIANT PER LINE — a one-line enum
  (`enum S { A(x: int), B }`) is invisible to it and every pattern
  over it reports a wrong count. Enums are written one variant per
  line, always.
- bs2's test runner runs a MULTI-UNIT shard on WORKER THREADS whose
  stack holds 600–700 nested interpreter calls (each interpreted
  call is two native frames), while a SINGLE-unit run rides the
  main thread (1900+) — so a deep-recursion spec passes alone
  (`bs2 test one_file.av`) and crashes its shard under `make test`,
  "cause not classified", and the crash report
  (~/Library/Logs/DiagnosticReports, `EXC_BAD_ACCESS … stack guard
  region`) is the only witness. The interpreter's `call_limit`
  (400) is what keeps a runaway a trap; measure, never guess, when
  it moves.
- Three concurrent `make test` runs (each spawns eight compiler
  shards) crashed the machine; builds are serial — never let two
  agents build at once.
