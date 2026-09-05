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
Toolchain: the compiler builds itself — `./avra` runs `build/avra`,
and a cold tree bootstraps from `bootstrap/seed.ll` (`make bootstrap`;
README.md).

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
  than once, or the subset REQUIRES a pin (a `dyn` value selected
  among arms, a Result-answering lambda — "The subset today" names
  each). Empty literals (`[]`, `{}`) infer inline in
  constructor fields — never bind them to a throwaway name. When a
  pin seems needed, probe before assuming.
- A state struct's impl is its VOCABULARY: the small verbs that
  read or write its tables (`speak`, `bind`, `mint`, `give`) live
  as methods, so drivers read as prose. The free state fns the
  bootstrap habit left (`eval_node(ev, cx, e)`, the interpreter's
  `put(m, …)`, the backend's `define(em, …)`) are methods now — ours
  has no #1377 (probed); new code writes the method.
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
- A fact EVERY BODY MAY READ is answered from the PROGRAM — the
  store — never from a pass's fact tables. Fact tables are per
  declaration, over that declaration's expression range alone, so an
  answer computed from `facts` is right in the body that recorded it
  and WRONG everywhere else (a const's declared `int?` read back as
  `int` across a fn floor, and `??` warned it would never fire).
  The store holds what the program wrote; that is what shared
  answers are made of.
- A law that HOLDS A BINDING TO ITS ANNOTATION compares the value to
  the DECLARED type it computed, never to the binding's own type —
  asking the binding for its type compares the value against itself,
  and the law silently stops refusing anything.
- Ask a BINDING, never a NAME, whether it is a const/a capture/a
  seat. A name may be defined twice (a `let` shadowing a const), so
  a name-keyed question and the binding in hand answer about
  DIFFERENT statements — the mismatch reads a slot nobody wrote
  ("index -1"). One question, asked of the statement. And a
  name-keyed table holds what it holds: `resolve_assign` asked
  `binding_of(name)`, a LOCALS table, so a fn's name walked
  through as a place — the walk had already recorded the root's
  binding; ask that.
- A READ WEARS THE TYPE OF WHAT IS READ, never the type of the node
  doing the reading. This bit THREE times in one slice: a captured
  callee took the CALL's type (a call's type is its answer, never its
  callee's), a capture took the LAMBDA's type (a lambda is a managed
  box, so an `int` capture looked managed and the memory pass
  retained a number), and a field read took the field expression's
  type where the SUBJECT's decides the layout. A register's recorded
  type is the wrong witness under mono, where it may still name a
  type parameter; the STATIC type of the thing being read is right.
- UNIFY BINDS, `accepts` RECORDS. `unify` agrees two types and pins a
  declaration's Vars; it does NOT record the lift that lowering
  mints. A seat that unifies and returns without passing through the
  agreement door silently drops the widen — invisible for as long as
  the widen happens to be identity, and a wrong answer the day the
  representation changes. The door is ONE verb, `agreed` (checks.av),
  and the three unified seats — a call argument, a struct field, an
  enum payload — call it; the payload once short-circuited and
  refused a `dyn` box and an auto-Ok its siblings took
  (corpus/seats.av holds the proof).
- EVERY POINTER AVRA HOLDS CARRIES A HEADER. The runtime counts
  references in sixteen bytes BEFORE each payload (tag, kind, rc,
  and a record's size class or a string's length),
  and `avra_rc_retain/release` read that header — so a managed
  value that came from anywhere else reads memory that is not ours.
  The sources are all headered: the backend's string constants
  (`avra_llvm_build_global_string_ptr`, kind STATIC, immortal),
  the runtime's own words (`bool_text`, "null"), argv and the
  environment (`str_static`). A new C fn that answers TEXT to a
  program allocates it with `box_alloc`/`str_owned`, or
  `str_static` when the program must never own it — never a bare
  `malloc` or a C literal. The tag is the belt (`hdr` refuses a
  header without it, and an unaligned or sub-image address before
  reading anything); the law is the braces.
- A CELL WEARS ITS BINDING'S DECLARED TYPE, never its first value's,
  and A STORE SETTLES BY THE CELL'S TYPE, never the value's. `mut x:
  T? = null` seeded a cell in the null's own type (the widen from
  null into a boxed nullable is identity, so no register ever wore
  `T?`), the memory pass saw no managed cell to settle, and whatever
  the cell held at the scope's end leaked — every `farthest` fold in
  the executor kept its last far record, 600 MB of a self-check —
  while `x = null` released nothing. The runtime's accounting found
  both; a flat struct's nullable hid them (that widen mints a box).
- A CLOSURE STORED IN A VALUE THAT CAPTURES THE VALUE'S OWNER IS A
  CYCLE, and counting never frees a cycle. The workspace's query
  verifiers, its declaration table's hooks and every Analysis in its
  table capture the workspace: no workspace could die, and 1674 spec
  cases kept 1674 of them — 922 MB in the test binary. A ONE-SHOT
  workspace ends its own cycles (`disarmed`, at `Language.analyze`)
  once the analysis it was made for has run: nothing re-verifies at
  revision one, every sig it will ask for is held, and an Analysis
  asked after is remade over the memoized parts, never kept. The
  language's answer is in the sugar backlog: weak captures.
- A RETAIN THE CALLEE RELEASES MUST BE EMITTED: callee-cleans means
  every managed seat of a call is retained by the caller, and a
  seat typed as unmanaged (`Ptr`, `Int`) is a release with no
  retain — under the registry a silent leak of nothing, under the
  header a write into freed memory. `AVRA_RC_GUARD=1` names it as
  "released an already-dead box"; the capture lane read as `Ptr`
  was one (`callee_binding`), and a mut fn CELL loaded at the
  call's answer type was its twin (the box read as `i64`, LLVM
  refused). The fourth and fifth instances of A READ WEARS THE
  TYPE OF WHAT IS READ: a capture wears the CAPTURED binding's
  type, seated by typing (`TypeFacts.captures`), a cell's load the
  DEFINITION's (`def_type_of`) — at every read that MINTS, which
  in `callee_binding` is exactly those two.
- A PROCESS STATUS IS A VERDICT, never a count: statuses are eight
  bits, so 256 failures read as success. Exit 0 or 1 and print the
  count. A TRAP is not a verdict either — `avra_trap` exits 2, so a
  wreck can never be mistaken for a disagreement. And A COMMAND IS
  AN ARGV, never a shell line: `avra_spawn_status(prog, args)` runs
  a program with its words, so no character in a path or a
  manifest's `[link]` row means anything but itself — nothing
  quotes, nothing fences, and a dependency's flag cannot run.
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
- Grammar authoring: EVERY COMMA LIST TAKES A TRAILING COMMA — a
  repeated `( "," x )*` ends `","?` before its closer, in every
  rule (params, type params and args, payload declarations, lambda
  params, fn types, literals, `use` lists). A list that refuses the
  comma is a grammar defect, not a style.
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
  3. PAY THE EIGHT CONSUMERS, which the compiler lists for you
     because each dispatch is exhaustive: `dst_of`, `body_symbol`
     and `hosted_symbol` (core/ir.av), `step` (interp),
     `memory_ins`, `body_lines` (ir_text), `emit_ins` (llvm),
     `give` (features/facts.av — does the runtime registry
     validate it) — plus a corpus program proving eval == native
     and the IR golden that shows the shape.
  4. THE GUARANTEE: those eight matches carry no `_ ->`, so a new
     variant breaks all eight at compile time. The vocabulary
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
- THE EMISSION VOCABULARY (features/emit.av): a feature's lowering
  emits its own VALUE shape and SPEAKS every control shape —
  `open_region`/`arm_end`/`close_region`, `loop_start`/`loop_cond`/
  `loop_end`, the walk (`opened`/`counted`/`turn_*`), the cells,
  `const_int`/`const_bool`, `measured_reg`/`measure_of` — never a
  raw `cx.emit(Ins.IfStart…)` or `Ins.LoopStart`. Two engines read
  one instruction stream by construction; I33 ratchets it, and the
  vocabulary grows with the next shared shape.
- THE IR's BOOL LAW (ours, enforced by the evaluator): `&&`/`||`
  are never `Bin` over bool registers — they are lazy regions
  (`IfStart … ArmEnd … RegionEnd`); a `Bin(Or)` on bools is the
  defect "a non-equality op reached bool operands". And THE MINT
  LAW: a register is DEFINED in the order it was minted — mint
  operands first (`let tag = tag_of(cx, v)` before minting the
  constant it compares to), the answer last.
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
  statement and expression spines share ONE context per pass
  (`type_stmt(mut cx: TypeCx, s)`): the context IS the pass's
  state, and the walk's verbs are its methods, written where the
  walk lives (language/typing.av's `impl TypeCx`).
- Keywords are never listed by hand: they derive from the assembled
  grammar's identifier-shaped literals (`Grammar.keywords()`) — a
  feature's gram fragment IS its keyword claim.
  A feature owning a STATEMENT kind also impls `StmtSemantics`
  (`stmt.av` or `semantics.av`) and joins `stmt_semantics_of` — the
  drivers' one statement loop reaches it there.
  Start a feature with `avra new feature <name>`; prove it with a
  corpus pair (`corpus/<name>.av` + `.expected`). `make gate` is
  the bar. A corpus program shows its FINAL statement's expression
  only, and only when that statement IS an expression, and
  an interpolation hole prints scalars and strings only — a list
  is shown through `join`, an index or `length`.

- The CLI: each subcommand is ONE file in
  `packages/cli/src/commands/`, exporting
  `<name>_command() -> Subcommand`; `cli/src/main.av` only composes
  the list. A new command is a new file plus one line. A command
  that takes a program is `phased(args, "<phase>", act)`
  (commands/phase.av): the act is a NAMED fn answering
  `Result<int, string>` — its exit code, or the report `phased`
  prints as exit 1 — and says only what its phase does.
- A BORROW ALIASES, A PATH WRITE THROUGH A SHARED INTERMEDIATE
  COPIES. `mut xs = a.b.list; xs.push(v)` writes through every
  holder of `a.b`; `a.b.list.push(v)` opens `a.b` unique and COPIES
  it when another reference holds it, so the push lands in a copy
  the other holder never sees (the lowering's worklist lost every
  lift so, `toml$l1040` undeclared). A receiver's direct field and a
  method call on a nested path write through; only a VOCABULARY
  write (`push`, `set`, `pop`) on a nested struct copies. Converting
  a borrow to a path write is a change of meaning exactly where the
  intermediate is shared: make it unique (a value built in place and
  handed back — the worklist per body) or keep the borrow and name
  the sharing. Probed 2026-09-05, both engines agree.
- THE CONDITION RUNS EVERY TURN: the memory pass settles what a
  `while` condition mints at each `LoopCond`, inside the loop. A
  release placed after the loop settles one turn's debts for all of
  them: every other turn's owned load leaked, and holding a
  reference it turned every write in the body into a copy — `while
  self.cells.length <= at { self.cells.push(v) }` cost 9 s and 17.5
  GB for 60k pushes, 0.26 s and 1.6 MB fixed; the gate's peak fell
  3.4 GB -> 1.9 GB. A loop region opens a scope for its condition;
  lower_test pins the placement.

## Vendored code — do not imitate

`packages/std-cli/` is a symlink into the old tree's bootstrap CLI,
rent paid until lane B's `@std/cli` lands and the package is
deleted. It is NOT reference code for anything. (`spec_test` is
gone: `avra test` is the runner.)

## The subset today

What our compiler REFUSES that the language will want. Each entry
is a sugar-backlog candidate, not a trap to write around: write the
form the compiler's help names, and when a site wants the missing
form, add the ask to the ROADMAP's sugar backlog naming the site.
Every entry was probed with `./avra check` on a scratch file and
quotes the refusal, so a re-probe is cheap; an entry the compiler
starts accepting is deleted. Laws that SPEAK are not listed —
reserved words (F3002 names the word and its status), a mutating
method on a non-`mut` binding (F2034), a lambda assigning to a
capture (F3005: captures are copies), a fn body reading a top-level
`let` (F3020: the const law), an extra method inside an `impl Trait
for` (F2032), a duplicate name across a module's files (F3017 names
both files), a pattern or construction with the wrong payload count
(F2015), a `DeclId` handed to a `StmtId` seat (F2000) — the
compiler's help is the note.

Syntax the grammar lacks:
- Struct destructuring in `let` (`let Sp { lo, hi } = s`):
  "expected `=` while parsing `stmt`".
- `|` between or-pattern alternatives: "expected `}` to close the
  `match`" — the spelling is `or`. A BINDING across alternatives
  (`.A(n) or .B(n) -> n`): F2039 "an `or` arm binds nothing — its
  alternatives take wildcards only".
- Destructuring `enumerate()` in a comprehension (`[i for (i, m)
  in xs.enumerate()]`): F2005 "`enumerate` pairs only under a paired
  `for` head — pairs as values arrive with tuples". The head IS the
  `for` statement's: `[f(i, x) for i, x in xs]` pairs, `[f(i) for i
  in lo..hi]` counts.
- Type aliases and newtypes (`type Id = int`): "expected `{` while
  parsing `stmt`". Typed ids are single-field structs (`{ index:
  int }`), which the checker keeps apart.
- A `table` literal without its row type (`table { … }` under a
  typed let): "expected BREAK while parsing `stmt`" — `table<Row>
  { … }` is the form.
- The pipe `|>`: "expected BREAK while parsing `stmt`".
- `@comptime`: refuses at the `@` ("expected `mod`, `use`, … while
  parsing `stmt`").
- A `mut` seat in a fn TYPE (`fn(mut Cx, Seat) -> int`): "expected
  `)` while parsing `stmt`" — a verb cannot yet take a body that
  writes through the context it is handed (lists/walks.av's seven
  seat preambles wait on it).
- The bare component form (`Cfg d { depth = 8 }`): "expected BREAK
  while parsing `stmt`" — `component Cfg d { … }` is the form.
  Instantiation is a STATEMENT: as a fn's tail it answers `void`
  ("the body answers `void` but `made` declares `Cfg`") — bind,
  then return the name.
- A PRESENT-BIND arm after a COMMA-ended arm (`null -> a,` then `v?
  -> b`): "expected `}` to close the `match`" — the comma continues
  the line and `v?` is read into it. Separate such arms by line, as
  the corpus does; variant and literal arms take the comma.
- A match arm whose body is an EMPTY BLOCK (`1 -> {}` in statement
  position): `{}` is an empty map — F2013 "a `match`'s arms
  disagree: `void` vs the first arm's `{}`".
- `?` then a field on a Result (`get(i)?.name`): lexes as `?.` —
  F2023 "`?.` reaches into a nullable, this is `Result<P, E>`".
  `(get(i)?).name` says it, in a comprehension element too.
- `export let` / `export const`: F3014 "`export` marks a fn, type,
  enum or trait — not this statement" — a constant crosses modules
  as a fn.

Wants the typer does not carry yet:
- A GENERIC struct literal's field seat UNIFIES instead of planting a
  want, so a no-argument generic call written there still needs its
  pin (`MatchContext { absent: captured_absent<N>(), … }` inside a
  generic fn): F2000 "`N` is not pinned by the arguments". Every
  other seat pins it.
- A LAMBDA in a FIELD or ARGUMENT seat does not read the seat's
  answer: `Cx { get: (n: int) -> .Ok(n) }` under `fn(int) ->
  Result<int, E>` is F2043 "`.Ok` needs a known enum — nothing here
  says which". Under a TYPED LET the body hears the answer (bare
  variants, a free Var, a `dyn` box all read it); a NAMED fn in the
  seat works everywhere, `?` on the field's call included.
- A `dyn` want does not reach into arms or branches: `match k { 0
  -> P { … }, _ -> Q { … } }` under `-> dyn Show`: F2013 "a
  `match`'s arms disagree: `Q` vs the first arm's `P`"; the `if`
  twin: F2000 "an `if`'s branches disagree: `P` vs `Q`". Box each
  under `let x: dyn Show = …` and select among the lets.
- A trait impl over a GENERIC type (`impl Show for Box<T>`): F2031
  "`P` is generic — a trait impl over a generic type is recorded,
  not landed". Inherent generic impls (`impl Box<T>`) land.
- Variant arms on a NULLABLE enum (`match k { .A -> …, null -> …
  }` over `K?`): F2013 "`match` chooses over an enum, found `K?`"
  — unwrap first (a `k?` arm), then match variants.
- A generic impl's body naming its own `T` in a local annotation
  (`let held: T? = self.rows[i]`): F2001 "`T` names no type".
  Leave that local un-annotated; a field read or `with` on a
  generic method's answer needs no bind at all.
- `it` through a self-method wrapper (`xs.any(self.rides(it))`):
  F2033 "`it` has no element here — this seat takes `int`, not a
  fn" — `it` binds to the NEAREST call; write `(k) ->
  self.rides(k)`. `it is .A` binds fine.
- `==` between lists, `contains`/`index_of` over structs or enums:
  F2000 "`==` compares scalars for now"; F2005 "`contains` scans by
  value — scalars and text for now, this list holds `K`" — spell
  the scan (`xs.any(same(it))`).

Methods the runtime lacks (F2030 "`.reverse(…)` calls a method, and
`List<int>` has none" — the others read alike — or the map's F2000):
- `List.reverse()` / `sort()` — core's `reversed` is the helper
  (and a copy: nothing here mutates in place).
- `List.find_index(pred)` — builders.av's `attach` is LICENSED I4
  for it.
- `m["k"]` on a map: F2000 "`[...]` indexes a `List`, found
  `Map<string, int>`" — `.get(k)`, which answers `T?`.
- A `List<T>` never adopts a `List<T?>` want: `let tys: List<TypeRef?>
  = [t for t in refs]` is F2024 "`tys` declares `List<TypeRef?>`,
  this is `List<TypeRef>`" — the element's nullable is not widened
  through the list. Align by span, or build the nullable list
  directly.

Runtime facts, ours to ratify:
- A STRING's `.length` is a LOAD — the header carries the length
  (lane A), as a list's does; `while i < s.length` costs a load per
  turn, and I27 retired with the strlen it ratcheted.
- `split` DROPS a trailing empty segment and keeps a leading one:
  `"a.".split(".")` is one element, `".a".split(".")` two,
  `"".split(".")` is `[]`.
- `avra run` INTERPRETS, and recursion past 400 calls traps
  ("recursion too deep — 400 nested calls", exit 1); `avra test`
  and `avra build` are native and have no such floor (5000 deep
  runs). The limit is what keeps a runaway a trap; measure, never
  guess, when it moves.

## Working discipline

- ONE HEAVY PROCESS AT A TIME, in the FOREGROUND, under the
  watchdog: `sh tools/watch.sh 4000 make gate`. The machine is
  shared with a loaded desktop and has panicked twice under this
  tree — three concurrent `make test` runs once, and a background
  gate with other compiler runs beside it (a WindowServer watchdog
  panic). A gate is ~2.4 GB for a minute; nothing else heavy runs
  beside it, no gate runs in the background, and every suite, gate
  or whole-package check runs through the watchdog, which holds the
  machine-wide lock, kills the tree past its cap and prints the
  peak. `./avra` takes that lock ITSELF for any package-scale run
  (an argument that is a directory), and a step does not start
  under a 20% memory floor — so NOTHING runs `build/avra` directly,
  and a PROFILE runs under the lock too: `AVRA_SAMPLE=12 sh
  tools/watch.sh 4000 ./avra test packages/std-avrac` (the file at
  AVRA_SAMPLE_FILE), and a MEMORY question is answered by the
  runtime's accounting, `AVRA_MEM_STATS=1 ./avra check <pkg>`: live
  bytes by category, by list capacity, and by the allocation site
  that made them (`atos -o build/avra <addr>` names it; under
  AVRA_RC_GUARD it replays a leaked box's life — AVRA_MEM_SITE aims
  it at one site, AVRA_MEM_SITES widens the list). PROFILE, DON'T
  REASON holds for memory too: the first hoard it named was a
  refcount leak no reading had found. The second panic (2026-09-05) was exactly a
  bypass: `build/avra test` launched in the background to be
  sampled, beside two lanes' gated steps. `AVRA_RC_GUARD=1` only on
  small programs: its log is bounded but a guarded compiler run
  over a package is still a machine's worth. Scratch probes
  (`./avra check` of one file) are sub-second and need no lock.
- A PATCH SCRIPT that inserts before an anchor, or replaces `old`
  with `new` where `new` CONTAINS `old` (an `export` prefix, a doc
  comment), applies TWICE when re-run after a partial failure: the
  anchor is still there. Check for the new text FIRST, and let
  `grep -c` (never `-l`) say how many times a fn is defined.
- A TOOL that reads source line by line sees a multi-line `use
  a.{x,\n  y}` as a truncated statement, and one that scans "to the
  closing brace" then eats the code after it. Join continuation
  lines first; write an import on one line where it fits.
- A SYNTAX CHANGE TO THE COMPILER'S OWN SOURCE runs in one order:
  write the new grammar in the OLD spelling, SAVE the standing
  binary aside (`cp build/avra build/avra.pre`), build the product
  with it, rewrite the tree by script, build again with the
  product, gate. The product refuses the old form, so a broken
  product leaves no compiler — the saved copy is the way back. And
  the script must never cross a SYMLINK into another tree
  (`packages/std-cli` was one, into bs2's source, and the rewrite
  changed bs2's file; it is a real file now).
