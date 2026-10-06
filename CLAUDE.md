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
2. Building head-plus-tail? `concat` (a list METHOD) / `flatten`
   (core's FREE fn — `flatten(xs)`, never `xs.flatten()`), never
   push-ceremony.
3. Is a projection being spelled twice? The second spelling names a
   verb (`cx.int_at`, `expr_fps`) or uses the existing one.
4. Does absence read straight? (`?? `, `?.`, if-null early return —
   never a two-arm null match without payload logic on both arms.)
5. Scanning for one element? `find`/`any`/`index_of`, not a flag
   loop.
6. Unsure a shape compiles in the subset? PROBE in scratch first —
   fear of traps is how ugly-but-safe drafts happen, and every
   probe result gets recorded so the fear shrinks.

DOGFOODING.md is the full rulebook; `avra check --baseline
tools/idioms.baseline` FAILS on any NEW site — the baseline lists
sites, never counts, and no tool path can add to it (`make idioms`
runs every package, `make idioms-accept` prunes what a fix made
gone). Every idiom the language can state is a `rule` declaration,
found by `avra check` itself, and the gate counts a RULE's finding
only — `type.alias_copy` wears the same `warning[kind]` shape and is
the compiler's own law, never a rule, so the gate reads the rule
table (`avra rules --json`), never a kind-string shape. Accepted
debt lives in the baseline alone, reviewed at adoption and every
time after. A new idiom lands in DOGFOODING's registry AT DISCOVERY,
named by its rule — `<module>.<rule>`, never a number.

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
  `put(m, …)`, the backend's `define(em, …)`) are methods now, and
  so are the pass contexts' whole vocabularies (`cx.accepts(e,
  want)`, `cx.open_region(c)`, `ws.sig(d)` — 320 verbs, one sweep);
  style.free_state_verb refuses a new free verb in the pass's own files. A PASS ENTRY
  POINT (`lower(a: Analysis)`, `memory(l: Lowered)`) keeps the one
  standard signature and is not a verb.
- A long fn splits at its PHASE boundaries into named helpers, each
  with a one-line contract (`match_seq` matches, `built` builds —
  grammar/executor.av; `window` frames, `severity_word` branches —
  diagnostics/render.av). If a fn needs a paragraph comment
  mid-body, that paragraph is a helper's name.
- A LAW never assembles PROSE: every refusal is a NAMED VOICE fn
  (its whole body the one `spoken`/`emit`), in a voices section at
  the file's tail or shared where features share words. Rule
  bodies read as guard + verb (rule.compiler.refusal_assembled;
  enums/check.av is the exemplar).
  AND A VOICE STATES THE LAW, NOT THE SYMPTOM. "a pointer's only
  constant is null" is the rule; "both engines read it as null" was
  the observation that happened to hold the day it was written. A
  symptom-worded refusal goes STALE the moment the mechanism moves,
  and until then it reads as a workaround for a quirk rather than a
  rule to obey — so it teaches the reader to look for the quirk. The
  law's wording outlives its own implementation, which is what makes
  it worth pinning in the golden (lower.av's pointer-constant guard).
- A BUILDER'S WORDS ARE ITS CLAIM. A builder's refusal is carried
  WHOLE into its diagnostic (grammar/executor.av's build phase:
  `cause: Cause.Builder, message: m`), so a message that is a LAW
  the writer broke reads as the law, and one that is a DEFECT says
  so in its own words. A blanket "builder failed:" prefix once told
  the reader the compiler had broken about every law — five of the
  seven refusals sampled at c7b5038 — while `Cause` had separated
  `Builder` from `Defect` all along: the seam was right and only the
  WORDING lied. THE GENERAL SHAPE: A PARAPHRASE OF A FLAG IS A
  SECOND COPY, and the reader believes the words — the flag is
  checked by the code, the prose by nobody. So the WORDS carry the
  CLAIM and the STRUCTURE carries the CATEGORY (`Cause.Builder`
  projects to F0102, compiler/codes.av), and the words never restate
  the category.
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
the greppable ones become `rule` declarations `avra check` finds
directly (compiler/idioms.av, or a feature's own idioms.av). The
registry is the idiom engine's spec, written by dogfooding.

## Rules

- `core/` is infrastructure only. Features never import features.
- Layering is one-way: core -> grammar -> features -> compiler, all
  over `@std/relation`, whose `engine/` is the memo kernel —
  infrastructure, language-agnostic, the one a running program asks too.
  `grammar/` is the language-agnostic engine; `compiler/` is the
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
  keep that affordable. Ratcheted as style.registry_catchall AND held by the compiler:
  F2040 counts the ANSWERING ARMS over the declared enum and names
  the variants a hole would forget. The license is a SPELLING, not a
  comment — `rest ->` says the remainder is deliberate, and both the
  compiler and the ratchet read it. The two licensed shapes are a
  feature matching its own variants (it cannot enumerate other
  features') and a loop that DELEGATES the rest to an exhaustive
  dispatch — each writes `rest ->` at the site.
  AND THE LAW IS ABOUT THE TEST, NOT THE MATCH. For a REGISTRY enum
  `is .Variant` IS A CATCH-ALL IN DIFFERENT CLOTHES: a boolean that
  asks about ONE variant and falls through for the rest discharges
  the registry's obligation no better than `_ ->`, and it is harder
  to see. For a PROJECTION enum it stays the right idiom. Two
  `RtKind` consumers were written that way (`rt_arg`, `answers_word`
  in llvm.av), correct only while the enum had three variants —
  widening it to carry C's integer widths would have sent an Avra
  `int` into an `i32` seat with no truncation, compiling clean. Both
  are exhaustive matches now.
  ENFORCEMENT SPLITS FROM THE LAW HERE, deliberately: no grep tells a
  registry enum from a projection one, so this gets NO ratchet rule.
  The keeper is `make vocab`, a CURATED table naming each registry's
  consumers and refusing BOTH shapes inside them — the table says
  which registries it holds, and a registry it does not name is
  unguarded. Naming the next one IS how this law is enforced.
  AND THE OBLIGATION CROSSES INTO C, where no keeper can follow. The
  runtime's `acc_kind_of` was a kind-keyed ternary falling through to
  ACC_RECORD — correct for the three kinds that existed when it was
  written and wrong from that same day for `KIND_STATIC`, so every
  immortal string was filed as a RECORD by `AVRA_MEM_STATS`: the
  instrument THIS FILE names as the way to answer a memory question,
  miscounting its own data since birth. A C chain keyed on our kinds
  carries a registry's obligation and `make vocab` cannot see it, so
  spell the kinds there too.
  AND THE REASON IT HID GENERALIZES: `RtKind` had three variants from
  the day it was written and had not yet grown — it carries six now
  — so nothing ever tested the assumption. A KEEPER THAT HAS ONLY
  EVER GUARDED A STATIC ENUM IS UNTESTED — the first widening is its
  first real test, and that is the worst moment to learn it was only
  ever looking for one shape.
  AND THE OBLIGATION CROSSES A PACKAGE BOUNDARY TOO, not only into C.
  A registry keyed on ANOTHER PACKAGE'S enum is spelled over NAMES —
  `node_value` matches `@std.meta.Node`'s variant names, because a
  foreign enum has no typed id here — so no compiler law and no grep
  sees it, and its `_ -> null` forgot the next variant the way every
  registry hole does: a template generated nothing and nobody was
  told. The keeper cannot follow across the seam; spell the arms and
  make the unknown SPEAK.
- THE EXEMPTION LAW, which the above is one instance of: a doctrine
  exemption that is not written AT THE SITE is an unbounded amnesty.
  Prose exemptions are invisible to tooling and to the next reader,
  so they rot into the default. Every licensed deviation carries
  `// LICENSED I<n>: <reason>` where the code is — that is what
  makes `make idioms` able to demand a decision instead of guessing
  which deviations were once approved.
- Node facts (spans included) live in side tables keyed by typed ids,
  never on nodes.
- A SLOT'S SEED IS COMPUTED THE SAME WAY AS ITS UPDATES, or the
  first decision judges a different quantity from every later one —
  and only the first, which is what makes it invisible.
  `collapse_breaks` seeded `line_indent` from `raw[0].span.lo`, a
  byte OFFSET, and assigned it a character DISTANCE everywhere after;
  the seed read as a column only while the first token sat on line
  one, so a LEADING COMMENT's own length became the indent and a
  four-character comment changed how the file parsed. Write the seed
  as the update's rule applied to nothing, not as whatever value
  happens to be at hand.
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
- A BODY IS TYPED UNDER ITS SIGNATURE, so a declaration whose
  SIGNATURE WAS REFUSED has no scope for its body to be typed in —
  and the empty list that stands in for the missing one is read as
  a real scope by every seat. `walk_under` sets `self.scope =
  sig?.params ?? []`, the plausible default the protocol law
  refuses, and `target_type`'s `.Param(i) -> self.scope[i]` then
  indexed past the end: a generic METHOD is refused whole (F2031,
  no sig recorded) and its body still walks, so `fn f<T: Tr>(x: T)
  { x.m() }` inside an `impl` CRASHED THE COMPILER while the same
  fn at the top level was fine. The tell was a SIBLING PAIR
  disagreeing in one match — `.Receiver -> self.scope.first() ??
  self.error_type` was total and `.Param(i)` was not, four lines
  apart, so one seat kind had the guard and the other did not.
  SEVERAL SPELLINGS OF ONE QUESTION IS THE DEFECT, not the missing
  bound: every one asks "what type does seat i wear", and one file
  held five — two receiver reads, total, and three parameter reads,
  none of them. The split was invisible because each pair sat
  inside ONE match, arms apart, so a reader checking either arm saw
  a guard right beside it. There is one reader now (`seat_type`),
  and the refusal was already spoken before the body ran, which is
  what makes Error the honest answer rather than a defect voice.
- A COPIED TEMPLATE'S SPANS ARE ITS ORIGIN FILE'S OFFSETS — so its
  errors point home — and any pass that reads a span as THIS file's
  offset must ask `store.spanned_elsewhere(e)` first. `range_bodies`
  did not, and `within`'s copied nodes landed in whatever `client.av`
  declared at `time.av`'s offsets (a write through `self` blamed on
  `describe`). A sublanguage's nodes are foreign too but spanned HERE
  (shifted into the block); `ForeignRange.spanned_home` tells them apart.
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
  (compiler/tests/seats holds the proof).
- EVERY POINTER AVRA HOLDS CARRIES A HEADER. The runtime counts
  references in sixteen bytes BEFORE each payload (tag, kind, rc,
  and a LENGTH — a string's text length, a record's payload bytes),
  and `avra_rc_retain/release` read that header — so a managed
  value that came from anywhere else reads memory that is not ours.
  The sources are all headered: the backend's string constants
  (`avra_llvm_build_text`, kind STATIC, immortal),
  the runtime's own words (`avra_bool_text`, "null"), argv and the
  environment (`str_static`). A new C fn that answers TEXT to a
  program allocates it with `box_alloc`/`str_owned`, or
  `str_static` when the program must never own it — never a bare
  `malloc` or a C literal. The tag is the belt (`hdr` refuses a
  header without it, and an unaligned or null-page address before
  reading anything); the law is the braces. THE FLOOR IS THE NULL
  PAGE, NEVER THE IMAGE BASE: a 4 GB floor held only while the loader
  put everything high, so under valgrind (and any non-PIE image)
  every box read as foreign — nothing counted, nothing freed, every
  constant copied — and the first Linux profile reported that as the
  program.
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
- ONE DERIVATION IS ALIVE AT A TIME. A derivation that turns, owes
  its instantiations, or quarrels under a hold is asked AGAIN in a
  fresh workspace, and the one before must be LET GO first or the
  build's peak is their SUM — a file test then its directory's passed
  5 GB where either alone is 2.2. Three holders keep one alive, and
  each needs its own answer. THE STACK: a caller's binding stands for
  the whole call, so the derivation that is superseded is bound in a
  HELPER that returns the next attempt and dies (`stood_first`,
  `heard`, `tried_anew`), never in the fn that asks again. THE HOOKS:
  `Workspace.discarded()` ends every one, the registry's declare hook
  among them — it captures the table that holds the registry. THE
  PROCESS: a relation's rows stand in a process-wide store under their
  Db until `close()`, whoever else died. `make turn-memory-attack`
  holds it by memory: a rebuild that turns twelve times, under a
  ceiling one attempt clears and their sum trips.
- A VALUE ITS OWN HOOKS CAPTURE IS AN IDENTITY, AND A COPY FORKS IT.
  `mut q = p` is a copy (spec 11.5), hooks included: the copy's writes
  land in the copy while its hooks answer for the original. The
  workspace is one (its families and its table's hooks capture it), so
  `check`'s `mut ws = o.ws` — a workspace read out of a record — lost
  every std package admitted after the copy, and a compiler built by a
  compiler that copies read `@std.meta`'s own `Kind` as undefined (522
  errors). MINT AN IDENTITY IN THE BINDING THAT WRITES IT (`mut ws =
  build_workspace(path)`), and read F2106 as naming exactly this.
  features/tests/borrow_identity is the one-generation witness. AND
  THE SWEEP THAT ACQUITTED THE TREE READ ONE PACKAGE: five lanes paid
  "the 15 sites" of `check packages/std-avrac`, and the two that broke
  were in `packages/cli`, warned about the whole time.
- A READ-MODIFY-WRITE THROUGH `get` IS A COPY, AND THE COPY IS WHOLE.
  `mut t = c.get()`, a write through `t`, `c.set(t)` is correct under
  spec 11.5 and COPIES what the cell holds on every turn — `get`
  answers a copy (the owner's Q2(a)), and F2106 names the local. When
  the loop is hot the copy is quadratic: the memo's settle did it per
  query until `Table` became ONE SHARED SLOT (a `Cell` of rows, an
  in-place `keep`). Write in place through the holder's own verbs —
  `put`, `push`, `set_at` on the cell, or a type that owns its cell —
  and keep `get`-then-`set` for values nobody writes often.
- A PARAMETER IS BORROWED, AND WHAT A CALLEE KEEPS TAKES ITS OWN
  REFERENCE. The caller keeps every managed argument STANDING for
  the call — a param, a register a scope owns, a cell's load and the
  binary's own data stand already; a VIEW into a box does not, since
  the callee may empty that box, so it is held across the call
  (memory.av's `standing_regs`, `lent`). The callee owns none of its
  params: a store, a push, a pack, a yield and its ANSWER each take
  a reference of their own, as any value a scope does not own does.
  A call that only reads costs no count at all — callee-cleans spent
  a retain and a release a managed seat, 1.3 billion counts in one
  cold `check` of the cli and 15% of its CPU. THE PROOF IS
  features/fns/tests/borrowed_params, each rule witnessed failing
  without it under `AVRA_RC_GUARD=1`. AND THE TYPE STILL DECIDES: a
  seat typed as unmanaged (`Ptr`, `Int`) is a view never held and an
  answer never retained — a read of freed memory. The capture lane
  read as `Ptr` was one (`callee_binding`), and a mut fn CELL loaded
  at the call's answer type was its twin (the box read as `i64`, LLVM
  refused). The fourth and fifth instances of A READ WEARS THE
  TYPE OF WHAT IS READ: a capture wears the CAPTURED binding's
  type, seated by typing (`TypeFacts.captures`), a cell's load the
  DEFINITION's (`def_type_of`) — at every read that MINTS, which
  in `callee_binding` is exactly those two.
- A FN TYPE CARRIES ITS SEATS' CONTRACT: `fn(mut Cx, int) -> int`
  is a DIFFERENT TYPE from `fn(Cx, int) -> int`, and the interner
  keeps them apart (the marks ride the key). That is the missing
  half of the seat law: without it a `mut`-taking fn stored in a
  plain fn seat wrote through an immutable `let` with no diagnostic,
  in both engines. The law has ONE asymmetry, and it is the sound
  direction — a seat that PERMITS writing accepts a callee that does
  not write (`fn_fits`), a seat that promised not to write refuses
  one that does. A fn type's marks are NORMALIZED at `intern` (the
  trailing unwritten ones dropped), so `fn(T)` built with no marks
  and with two false ones are one type; skip that and two spellings
  of one type refuse each other with identical words on both sides.
  The seat law then reads MARKS, never a DeclId, so a declared
  callee and a fn-typed value are one rule: `declared_marks`
  projects a declaration into the same currency.
  AND A SEAT'S PROMISES ARE ONE CHANNEL: `SeatMark { mutable,
  settled }`, carried as a `List<SeatMark>` on `Type.Fn`, `Arrow`,
  `TypeRef` and `Param` — never a parallel `List<bool>` per promise.
  A promise added as a second list doubles every mark site and drops
  silently wherever a site forgets it (the `TypeRef` default-field
  bug, twice); added as a FIELD it reaches every reader through the
  one `mark_at`, and `intern` normalizes one shape. The spelling
  boundary is the one exception: `TypeLit.Fn` keeps the grammar's
  two written lists and `interned` zips them once, so the currency
  never leaks into a user's `interned` receiver.
- A TYPE MIGRATION CAN MOVE WHO HOLDS A VALUE, AND A LIFETIME PROMISE
  IS A PROMISE ABOUT THE HOLDER. Changing a seat's type is arithmetic
  on signatures until the value's PROVENANCE changes — then a
  caller-held box silently becomes a CALLEE-MINTED one. @std/sqlite's
  `bind_text_unsafely_borrowed(…, value: string)` promises the
  caller's bytes outlive the statement, and is keepable only because
  the caller's own box goes straight through; migrating the WALL seat
  to `Bytes` while the FACE kept `string` would force the face to
  call `.bytes()` — minting a box whose only holder is that call,
  dead at return, handing C a dangling pointer every time with the
  caller having done nothing wrong. The face takes the new type too,
  so the box stays in the caller's hands and the type says what the
  contract always required. THE SEATS WHERE THIS BITES ARE FEW AND
  GREPPABLE: those whose contract mentions LIFETIME.
  One level down, the same law: a box materialised ONLY to be staged
  has no other holder, so its last reference dies before the call and
  C reads freed memory — staged boxes are held until the call
  returns, and the engines disagreeing is how it was seen.
  (Attributed to the sqlite lead and the substrate lane: `Bytes` is
  not on main. The seat, its contract and its `string` type ARE here,
  so the hazard is live for whoever migrates it.)
- A SETTLED AGGREGATE IS STATIC DATA, AND ITS BUFFER IS THE
  BINARY'S. A const's list, record, enum or map is laid out as an
  immortal headered global (`Ins.StaticAddr`, features/statics.av;
  the runtime's layouts are ONE definition, runtime/avra_box.h, that
  the backend mirrors and static-asserts). A read is an address; the
  memory pass owes it nothing. The runtime never frees or reallocs
  what it did not allocate: `array_grow` moves a laid-out buffer's
  cells out (`laid_out`), and a static map's index is BUILT ON FIRST
  LOOKUP, sized for its keys — one hash, the runtime's, never a copy
  in the compiler. AND A FIX THAT IS THE LAW CAN STILL TRAP THE
  COMPILER: opening every `mut`-seat argument unique (a copy is a
  copy) trapped the product's own `check` with "index 304 is out of
  bounds" — the compiler's source rides that write-through channel
  (ROADMAP H3b) — and the way it was told apart from a broken tree
  was the pre-fix product checking the SAME source clean. When a
  second-generation product traps, run the first generation over the
  same source before reading the trap as the tree's.
- THE `avra` SHIM MOVES TO THE TREE'S ROOT, so "." inside a command is
  the TREE and `PWD` follows the move: `explain @name` and `explain
  process` rooted at "." analysed nothing from the day they landed,
  and read as "no fn declared in this package" for a fn declared
  right there. The caller's directory is `AVRA_CWD`, exported by the
  shim before it moves; a command that reads the package it stands in
  roots at `here()` (cli/commands/shared.av), never at ".", and EVERY
  PATH ARGUMENT is rooted there too, ABSOLUTELY (`rooted`) — a
  relative one read where the tree stands found nothing from another
  directory, and read from a package's own root it walked past the
  `avra.toml` at `.`; one absolute spelling serves both. AND THE
  SHIM'S HEAVINESS TEST SKIPS THE SUBCOMMAND WORD: `build/` is a
  directory at the tree's root, so every `avra build <file>` queued
  on the machine lock as a package-scale run until the loop learned
  to start at the second word. AND A
  PACKAGE IS NAMED BY ONE VERB: a root module carries no package
  prefix, so `package_of_module` answered "" for the root while the
  manifest named it — `Decls.package_named` answers the root's
  manifest name (dotted) for both the declaration read and the file
  view's, and the orphan-impl law, which compares the two, refused
  every impl in the compiler's own cli the moment only one side knew.
  A second-generation build that REFUSES its own source is this law's
  symptom as much as a trap is.
- A POINTER SEAT NAMES ITS BOX. A row's `Ptr` says a header stands
  there, not WHICH — and `avra_str_len` handed a list answers the
  list's byte size as a text length, in a clean program (native 40,
  the evaluator "defect"). `RtSig.boxes` (core/ir.av's `Box`: `Text`,
  `List`, `Map`, `Any`) says what each pointer seat reads; a row that
  names none takes `Any` everywhere — unconstrained, never wrongly
  constrained, since most pointer seats do take any box and
  `avra_rc_retain` means it. TWO READERS, ONE COLUMN: `checked_extern`
  refuses an `extern fn` that names a row with the wrong seat count
  or a type that is not the seat's box (F2084; `ptr` is the raw
  crossing and fits any), and `make externs` refuses a `Text` box over
  a C `void*` or a `char*` under any other — so the column, the C and
  every declaration agree or the gate says which does not. Filled from
  the C in one sweep (46 rows, 141 seats): `const char*` is `Text`;
  the array, map and process rows say `List`/`Map` by name.
- AN `extern fn` WITH A BODY DEFINES ITS SYMBOL; ONE WITHOUT NAMES
  ONE. `extern fn avra_ui_event(who: int, …) { … }` is a HOST FN: the
  host calls it by exactly that name, a non-host target exports it from
  WHEREVER IT IS DECLARED, and a bodiless `extern fn` of the name in
  any file is answered by it — which is how a test answers a host's
  row in Avra (std-ui's `web/tests/mount` answers `avra_dom_frame`, so
  the one module that names the page runs eval == native). `export` is
  a module's visibility and exports nothing to a host. Its seats and
  answer are plain `int`, `float`, `string`, `Bytes` or `ptr`
  (type.host_fn); two of one name in a program are refused
  (lower.host_fn_twice). The backend defines the bare symbol beside the
  body under the extern row's shape; the evaluator, which has no
  linker, turns a call of the name into a call of the body
  (`hosted_within`).
  AND A SYMBOL IS THE WHOLE LINK'S, so three things are held where the
  host fn stands (compiler/whole.av's `host_fn_owes`). WHO OPENS IT: a
  dependency's host fn is the program's export only when the program's
  OWN sources import that package (lower.host_fn_unasked), and a build
  lists each as `host fn: <package> <name>`, fresh or kept. WHAT IT
  MAY NAME: nothing the platform already defines (lower.host_fn_shadows
  — a host fn named `malloc` once linked and REPLACED the allocator),
  and a bodiless extern of ANOTHER package only from the program's own
  package (lower.host_fn_answers). THAT IT STAYS: a native link keeps
  each with `-u <symbol>`, since no caller inside the program reaches
  it. THE SHADOW CHECK ASKS THE BUILD MACHINE (`platform_defines`, the
  compiler's own process), so its verdict is that machine's C library,
  for every target; a name defined only in a package's C archive member
  is not seen at all.
- A ROW'S ANSWER IS THE ROW'S, NOT THE DECLARATION'S — the seat law's
  other end, and it was unheld while every argument was held. An
  extern naming a runtime row could answer ANY type:
  `extern fn avra_array_new() -> bool` checked clean and the engines
  then disagreed about what it answered (the evaluator printing a
  list, native printing `true`). The declared answer rides the row's
  CURRENCY (`extern_kind` against `RtSig.ret`, a narrow width and a
  word being different), and a POINTER answer names the BOX the C
  body built (`RtSig.answer`) — without that half, `-> Bytes` on a
  list-building row still agreed on the kind and the program read a
  list's header as octets, "a non-Bytes value reached a byte
  operation in a clean program", the compiler blaming itself for what
  it accepted. THE NATIVE BUILD ALREADY NOTICED AND COULD NOT SPEAK:
  it warns "redeclared with a different type — stale: ptr (), source:
  i64 ()", and that channel exists for seed/source generation SKEW,
  so it cannot become an error — a name that is IN `rt_sigs`
  redeclared with a different answer is not skew, and needs its own
  refusal at the declaration.
- A RUNTIME ROW BORROWS ITS ARGUMENTS, as an Avra call does — and a
  row's KEEPING is C's to do, where the memory pass cannot place it:
  that is why `avra_array_push_owned` exists as a TWIN and why
  `avra_slot_set_owned` retains at the pack. A C body
  that KEEPS what it was handed takes its OWN reference
  (`avra_rc_retain`), and one that answers a value it keeps answers
  it retained (`owns_result: true`, as `avra_insist` does). A body
  written to the Avra convention instead — releasing what it was
  handed, storing what it never retained — leaves the cache holding
  freed memory, and the next reader segfaults (the once cache, first
  draft).
- A NAME IS OPAQUE AT A SEAT AND TRANSPARENT AT A READ. `type Name =
  Shape` is ALWAYS a DISTINCT type, and that is the point (P9) — over
  a fn shape as over any other. `alias Name<T> = Shape` is the OTHER
  spelling, never a mode of `type`: the same type under a shorter
  name, so it fills and is filled by its shape. `type` makes a new
  type; `alias` names an existing one. A seat (a parameter, a field, an annotation, an
  argument, an operand) judges the NAME; a read (a property, a
  method, an index, a `for` head, an interpolation hole, a LITERAL
  PATTERN, printing) judges the SHAPE — `match id { 5 -> … }` over a
  `UserId` compares the number, exactly as `id == 5` does. The two doors are spelled: `shape_at`/`shape_of`
  keep the name, `seen_at`/`seen_shape` see through it
  (style.seen_shape_vs_seat_shape). A
  LITERAL fills a named seat directly (`let rows: Rows = [1, 2]`,
  `let id: UserId = 5`) because a literal has no type of its own
  until a want lands on it; nothing COMPUTED wears a name it was not
  given, and `Name(value)` is how it crosses. AND THE OTHER SIDE
  DECIDES WHICH REFUSAL IS TRUE at an operand: the name's own SHAPE
  hears the conversion, ANOTHER NAME hears "two types" and NO fix
  (neither stands over the other, so no wrap is honest), and
  anything else is the operator's own law to refuse. One voice for
  all three told `A == B` that `B` was `A`'s shape. A name is FREE at
  runtime — it is a FLAT RECORD over one anonymous field, so the
  value IS its shape and the pack is identity. The seams and the
  recorded triggers are docs/2026_09_14_NAMED_TYPES.md.
  AND ITS MARK IS MADE AT ITS DECLARATION, which is the flat law's
  own hazard one type over: a law reading the registry mid-flight
  answers by declaration ORDER. `declared_type` ASKS the declaration
  before handing out a named type's id; without it the CLI (which
  signs types first) was green and `analyze_source` (which types the
  entry first) refused every literal fill — one tree, two answers,
  22 spec cases red while every probe passed.
- A CONTINUING OPERATOR TRAILS, IT NEVER LEADS. The lexer drops a
  break AFTER a continuing operator, so the line that continues is the
  one ENDING in `&&`; a line BEGINNING with `&&` starts a new
  statement and the parse dies one line later — "expected `}` to close
  the block" at the `&&`, then "expected EOF while parsing
  `program`". The habit every other language teaches is the leading
  form, and the cost is not the parse error: the file fails WHOLE, so
  the module exports nothing and the symptom lands in the FILES THAT
  IMPORT IT ("`@std.avrac.features` does not export `Decls`", from
  three innocent files, with the real error unread above them). Same
  shape for every binary operator a condition wraps on.
- A CLOSER NEVER CONTINUES A LINE. The lexer's continuation rule
  listed `>`, which closes a TYPE ARGUMENT LIST as well as wanting a
  right side — so `type Rows = List<int>` dropped its BREAK and
  swallowed the statement below it. No statement in the tree had
  ever ENDED in `>` (a trait's bodiless `fn a() -> List<T>` does, and
  parsed only because a `}` supplied its END), so the rule had never
  been tested: the assumption-nobody-violated law wearing the
  lexer's clothes. `>` is out, `<` stays — a line ending in `<` is
  incomplete under either reading. The next `>`-shaped closer faces
  the same question.
- WHETHER A VALUE RIDES A POINTER IS ITS DECLARATION'S ANSWER, so a
  law that asks the type registry must ask the DECLARATION first.
  A record of one scalar field is FLATTENED — it travels as the
  field — but only once its own signature has been asked
  (`declare_record` marks it), so a law reading `rides_pointer`
  mid-flight answers by declaration ORDER: the `once` answer law
  refused a flat record under the CLI and accepted it under
  `analyze_source`, in the same tree. Ask `decls.sig(d)` for the
  answer's declaration, then judge.
- AN ENCODING SPENDS THE EMPTY VALUE, so WRITE THE EMPTY CASE
  FIRST. An encoding earns its efficiency by spending a value it
  believes is spare, and the spare value is almost always the empty
  one — the null pointer, the zero length, the absent terminator. So
  the premise that hides is "nothing is not a real value here", and
  it hides inside code that is sound everywhere else. Three
  instances in one day, three authors: a write that truncated on
  `strlen`; `str_len` distrusting a ZERO length and falling back to
  `strlen` — PAID at 44c36f1, and safe until then only because every
  text box carries a spare byte its callers fill; and the niche — a nullable pointer IS its own
  value, so ABSENCE is the null pointer. Inside the language the
  distinction holds, measured in both engines: an empty list, an
  empty string, a zero-field record and a zero int all read PRESENT
  while their absent twins read null. It is at the C BOUNDARY that
  the value gets spent twice — a runtime row answering NULL to mean
  "empty" collides with the niche's absence, so an empty blob
  arrives indistinguishable from a SQL NULL. A row answers an EMPTY
  BOX for empty and NULL only for absent. The rule is a TEST, not a
  discipline: for every representation you add or consume, the empty
  case is the first case you write, and a diff shows whether you
  did.
  AND THE SPARE VALUE IS SPENT TWICE INSIDE THE LANGUAGE AS WELL.
  `Directive.source: Node?` answered null for a directive that
  declares NO source and for one whose source the crossing could not
  read — the second generated nothing, quietly, three lines from the
  sibling law that says a fill the compiler cannot place is spoken
  and never spliced. The tell is a `T?` whose absence has TWO causes;
  the fix is the enum that names them (`Generated.None` /
  `.Made` / `.Foreign`), never a flag beside the null.
  AND A NULLABLE OVER A NULLABLE IS THAT TELL BY CONSTRUCTION. When
  `T?` met `T = string?`, four layers each read one null as both
  absences: the niche (a `string??` as one pointer — `[null].first()`
  answered empty), the `once` cache (a cached `null` read as "not
  yet", so a `once fn` answering null RAN EVERY CALL), the
  evaluator's slot (`Val.N` for a present null and an absent mark
  alike) and the const crossing (`MetaVal.Absent`). Each fix NAMES
  the second absence: a pair, a one-cell box, `Val.Gone`,
  `MetaVal.Gone`. A generic seat reaches this shape in any program,
  so a layer that files absence is asked what it does under `T??`.
- ITS SIBLING AT THE OTHER END: A FLAT CONCATENATION OF TWO
  SEQUENCES HAS A BOUNDARY THAT MOVES. Splice two variable-length
  runs into one list and the split between them is not recorded, so
  moving an item from the first into the second leaves the SAME
  list and two different things wear one identity. `use a.b` and
  `use a.{b}` fingerprinted alike; so did `f<A>(B)` and
  `f<A, B?>()`, `f<B?>()` and `f(B)` (a written type and an ident
  were the same value), `fn f<T>(x: int)` and `fn f<T, x: int>()`.
  THE FIX IS ARITY: fold each sequence to ONE value so a payload's
  shape is fixed per kind. BOTH INTUITIVE FIXES ARE WRONG, and
  each is worth knowing. A SEPARATOR is the first —
  `stmt_fps(then).concat([0]).concat(stmt_fps(else))` was written by
  someone who saw this
  hazard exactly and spent the one value that is not spare, which
  is the empty-value law above wearing this law's clothes. A
  RENUMBERING is the second: under a LINEAR fold (`131t + x + 7`)
  a tag is an additive offset, so distinct tags separate nothing
  that a chosen literal can reach — renumbering turns the first
  test green and leaves every collision live. THE TEST: for each
  encoding ask which two shapes produce the same bytes, and write
  that pair as a test BEFORE the fix. Three collisions were
  nameable by hand here; enumerating every splice site and running
  it against the parent made nine.
  AND ITS QUIETER TWIN: A HASH THAT FORGETS A PAYLOAD. Same
  consequence — two values, one identity — but nothing to enumerate,
  because the omission leaves NO MARK at the site: the parts list
  reads complete. THE TEST IS A DIFF, the record's fields against the
  hash's parts, field by field. Seven were missing here in one sweep
  and every one was a field ADDED after its hash was written —
  `Param.mark` (so `fn f(mut x)` and `fn f(x)` were one statement),
  `Param.default`'s OWNER (a defaults list beside the fields says
  which exist, never whose), `TypeRef.dynamic`/`marks`/`arrow`,
  `export`, `StructSig.defaults`, and a named type whose whole
  signature hash was the constant `1`. So ask it of a hash on the
  same day a field lands, never of the hash alone.
  AND THE PART WORTH THE MOST: `export` was forgotten THREE LINES
  UNDER the comment that states the law — "A MARK IS PART OF THE
  STATEMENT: `fn f()`, `mut fn f()` and `once fn f()` declare
  different things". The doc named three of the five marks and the
  code stamped those three. A LAW WRITTEN AS A DOC COMMENT THAT
  ENUMERATES ITS INSTANCES DECAYS INTO A LIST, and the list stops
  growing before the code does; the reader sees a stated law and
  stops looking. `make fingerprints` is the enforcement now — it
  refuses a run spliced into a parts list (both surfaces witnessed
  failing), counts the lists it read, and claims the shared fold's
  tag in every file that CALLS it, since a borrowed tag mixes into
  that file's space.
- A GUARD IS A PROPERTY OF EVERY CROSSING, NOT OF A PACKAGE. The law
  above says a NUL is spent at the C boundary; this one is where the
  refusal goes. THE CROSSING IS THE EXTERN SEAT, and only that: every
  verb in `@std/text` reads the header, so a NUL is an ordinary
  character on this side — text carrying one is longer than its
  prefix and unequal to it (`==`, `contains`, `index_of`, `split`,
  `replace` walk the length under `memcmp`/`memmem`, f57372a, and
  `starts_with` joined them here — it was left off that list and
  still walked with `strncmp`). It is
  `getenv`, `execvp`, `fopen`, `sqlite3_open` that end at the first
  NUL, so a value means a PREFIX of itself the moment it crosses, and
  the guard belongs at the row that hands the pointer over.
  `@std/text`'s `nul_at`/`has_nul` are that guard, once.
  THE SPREAD IS THE LESSON, and it is what made eight defects in two
  days across three packages: `@std/process` guarded `tool` and not
  `tool_from_env`; `@std/io` guarded ten verbs and not `env`;
  `@std/sqlite` guarded some and not five. Each package HAD the
  guard, one door down. The failures were SILENT, not traps — a holed
  name read a DIFFERENT variable (`env("PATH" + from_codepoint(0) +
  "/junk")` answered PATH's value), which no crash surfaces. SPELL
  THE EXAMPLE THE WAY THE HAZARD IS MINTED: this entry first wrote
  that name as `"PATH\0/junk"`, and `\0` IS NOT AN ESCAPE, so the
  demonstration contained no NUL and would have answered null for
  the wrong reason. @std/sqlite's boundary header taught the same
  trap with the same dead literal (fixed by the docs lead at
  e523655), in the file whose whole subject is that hazard. A doc
  that DEMONSTRATES a hazard is code that has never been run — the
  four guard cases here were witnessed failing with the guards
  removed, which is what a prose example cannot be. And A METHOD MUST NOT READ
  ONE NAME TWO WAYS: `Env.get` compared with `==` under `Only` and
  handed the name to C under `Inherit`, so one method disagreed with
  itself by variant. THE TEST: list every row that hands text to C,
  and diff it against the guarded ones — never "does this package
  guard".
  AND THE STALE-DOCTRINE TRAP THIS LAW WAS FIRST WRITTEN INTO. The
  first draft of this entry, and `@std/text`'s own module doc, and
  `std-sqlite/boundary.av`, all taught that those five verbs stop at
  a NUL. They DID until f57372a landed the same day, and I wrote the
  correction quoting the behavior the docs described instead of the
  behavior I measured — in the entry directly above the rule that
  says to measure. A doc is a claim with a date on it; the test that
  disagrees with it is the newer fact. `85abb9e`'s message carries
  the wrong rationale for a real fix because of it.
  AND A RETRACTED FACT SPREADS BY CITATION, WHICH NO SWEEP OF ITS
  ORIGIN REACHES. This one was quoted into four documents across
  three campaigns — a ROADMAP red-team entry, a docs vision's
  blockquote, a subset probe log's row, a census heading — and the
  package that OWNED the claim swept itself twice by file, correcting
  five sites, while every citation stood. A citation is a COPY that
  does not know it is one: it names the finding, not the mechanism,
  so it survives the mechanism changing and reads as corroboration
  from an independent source. THE SWEEP IS BY CLAIM, NEVER BY FILE
  OR BY PACKAGE — grep the tree for the ASSERTION and for the
  distinctive example that carries it (`ab\0cd`, `"\0x"` here), not
  for the files you remember writing.
- THE RUNTIME IS A LIBRARY AND THE HOST HOLDS EVERY ROW. A program
  links `build/libavra_runtime.a`, one object per `runtime/*.c`, and
  carries only what it reaches — so a program that never spawns carries
  no scheduler. The COMPILER must carry all of it, because its
  evaluator binds package C to the runtime inside its own process:
  `avra_rt.h`'s host table, generated from `rt_sigs()` and included by
  the extern host, names every row. A row with no evaluator arm is
  called by name through the uniform frame (`RtSig.armed`), so the
  frame's seat law holds for it — a closure cannot reach C that way.
- A FRAME NEVER SKIPS A GUARD. A task's stack has one guard page, and a
  frame wider than a page could step over it into a neighbour's stack.
  Every fn Avra emits carries `probe-stack`, and C built here probes
  too (Apple's clang by default, `-fstack-clash-protection`
  elsewhere). CHECK AN ATTACK BUILDS WHAT IT CLAIMS: the first
  wide-frame attack was a `volatile` array the compiler shrank to 16
  bytes, and it "passed".
- A COLD PATH IN A HOT LEAF COSTS EVERY CALL A FRAME. A lazy
  `getenv`, a `char msg[80]` for a trap's words, a grow branch, a
  `__builtin_return_address` read — each is free when it runs and
  ruinous where it sits, because the compiler hoists the register
  saves it needs ABOVE the fast path. `avra_rc_retain` saved four
  register pairs to perform one `add`; `avra_array_get` reserved 128
  bytes per read. Move the cold half OUT OF LINE (`noinline`,
  `cold`, `noreturn` where it traps) so the branch to it is a TAIL
  call, and settle env flags in a `constructor`. CONFIRM IN THE
  DISASSEMBLY — `objdump -d --disassemble-symbols=_fn build/avra`,
  and a leaf shows no `stp`/`sub sp` — because no profiler names
  this and LTO cannot see it: the cold code is inside the hot fn.
  And measure with `make census`, never a sampler: a sampling
  profiler charges a release cascade to whoever was on the stack.
  THE WIN IS THE FRAME-TO-BODY RATIO, NOT THE FRAME, and the law
  reads as a licence to chase every prologue without it.
  `avra_rc_retain` is ~5 instructions called 557M times, so its
  4-instruction prologue more than DOUBLED it — that is the 26%.
  `avra_array_get_owned` carries the same prologue on a ~20
  instruction body at 3.9% of self time: worth ~0.8%, which is
  UNDER a stopwatch's noise floor here (+/-0.05s on 5.9s), and
  removing it measured nothing. Price the ratio before paying.
  AND FIXING EACH LEAF DOES NOT FIX A CALLER THAT INLINES SEVERAL:
  `get_owned` inlines two ALREADY-CLEAN leaves and their cold
  tails, and the union's saves get hoisted above the fast path
  again. Two acquittals worth keeping: counting `stp` does not
  find this — `avra_array_get` reports one and is clean, its `stp`
  sitting below the `ret` — so count frame ops BEFORE the first
  branch; and a `__builtin_return_address` read, named above as a
  suspect, was innocent here (removing it left the prologue
  byte-identical). The cold branch being a CALL is what clobbers
  x30 and forces the save.
- ALLOCATION HERE IS CHEAP, so avoiding one is a trade, not a win.
  The size-class free lists made a box cost less than the scan or
  the branch that would dodge it: deduplicating `far_merge`'s
  expected sets measured 3% SLOWER, and skipping an empty
  `concat` measured neutral. Measure before removing an allocation.
- A CAP BELONGS ON A LOG, NEVER ON DATA THAT IS COMPARED. A build log
  with no ceiling is a full disk — `make avra` wrote 43 GB into a file
  whose last 200 KB was all anyone read, twice in one day, and took a
  compiler binary and every other session's work with it. So every log
  runs through `tools/capped.sh`, which caps the output and answers
  the COMMAND's status (a bare pipe answers `tail`'s). But the same
  `tail` over an artifact that is DIFFED can truncate two different
  outputs INTO AGREEMENT — `witness` and `native-check` exist to prove
  two readings agree, and a cap there manufactures the agreement with
  no failing run to reveal it. Those two stay uncapped, with the
  reason at the site. Ask of every redirect which it is: read by its
  tail when something breaks, or compared to another file.
- A PROCESS STATUS IS A VERDICT, never a count: statuses are eight
  bits, so 256 failures read as success. Exit 0 or 1 and print the
  count. A TRAP is not a verdict either — `avra_trap` exits 2, so a
  wreck can never be mistaken for a disagreement. And A COMMAND IS
  AN ARGV, never a shell line: `avra_spawn_status(prog, args)` runs
  a program with its words, so no character in a path or a
  manifest's `[link]` row means anything but itself — nothing
  quotes, nothing fences, and a dependency's flag cannot run.
- THE LAW ABOVE THE ARGV ONE: A VALUE THE CALLEE WILL REINTERPRET IS
  TWO THINGS AT ONCE, AND THE FIX MAKES THE REINTERPRETATION
  IMPOSSIBLE — never an escape. A command asked to be inert data AND
  a grammar the shell parses is the first firing: `avra_spawn_status`
  did not quote better, it REMOVED THE PARSER, and the supply-chain
  hole closed as a consequence rather than as the goal. @std/sqlite
  is the second, at a different boundary — under `SQLITE_USE_URI` a
  path handed to `sqlite3_open_v2` is a filename AND a URI parsed for
  `?mode=`, so a user's path beginning `file:` changes meaning with
  nobody writing a line. The RESOLUTION is the same shape, which is
  what makes it a law and not a coincidence: SPLIT THE VERB, one per
  grammar. `open(path)` is always a filename and refuses a `file:`
  prefix, saying to ask deliberately; `open_with` is where the ask
  lives (`uri: true`). The capability was never the
  problem, the AMBIGUITY was. THE TEST: when a value crosses a
  boundary, ask whether the CALLEE will parse it — if it will, the
  value wears two hats and the design owes a SPLIT, not an escape.
  Ask it of format strings, glob patterns, regexes, and the next
  `[link]`-shaped manifest row.
- ITS SIBLING, AND THE SHARPER ONE: A GUARD AND THE THING IT GUARDS
  MUST READ THE SAME BYTES — and the DISAGREEING PAIR is not always
  the one you can name. This entry first said our own primitives
  disagree, `from_codepoint(0) + "x"` having `.length` 2 while `==`
  read it as `""`. RETRACTED, re-probed at 927ed49: it is length 2
  and UNEQUAL to `""`, because f57372a made `==` a length compare
  (pinned in std-text's suite). The two readers that actually
  disagree are AVRA AND C, never two Avra verbs, so the door and its
  callee are inspecting DIFFERENT VALUES only where the callee is
  the C one. The trap the door exists to stop walks straight through
  it there. @std/sqlite's empty-path door is the instance (the
  sqlite lane's, open.av's `path_fault`): an empty path opens a
  PRIVATE TEMPORARY database deleted at close, so every write
  succeeds and the data is silently gone. The guard was not weak —
  it was reading a different string than the callee.
  AND THE NEAR-MISS IS THE HALF TO REMEMBER: one hostile case was
  refused BEFORE the fix, by accident, because `==` truncated it
  into a match. Right answer, wrong reason — a suite written that
  day goes green and ships the door broken. Recording it as a
  near-miss rather than counting it as a pass is what separates a
  red team from a demo. (That accident was the pre-f57372a `==`; the
  lossy half it relied on is gone, and the near-miss lesson is not.)
- `@std/*` IS THE TOOLCHAIN'S, NOT THE MANIFEST'S. A `use @std.x` needs
  no dependency row: the CLI's disk host names a std root found from
  the binary's own directory (`<self>/../packages` in a checkout,
  `<self>/../lib/avra/std` under `make install`), and the workspace
  admits `@std/x` from `<std_root>/std-x` the first time a `use`
  reaches for it — `reaches` is the ONE door, F3013 is what it still
  says for a key the toolchain does not carry. A row that names a std
  package is a PIN and wins for the whole graph. The old blocker —
  one directory under two spellings refusing as F4014 — is paid in
  `admitted`, which compares `host.absolute(...)` of both roots.
  RECORDED TRIGGER: the compiler's own manifests (`packages/std-*`,
  `packages/cli`) still declare their `@std/*` rows, and must, until
  `make seed` on main carries this resolver — the committed seed
  compiles HEAD in `seed-check`, and a seed that predates the door
  cannot read a manifest with no rows. Strip them in the slice after
  that refresh, and the pin law holds across the tree.
- THE PRELUDE IS THE FLOOR: `@std/prelude` (packages/std-prelude) is
  seen by every file in every package without a `use` — `println`,
  `eprintln` and `Entry<K, V>` (what `m.entries()` answers) today,
  and nothing a program can be compiled without; a name that fails
  that test belongs to a package above.
  It is a PACKAGE the toolchain carries, not a scope the resolver
  injects (P7: a reader can open it, `explain` can point at it, and
  the layering `prelude <- text <- io <- process <- …` has a node at
  its bottom). It binds WEAKLY (`bind_weakly`, features/
  namespace.av): a file's own declaration, an explicit import, a
  local binding all win silently. It DEPENDS ON NOTHING, and the
  compiler refuses a prelude manifest that says otherwise (F4018).
  A package's tests print through it, never through `@std/io`, so
  a dev edge never points up — `@std/text`'s did, and is gone.
  RECORDED TRIGGER: `@std/io` still exports `println`/`eprintln`
  and the compiler's own source imports them, because the committed
  seed predates the prelude and `seed-check` compiles HEAD with it;
  after `make seed` on main carries the prelude, drop io's two verbs
  and the 19 `use @std.io.{println…}` lines — an explicit import of
  the prelude's name is legal, so the sweep is deletion only.
- A COMPILER UNDER TEST MUST STAND WHERE A COMPILER STANDS. `@std/*`
  resolves from the BINARY'S OWN DIRECTORY, so a harness that links
  the binary somewhere else changes what it can resolve: `seed-check`
  linked into `build/seed-check/`, looked for `build/packages`, found
  no std root, and could reach a std package only through a manifest
  row. Green for as long as every manifest carried rows, and red the
  day they went — the assumption-nobody-violated law, wearing a
  harness's clothes. A binary under test links beside `build/avra`.

- A REFUSAL THAT EXPLAINS ITSELF ON THE SAME CHANNEL AS ITS CONSENT IS
  A TRAP FOR THE NEXT CALLER. A verb answering both a VERDICT and
  PROSE must not send the prose where a reader takes it for the
  verdict: `receipt_trusts` printed "no receipt in …/build" on STDOUT
  and returned 1, the caller read stdout and swallowed the status, and
  a MISSING receipt read as permission to skip a gate — on the
  feature's first integration. Consent gets its own channel (stdout
  non-empty if and only if trusted, every reason on stderr), and a
  status-blind caller then fails SAFE rather than open. AND BOTH
  BRANCHES ANNOUNCE: moving the reason to stderr silenced the
  integrator's own log until the caller was taught to read it, so a
  skip says what it trusted and a gate says what it read instead —
  neither branch silent is what makes a mechanism auditable rather
  than merely honest. AND THE TESTS MUST USE THE CALLER'S CONVENTION:
  four fixtures called the function and checked its EXIT STATUS while
  the caller read its STDOUT, so they were green over a contract
  nobody used — "a test with its own copy of the logic tests the
  copy", one seam over, where the copy is the calling convention.
- A SELF-TEST MUST NOT BE REACHABLE FROM THE ENTRY POINT IT
  EXERCISES. "An instrument proves itself before it certifies
  anything" put the fixtures inside `write`, and the fixtures call
  `write`: 986 processes in one chain, 2441 of a 2666 fork limit, and
  every other session's builds died on `fork: Resource temporarily
  unavailable`. THE FIX IS THE SHAPE, never a depth counter — every
  verb a function, the fixtures calling the functions, so recursion is
  unreachable rather than bounded; run the fixtures once at gate time
  beside the verb, not inside it. A fixture may re-enter the script
  only where what it checks is a PROCESS's exit status, and only while
  the path it re-enters runs no fixtures. AND THE SIGNATURE IS THE
  HALF TO REMEMBER: A RESOURCE EXHAUSTION PRESENTS AS A FAILURE IN
  WHATEVER ELSE HAPPENS TO BE RUNNING, so the first unexplained
  "Resource temporarily unavailable" is a question about the MACHINE,
  never about the command that reported it — it fooled the author of
  the bomb, holding its own output, ten minutes before anyone else saw
  it.
- Every module has `spec`/`given`/`then` tests in `tests/` beside it.
  `tests/` IS A MODULE LIKE ANY DIRECTORY: a private name one of its
  files declares is its siblings' too, and fixtures shared across test
  files lean on exactly that (witness_fixtures.av). Two files each
  declaring one private name KEEP IT APART — each reads its own, and a
  third file's read is `resolve.kept_apart`, naming both; an EXPORTED
  name stays the module's one declaration (`resolve.duplicate_in_module`).
  A helper a package's suites AND its program tests share is EXPORTED
  from `tests/support/` and read as `use tests.support.{…}` — a program
  test is a module like the rest, so it reaches the same file
  (packages/std-http/src/tests/support).
  AND A TEST READS ITS MODULE'S PRIVATE NAMES: a file DIRECTLY in a
  module's own `tests/` may `use` a top-level name that module declares
  and does not export — by an explicit `use`, never bare. Nothing else
  may: another module's tests, a directory under `tests/`, another
  package. A name two of the module's files each keep private is
  `resolve.private_apart`, naming both; a private name is never
  re-exported.
- A DEPENDENCY IS ITS LIBRARY. The file a dependency's `[bin]` names
  is that package's program and runs only where the package is the
  root, so it is no module file of a program that depends on it — its
  statements never run there and its names are not the library's
  (tools/ui-board: the page program is the package's own `[bin]`, and
  `term/` depends on it).
- A SEALED TYPE IS BUILT WHERE IT IS DECLARED. `@sealed` (`@std/meta`)
  on a type: outside the declaring MODULE no literal fills it, no
  `Name(value)` converts into it, no record literal, `with`, field
  write or variant makes one (type.sealed) — every seat a literal
  reaches, a default and an annotation's argument included — while
  every read stays open. The doors are the fns the module exports, so
  a value anywhere is one a door answered (std-ui's `Url`). Generated
  code is judged where it LANDS: a derive on a sealed type lands in its
  module and builds it. The module's own `tests/` is another module.
- A TEST'S NAME IS READ AS ITS SCOPE, so a name that claims a
  PROPERTY where the body checks an INSTANCE promises coverage the
  suite does not have. "a comment-only line is a blank line" asserts
  a BREAK COUNT and nothing else — true, and it read as settling the
  layout question, so the `line_indent` defect below sat behind it
  unprobed. Nobody misread the assertion; a reader reads the NAME
  when deciding whether a question is already answered. NAME A TEST
  AFTER WHAT IT ASSERTS, never after the property it gestures at.
  The family is wider than tests and the members look alike: a keeper
  whose name says it guards an enum while it only ever tested one
  shape, a green run whose scope excluded its subject. In every one
  the artifact was CORRECT and its LABEL was broader than its
  coverage, which is why no amount of verifying the body finds it.
- Passes are pure queries with ONE standard signature:
  `pass(p: Parsed, ...upstream Facts) -> Facts` — the program
  first, prior passes' facts next, its own Facts (which OWN its
  diagnostics) out. A pass OWNS its fact tables — NodeStore is
  parse-owned and never accretes pass facts. `analyze` is the only
  place pass order exists; consumers hold ONE Analysis. A source is
  ONE value (`SourceFile`: `file` + `text` + `line_starts`) — never a
  loose (file, text) pair.
- Queries own granularity and caching; features own the per-variant
  logic a query's body dispatches to.
- AN EARLY-CUTOFF HASH MUST COVER THE WHOLE VALUE, or the cutoff
  claims "unchanged" about something that changed. `parsed` settles
  on a fold of STRUCTURAL fingerprints while its value carries the
  source TEXT and every SPAN, so a reindent leaves every later span
  stale and certified fresh. The answer is not one hash over
  everything — that re-runs typing on a blank line — it is a cutoff
  PER CONSUMER: what a dependent READ decides which fingerprint may
  cut it off. Latent only while compiles are one-shot.
- AND THE KEY A REMEMBERED VALUE SETTLES ON AND THE NAME ITS RESULT IS
  STORED UNDER ARE ONE DERIVATION. A specialized `const`'s settlement
  was keyed per unit (the settled seats' fingerprints) while the
  MATERIALIZED const unit was named by the plain statement — so the
  first unit's folded value served every other unit, and
  `matches("x", …) + matches("y", …)` answered with one value twice.
  When a computation is keyed AND its artifact is NAMED, derive both
  from ONE value (`settled_symbol`); two spellings of the identity a
  cache depends on is a wrong answer waiting for a second caller.
- Every diagnostic names a registered kind — its own identity,
  unique by construction — carries help or a structured fix where
  expressible, and has a golden rendering test.
  AND THE RENDERER NEVER DROPS A LABEL: a voice with NO PLACE still
  renders its label. A label is what the diagnostic SAYS; a Loc is
  only where to point while saying it, so `render_with` windowing
  the label and skipping it when `loc == null` lost information for
  a reason that has nothing to do with information. It was silent,
  because a label is optional everywhere else: a package-level
  refusal (the meta boundary's — the package moved, not a line)
  wrote its detail in the label the way every located voice does,
  and six suites asserting that detail went red with the refusal
  itself correct. An unlocated label renders as its own line under
  the message, and a golden pins it.
  THE INSTANCE WORTH KEEPING IS THE FIX I NEARLY SHIPPED: folding
  the label into that one voice's MESSAGE. It was smaller, it was
  green, and it was a COPY — the next voice about a package rather
  than a line repeats it, and the third one is where someone notices
  the concept was never named. When a voice cannot say something the
  renderer drops, the renderer is the defect; a workaround at the
  voice is the shape that arrives three times.
  AND A HELP IS A CLAIM ABOUT THE GRAMMAR THAT NOTHING CHECKS. The
  golden test pins the WORDS; no test anywhere compiles the FORM a
  remedy names, so a help can send every reader at something the
  parser refuses and stay green forever. Two fired in one session:
  F2030's "add a bound — `<T: SomeTrait>`" was spoken for a type's
  and an impl's parameters, where a bound is F0100 AT the `<` (fixed
  — `bound_remedy` is a registry on the declaring kind); and F2033's
  "wrap it — `(x: T0) -> always(x)`" is F2001 "`V` names no type"
  inside the generic impl that wants the wrap. A REMEDY NAMES A FORM
  THAT PARSES WHERE IT IS SPOKEN — the `where` is half the claim, and
  the keeper this wants compiles the named form in the refusing
  context.
- A LINT COUNTS WHAT ITS DOCTRINE COUNTS, never a proxy that
  correlates. F2040 was written to count HIDDEN VARIANTS where the
  doctrine counts ANSWERING ARMS: measured tree-wide, 191 sites
  fired (361 warning lines across a package sweep, a shared
  dependency counted once per package) and 0 were the defect, so
  the real errors beside them were read past. A warning
  nobody must act on trains the reader to skip the column errors
  arrive in — MEASURE a lint's true-positive rate before it ships,
  and again when its doctrine moves. The rate is the lint's spec.
- AND ITS COUNTERPART: A LOUD LINT IS NOT A LINT TO WEAKEN. F2047
  fires 100 times and every one is TRUE — a writing method called on
  a non-`mut` receiver, permitted because the receiver law is still a
  warning. It counts exactly the right thing and fires because the
  conversion was never paid, which is the MIRROR IMAGE of F2040 and
  not another instance of it. So measure the rate before deleting a
  lint's noise AND before trusting a quiet tree: a lint that counts
  the wrong thing and a law nobody has paid look identical from the
  warning count alone, and only the true-positive rate tells them
  apart. PAYING IT WAS THE PROOF: turning the compiler's identities
  into Cells took std-avrac from 165 sites to 4 and the cli from 60 to
  1 (deduped by file:line), and nothing that fired was a false alarm.
- A MAP'S ORDER IS ITS INSERTION ORDER, and that order is the only
  one a map's output may use: `m.keys()` and `m.values()` read back in
  written order, an overwrite keeps a key's place, and a snapshot
  keeps the order it had. The hash seed never reaches output (tests
  pin it with `AVRA_HASH_SEED`). AND A MAP WALKS PAIRED: `for k, v in
  m` and `[f(k, v) for k, v in m]` bind the key and the value over a
  snapshot, and a head naming ONE binder is refused ("a map walks as
  key and value — `for k, v in m` binds both"). `m.entries()` answers
  `List<Entry<string, V>>`, and `Entry<K, V> = { key: K, value: V }`
  is the PRELUDE's record, never a built-in name: a file's own `Entry`
  takes the name silently and the answer stays the prelude's (import
  it under another name to say both — `use @std.prelude.{Entry as
  Pair}`). A LONE FILE sees no prelude, so `entries` there is
  `type.map_entry` — probe it from a directory with an `avra.toml`.
  Its vocabulary is `get`/`set`/`has`/`remove`/`keys`/`values`/
  `entries`/`length`/`is_empty`, and A MAP IS A WALK SOURCE: every
  walk verb runs over its entries (`m.any(it.value > 1)`,
  `m.map(it.key)`, `m.find(…)`, `m.fold(…)`) with no list between,
  and a shape-keeping one — `filter`, `take`, `drop`, `take_while`,
  `drop_while` — answers a `Map` in the same order. `get` is ONE
  probe, and `m.set(k, f(m.get(k)))` is one too when the map's root
  and the key are each named once under the value: the read's word
  is the write's (`AVRA_MAP_STATS=1` says a run's probes at exit).
  Spelled as two statements it stays two. THE RUNTIME BELIEVES THAT
  WORD ONLY WHERE THE MAP CONFIRMS IT — a hit's slot must hold the
  very key, a miss's index word must be of the same building of the
  index and still empty — so the lowering's proof is the fast path,
  never what the write's rightness rests on.
- Grammar authoring: EVERY COMMA LIST TAKES A TRAILING COMMA — a
  repeated `( "," x )*` ends `","?` before its closer, in every
  rule (params, type params and args, payload declarations, lambda
  params, fn types, literals, `use` lists). A list that refuses the
  comma is a grammar defect, not a style.
- Grammar authoring: A TWO-CHARACTER OPERATOR ENDING IN `>` CANNOT BE
  MUNCHED. A type argument closes with `>`, so `Table<List<string>>`
  ends in the same two characters `>>` does, and one token there
  means the type NEVER CLOSES — 97 sites, and the symptom is a module
  that stops exporting. `<<` is safe, nothing opening two argument
  lists adjacently; `>>` is TWO tokens the grammar joins, both
  branches capturing ONE token into the same label so the run stays
  aligned. The next `>=`-shaped operator faces the same question.
- A RUN OF TEMPLATES HAS NO EXPRESSION POSITION, and every OTHER seat
  takes one. `${xs}` with a `List<Code>` flattens where a RUN belongs
  — statements, arms, binders each join a `Many` — and an expression
  seat holds ONE value, where no separator between two of them is the
  compiler's to choose. That arm answered an `Expr.Error` node, so
  the only word spoken was the TYPER's about the seat (F2075, "a hole
  takes what its seat takes"), which names neither the mistake nor
  its exits; it is F2085 now, homed at the hole, and it carries both.
  THE FIX IS IN THE GENERATOR, NOT THE TEMPLATE: fold the list where
  the derive runs, one hole per element (`[a].concat([b])`), so the
  generated literal's length is fixed per type — which is also what
  the ARITY law wants, so the two laws agree on one shape. Not listed
  under "the subset today" because it SPEAKS, which is the whole
  point of the change. And the hole vocabulary is wider than it
  looks: an INT hole is native in both positions (`int_node` in an
  expression, `int_name` in a name), so `${tag()}` needs no
  hand-rolled `name("${v}")` — a second instrument for a question the
  compiler already answers.
- A BOUNDARY CHECK MAKES A MOVED SHAPE UNMOVABLE IN ONE GENERATION,
  AND GROWTH IS NOT A MOVED SHAPE. `features/crossing.av` holds
  `@std/meta`'s shapes as rows the compiler was built against; a
  package that RENAMED, REORDERED or SHRANK one is refused, and one
  that merely GREW — fields appended, in order — crosses, because
  the reader takes the slots it knows by SLOT ORDER and never looks
  at the trailing ones. So adding a field is ONE commit; moving a
  shape is two — one that stops the door refusing, one that moves it
  and restores the door — because there the STANDING binary carries
  the old rows and refuses the new package while compiling it. The
  seed is a THIRD generation with the same rule: `make seed` rides a
  MOVING commit, and a merge that brings an older seed needs it only
  when a shape moved.
  AND THAT LAST SENTENCE WAS WRONG, BY ITS OWN AUTHOR, ONE SLICE
  LATER. Growth needs no refresh WHILE NOTHING READS THE NEW FIELD —
  and the refresh is owed by the FIRST READER, not by the grower. B2c
  appended `Variant.fields` and crossed unassisted, which is the rule
  working; H2's `@derive(Fingerprint)` then READ that field, and the
  committed seed — older than the growth — refused with
  "`derive` index 3 is out of bounds (length 3)" at the annotation.
  Nothing moved; the seed simply writes three slots where the derive
  reads four. So the obligation does not ride the commit that grows a
  shape, it rides the commit that first CONSUMES it, and those are
  usually different commits by different hands. THE TELL IS THE
  ARITHMETIC IN THE REFUSAL: an index one past a length, named at an
  annotation, is a seed behind the source — never a defect in the
  derive.
  WHAT AN OLDER COMPILER OWES A NEWER PACKAGE IS NOTHING, and the
  program hears it: the old compiler writes the slots it knows, so a
  program reading a field it never wrote reads past the row's end and
  the annotation refuses, naming itself. That honest failure is why
  growth needs no ceremony — and the rule was WRITTEN as two commits
  for everything, which cost three rungs of a build ladder twice in
  one day before the growth case was told apart from the moving one.
  AND THE DOOR CHECKS THE PACKAGE, NEVER THE WRITERS. It holds the
  LOADED shapes to the rows and says the exhaustive matches are the
  guarantee past it — but a WRITER is a positional list literal, not
  a match, so nothing compared `meta_of_fn`'s slot count to the `Fn`
  row's. Growing `Fn` by one field and forgetting that one writer
  produced a 4-slot value where the record declares 5, with the
  boundary green: "A HASH THAT FORGETS A PAYLOAD" in the crossing's
  clothes, a field added after the writer was written, leaving NO
  MARK at the site. Every outbound record goes through `written`
  now, held to the SAME rows the reader is.
  AND A FAILED LIFT IN THE `Declares` PATH WAS SILENT. The same
  defect SPOKE as F2070 under a VALIDATES annotation and said
  NOTHING under a DECLARING one: `materialized` answered `[]` and
  the only evidence was F3000 at the USE SITE of a name nobody
  minted. One mechanism, one loud door and one mute one, and the
  mute one is the door every `@derive` takes. All three doors read
  one `unsettled_label` now.
- A NODE VARIANT IS APPENDED, NEVER INSERTED. A `rule`'s pattern is
  baked into the compiler as constants by the compiler that BUILDS it,
  and its `shallow` fold names each node kind by its POSITION in
  `Expr`/`Stmt`/`Pat` (`@derive(Matchable)`). Insert a variant mid-enum
  and every later one moves: the product's baked shapes carry the old
  positions while it computes the new ones, `match_node` trusts two
  equal shallows to share an arity, and the product traps checking its
  own tree ("index 0 is out of bounds (length 0)" in `match_kids`,
  under `rule_candidates`) — the generation law with a derive as the
  carrier. `Collect` hit it and moved to the end.
- Grammar authoring: A RAW BODY'S CLOSING BRACE IS A TOKEN. `grammar {`
  and a block word's `{` hand their body over whole, so the lexer emits
  the `}` that ends it too, and the rule consumes it (`"grammar" "{"
  s:STRING "}"`). Swallowing it left the line law's bracket stack
  holding a brace nothing closed. A `quote {` body is NO raw body —
  tokenized as source, parsed where it stands — and its rule consumes
  its own `"}"` all the same. AND A RAW BODY OPENED INSIDE A HOLE pays
  the hole's count too: the opener was counted against the enclosing
  hole when emitted, and the closer never passes through it. Line
  comments inside a raw body are the generated program's — a `}` in
  one ends nothing.
- A NAME-KEYED TABLE CROSSES MODULES. `impls_named` answers every
  `impl` filed under a NAME (the Decl relation's name bucket), so asking `@std.meta.Code`'s methods signed
  the compiler's own `impl Code` and dragged `features` into a
  derive's resolve. A consumer of such a table filters by what the
  impl's FILE can name (`aims_at`: `visible(file).types`), which
  needs no resolve. And the RECEIVERS pass is the third whole-program
  pass guarded against running inside a resolve (docs/2026_09_21_COMPILER.md §5).
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
  AND THE ANCHOR IS SHARED ACROSS RULES, not just within one, which
  this wording did not reach. `grammar` anchors a STATEMENT and an
  EXPRESSION both — `grammar_lit` contributes `primary = "grammar"
  "{" s:STRING`. A recovering statement branch on that keyword
  commits every `grammar {` line as a hole and eats it, and five fns
  in the compiler's own source "answered void", because `stmt` is
  tried before the expression floor ever sees the line. So the law is
  not "the last branch in this RULE" but THE LAST BRANCH ON THAT
  KEYWORD ANYWHERE: a statement anchored on a keyword that already
  anchors an expression must NOT recover. (The instance is
  lane/strings', ATTRIBUTED and not yet in this tree; the shared
  anchor is verified here.)
- Grammar authoring: a rule's GRAM TEXT and its BUILDERS are one
  unit — a builder named in feature A's grammar registers in
  feature A, never in a feature that might be absent (a partial
  assembly refuses on the dangling name — "no feature owns builder
  `x`"; the let_stmt tests assemble a PARTIAL list). The NODE may
  still be another
  feature's to give meaning: semantics_of decides ownership of
  MEANING, the gram decides ownership of PARSE.
- Grammar authoring: a KEYWORD ANCHOR merges before every
  NAME-HEADED branch, not merely before the spine's bare `ident`.
  `fns` contributes a call rule headed `primary = c:NAME "("`
  (features/fns/mod.av spells its argument list), so with `fns`
  ahead of `if_expr` the parser read `if (c) { }` as a CALL to a fn
  named `if` and reported "expected BREAK" — `if`, `match` and
  `while` all lost their parenthesised condition, the habit every
  C-shaped language teaches. `fns` now merges after the anchors.
- Grammar authoring: an EXPRESSION-HEADED statement branch before
  the floor (`t:expression "=" …`) parses every expression
  statement TWICE and leaks the failed attempt's nodes into the
  arena (node counts double, orphan exprs go untyped). An optional
  TAIL belongs AT the floor — `v:expression ( "=" a:expression )?
  END` — and the floor's builder picks the node (assignment
  landed so; the Assign node is built by expr_stmt, given meaning
  by mutation).
- Grammar authoring: expr_stmt is the stmt rule's FLOOR — its
  recovering expression-line branch merges LAST in language_features,
  and every statement feature lands BEFORE it (a keyword line like
  `type P = ...` otherwise parses as ident-then-failed-BREAK and the
  floor's @recover commits the hole, stealing the line).
- A feature never matches ANOTHER feature's variants — nor
  re-extracts its OWN literal's payload inline: all literal reads
  go through core's value protocol (`bool_of`, `int_of`, `text_of`,
  `pairs_of`, `elems_of` and their siblings, DERIVED onto `Expr` by
  `@derive(ValueProtocol)`, core/protocol.av) — one projection per
  category a feature reads WITHOUT its own dispatch. The protocol
  grows with value categories — a core event — never per feature.
  (N variants need N projections — payload types differ, and a
  unified return would be the parallel Value enum the doctrine
  refuses.) A protocol read is NEVER `?? <a
  plausible default>`: the dispatch guaranteed that payload, so
  absence is a DEFECT — `cx.lower_defect(e, ...)`, or the compiler
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
  3. PAY EVERY CONSUMER, which the compiler lists for you because
     each dispatch is exhaustive: `make vocab`'s Ins rows name
     them and `avra new ins` prints the arm each wants, across
     core/ir.av, interp, memory, ir_text, llvm and
     features/facts.av (does the runtime registry validate it) —
     plus a program test proving eval == native and the IR golden
     that shows the shape.
  4. THE GUARANTEE: those matches carry no `_ ->`, so a new
     variant breaks every one at compile time. The vocabulary
     cannot grow half-way, and a variant nobody implements cannot
     ship. Keep them catch-all free.
  5. AND THE PROTOCOL GUARDS THE WRONG DOOR ON ITS OWN — it gates
     ADDING a variant and says nothing about REPURPOSING one, so it
     refuses the honest change and would pass the dishonest one.
     THE SEQUENCE IS THE RECIPE, and no name belongs on it: seat
     retains were wanted distinguishable for a measurement; the
     HONEST form is a reason on `Ins.Retain`, and it was REFUSED on
     the four justifications, rightly, since a measurement is not a
     control shape, a value category, a memory boundary or a machine
     shape; the hatch below was then reached for, and its cost was
     noticed only while WRITING OUT WHY THE REFUSAL WAS RIGHT. Had
     the honest version not been refused first, the dishonest one
     would have been built and nobody would have looked. So the
     finding needs both moves and belongs to neither — REFUSE THE
     HONEST FORM ON THE RULE, THEN WRITE DOWN WHY, and the cheat you
     were about to reach for becomes visible in the writing.
     THE ESCAPE HATCH PASSES EVERY GATE: emit `CallRt("avra_rc_retain_seat", [r])` at seat
     sites instead. An existing instruction, an existing mechanism,
     one registry row, no vocabulary growth — and those retains stop
     being RETAINS to the compiler. The memory pass reasons about
     `Ins.Retain`; the largest category of the thing it exists to
     manage would become an opaque runtime call, and liveness and
     every later placement pass would silently stop seeing it.
     THE LAW: THE REASON A VALUE WAS PRODUCED IS NOT PART OF WHAT THE
     INSTRUCTION MEANS. Encoding it there — as a payload, a sibling
     variant, or a runtime row worn as a disguise — CORRUPTS the
     instruction rather than extending it. So the question the four
     justifications do not ask, and the one to ask first: does every
     pass that reads this instruction still read the same thing
     afterwards? A change that grows nothing and answers NO is worse
     than one that grows the vocabulary and answers yes.
     THE MEASUREMENT WANTED A COMPILER-SIDE COUNT INSTEAD — the
     memory pass knows why it emitted each retain at the moment it
     emits it (a cell store, an owned load, a pack, a scope's yield,
     a call seat), and counting them needs no IR at all.
  The backend and memory pass stay functions of the IR, dispatching
  on shapes, never on features.
- THE VOCABULARY SEAM RULE — which shape a new vocabulary takes,
  decided by ONE question: is the item DATA or BEHAVIOR?
  DATA (a runtime fn: name, param kinds, ownership) -> a REGISTRY
  ROW: `rt_sigs()` is ONE PLACE holding rows and five consumers
  QUERY it;
  adding is one row plus one C body, nothing dispatches. ITS
  SPELLING IS NOT `table<Row>`, and reading "table" as the literal
  cost a lane a design round: `rt_sigs`'s WIDE rows are struct
  literals in a list, while `width_rows`'s NARROW ones are a
  `table`. A `table` buys ALIGNMENT and a multi-line cell SPENDS
  it, so the row's width picks the spelling — both are registries.
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
  `cx.open_region`/`arm_end`/`close_region`, `loop_start`/`loop_cond`/
  `loop_end`, the walk (`opened`/`counted`/`turn_*`), the cells,
  `const_int`/`const_bool`, `measured_reg`/`measure_of` — never a
  raw `cx.emit(Ins.IfStart…)` or `Ins.LoopStart`. A TWO-ARMED REGION
  IS ONE EXPRESSION: `cx.region(c, e) { cx -> … } else { cx -> … }`,
  `region_as`, `presence` (the present arm handed what the value
  carries), `void_region`/`void_branches` — the brackets spoken once
  inside the verb, so no site can mismatch them; the open/arm/close
  verbs remain for folds and switches. The block takes the context
  as a `mut` seat heard from the slot, never as a capture. RUNTIME
  CALLS route through ONE door too: `call`/`call_at`/`call_void`
  mint-and-emit `Ins.CallRt(Void)?`, and every row's OWN generated
  method (`cx.<name>(sh, args)`, `features/rt.av`, from
  `core/rt_namespace.av`'s projection of `rt_sigs()`) calls through
  one of the three — a bare `Ins.CallRt(dst, "avra_x", args)` outside
  them is style.raw_rt_call's own refusal, and a misspelled or wrong-arity call
  through the generated method is the ordinary "no method"/method-
  arity refusal (F2030) at typing, for free. EVERY OTHER VALUE-
  PRODUCING SHAPE mints and emits in ONE call too, the same
  `verb(sh, …)`/`verb_at(e, …)` split as `call`/`call_at` — a fixed
  shape (or an explicit `TypeId`) beside a node's own answer type:
  `bin`/`bin_at`, `un`/`un_at`, `pack` (a `TypeId` always, no site
  needs the node's), `call_decl`/`call_decl_at` (a declared fn's own
  symbol — never a runtime row, that is `call`), `call_ptr_at` (a
  call THROUGH a register holding code), and the literal twins
  `const_int_at`/`const_bool_at`/`const_str_at` beside the fixed-shape
  three — a source LITERAL's own node may carry a NAMED seat's type
  (a literal fills a named seat directly), never the raw scalar the
  fixed forms mint at, so a literal's defining register needs the
  node-tied verb. A raw `let dst = cx.mint_shape(sh); cx.emit(Ins.…
  (dst, …))` outside `emit.av` is style.raw_mint_emit's refusal; a shape with only
  ONE call site (`FnAddr`, `ConstFloat`, a bare uninitialized
  `Alloca`) has no covering verb and stays a two-statement pair, and
  a site whose one register answers several branches — a mint shared
  across match arms, a mint at neither a fixed shape nor a node's own
  type — is licensed at the site. Two
  engines read one instruction stream by construction; style.raw_region ratchets
  the raw brackets, style.free_state_verb the free verbs, style.raw_rt_call the raw runtime-call
  string, style.raw_mint_emit the raw mint-then-emit split, and the vocabulary grows
  with the next shared shape.
- A DERIVE'S FILE IS TYPED WHILE THE ANNOTATED FILE IS STILL
  REGISTERING, so it must name nothing that file declares. Running
  `@derive(X)` over a declaration in file A types the file that
  declares `X` — the WHOLE file, not just the trait — and A's own
  impls are half-registered at that moment. The failure is SILENT and
  accuses an innocent: `@derive(Rebuild)` on `Expr` in core/nodes.av,
  with the trait beside the walk in core/rebuild.av, made every
  `impl NodeStore` method in nodes.av VANISH — 51 diagnostics of the
  form "`NodeStore` has no method `hole_stmt`", all pointing at
  rebuild.av, none at the annotation. `methods()` already refuses to
  MEMOIZE a table it cannot complete (workspace.av); what it cannot
  do is stop the half-table from being READ. The remedy is the shape
  `core/protocol.av` had by accident and `core/rebuild_derive.av` now
  has on purpose: A DERIVE STANDS ALONE IN ITS FILE, with `@std/meta`
  and nothing else. The generated code may still call the annotated
  file's neighbours — that resolves later, at ordinary typing.
- A TYPE IN A PASS IS SPELLED, NEVER REBUILT: `cx.type(List<string?>)`,
  `cx.type(Map<string, want>)` — a type literal, the type in its own
  spelling folded ONCE by its receiver's `interned` (core/types.av's
  `TypeLit`); a name that spells no shape is a HOLE, the `TypeId`
  binding it names. `intern(Type.Opt(intern(Type.Str)))` is style.interned_by_hand. The
  receiver is any value with `interned`: the registry, TypeCx,
  LowerCx, Decls. A declared type has no spelling — bind its id and
  name the binding.
- THE IR's BOOL LAW (ours, enforced by the evaluator): `&&`/`||`
  are never `Bin` over bool registers — they are lazy regions
  (`IfStart … ArmEnd … RegionEnd`); a `Bin(Or)` on bools is the
  defect "a non-equality op reached bool operands". And THE MINT
  LAW: a register is DEFINED in the order it was minted — mint
  operands first (`let tag = cx.tag_of(v)` before minting the
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
  walk lives (compiler/typing.av's `impl TypeCx`).
- Keywords are never listed by hand: they derive from the assembled
  grammar's identifier-shaped literals (`g.keywords()`, a method on
  a Grammar VALUE — Avra has no type-qualified call) — a feature's
  gram fragment IS its keyword claim.
  A feature owning a STATEMENT kind also impls `StmtSemantics`
  (`stmt.av` or `semantics.av`) and joins `stmt_semantics_of` — the
  drivers' one statement loop reaches it there.
  Start a feature with `avra new feature <name>`; prove it with a
  program test (`<feature>/tests/<name>/<name>.av` + `.expected` — a
  program gets a directory of its own, so its names are its own,
  which `avra test packages/std-avrac` runs). `make gate` is
  the bar. A program test shows its FINAL statement's expression
  only, and only when that statement IS an expression, and
  an interpolation hole prints scalars and strings only — a list
  is shown through `join`, an index or `length`.
  A program whose proof is a TRAP gets `<name>.refuses` (the voice it
  must speak) instead of `.expected`; `avra test` runs it as a CHILD
  in both engines and passes it only on exit 2 with that voice on
  stderr. Either marker makes its file a PROGRAM, not a module file:
  the entry's law (`lower.entry_only`) never refuses its statements,
  so `avra run`/`build` on one program test works beside its siblings
  (`Workspace.is_program`, suite.av — discovery reads the same markers).

- The CLI: each subcommand is ONE file in
  `packages/cli/src/commands/`, exporting `command <name> { … }` —
  an `@std/cli` component instance, a declaration imported by name —
  and `cli/src/main.av` only composes them in `cli avra { … }` — and hands a HAND-OFF's words (the stage word, then the
  link plans) to `cli/src/stage.av` before the app reads them: the
  suite's light phase is a re-exec, never a command, so no name
  reaches it. A new command is a new file plus one line. A command
  that takes a program is `phased(args, "<phase>", act)`
  (commands/phase.av): the act is a NAMED fn answering
  `Result<int, string>` — its exit code, or the report `phased`
  prints as exit 1 — and says only what its phase does.
- THE ROOT OF A PATH DECIDES WHERE A WRITE LANDS: "changes through
  `self` or a `mut` parameter reach the caller; changes to a local stay
  local." A writing call on a PATH opens every box BELOW the root
  unique (`path_copy_law`, the alias-copy fact `reg_of` reads), so an
  element another value also holds never sees the write, whatever the
  root. The root decides only whether the ROOT itself is written
  through: `self` and a `mut` seat are (the seat law — Swift's
  `mutating`/`inout`, Rust's `&mut`); a `mut` LOCAL is opened with the
  rest, and F2106 says so once per local. A FRESH seed is written in
  place (an identity its hooks capture stays one) unless its box is the
  binary's own data — a constant literal is — which `avra_cell_thawed`
  copies first. An unwrap is a step on the
  path (`h.r!.add(1)`), never a target itself. A local READ FROM a
  place is a copy already (spec 11.5). AN IDENTITY IS A `Cell`, NEVER A
  PATH: the compiler's shared structures (TypeRegistry, NodeStore and
  its arenas, Decls, Workspace) hold every table behind a Cell (core
  names `Cell` like any file; `list_cell`/`map_cell` seed one), so
  their writes are in-place Cell writes that no path opens — before
  that, opening `self.store.alloc_stmt(…)`'s path forked the executor's
  arena and the second generation trapped. A `mut fn` in a recursion
  cycle is judged writing by its CONTRACT, so a stale `mut` keeps every
  caller writing; F2050 names it. Witnesses: features/tests/
  borrow_root_path and features/impls/tests/alias_copy_adversarial_test.av,
  eval == native.
- THE CONDITION RUNS EVERY TURN: the memory pass settles what a
  `while` condition mints at each `LoopCond`, inside the loop. A
  release placed after the loop settles one turn's debts for all of
  them: every other turn's owned load leaked, and holding a
  reference it turned every write in the body into a copy — `while
  self.cells.length <= at { self.cells.push(v) }` cost 9 s and 17.5
  GB for 60k pushes, 0.26 s and 1.6 MB fixed; the gate's peak fell
  3.4 GB -> 1.9 GB. A loop region opens a scope for its condition;
  lower_test pins the placement.
- A `defer`'s FRAME IS ITS STATEMENT LIST: a scope bracket
  (`cx.scope_enter()`/`cx.scope_exit(r)`) or a statement-list arm
  (`cx.arm_stmts(stmts)`) — never a raw `Ins.ScopeEnter`/`ScopeExit`
  through a LowerCx, never a bare `cx.lower_stmts` inside an arm. A
  raw bracket is invisible to the frames, so a `defer` inside it
  runs at the ENCLOSING frame's end (an `if` statement's branch did
  exactly that). The seats' bracket in lower_fn/lower_lambda is
  `seats_enter/seats_exit` — no statement list, no frame — so a
  body's block is depth 1 and its close is the fn's TAIL. And an
  early exit calls `cx.leaving(answer)` (an answer — an `errdefer`
  runs behind its tag when it is a failing `Result`) or
  `cx.failing()` (the failure channel — `fail`, `?` — which runs
  `errdefer`s unconditionally) BEFORE its `Ins.FnExit`: the value is
  computed, the deferred calls come next, then the exit.

## The subset today

What our compiler REFUSES that the language will want. Each entry
is a sugar-backlog candidate, not a trap to write around: write the
form the compiler's help names, and when a site wants the missing
form, add the ask to the ROADMAP's sugar backlog naming the site.
Every entry was probed with `./avra check` on a scratch file and
quotes the refusal, so a re-probe is cheap; an entry the compiler
starts accepting is deleted. THIS SECTION IS A CACHE, and a
fifth of this file — every entry is a fact the COMPILER can answer,
which is why entries go stale unseen until a re-probe (nine moved in
one audit). RECORDED TRIGGER: when the docs campaign's
`lang/subset/*.av` lands as gate-verified program tests, this section
becomes a POINTER to them and stops being a hand-kept list. Laws that SPEAK are not listed —
reserved words (F3002 names the word and its status), a mutating
method on a non-`mut` binding (F2034), a lambda assigning to a
capture (F3005: captures are copies), a fn body reading a top-level
`let` (F3020: the const law), an extra method inside an `impl Trait
for` (F2032), an exported name declared twice across a module's
files (F3017 names both files), a pattern or construction with the wrong payload count
(F2015), a `DeclId` handed to a `StmtId` seat (F2000) — the
compiler's help is the note.

Syntax the grammar lacks:
- Struct destructuring in `let` (`let Sp { lo, hi } = s`):
  "expected `=` while parsing `stmt`".
- AN IMPORT IS SPELLED WITH DOTS, and this file writes package names
  with a SLASH throughout (`@std/io`, `@std/text`) because that is the
  package's name in prose. The `use` line is not:

      use @std.io.{read_text, write_text}
      use @std.text.{from_codepoint}

  `use @std/io.{…}` is F0100 "expected `.` while parsing `stmt`", at the
  slash. This is the ONLY spelling a reader of this file was given until
  now, and a cold-start measurement recorded it as the single failure of
  a subject that had read nothing else.
- `|` between or-pattern alternatives: "expected `}` to close the
  `match`" — the spelling is `or`, IN A PATTERN ONLY. As a BOOLEAN it
  does not parse: `true or false` is F0100 at the `or`, and `and`/`not`
  fail alike. The boolean operators are `&&`, `||`, `!`.
- Destructuring `enumerate()` in a comprehension (`[i for (i, m)
  in xs.enumerate()]`): F2005 "`enumerate` pairs only under a paired
  `for` head — pairs as values arrive with tuples". The head IS the
  `for` statement's: `[f(i, x) for i, x in xs]` pairs, `[f(i) for i
  in lo..hi]` counts.
- A GENERIC STRUCT LITERAL WITH EXPLICIT TYPE ARGUMENTS (`Box<float>
  { held: 1.25 }`): F0100 "expected BREAK while parsing `stmt`", at
  the `>`. A TYPED LET carries it instead — `let b: Box<float> = Box
  { held: 1.25 }` — and INFERENCE IS FINE without any pin: a generic
  fn over a generic struct resolves from its argument
  (`unwrap(bf)` where `bf: Box<float>`, probed at 5575a2e, both
  engines). Worth stating because the literal's refusal cascades into
  a "write the type explicitly" further down, and the pin that
  silences it is not the thing that was wrong.
- A DOUBLE `?` on a type (`int??`): F0100 at the FIRST `?`, wording
  by position ("expected `)`" in a parameter seat, "expected `=`"
  under a `let`, "expected BREAK" under a `type` alias) — the type
  grammar takes one `?` per name, so it has no spelling anywhere.
  It is REACHED through a generic all the same — `T?` over `T =
  string?` is a `string??`, a pair that keeps a PRESENT null apart
  from absence in every slot, and `??` unwraps one level
  (features/nullable/tests/nested_slots).
- A `table` literal without its row type: a bare `table { id: 1 }`
  reads as a STRUCT LITERAL of a type named `table` — F3000 "no `type
  table` is declared", with no hint that the row type is missing. The
  form is `table<Row>`, and its body is a PIPE-DELIMITED header plus one
  line per row, not struct syntax:

      let rows = table<Row> {
          id | name
          1  | "a"
          2  | "b"
      }
- A RECORD LITERAL AS A COMPONENT INSTANCE'S HEAD STANDS IN
  PARENTHESES: after a component's word, a name and then a brace is the
  head and the instance's block, so `counter id { key: id }` is
  `counter` over `id`. `tally Span { n: 2 } { extra: 3 }` is
  `build.failed` "the brace after an instance's head opens the
  instance's block, so `Span { … }` is no record literal here — a
  record literal as the head stands in parentheses: `tally (Span { …
  })`", and with no block after it `type.component_head` says the same
  — followed by `type.struct_fields` "`tally` has no field `n`", the
  block having been read as settings. A module's OWN component word
  before a parenthesis is a CALL (`type.lambda` "`nest` is a component,
  and a parenthesis after its word is read as a call"): its head is
  written bare (`nest self.depth - 1`) or bound first. Every other head
  (`if`, `while`, `for`, `match`, `if let`, `let … else`) takes a
  literal bare.
- A SEMICOLON between statements (`let a = 1; a + 1`): F0001
  "unexpected character" at the `;` — a statement ends at a line
  break, and a one-line body is `{ a }` with one statement. A
  TEMPLATE that spells `;` is refused at its own line (S4r homing).
- A RANGE TAKES METHODS — `(0..n).any(it == 2)`, `(0..n).find(it
  == 2)`, `(0..3).map((i) -> i * 2)` and `(0..n).all(it < 5)` all
  parse and run (avra-8sb5.65.3.4, eval == native) — but `.length`
  is `no property `length` on `Range``. The scan verbs faulted with
  `language.defect: a row without its seat survived typing` until
  that commit landed; the idiom bar's "scan with `any`/`find`"
  reaches a range directly now.
- A `once fn` with TYPE PARAMETERS (`once fn f<T>() -> List<T>`):
  "expected `(` while parsing `stmt`" — the once grammar takes a
  name and a parameter list only, and a `T` no argument can pin has
  nothing to answer anyway.
- A `once fn` answering a SCALAR (`once fn seed() -> int { 7 }`):
  F2055 "`once fn seed` answers `int`, which the runtime cannot
  keep" — the answer must be MANAGED, and `-> string` and
  `-> List<int>` both land. Its sibling law speaks too: parameters
  are F2055 "takes arguments — a `once` answer is one value for the
  whole process", and that refusal reaches the mistake whether or
  not the parameter carries a `mut`.
- A TRAILING BLOCK IN A HEAD: `if f(a) { x -> x } { … }` is F0100
  "expected BREAK" at the `->` — a head (`if`, `while`, `for`, `match`,
  `if let`, `let … else`) keeps its brace, so a call wanting a block
  there is parenthesised: `if (f(a) { x -> x }) { … }`. Everywhere
  else `f(a) { x -> body }` is `f(a, (x) -> body)`, a postfix like the
  rest (`xs.find { it > 1 } ?? 0`), and `else { … }` fills the next fn
  seat — provisionally: sugar 5 retires the word for the seat's name
  (`other: { … }`), since `else` reads as a branch whatever the seat is. Two shapes it does not reach: `a?.m { … }` (the chain lowers
  to a match — the block goes in the parentheses), and `(f(a)) { … }`
  widens `f(a)` (a paren group mints no node) where `f(a)() { … }`
  applies the answer.
- A SEAT DEFAULT (`fn f(a: int, n: int = 1)`) lands on a `fn`, `mut
  fn` and `static fn` seat and NOWHERE ELSE: `extern fn g(a: int = 1)`
  and a trait's `fn m(a: int = 1)` are F0100 at the `=` ("expected
  `)`" / "expected `}`"), a lambda's `(a: int = 1) -> a` is "expected
  `)` to close the group", and none of them says a default is what
  it refused. A NAMED argument skips any defaulted seat (`f(1, c:
  9)`), and a default reads no param beside it — `b: int =
  a` is F3000 "`a` is not defined". A fn VALUE of a defaulted fn
  wears every seat, so `let f = add` then `f(1)` is the ordinary
  arity refusal — its seats carry no names either (F2105).
- A GENERIC FN AS A VALUE: the PINNED spelling (`let f: fn(int) -> int
  = ident<int>`) is F0100 "expected BREAK while parsing `stmt`" — a
  pinned call is a CALL, so it wants arguments. The BARE spelling
  SPEAKS: F2033 "a generic fn is not a value — no single signature to
  wear", whose help writes the wrapper. Genericity is all of it — a
  non-generic `mut`-seat fn fills `fn(mut Cx) -> int` clean.
- The bare component form (`Cfg d { depth = 8 }`): "expected BREAK
  while parsing `stmt`" — `component Cfg d { … }` is the form.
  Instantiation is a STATEMENT: as a fn's tail it answers `void`
  ("the body answers `void` but `made` declares `Cfg`") — bind,
  then return the name.
- A SHELL `${VAR}` INSIDE AN AVRA STRING IS AVRA'S INTERPOLATION.
  `"echo ${HOME}"` is F3000 "`HOME` is not defined" when no binding
  has that name — and SILENT when one does: with `let HOME = "/tmp/
  not-your-home"` above it, the same line compiles clean and the
  command becomes `echo /tmp/not-your-home`. Spell a shell variable
  `$VAR`, which Avra leaves alone.
- `_` IS A PARAMETER NAME NOWHERE, and `let _ = f()` everywhere.
  `fn f(_: int)` is F3002 "`_` is a keyword — cannot be a name", help
  "pick another name", while `let _ = g()` and `.Bind(_)` are the
  ordinary spellings. A parameter a SEAT owns and the body never reads
  is `_q` — a leading underscore is a name, it compiles, and the idiom
  bar has always read that prefix as "unread by contract" (style.dead_parameter).
- A MAP'S KEYS ARE STRINGS ONLY: `Map<int, int>` is F2019 "a map's
  keys are strings, not `int`", help "other key types are recorded".
  It kills the obvious trie-node shape; key by the text.
- `++` IS NOT A LIST OPERATOR: `xs ++ ys` is F0100 "expected BREAK
  while parsing `stmt`" AT the `++`, and that is the WHOLE refusal —
  the fn draws no type complaint of its own, and typing is not
  suppressed here (a sibling fn's error reports in the same run).
  `xs.concat(ys)` is the spelling.
- `List` HAS `all`, NOT `every`: `.every(it > 0)` is F2030, `.all(it
  > 0)` compiles — which retires the double negative `![…].any(!it)`.
- A MATCH ARM SHARING THE OPENING BRACE'S LINE NEEDS A TRAILING COMMA
  when another arm follows (found by the HTTP lane, probed here).
  `match v { .R(o) -> o` with `.S -> "s"` on the next line is
  "expected `}` to close the `match`", reported at the SECOND arm —
  so the message points past the arm that needs the comma. Two forms
  work: the comma (`.R(o) -> o,`), and the whole match on ONE line
  (`match v { .R(o) -> o }`), which has no following arm to separate.
  Each arm on its own line is the ordinary spelling and parses.
- A PRESENT-BIND arm after a COMMA-ended arm (`null -> a,` then `v?
  -> b`): "expected `}` to close the `match`" — the comma continues
  the line and `v?` is read into it. AND A PRESENT-BIND ARM ENDING IN
  A COMMA (`v? -> v,` then `null -> 0`) refuses the same way, at the
  first arm. Separate such arms by line, as the program tests do;
  variant and literal arms take the comma.
- A match arm whose body is an EMPTY BLOCK (`1 -> {}` in statement
  position): `{}` is an empty map — F2013 "a `match`'s arms
  disagree: `void` vs the first arm's `{}`".
- A `\u` ESCAPE in a string literal: `"\uFFFD"` is not refused — the
  lexer keeps an unknown escape as its two characters, so the text
  holds a backslash and a `u`. Spell a code point with `@std/text`'s
  `from_codepoint(65533)` (sugar backlog: `\u{…}` escapes).
- A BARE NAME IN A PATTERN IS A CONST'S OR A BINDER'S, BY ITS
  BINDING — never by its spelling. `match c { escape -> …, _ -> … }`
  COMPARES where a `const escape` is in scope (declared, imported
  through `use`, a body's own) and no parameter or local of that name
  hides it; any other name BINDS what arrives. The const's type is
  the subject's own ("a `int` never matches `int?`" — unwrap first),
  it must compare by value ("`==` compares by value — …"), and a
  comparison covers nothing: the catch-all is still owed. THE HAZARD
  IS THAT ONE SPELLING MEANS TWO THINGS, and adding or deleting a
  const flips an arm with no edit at the arm. Two warnings stand
  where the flip would be silent: type.const_pattern on a match that
  ENDS on a const's name ("`escape` is a const here, so this arm
  compares" — add `_ -> …` or rename the binder), and
  type.unreachable_arm on any arm after one that takes every value
  ("this arm is never reached — `gone` above binds, and takes every
  value" — what a deleted const leaves behind). A name-turned-binder
  that is the LAST arm says nothing: it is a catch-all, as written.
  An arms block cannot START on a bare name (`xs.map() { tab -> … }`
  is a lambda's head) — write the `match` out. An `is` payload under
  `if` (`if k is .C(tab) { … }`) is a pattern seat like any other. A
  TEMPLATE'S bare name is judged in the file that WROTE the template:
  its const compares there, and a const of the same name in the file
  the code lands in never turns the template's binder into a
  comparison (features/enums/tests/const_pat_template).
- A match arm whose body is a bare STATEMENT (`.Unknown(t) -> fail
  E.Bad(t),`): F0100 "expected `}` to close the `match`" at the
  `fail`'s payload, then "expected EOF while parsing `program`" — and
  the whole file goes UNTYPED, earlier declarations included. An arm's
  body is an expression — brace it: `.Unknown(t) -> { fail E.Bad(t) },`
  (a block that leaves joins the other arms).
- `?` then a field on a Result (`get(i)?.name`): lexes as `?.` —
  F2023 "`?.` reaches into a nullable, this is `Result<P, E>`".
  `(get(i)?).name` says it, in a comprehension element too.
- `export let`: F3014 "`export` marks a fn, type, enum or trait — not
  this statement", help "drop the `export`, or declare the value as a
  fn". `export const` LANDED — a constant crosses as a const, and the
  help's "as a fn" reaches a `let` alone.
- `Result<void, E>` as a fn's answer: F2019 "a `Result` side cannot
  hold `void` yet" (help: "a verb that answers nothing but may fail
  is recorded — answer what it wrote"). A writing verb answers what
  it wrote instead —
  `@std/io`'s `write_text`/`make_dirs`/`remove` answer the path.
- A `mut` SEAT CANNOT BE ASSIGNED WHOLE, BY DESIGN, NOT PENDING
  MACHINERY: `a = a + 1` on a `mut a: int` parameter is F3005 "`a`
  is a `mut` seat — a seat is written along a path, never replaced
  whole", help "wrap the value in a `Cell<T>` and `.set(…)` it,
  write a path under it (`a.field = …`), or answer the new value".
  `Cell<T>` is the door for whole reassignment from inside a callee
  (docs/2026_09_22_S2C_CELL_SEAT_DESIGN.md).
- A TOP-LEVEL `const` IS A DECLARATION, like a fn: module-wide,
  order-free, exported only when it says `export`. Two in one module
  clash (F3003 in one file, F3017 across files); a `let` of the same
  name shadows it from that line on, in the sequence alone — a fn
  body reads the const. A const whose value asks for its own type is
  F2078; an annotated one settles and traps (F2062). The old entry
  here — "`const` in a MODULE file is F0902" — was stale twice over.
- A METHOD after `?` on a Result (`shell(line)?.run()`): F2023
  "`?.` reaches into a nullable, this is `Result<R, string>`". The
  chain DOES call methods now (`a?.m(args)` on a nullable), which is
  why a Result there reads as one `?.` and is refused for its type,
  not its shape. Parenthesise the propagation — `(shell(line)?).run()`
  — or bind it first. The field twin (`x()?.out`) is the same
  refusal; its help says "write `.out`", wrong for propagate-then-read.
- `fail` inside a `catch` ARM's block (`x catch e -> { … fail e }`,
  the block's statements on their own lines — a `;` is F0001): F2029
  "a `catch` arm answers the ok side: `T`, this is `Result<…>`" — the
  arm's block is not read as diverging. Write the statement `match`
  (`.Err(e) -> { … fail e }, .Ok(v) -> …`), as @std/process's three
  drivers do.
- A LITERAL OF `null` ALONE names no type WHERE NO SEAT NAMES ONE:
  `let xs = [null, null]` is F2006 "a list element takes its type
  from its value, and `null` has none of its own" — `{"a": null}` and
  `Cell.new(null)` alike. Any sibling with a type names it (`[null,
  7]` is a `List<int?>`), and so does the seat it lands in: a
  declared want (`let c: Cell<int?> = Cell.new(null)`), an argument
  (`count([null, null])` at a `List<string?>` seat), a field, a fn's
  answer. A generic seat nothing else pins (`g([null])` at `List<T?>`)
  is the same refusal, spoken once, at the literal.
- A KEYED LIST (`list xs by it.id { x -> … }`): "`list` takes no head
  value — name it at a statement (`list name { … }`), or write `list
  { … }`". Write `list { for x in xs { item { key: "${x.id}" … } }
  }` — the key rides the tree, but `SiteLowering` has no `Keyed` arm,
  so reconciliation is positional (avra-xubk.3).
- `derived x = …` and `query x = …`: "expected BREAK while parsing
  `stmt`" at the name — recompute in a `fn`, or hold a `state`
  (avra-8sb5.59.27).
- `@model type`: "`model` is not defined" — a plain `type` until the
  derive exists (docs/2026_09_24_DOCUMENTATION.md §4.0).
- A BUILT-IN TYPE NAME IS NOT A DOMAIN TYPE: `type Task = { … }` is
  "`Task` is a built-in type", help "choose another name — `int`,
  `string` and `bool` are the language's" — though `Task` is not
  among the three it names.

Wants the typer does not carry yet:
- A DECLARES ANNOTATION'S ARGUMENT IS A LITERAL. `@traced([1, 2])`
  is F2067 "`traced` generates declarations, so its arguments come
  from the source alone" — a generated name must exist while the
  file's names are still being resolved, so the crossing reaches
  only what the parse tree holds. A computed argument is the ask
  that arrives with quotes (S4); `Records`/`Validates` annotations
  take aggregates today, because they run after resolve.
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
- A `dyn` want reaches into `match` ARMS now, not yet into `if`
  BRANCHES — RETRACTED for match, re-probed 2026-09-24 (twice,
  independently, both engines): `match k { 0 -> P { … }, _ -> Q { …
  } }` under `-> dyn Show`, and a concrete arm beside a `null` arm
  under `-> dyn Show?`, both compile and run, eval == native. The
  `if` twin still refuses exactly as before: F2000 "an `if`'s
  branches disagree: `P` vs `Q`" — box it under `let x: dyn Show =
  …` and select among the lets. A CALL's seat DOES reach now too —
  `refused(p)` with `fn refused(e: dyn Error)` and a `ProcessError`
  in hand checks and dispatches (probed at `8519ae9`, answering
  `proc 2`); that clause is retired. Found live (not by re-probing
  this entry on a hunch) while writing `std-errors`' `Traced<E>`:
  `cause() -> dyn Error? { match self { .A(x) -> x, .B(y) -> y } }`
  over two different concrete Error types compiled clean.
- A trait impl over a GENERIC type (`impl Show for Box<T>`): F2031
  "`Box` is generic — a trait impl over a generic type is recorded,
  not landed". Inherent generic impls (`impl Box<T>`) land.
  NOT EVERY GENERIC TYPE WANTS THIS, though — `@std/errors`'
  `Traced<E>` (the `? context` propagation carrier) LOOKS like an
  instance and is not: its `cause()` deliberately answers the
  concrete `E` it holds, and a trait member's answer is fixed by
  its signature (`Error.cause() -> dyn Error?`), so no `impl Error`
  could ever return the narrower type — lifting F2031 would not
  change this. `cause`/`context`/`trace` stay `Traced<E>`'s own
  inherent methods for that reason, permanently, not as a workaround
  (found while writing avra-8sb5.40.1; the real want it surfaced is
  a bound on the type's OWN parameter, `type Traced<E: Error>` —
  ROADMAP's sugar backlog, not this entry).
- A BOUND LANDS ON A FREE FN'S PARAMETERS AND NOWHERE ELSE, so a
  GENERIC TYPE CANNOT READ ITS KEY. `type T<K: Tr, V> = { … }` and
  `impl T<K: Tr, V> {` are both F0100 AT the `<` ("expected `=`" /
  "expected `{`"), a generic METHOD is F2031 "generic methods are
  recorded, not landed" with or without a bound, and the body then
  refuses with F2030 "`K` has no known methods". `fn f<T: Tr>(v: T)`
  is the one form that works. So a generic CONTAINER keyed by a
  typed id has no spelling: key by the slot and keep the typed door
  on the owner (core's `SideTable`, and its accessors). Worth
  stating because F2030's help named the type/impl form until phase
  H — A REMEDY THAT NAMES AN UNPARSEABLE FORM sends the reader at
  the grammar, and the reader tries it, twice.
- Variant arms on a NULLABLE enum (`match k { .A -> …, null -> …
  }` over `K?`): F2013 "`match` chooses over an enum, found `K?`"
  — unwrap first (a `k?` arm), then match variants.
- `is` over a NULLABLE enum, the `match` entry's twin: `c is
  .Timeout` where `c` is `Cause?` is F2013 "`is` asks an enum for its
  variant, found `Cause?`" — unwrap first, then ask.
- A generic impl's body naming its own `T` in a local annotation
  (`let held: T? = self.rows[i]`): F2001 "`T` names no type".
  Leave that local un-annotated; a field read or `with` on a
  generic method's answer needs no bind at all.
- A BOUND METHOD AS A VALUE (`xs.any(self.rides)`): F2003 "no field
  `rides` on `S`" — a method name without parentheses is a PROPERTY
  read. A free fn is a value (`xs.any(big)` answers); the method is
  not. Write the wrapper `(k) -> self.rides(k)` (sugar backlog: a
  bound method as a value).
- `it` through a self-method wrapper (`xs.any(self.rides(it))`):
  F2033 "`it` has no element here — this seat takes `int`, not a
  fn" — `it` binds to the NEAREST call; write `(k) ->
  self.rides(k)`. `it is .A` binds fine. A PIPE STAGE IS SUCH A CALL:
  `users |> keep(it.age >= 18) |> names(it.name)` binds each `it` at
  its stage, where the same free call with no pipe feeding it
  (`keep(users, it.age >= 18)`) is "`it` rides a METHOD call's
  arguments — nothing binds it here".
- `join` over a list that is not text: `[1, 2].join(",")` is F2005
  "`join` reads a list of text, this one holds `int`" — map to text
  first.
- `==`/`!=`, `contains`/`index_of` and a literal pattern share ONE
  equality: a scalar, text, a tagged enum, or a record of ONE such
  field, compared by that field (a one-field record inside one
  compares through), so `Id { n: 1 } == Id { n: 1 }` answers true
  and `[a, c].contains(b)` finds it. Everything else refuses:
  a record of two fields is F2000 "`==` compares by value — a
  scalar, text, a tagged enum, or a record of one such field" with
  help "compare a field instead"; two different one-field types, or
  one against its own field's scalar, is "`==` compares matching
  types, found `Id` and `Other`"; the list scan is F2005 "`contains`
  scans by value — … — and this list holds `Pair`" (a nullable of
  a comparable type scans through presence) — spell the scan
  (`xs.any(same(it))`). Probed at d11ea0f. ENUMS SPLIT ON THE PAYLOAD, which
  nobody had written down: a payload-FREE enum compares fine
  (`.Timeout == .Refused` answers false), and one CARRYING a payload
  is F2000 with the help "match on it instead — only an enum carrying
  nothing compares, by variant".

Methods the runtime lacks (F2030 "`.reverse(…)` calls a method, and
`List<int>` has none" — the others read alike — or the map's F2000):
- `List.reverse()` / `sort()` — core's `reversed` is the helper
  (and a copy: nothing here mutates in place).
- `m["k"]` on a map: F2000 "`[...]` indexes a `List`, found
  `Map<string, int>`" — `.get(k)`, which answers `T?`.
- AN EMPTY LITERAL ADOPTS A NULLABLE AGGREGATE WANT NOW: `let xs:
  List<int>? = []`, `let m: Map<string, int>? = {}` and a `->
  List<int>? { [] }` tail all compile at 48e8e62 (probed). This
  entry is DELETED — it quoted F2024, stale since the want began
  deciding the literal. An empty STRING adopted `string?` before it.
  (`??`'s want is its NON-nullable answer type, so `parts(k)?.params
  ?? []` always compiled, unrelated.)

Runtime facts, ours to ratify:
- `Bytes` IS NOT A LIST AND `bytes()` HAS TWO ANSWERS. `b[0]` is
  F2000 "`[...]` indexes a `List`, found `Bytes`" — the octet read is
  `b.at(i)`, answering `int`, and it TRAPS past the end ("index 99 is
  out of bounds (length 3)"), so absence is not how a range error
  arrives. `.length` reads. AND THE ANSWER FOLLOWS THE RECEIVER: a
  string's `.bytes()` is `Bytes` (every text is octets), a
  `List<int>`'s is `Bytes?` — an element outside 0..255 makes the
  whole answer null, so `let b: Bytes = [104, 105].bytes()` is F2024
  "`b` declares `Bytes`, this is `Bytes?`" and `.at` on the unwrapped
  value is F2030 "`.at(…)` calls a method, and `Bytes?` has none" —
  while a `List<Bytes>`'s GATHERS the parts and answers a plain
  `Bytes`. One name, three receivers, and only the octet reading is
  nullable. AND TEXT OUT OF OCTETS HAS THREE READERS, by what a bad
  octet should do: `b.text()` answers `string?` (null when any octet
  is not UTF-8), `b.text_prefix()` the longest whole-UTF-8 prefix
  (never null; the rest is `b.slice(prefix.length, b.length)`, and a
  stream holds at most one unfinished character there), and
  `b.text_lossy()` every octet, each ill-formed subpart one U+FFFD.
- A STRING's `.length` is a LOAD — the header carries the length
  (lane A), as a list's does; `while i < s.length` costs a load per
  turn, and style.restrlen_loop retired with the strlen it ratcheted. WITH ONE
  CAVEAT, NOW PAID: `str_len` read `(h && h->len) ? h->len :
  strlen(s)`, so an EMPTY box failed the truthiness test, discarded
  its own header and answered from a terminator instead. That was
  safe only because every text box is minted at n+1 with the NUL
  written (lane B probed all eight ways to make an empty string,
  both engines) — a CONVENTION OF THE CALLERS, not a property of the
  function, and a live bug the day a box is allocated at exactly n.
  It reads `h ? h->len : strlen(s)` now (44c36f1): a box that says
  its length is zero is telling the truth, and the fallback is for a
  pointer that is not ours.
- `split` DROPS a trailing empty segment and keeps a leading one:
  `"a.".split(".")` is one element, `".a".split(".")` two,
  `"".split(".")` is `[]`.
- A STRING HOLDS A NUL, ALL THE WAY. A NUL cannot be written as a
  LITERAL (`\0` is not an escape — `"ab\0cd"` is six characters),
  but a program MINTS one with no foreign input at all:
  `@std/text`'s `from_codepoint(0)` answers a one-byte NUL,
  `from_codepoints` weaves it, and `+` and interpolation both carry
  it. It also arrives from outside — a file, an env var, a process's
  output, a database blob. EVERY text verb reads the header, so a
  NUL is an ordinary character: `ab\0cd` has `.length` 5, is UNEQUAL
  to `ab`, and `contains("cd")` answers true at index 3. A NUL is
  itself a findable needle.
  "EVERY" WAS A CLAIM ABOUT FIVE VERBS AND THERE WERE SEVEN.
  `starts_with` was not on f57372a's list and still walked with
  `strncmp`, so at EQUAL LENGTH it disagreed with `==` about the same
  pair — `"ab" + from_codepoint(0) + "cd"` was NOT equal to the same
  text ending `ce` and DID start with it — and a prefix longer than
  the text read as a prefix. `ends_with` was on neither list and was
  already right, which is what let the gap read as closed. Fixed here
  (`memcmp` over the header), pinned in std-text's NUL block. A
  UNIVERSAL written from an ENUMERATION is only as wide as the list
  that produced it, and the list came from the fix rather than from
  the vocabulary.
  THIS ENTRY SAID THE OPPOSITE UNTIL 927ed49, and half this file's
  NUL doctrine was written from it. Five primitives — `==`,
  `contains`, `index_of`, `split`, `replace` — WERE C string calls
  that stopped at the first NUL; f57372a made them walk the header
  under `memcmp`/`memmem`. The retraction is worth more than the
  fact: I wrote three guards and a law against this paragraph on the
  day it stopped being true, and no test disagreed because I had
  asserted rather than run. The scope a `Bytes` value would have
  carved out is gone with it — f57372a's own message says so, and
  the HTTP lane confirmed `Bytes` never rested on this premise.
  Probed both engines, minted and foreign alike, before and after.
- `avra run` INTERPRETS ON ITS OWN STACK: a call saves the caller's
  place on the machine's stack and never recurses on the host's, so a
  50000-deep recursion runs (it trapped at 400 while the evaluator
  recursed natively). A runaway traps at 100000 ("recursion too deep —
  100000 nested calls"); a const settlement meets its memory budget
  first (F2061). Measure, never guess, when either moves. AND IT ENDS
  AS A NATIVE PROGRAM ENDS: lines stream as printed (`run_live`), a
  trap says `avra: <words>` after them and exits 2.
- `parse_int` TAKES EXACTLY `-`? DIGITS, NEVER MORE — no leading
  `+`, no surrounding space, no digit separator, no fraction or
  exponent, so `"+42"`, `" 42"` and `"4_2"` are all absent; the
  caller trims and strips a sign prefix first, on the two-hats law
  (a parser accepting two spellings of one number is the hazard).
  Past the ceiling on EITHER side answers absent rather than
  wrapping — except the smallest int itself, `-9223372036854775808`,
  which `parse_int` answers WHOLE though the LANGUAGE'S OWN INT
  LITERAL cannot spell it: the lexer's token grammar has no leading
  sign, so the unsigned digit run overflows one short of where a
  trailing `-` would land. The row is two calls over one guarded
  walk (`avra_str_parses_int`/`avra_str_parsed_int`,
  `avra_int_parse_walk` in avra_runtime.c) — `RtKind`'s one-scalar
  answer has no shape for a nullable int yet, so a presence question
  and a value question is the crossing, the way `avra_map_has`/
  `avra_map_get` already do it.

## How work lands

- ALL WORK MOVES THROUGH SEVEN COMMANDS, and nothing else touches main:

      sh tools/work new <name>   # a worktree ../avra-<name> off main, and its Sprite
      sh tools/work run <cmd>    # run it on this lane's Sprite, streamed, its exit status
      sh tools/work test         # what this branch touches, on this lane's Sprite
      sh tools/work land         # push, PR, queue — no Sprite involved
      sh tools/work status       # PRs and the queue; each lane and its Sprite
      sh tools/work sprites      # every Sprite at a glance; `--fix [name]` repairs
      sh tools/work done         # remove this lane, free its Sprite

  Main lives on GitHub (avra-lang/avra) and moves only through its merge
  queue: squash merges, linear history, no direct pushes. A local main
  only follows `origin/main` (the reference-transaction hook refuses any
  other update; a deliberate repair sets `AVRA_MAIN_OVERRIDE="<reason>"`).
- A PR TESTS ITSELF FIRST, AND THE QUEUE STILL TESTS THE TRAIN. A PR's
  own `test` check runs the SAME keepers, fmt, idioms and affected
  suites as the train, on the PR's own tree (`.github/workflows/
  checks.yml`). A PR has no cached compiler, so it BOOTSTRAPS from the
  committed seed — a derived cache never does (the generation law); a PR
  that ADDS SYNTAX cannot be bootstrapped by its base's seed, so it
  proves itself with the branch-local compiler and lands by the
  refresh-after rule. So a green PR check is the pre-enqueue proof, and
  a slip dies before the queue. The queue then builds main plus every PR
  ahead of it plus this one and tests that COMBINATION in ONE job on
  GitHub's runners (Ubuntu 26.04, LLVM 22, the image in `.github/ci/`) —
  the only place a CROSS-PR interaction (two individually-green PRs
  colliding on a latent bug) can be seen. Ten trains test at once; when
  one passes, it and every PR ahead of it land together (HEADGREEN). A
  failing train drops its PR with the log on the PR. Main's own push run
  caches the compiler every train starts from.
- A PRE-COMMIT HOOK refuses staged `.av` that is not canonical; the fix
  it prints is `build/avra fmt --write <files>`. Never `--no-verify`.
- HEAVY RUNS GO ON SPRITES, ONE SPRITE A LANE: `sh tools/work run <cmd>`
  from inside the worktree. `work new` binds a free Sprite (`work bind`
  for a worktree that has none, `work done` frees it), and the lane's
  tree and compiler stay warm there between runs. Bootstraps, whole
  suites and censuses run there; the Mac keeps quick targeted checks and
  anything macOS-only. ONE RUN PER SPRITE, EVERY STEP BOUNDED: `run`
  answers the command's status, or 76 (busy), 70 (the compiler does not
  build), 124/125 (a bound; `--for <minutes>` raises the command's), 137
  (out of memory), 75 (the Sprite did not answer), 74 (the provider did
  not answer) — and a failure's last line begins with the one of three
  that failed: SPRITE, CONNECTION or COMMAND. A RUN BELONGS TO THE
  SPRITE, NOT TO THE CONNECTION: a supervisor there keeps its output and
  status and holds the Sprite awake while it lives, `run` only follows
  it, and a dropped connection is followed again from the byte it stood
  at — so an interrupt stops a run, a drop never does, a run is as long
  as its `--for` says, and the Sprite ends it at its bound whoever is
  watching (`work attach` follows again, `work stop` ends it, `work
  done` ends it with the lane). `sh tools/work sprites` shows all of
  them in seconds.
  A RUN ANSWERS ABOUT THIS WORKTREE OR NOT AT ALL: rsync carries files
  to the Sprite, a file the worktree no longer has is removed there by
  name, and the Sprite's manifest (every path and its hash) must equal
  the worktree's before anything starts — else `SPRITE — sync:` and 75.
  What a run wrote is left: `build/`, `.avra-cache`, anything git ignores.
  WHAT ENDS A RUN EARLY IS MEMORY, NOT TIME: a twenty-minute exec holds,
  chatty or silent, and thirty-two spinning processes leave a Sprite
  answering in a second — but a Sprite says 16 GB and a balloon holds
  half, more while it idles (3.3 to 7.3 GB were free to a run), there is
  no swap, and under about 250 MB the whole machine answers nobody for
  minutes. The Sprite's keeper ends a run at 600 MB (137), and every run
  says what it had to start with. A SPRITE WITH NO SESSION AND NO HOLD
  IS SUSPENDED WITHIN SECONDS, MID-WRITE IF NEED BE, which is why
  nothing runs there detached without the hold; one silent for minutes
  has lost its filesystem and is destroyed and created again
  (provisioning is `run`'s first step, from `.github/ci/packages.txt`).
  WHAT HOLDS A SPRITE AWAKE WITH NOBODY ATTACHED IS ITS TASKS API AND
  NOTHING ELSE WE TRIED, measured over 400 s without contact: a task
  refreshed each minute, no gap; a detached TTY session that prints, no
  gap; a running service, a 372 s gap; outbound traffic, frozen at once;
  an exec from outside every 20 s, one tick each. And a task's name is
  lowercase letters, digits and dashes or the Sprite answers 400 — a
  run is named after the machine that began it, capitals and all, so the
  hold is asked under a name made to fit and ITS ANSWER IS READ. A run
  that stood still says for how long in its own output, and `work
  sprites` shows it beside how long the run has been quiet.
- A BRANCH IS REBASED ONTO `origin/main` ONLY, never onto another
  unlanded branch: that lands the other branch's work unverified. A
  branch built on a stale local main moves with `git rebase --onto
  origin/main main <branch>`, which carries only its own commits.
- A PID IS CHECKED BEFORE IT IS KILLED. A recorded pid is reused once
  its process exits; read `ps -o command= -p <pid>` first.
- A TOOL IS RUN FOR REAL ONCE BEFORE IT BECOMES A DEFAULT. Fixtures
  prove the logic; a live run proves the path (a 62 MB upload hit a
  30 s client timeout that no fixture could reach).
- A GATE FLOOR IS RELATIVE (N − k), NEVER AN ABSOLUTE COUNT: the total
  moves when a branch deletes files, and an absolute floor then fails
  correct work.
- A CHANGE THE COMPILER CHECKS ABOUT ITS OWN SOURCE (a renamed type, a
  new license form) lands as a BRIDGE first: main's compiler must build
  the branch, because the seed and the train's own build both use it.

## Working discipline

- NOTHING WE RUN TAKES MORE THAN A COUPLE OF MINUTES. Every command,
  build, wait and poll is bounded to ~2 minutes; the ONE exception is a
  full test run, which is ~5 minutes and runs on a Sprite. No `sleep`
  chains, no 10–60 minute timeouts, no loop that polls `main` or a build
  to infer progress. Break work into bounded steps: kick a long job off
  as ONE bounded background command, do useful work, then check ONCE. A
  `work wait` for a landing is bounded to a couple of minutes per call,
  never an hour, and it reads the PR's merge-queue state, never `main`.
  A lane that blocks for minutes waiting is a defect in the lane, not
  patience. (Owner rule, 2026-10-02: an 18-minute `sleep` loop waiting on
  `main` deadlocked the merge queue — main could not move because that
  lane's own PR was failing the train.)

- GITHUB'S RUNNERS ARE THE ONLY GATE. `tools/gate_changed.sh` is the
  train's checks in one definition — the static keepers, `fmt --check`
  on the changed `.av`, `check --baseline` on every affected package —
  and checks.yml runs it on the PR and on the train. `tools/work land`
  checks formatting alone, with the compiler the worktree already
  holds, and asks no other machine; a lane that wants the whole gate
  before pushing runs that script through `work run`.
- A QUEUED PR WITH NO TRAIN IS STUCK, AND WAITING DOES NOT START ONE.
  An entry can sit in the merge queue with no `merge_group` run until
  it is taken out and put back; `work status` and `work wait` do that
  to one queued five minutes with no train, and say so.
- MEASURE, THEN CHANGE. `make census CMD="check <pkg>"` gives EXACT
  retain/release/list-write counts and, with the per-caller tables,
  who causes them; `AVRA_SAMPLE=<secs> sh tools/watch.sh 4000 ./avra
  …` samples. Trust the census over the sample — and read
  `sample`'s output with its tree characters (`+ ! : |`) in mind,
  since parsing it as plain indentation reports the wrong fn.
- A GEN-N VS GEN-N+1 DIVERGENCE IS FOUND BY TRACING, NEVER GUESSED.
  `AVRA_QTRACE=1` prints one stderr line per query-kernel event —
  every `Memo.ask` (family, arg, reuse/compute/cycle) and
  `Memo.settle` (family, arg, fingerprint) in @std/relation's
  engine/answers.av, every
  `Binder.declare` (name, file) in features/namespace.av, every
  failed `named_type` lookup in compiler/typing/declare.av, every
  file a check PARSES (`Q parse <path>`, compiler/program.av), every
  ATTEMPT a derivation makes (`Q attempt <turn> hold … reading <n>`,
  compiler/derive.av) — behind
  `avra_qtrace` (runtime/avra_runtime.c), inert without the flag.
  Run both binaries on the SAME input with `AVRA_QTRACE=1`, confirm
  each is deterministic against itself (diff two runs of the same
  binary — must be empty), then diff the two traces: the FIRST
  differing line names the query whose answer diverged first. Add a
  probe at the divergent query's own site the same way — one
  `qtrace(...)` call, removed once the cause is found.
- WHICH COPY FORKED IS ANSWERED BY A CLONE LOG, NEVER BY READING THE
  MECHANISM'S SOURCE. `AVRA_ALIAS_LOG=1` prints one stderr line per
  ACTUAL `box_clone` (`avra_cell_unique`/`avra_slot_unique`,
  runtime/avra_runtime.c's `alias_log_clone` — box_clone's only two
  callers, so nothing clones outside this log) — the caller's
  unslid return address (`atos -o <binary> <addr>` names it, no
  `-l` needed) and the cloned box's ELEMENT COUNT. THAT COUNT IS
  `a->len`, NEVER the header's `len`: every list, record and enum
  payload is one `AvraArray` shape (`array_clone` treats them so),
  and the header's `len` is that WRAPPER STRUCT's own fixed byte
  size (40, `sizeof(AvraArray)`) — constant regardless of how many
  fields or elements the box holds, so reading it answers "a box
  was cloned" and never "how big". The first draft of this log
  read the header and every clone in a 5.2M-line run showed length
  40 or 32 — a tautology, not a finding.
  AND DIFF THE LOGS BY SITE, NEVER BY PROFILE. avra-2y5c.5's gen-2
  break was read from this log as an acquittal — "the same functions
  at the same counts" in the good run and the broken one — while the
  broken run held ONE line the good one did not: a 44-field clone at
  `CheckCmd.run` (`mut ws = o.ws`, a workspace copied out of a record;
  see A VALUE ITS OWN HOOKS CAPTURE, under Rules). Five million lines
  that agree hide the one that forks.
- A `check` HIT ON `.avra-cache` EXAMINES NOTHING, AND A SECOND
  BINARY ON UNCHANGED SOURCE CAN SILENTLY HIT THE FIRST'S ENTRY.
  `Workspace.checked`/`build_program` key their store by the
  COMPILER'S OWN BYTES digest (`compiler_print`, compiler/build.av)
  beside a `.avra-cache` directory, so building or checking with a
  SECOND binary over the SAME source can read the FIRST binary's
  kept warnings or kept binary outright — a differential build
  (`AVRA_ALIAS_EMIT=0` vs `=1` over one source, or any two-binary
  comparison) silently compares one binary's real run against the
  other's cache hit, byte-identical checksums included. `rm -rf
  .avra-cache` before every run whose ANSWER is being compared, not
  only before the first.
- ONE HEAVY PROCESS AT A TIME, in the FOREGROUND, under the
  watchdog: `sh tools/watch.sh 4000 make gate`. The machine is
  shared with a loaded desktop and has panicked twice under this
  tree — three concurrent `make test` runs once, and a background
  gate with other compiler runs beside it (a WindowServer watchdog
  panic). A gate is ~0.3 GB for twenty seconds; nothing else heavy
  runs beside it, and every suite, gate or whole-package check runs
  through the watchdog, which holds the machine-wide lock, kills the
  tree past its cap and prints the peak.
  THE LOCK IS THE LAW AND THE FOREGROUND IS ITS MECHANISM. "One
  heavy process at a time" means ONE PROCESS HOLDING THE WATCHDOG'S
  LOCK, and every heavy run is LAUNCHED in the foreground under it.
  When the harness moves a launched run to the background past its
  own window — `make gate` and `tools/integrate.sh` both outgrew a
  600s limit — that is NOT a violation: the lock still serialises,
  the cap still kills, the peak still prints, and three
  watchdog-wrapped runs were measured queued behind it with exactly
  one executing. WHAT IS FORBIDDEN IS WHAT THE PANICS ACTUALLY WERE:
  a heavy process OUTSIDE the lock, or one launched into the
  background IN ORDER TO RUN BESIDE another. Both panics are that
  and neither is a backgrounded watchdog — the first was three
  CONCURRENT `make test` runs, the second a `build/avra test`
  launched in the background to be sampled BESIDE two lanes' gated
  steps, with lane B's bare `./avra test <pkg>` the same night as
  the other bypass. Read the rule as the lock and it has never
  changed; read it as the foreground and a harness limit gets to
  shape the tree's proof.
  `./avra` takes that lock ITSELF for any package-scale run
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
  sampled, beside two lanes' gated steps — and lane B's bare `./avra
  test <pkg>` runs the same night were the other bypass: a package
  suite is a whole-package compile plus a linked binary spawning
  children, never a probe. AND KNOWING WHAT AN INSTRUMENT DOES TO A
  MEASUREMENT IS PART OF READING IT: under `AVRA_RC_GUARD=1` a box
  that reaches rc 0 is KEPT (runtime, by design — that is how it
  replays a dead box's life), so `AVRA_MEM_STATS` reads 1486 MB with
  `now == peak` and looks exactly like a total leak; the same run
  unguarded peaks at 1 MB with every category zero at exit. A lane
  nearly reported the instrument as the defect. `AVRA_RC_GUARD=1` only on
  small programs: its log is bounded but a guarded compiler run
  over a package is still a machine's worth. Scratch probes
  (`./avra check` of one file) are sub-second and need no lock.
  AND A PROBE LIVES OUTSIDE THE TREE: `./avra check build/scratch/x.av`
  under any directory with an `avra.toml` above it answers exit 0
  and NOTHING for a file full of syntax errors — the file is not a
  program of that workspace, so nothing is examined and nothing is
  said (a check that examined nothing, in the CLI's own clothes;
  filed the day it was found). Probe from the session scratchpad or
  `/tmp`, where a refusal actually prints.
- A PATCH SCRIPT that inserts before an anchor, or replaces `old`
  with `new` where `new` CONTAINS `old` (an `export` prefix, a doc
  comment), applies TWICE when re-run after a partial failure: the
  anchor is still there. Check for the new text FIRST, and let
  `grep -c` (never `-l`) say how many times a fn is defined.
  ITS SIBLING, WHICH CAUGHT ME IN THIS FILE: AN ANCHOR THAT OCCURS
  TWICE APPLIES TO THE WRONG ONE. A splice bounded by
  `t.index(start)` and `t.index(end)` where `end` sits EARLIER than
  `start` re-emits the span between them and leaves the original
  standing — so 2d49858 duplicated the very law it was correcting,
  and two entries with one name contradicted each other 55 lines
  apart. PROSE HAS NO GATE: no test, no build and no keeper reads
  it, and a MERGE RESOLUTION over prose fails the same way, since
  both sides can survive. THE CHECK IS ONE COMMAND, run after any
  prose splice and any resolution of one —
  `grep -n "^- [A-Z]" CLAUDE.md | sed 's/^[0-9]*://' | sort |
  uniq -d`, which must answer nothing.
- A TOOL that reads source line by line sees a multi-line `use
  a.{x,\n  y}` as a truncated statement, and one that scans "to the
  closing brace" then eats the code after it. Join continuation
  lines first; write an import on one line where it fits.
  ITS MIRROR, and it caught the author of this line: a tool that ends
  a body at the next LINE-STARTING brace eats everything after a
  ONE-LINE definition, which has no such brace. The mint keeper's
  first draft did exactly that over C and read twelve float helpers as
  minting, because a minter sat two definitions below them. THE
  DELIMITER IS NOT WHERE THE LAYOUT SUGGESTS — count the nesting, in
  either direction, and pin a one-line case.
- A SYNTAX CHANGE TO THE COMPILER'S OWN SOURCE runs in one order:
  write the new grammar in the OLD spelling, SAVE the standing
  binary aside (`cp build/avra build/avra.pre`), build the product
  with it, rewrite the tree by script, build again with the
  product, gate. The product refuses the old form, so a broken
  product leaves no compiler — the saved copy is the way back. And
  the script must never cross a SYMLINK into another tree
  (`packages/std-cli` was one, into bs2's source, and the rewrite
  changed bs2's file; it is a real file now).
  AN ADDED GRAMMAR ALTERNATIVE IS ONE, and its failure is worse than
  a rewrite's. Adding a branch that shares a leading terminal with an
  existing one is a defect in the ASSEMBLED grammar — "branches 1 and
  2 both begin with STRING — branch 2 is unreachable" (grammar/
  first.av) — and only the PRODUCT assembles it, so the first `make
  avra` SUCCEEDS: the standing binary knows nothing of the new rule.
  The second build refuses, and by then the first has already
  replaced `build/avra`, so the product refuses ITS OWN grammar and
  the lane has no compiler at all. The tree is fine; the compiler is
  broken, which is the reverse of a rewrite's failure. That is what
  makes `cp build/avra build/avra.pre` the whole protocol rather than
  a nicety — the HTTP lane's strings slice paid for this and its way
  back was a copy of ANOTHER LANE's product.
- ITS MIRROR, AND IT POINTS THE OTHER WAY: A REGISTRY ROW THE
  COMPILER'S OWN SOURCE DECLARES CANNOT BE GATED IN THE COMMIT THAT
  ADDS IT. A declaration naming an `rt_sigs` row is legal only to a
  compiler that ALREADY CARRIES the row — `crossing_law` exempts a
  row's name by asking its own `rt_sigs()` — so a tree that adds the
  row and declares it in the same breath is refused by every compiler
  that could build it: the standing binary, the committed seed, and
  therefore `seed-check` and `make bootstrap` alike. THE BRANCH CANNOT
  GATE BY CONSTRUCTION, and the first buildable point is a tree
  carrying BOTH the row and a seed that knows it.
  THE LADDER IS TWO LANDINGS, not two builds. FIRST the row alone,
  hosted `Unhosted` — which is TRUE, since the evaluator has no arm
  yet — plus the C body and whatever keeper table names it; that
  gates on the standing seed because nothing declares it. The seed is
  refreshed on landing. THEN the declaration, the `RtHost` variant and
  its arm, and the callers; that gates because the seed now knows the
  row. Splitting it is not ceremony: a single landing leaves main
  unbuildable between the merge and the refresh, and an integrator
  that gates the LANE hits the same wall one step later with the
  landing dead.
  AND A ROW WHOSE SEAT TAKES A BOX HAS THREE RUNGS: the row, its arm,
  its declaration. `crossing_law` exempts a row only when it is ARMED
  — an arm is what materialises the aggregate — so a compiler that
  knows a row `Unhosted` refuses a box at its seat exactly as one that
  has never heard of it. Probed at `590f8e3`, the rows known and
  `Unhosted`: `extern fn avra_gate_new() -> List<int>` is
  `type.host_seat` "the answer of `avra_gate_new` wears `List<int>`,
  which cannot cross to C", while the same row declared `-> ptr`, and
  every word seat, checks clean. So the arm lands with word and `ptr`
  seats alone — the evaluator's own source declares the row it arms,
  and a box there would need the armed compiler to build the arm — the
  seed is refreshed, and only then does a declaration spell the box.
  A PLACEHOLDER ARM IS NOT NEEDED AND SHOULD NOT BE WRITTEN. `Unhosted`
  already says what is true and already has its arm; inventing a
  temporary variant to delete next week is a comment about a point in
  time wearing code's clothes.
- A RECORD-LITERAL RESOLUTION IS A UNION OF FIELD LISTS, never either
  side's line. A merge that resolves a struct/record literal by taking
  ONE side wholesale silently deletes a field the other side added,
  and the compiler's F2010 ("every declared field appears exactly
  once") is what catches the loss. A record literal is the one place in
  a conflict where `--theirs` must never be taken whole: every other
  shape can be read and picked, but a literal's field list is merged.
  (Paid assembling phase D onto the milestone: `NodeStore`'s literal
  took the cursor's line and dropped main's `grammars:` field.)
- THE RECEIPT FOR A SLICE THAT REMOVES A RUNTIME SYMBOL IS `make
  bootstrap` GREEN, NEVER `make avra` GREEN. `make avra` builds the
  cli with the STANDING binary and copies the result; it never
  touches `bootstrap/seed.ll`, which is a COMMITTED artifact naming
  every runtime symbol it needs, the `avra_io_` names among them. So
  deleting a runtime symbol gates clean under `make avra`, twice,
  while the cold path is already broken — `make bootstrap` links the
  seed against the runtime and every removed name is undefined.
  Naming a package's object on the link line rescues only the names
  that SURVIVED into package C; one deleted by design exists nowhere
  in the tree, so only a SEED REFRESH restores the cold path, which
  is why that refresh rides the REMOVING commit and never a later
  chore. And the failed link DESTROYS `build/avra`, because bootstrap
  links straight at it (`-o build/avra`), so `cp build/avra
  build/avra.pre` is the whole protocol here too — and RUNNING OUT OF
  DISK is the same destruction by a second cause (2026-09-07: a lane
  stopped on ENOSPC).
  AND `make census` IS THE THIRD CAUSE, WORSE THAN BOTH, because it
  removes the compiler DELIBERATELY as step one and restores it with
  a trap that needs exactly the resources that just ran out. It killed
  one lane's compiler twice in an hour — once to an OOM kill, once to
  ENOSPC — and both times the trap's own `make avra` died with it, so
  the tree held no compiler at the moment the machine was least able
  to make one. A RECOVERY THAT REBUILDS IS NOT A RECOVERY UNDER THE
  CONDITIONS THAT BREAK THINGS; the recovery that worked was a COPY
  taken before the removal (`build/avra.gen1`, two commands back).
  Hence the tool saves the binary aside and restores by `mv`, and
  refuses early when there is no compiler to save.
  BUT THE FREE-SPACE NUMBER BREATHES, so ONE `df` READING IS NOT A
  DECISION. It went 4.7 GiB -> 651 MiB -> 3.1 GiB -> 2.1 GiB in
  minutes with NOTHING DELETED: macOS mints and releases swapfiles
  on the data volume in gigabyte steps under memory pressure, and
  `sysctl vm.swapusage` read 6.5 GB of 6.9 GB in use at the trough.
  So a low reading may be a swing rather than a budget, and CLEANING
  AT A TROUGH treats a symptom that is not there. What actually
  protects the binary is `cp build/avra build/avra.pre` and FEWER
  CONCURRENT HEAVY PROCESSES — the same serial discipline the
  watchdog exists for, which is also what shrinks the swings. It is the
  shadowing law one mechanism over: a target green because a
  DIFFERENT mechanism was doing the work. (The @std/io instance is
  the HTTP lane's, ATTRIBUTED — lane/http c8af70b, not in this tree;
  the mechanism above is verified here.)
- A CHANGE THE COMPILER MUST THEN READ REACHES THE PRODUCT ON THE
  SECOND BUILD — codegen is one instance, the FRONT END is another,
  and the wording used to say only the first. `make avra`
  compiles the source with the STANDING binary — ONE `make avra`
  ADVANCES THE COMPILER BY EXACTLY ONE GENERATION, because the recipe
  is one `./avra build packages/cli` and one `cp` over `build/avra`
  while the shim execs the binary already on disk (the Makefile's
  `avra` target). THE GENERATION IS THE LAW AND "THE SECOND BUILD" IS
  ITS CONSEQUENCE: change the recipe and the count goes stale while
  the rule does not. So a product built
  right after merging a memory-pass fix carries the fix as SOURCE
  but its own body was compiled by the pre-fix pass — it runs with
  the bug it knows how to fix. Lane A's loop-condition fix merged
  so: my product compiled the suite at 7 GB (main's at 1.2 GB), and
  its second build was killed at 4.2 GB — the leaky product could
  not even compile the cli.
  AND THE FRONT END IS THE SHARPER HALF, because there the first
  build PASSES. THE BUILD THAT SUCCEEDED WAS THE BUILD THAT LIED
  (the sqlite campaign's bitwise lane, three times in one slice): the
  standing binary knew nothing of `>>`, so it compiled the change
  happily; the failure arrived on the NEXT build, when the compiler
  that had learned to munch `>>` read `workspace.av` and lexed
  `Table<List<string>>`'s closing brackets as a shift. `make
  bootstrap`, not `make avra`, was the way out each time. A lane
  touching the LEXER must not read the codegen wording and conclude
  the rule is not theirs.
  AND A DIAGNOSTIC IS THE THIRD KIND, which this wording did not
  reach either: a refusal ADDED to the compiler fires on the
  compiler's OWN SOURCE during the very build that adds it. Making
  the declaring path speak turned a benign re-entry — a memo cycle
  the design calls "a recursive view that contributes nothing" —
  into two refusals of `@derive(Rebuild)` in core/nodes.av, and the
  source that fixes the CAUSE (a cycle wearing `Trap`'s name) could
  not be compiled by the only binary that had the voice. Not the
  seed, which is older; not `make avra`, which reproduces the
  refusal. THE WAY THROUGH IS THE GENERATION THAT DOES NOT YET
  SPEAK — a saved product from before the voice — which compiles the
  source silently and yields one carrying both the voice and the
  honest cause. So a change that makes the compiler SPEAK about a
  construct its own source contains is self-referential exactly as a
  syntax change is, and `cp build/avra build/avra.pre` is the whole
  protocol for it too.
  AND ITS SYMPTOM ACCUSES AN INNOCENT: the `>>` collision surfaced as
  "@std.avrac.compiler does not export Program" — from the file that
  DEFINES `Program` — and the `|` collision as "@std.process does not
  export Tool". Neither named the change that caused it. So ISOLATE
  BEFORE REPAIRING: stash, `make bootstrap`, confirm the clean base
  builds. That turns "main is broken" into "mine is broken" in one
  step, and it is how a red `make witness` on a stale binary was told
  apart from a red main the same day.
  The way out is a binary that already
  HAS the fix (main's `../avra/build/avra build packages/cli`, then
  `cp` to build/avra), then `make avra` once more to prove the fixed
  point (1.1 GB both times). Two rules: after merging a pass change,
  build TWICE before trusting a peak; and run a bare `build/avra`
  from another worktree with `LLVM_PREFIX` exported — the Makefile
  exports it, a bare shell does not, and the `[link]` row's
  `-L${LLVM_PREFIX}/lib` then names `/lib` ("clang failed linking")
  — and after `make build/libavra_runtime.a`, since a bare binary links
  the LIBRARY on disk, which a merge may have left behind the source
  (a missing `avra_array_sized` was that: the link failed, not the
  compile).
  And the watchdog's poll is not a wall: a fast leak reached 16 GB
  between polls before the kill — cap what you can, but never run a
  suspect product over a big input to "see".
- AFTER A LANGUAGE CHANGE MERGES, A LANE'S FIRST BUILD IS `make
  bootstrap`, NEVER `make avra`. `make avra` compiles the source with
  the LANE's standing binary, and a stale compiler cannot read the
  new syntax — so the build fails pointing AT the new code, which
  reads as "the merge is broken" when it means "my binary predates
  it". Main's refreshed seed already carries the change; bootstrap
  from it. The same staleness answers questions wrong before it
  fails: `./avra` in a lane is that same old binary, and it will
  re-verify a closed hole as still open.
  AND IT ARRIVES WITHOUT YOU DOING ANYTHING, which is the half a
  merge-shaped rule misses: in a worktree two sessions write to, the
  other session advances the branch and your BINARY is now older than
  your SOURCE, silently, with nothing failing. The sqlite lane probed
  `once fn seed(mut n: int)` and got a bare parse error; this tree
  answered F2055; both were right, because their binary predated the
  `( mk:"mut" )?` the rule gained in lane C's `mut`-in-a-fn-type
  slice. So A PROBE RESULT NAMES THE BASE THAT ANSWERED IT. Without
  that, a probe log is a historical document about a tree its own
  files no longer describe, and the entries rot in place while every
  one of them still reads as current. This is the attribution rule
  one axis over: that one asks WHICH TREE, this one asks WHICH
  VERSION of it, and receipts decay the same way for the same reason.
  AND A CORRECTION IS A PROBE RESULT TOO, which this wording reached
  only for LOGS. Told that `avra_exec_self` was the tree's only
  aggregate extern seat, I counted five and said so; the HTTP lane
  counted one. Both right — the other four died in their S4 and live
  on main. A count offered as a correction that does not name ITS
  base invites the other side to concede to a number that was never
  about their tree. When two people disagree about a COUNT of things
  in the tree, the first question is WHICH TREE EACH COUNTED, asked
  before either concedes.
- A SAFETY PROPERTY RESTING ON A CONDITION NOBODY STATED IS A
  DEADLINE, NOT A GUARANTEE. FIVE are on record, ONE now PAID, and
  the register is
  SPLIT ACROSS TWO FILES, which is why neither view is complete:
  doctrine instances land here, lane findings with their probes land
  in the ROADMAP, and a curator auditing one cannot see the other.
  HERE: `str_len`'s zero-length fallback, safe only by a CONVENTION
  OF THE CALLERS that a `Bytes` value ends — PAID at 44c36f1, and
  the way it was paid is the point: nobody met the deadline, a
  foreign-text design READ the entry and asked what the empty case
  would do. A deadline is paid by a new consumer arriving, not by
  the breakage arriving. And `parsed`'s early cutoff, sound only
  while compiles are ONE-SHOT.
  THERE: the pointer-constant guard, landed as "unreachable today"
  (and its condition ACTUALLY CHANGED hours later when `avra_ptr_at`
  made a pointer mintable; it survived only because the capability
  took a runtime-row shape rather than a constant fold, so by an
  unrelated design choice and nothing its author did); `plain`
  dropping a fn type's seat marks, safe only while a nullable fn type
  is unspellable; and @std/sqlite's `close(mut db)`, whose
  idempotence rested ENTIRELY on a `mut` SEAT writing through the
  caller's binding — PAID, and the way it was paid is the second
  half of the lesson above: NOT by meeting the deadline but by
  refusing the channel. A seat reaches ONE caller's place by the
  calling convention's leave; `Db` and `Stmt` hold their handle and
  their DONE mark in a `Cell` instead, so the write lands in one
  slot every copy reads and the property belongs to the TYPE rather
  than to whatever a seat copy comes to mean. A list element, a
  struct field, an enum payload, a lambda capture and a deeper
  frame are all carriers a seat could never have reached, and each
  is a case in the suite now. THE LOST DONE MARK IS THE HALF WORTH
  CARRYING: a lost handle traps, so it was the one on the register,
  while the same seat carried `Stmt.done` and losing THAT re-runs
  the statement and answers rows a second time with nothing in the
  answer saying so. When a deadline names one value riding a doomed
  channel, ask what ELSE rides it — the quiet passenger is the one
  nobody wrote down.
  So NAME THE CONDITION IN THE SAME BREATH — an unstated one is what
  makes the eventual breakage read as a new bug rather than an
  EXPIRY. A sixth instance is a CITATION of this line, never another
  paragraph; that is what this entry is for.
- ITS INVERSE, WHICH LOOKS ALIKE AND PRESCRIBES THE OPPOSITE: A FIX
  WHOSE TRIGGERING CASE CANNOT EXIST YET IS VERIFIED BY A TRACE, AND
  OWES A DEADLINE RATHER THAN A CASE. The law below says a check that
  has never failed is untested, so MAKE it fail. Sometimes you
  cannot. `str_len` trusting a zero length is unreachable today:
  `box_alloc` never yields a zero len (`size > 0 ? size : 1`), so
  only `sized_box(0)` mints one, and all eight of its callers write
  the terminator — both the old form and the new answer 0. A green
  test there proves an unreachable branch was not taken, which is
  theatre. THE TRACE IS THE VERIFICATION, and it is run in the
  BREAKING direction: trusting a header could only hurt by believing
  a box that claims zero while HOLDING CONTENT, and no such box
  exists by the same trace. THE ARTIFACT OWED IS A REGISTER ENTRY,
  not a test — the day a box is allocated at exactly n the branch
  becomes reachable, and on that day the old code would have been
  wrong. Telling the two laws apart is the whole skill: ask whether
  the failing case CAN BE BUILT. If it can, build it; if it cannot,
  trace it and write the deadline down.
- AND THE SHARPEST MEMBER, because it defeats the usual remedy: A
  SUITE CAN BE GREEN ON EVERY RUN, CORRECT ON EVERY CASE, AND SILENT
  ABOUT THE ASSUMPTION HOLDING IT UP — and NO ADDED CASE FINDS IT
  when the hostile case CANNOT BE BUILT. Seven fingerprint boundary
  attacks passed before a widening and after it, because every hole
  contributed the SAME NUMBER of elements, so the boundaries sat at a
  fixed stride nobody had written down; the widening was uniform, so
  they passed again. No non-uniform hole could be constructed, so the
  case that would fail did not exist to be written. THE TELL IS NOT A
  FAILING TEST, because there is none. What finds it is a question
  about SHAPE — does each sequence fold to ONE value or splice flat —
  where every probe asks about BEHAVIOUR, and a reviewer who CANNOT
  RUN THE CODE is forced to ask it. (Strings lane's, attributed. The
  ARITY law above is the fix, and this tree already pays it:
  `fingerprint_stmt` folds through `fp_list(param_fps(…))` rather
  than splicing.)
- A CHECK THAT EXAMINED NOTHING IS NOT A CHECK THAT PASSED. A keeper
  reading objects from disk examines nothing on a COLD TREE and
  reports success; a grep scoped too narrowly answers "absent" about
  a thing that exists — `avra_ptr_at` read as missing here because
  the search was confined to `packages/`, and it was in the runtime
  and the program tests. So A KEEPER COUNTS WHAT IT LOOKED AT AND SAYS SO:
  `tools/externs.py` already does ("N C source(s)"), `make idioms`
  reports its debt and not its coverage. The hazard is live because
  there are TWO LINK SITES — the bootstrap's hand-written clang line
  and `make avra`'s per-target prerequisites — and a hand-kept list
  let the compiler link an object it had never built, twice in one
  night. A keeper for that must read a DIFFERENT SOURCE than the
  Makefile: the manifests for the package list, `nm build/avra` for
  the compiler's. (Substrate lane's, attributed; the two sites and
  the idioms gap verified here.)
- ORDER, NOT GRANULARITY: when two requirements are opposite
  ORDERINGS around one event, no tuning satisfies both and TWO
  INVARIANTS do. A deadline already passed must fire BEFORE the child
  is polled, or `echo` under `ms(0)` still gets its word out; and a
  timeout's capture must hold everything readable WHEN it fired, so
  the last act before declaring is a DRAIN and the grace is a floor.
  A TUNED INTERVAL IS THE SMELL that two orderings are being
  approximated by one number.
  THE INSTANCE: a grace waited out after the child was reaped SPUN a
  core for its whole window, because the poll row's guard against
  spinning asked whether the CHILD WAS ALIVE where the question is
  whether the CALLER ASKED TO WAIT — so with nothing left to poll it
  returned at once and the driver looped hot. The fix moved no
  number: the row now waits whenever it is asked to, in every state
  of the child.
  AND THAT FIX ALONE LEFT THE WALL TIME WHERE IT WAS, which is the
  law demonstrating itself in two steps. With the burn gone the grace
  still waited its floor out for every command, because the loop's
  exit asked the CLOCK alone where the question needs TWO facts: the
  floor bounds how long a grandchild MAY still speak, and the pipe
  state says whether anyone is left to speak at all. The loop already
  asked the second question — AFTER itself. One invariant fixed the
  burn; only both fixed the wait.
  AND THE TEMPTING NUMBER WAS NOT THE TURN BUT THE GRACE — the turn
  was never consulted on that path, so shortening it would have
  measured nothing, while the spin lasted exactly the GRACE, so
  cutting that cuts the burn IN PROPORTION and pays for it
  by shortening the window a grandchild has to speak. A tuning that
  works is the dangerous one.
  AND ONLY A WITNESS THAT SEPARATES THEM CAN PIN IT: a wait and a
  spin take the same WALL time, so the law is tested in CPU.
- AN ASSUMPTION NOTHING HAS EVER TRIED TO VIOLATE IS NOT A GUARANTEE.
  A check that passes proves the arrangement it was handed happened
  to work; it does not prove the check would NOTICE. Two shapes,
  both verified here. THE UNEXERCISED KEEPER: `make vocab` guarded
  `RtKind` for the enum's whole life without once seeing it grow, so
  nothing ever tested that it looked for the right shape — and it did
  not, missing every `is .Variant` test. THE AGREEING ENGINES: `eval
  == native` proves the two engines AGREE, never that they are RIGHT.
  H2 and H3 both answer `1 2 2` on both engines where 11.5 demands
  `1 1 0` — the differential is unanimous and wrong, because
  agreement is a CONSISTENCY check while the LAW is the oracle. The
  gate's third leg does not rescue it: a program test's `.expected` is
  written by the same author from the same understanding, so it joins
  the consensus rather than breaking it. AND A THIRD BLINDNESS, from
  the HTTP lane: the engines can AGREE ON THE VERDICT AND DIVERGE ON
  THE VALUE. `max_capture: 1000` against `yes` answered `TooMuch` at
  the same cap in both, while the partial capture the caller reads
  was 679,786 bytes native and 52,035,584 evaluated — a 51 MB
  disagreement under a green differential, because the test asserted
  the DECISION. So A BOUND TESTED AFTER THE WORK IS A BOUND ON
  ACCEPTANCE, NOT ON THE THING IT NAMES: the drain emptied the pipe
  until it would block and THEN tested the bound, so the capture was
  bounded by the CHILD'S SPEED, which is exactly what differs between
  the engines. Ask for ONE BYTE PAST what is left and stop at the
  crossing — both answer 1002 for a cap of 1000. TWO MORE, from the sqlite
  lane's probes and re-run here. THE CALLEE-DEPENDENT ANSWER: a C
  `int` return writes 32 bits and ZEROES the upper half (`mov w0,
  #-0x1`) where a `long` writes 64 (`mov x0, #-0x1`), so an extern
  read through ONE 64-bit prototype answers 4294967295 for the first
  and -1 for the second — while this libc's `atoi("-1")` answers -1,
  because it happens to run through `strtol` and leave all 64 bits
  populated. A test that calls a REAL library proves only that THAT
  implementation widened. THE ORDER-DEPENDENT ANSWER: a variadic
  callee reads its argument from the STACK (`ldr x0, [sp, #0x10]!`)
  where a uniform trampoline passes it in a register, so calling one
  through the other returns the PREVIOUS call's value — 1111 when
  2222 was asked — and garbage when nothing ran before it. The first
  draft of that probe made the correct call FIRST and reported the
  broken path working: the check was fine, and its own first line
  rigged the arrangement it was checking. So when a check has never
  failed, ask what would make it fail and then MAKE it happen —
  restore the boolean and watch the keeper name the line, write the
  probe from the LAW rather than from the code. A green check whose
  failure has never been witnessed is an untested instrument — and the
  runtime's kind accounting is the dearest of them, wrong from the
  day it was written and found by CHECKING rather than by failing.
- AND A KEEPER HAS TWO SURFACES: what it REFUSES and what it
  ACCEPTS. Making it fail tests only the first. `tools/idioms.py`'s
  counted-refusal matcher listed `refused_n(` among the honest
  spellings while no fn of that name existed — a DEAD ALTERNATIVE:
  accepted by nobody, protecting nothing, quietly widening what the
  keeper permits, and invisible to every fixture that makes the keeper
  fail, because the keeper was working. So exercise each alternative a
  keeper ACCEPTS as well as one that breaks it — a matcher with N
  spellings needs N positive fixtures.
  THE LAW STOOD AND ITS EXAMPLE EXPIRED, which is the half worth
  keeping. `refused_n` LANDED at c515f04; the dead alternative became
  live and this entry went on naming it as the dead one, reading as
  current the whole time. And the alternative that was ACTUALLY
  missing from `COUNTED` was a different one — `refused_in`, the
  tree's own one-refusal verb (`refused_n(p, phrase, 1)`), which the
  matcher refused as an uncounted test. Nobody found that by grepping:
  it took WRITING a test with the honest verb inside a `then` block,
  which is the new-consumer law one rule over. An entry whose instance
  is a NAMED ARTIFACT owes a re-check the day that artifact moves —
  the law is evergreen, the example has a date on it.
  AND THE MECHANISM THIS LAW CALLS FOR DOES NOT EXIST AS FIRST
  WRITTEN: there is no `ACCEPTED` table in `tools/idioms.py`. What the
  tree holds is main's `CLEAN` table — the accept surface for
  style.refusal_uncounted_contains, style.unmutated_mut,
  style.dead_parameter and style.bool_comprehension — and the `COUNTS` list beside `COUNTED`, one
  matcher's worth of the accept surface; both are self-tested, and
  every other matcher's accept surface is still unexercised. Do not
  read this entry as saying every matcher's accept surface is guarded.
- A TEST WITH ITS OWN COPY OF THE LOGIC TESTS THE COPY, and the
  SYMPTOM IS WHAT MISDIRECTS. The externs keeper's self-test built
  its typedef map from an inline duplicate of the collection it
  existed to exercise, so its cases guarded a shadow of the rule.
  The tell was not a false green: a fix PASSED the tree and FAILED
  its own fixture, which reads as "the fix is wrong" and means "the
  test is not testing this". CHECK THE FIXTURE FIRST: the author of
  the duplicate, who had written it that morning and knew what it
  was, still spent TWO ROUNDS re-examining a correct fix before
  looking at the test — knowing the symptom does not defeat the
  instinct. It is a rule and its shadow disagreeing,
  which is the boundary law one level up, with the two sides of the
  boundary being a rule and its test. It was written in the same
  change that added the cases, to prove the tool honest, and nobody
  reading that change would have blinked. ONE DEFINITION, called by
  the tree and by its test; a keeper's fixture that cannot fail for
  the real reason is the untested instrument above, one level up.
- A PERFORMANCE DEFECT AND A SAMPLING TEMPTATION ARE THE SAME DEFECT.
  When a check is too slow to run over EVERYTHING, the next decision
  made is which subset to trust — and nobody records that the subset
  was chosen by the CLOCK rather than by the question. The receipt
  then covers what was fast to look at, which is not a property
  anything cares about. MEASURED HERE: `avra fmt` asked for the entry
  file to get a `FileId`, which forces the whole package to TYPE, so
  printing one file cost 2.5 MINUTES — and the honest receipt
  (`fmt(x) == x` over every file in the tree) became days. The
  pressure that creates is toward a CHOSEN CORPUS, which is how the
  case that would have failed goes unwritten; it is the
  hostile-case-cannot-be-built law with a stopwatch as the cause.
  Formatting moves no token that typing decides, so the fix was to
  PARSE and not analyse, and the tree-wide receipt went from days to
  minutes. THE TEST: when a check is about to be run on a subset, ask
  whether the subset was chosen by the QUESTION or by the RUNTIME. If
  by the runtime, the defect to fix is the runtime — the subset is a
  symptom, and shrinking the claim to fit it launders a tooling
  problem into a methodology.
- A CHECK CAN PASS *BECAUSE* OF THE BUG, and the obvious receipt for a
  ROUND TRIP is the one that does it. A formatter owes LOSSLESSNESS —
  `fmt(x) == x` where the input is already canonical — and the check
  every author reaches for first is IDEMPOTENCE, `fmt(fmt(x)) ==
  fmt(x)`. They are DIFFERENT QUESTIONS, and idempotence is not the
  weaker one, it is the WRONG one: measured here, `fmt` dropped every
  plain `//` comment and idempotence went GREEN precisely because the
  second pass had no comments left to lose. The bug made the check
  pass. 452 of 465 files carried a comment, so a `--write` behind that
  green would have deleted them tree-wide. THE TELL IS STRUCTURAL: a
  check that composes the transform with ITSELF can only see what
  survives the first application, so it is blind to everything the
  first application destroys — which is exactly what a round trip is
  supposed to be about. ASK WHAT THE TRANSFORM IS SUPPOSED TO PRESERVE
  AND COMPARE AGAINST THAT, never against the transform's own output.
  The family is wider than formatters: a serializer checked by
  re-serializing, a normalizer checked by re-normalizing, a migration
  checked by re-running it. This is the untested-instrument law in its
  sharpest costume, because here the instrument is not merely untested
  — it is REPORTING THE DEFECT AS HEALTH.
  AND TWO LOSSES NEED TWO GUARDS. `fmt` already refused a file with
  PARSE ERRORS, on the law that an error-tolerant parser answers a tree
  with HOLES and rendering it deletes what it could not read. That
  guard is right and does not reach this: the comment file parses
  CLEANLY and the RENDER is what loses. "Could not read it" and "read
  it and cannot say it again" are different failures.
- MACHINERY BUILT AHEAD OF A DECISION BIASES THE DECISION TOWARD THE
  SHAPE IT SERVES (lane A's, via lane C). The owner was asked whether
  a program may mint a pointer from an integer, and a correct unused
  `LLVMConstIntToPtr` wrapper was standing by for the constant-fold
  route — which aims an integer CONSTANT at a pointer register, the
  exact thing the pointer-constant law refuses. So the feature's
  first legitimate use would have ARMED a law hours old, and someone
  would have had to weaken it to let the feature through. A correct
  unused wrapper is not inert: IT ARGUES. The capability landed as a
  runtime row instead (`avra_ptr_at(address: int) -> ptr?`, one named
  door, a nullable answer) and the guard never armed.
- "THE PREDICTION DID NOT COME TRUE, AND HERE IS THE MECHANISM"
  BEATS "IT CAME TRUE". A prediction that lands can be luck; one that
  fails, explained, names a cause. The pointer-constant guard's entry
  predicted it would arm the moment a pointer sentinel became
  spellable. One is spellable now and it did NOT arm — because a mint
  is a CALL, its answer reaches a pointer register through `CallRt`,
  and no constant ever aims at one. That non-event with its mechanism
  is the better receipt, and it exists only because someone went back
  to check their own ledger entry against the tree.
- A DRAFT PARKED IN `packages/` IS IN THE COMPILER'S SOURCE, and the
  keepers read the TREE, not the commit. `seed-check` compiles the
  WORKING tree (`build/seed-check/avra build packages/cli`), so one
  untracked half-written file under `packages/` turned a gate red —
  GATE-STATUS 2, "the seed cannot compile HEAD — run `make seed`" —
  thirty-six seconds after it was saved, against a commit whose own
  gate had been green minutes before. THE SYMPTOM ACCUSES THE COMMIT:
  the words name HEAD and the seed, and nothing names the file. The
  isolation needed no build — `git status --porcelain` answered one
  line — but the reflex it interrupts is `make seed`, which would
  have rewritten a committed artifact to chase a file that was never
  in it. Park drafts in `/tmp` or `build/scratch` until they type;
  `packages/` is for code that compiles.
- A PROBE THAT TRUNCATES ITS OWN OUTPUT REPORTS THE ABSENCE OF WHAT
  IT CUT. `./avra check … | head -6` showed F3015 alone on an `export
  use` line, so this file recorded that the re-export law is never
  reached and that the entry needed a package to verify. Both fire —
  F3015 first, F3014 six lines below the window. The pipe was the
  instrument and it worked; what it SHOWED was incomplete, and
  absence-in-the-window was read as absence. So list the codes before
  concluding which ones there are: `grep -oE 'F[0-9]{4}' | sort -u`
  costs nothing and cannot lie by omission, where a `head` always
  can.
  AND `tail` IS THE SHARPER HALF, which this entry's wording missed
  by naming only `head`. A `head` cuts the LAST errors; a `tail` cuts
  the FIRST, and the first are the CAUSING ones — a bad manifest, a
  missing dependency, the parse error every later refusal cascades
  from. `./avra run <pkg> | tail -6` over a probe package whose
  manifest lacked a version and a dependency showed one "no method"
  line, and that line read as a defect in the `@derive` machinery
  that does not exist: the derive had never run at all. The author of
  this paragraph did that, in the session that wrote it. Both ends
  cut, and the cure covers both.
  THAT CURE HOLDS FOR LITERALS ONLY, AND IT FAILED HERE. Choosing a
  free fingerprint tag, `grep -oE 'fp\([0-9]+'` answered
  `102 105 108 109` — and 100, 101, 106 and 107 are taken, spelled
  `fp(if … { 106 } else { 107 }, …)`. A GREP FOR LITERAL VALUES
  CANNOT SEE A VALUE THAT IS COMPUTED, so four of ten were invisible
  and 106 read as free; only reaching for highest-plus-one out of
  habit kept a second collision out of the tree, and `make
  fingerprints` had just caught the first. THE GENERAL FORM:
  ENUMERATE FROM WHAT THE CONSUMER SEES, NOT FROM WHAT THE SOURCE
  SPELLS. The keeper reads that space correctly — it is what found
  the collision — so the honest way to ask "what is free" was to ASK
  THE KEEPER, not to grep the file it guards. When a question already
  has an instrument in the gate, a hand-rolled second instrument is
  not a shortcut, it is an unverified one.
- A NEW CONSUMER IS THE INSTRUMENT THAT FINDS A LOCALLY COHERENT
  DEFECT, and reading is not. The entry above says to make a green
  check fail; this is its half for the artifacts that are not checks
  — a heading, a directive, a projection, a WORD. Each of these was
  correct in its own frame and failed only against a use that did
  not exist when it was written: a "the well is dry" heading that
  closed a question a re-measurement reopened; a self-test wired to
  a COPY of the rule, found by a second fix disagreeing with its own
  fixture; a cycle-breaker directive generalised from one leak to a
  rule the code does not hold; "one table" in the seam rule read as
  `table<Row>` by the first person to design a registry from it; the
  memo kernel's cutoff, sound until something edits; a width keeper
  blind to a typedef until third-party C arrived. NONE IS VISIBLE TO
  A READER, however careful — locally coherent is exactly what they
  all are. So the way to test doctrine is to BUILD SOMETHING AGAINST
  IT and watch where it misleads, and the way to be useful to another
  lane is to say out loud where theirs did.
- IN A RECORDED TRIGGER, NAME THE OWNER OR NAME NOTHING (lane A's
  wording, via the HTTP lane). "lane A's X" is a ROUTING INSTRUCTION;
  "X, owner unconfirmed" is a question. The difference matters more
  in a trigger than in prose because a trigger is written to be ACTED
  ON — a wrong owner does not sit there being wrong, it RECRUITS. One
  read "fires when lane A's shared decimal-parse row lands"; a lane
  acted on the trigger rather than asking, and by the time it reached
  lane A it arrived as a dependency they were expected to schedule.
  The row is nobody's and unbuilt, and the `decimal` it had been
  conflated with is another campaign's deferred value type. NOBODY
  MISREAD ANYTHING: every step was a faithful read of the one before,
  which is exactly what a routing instruction does when it is wrong.
  (That trigger never reached main. Audited here on landing: the two
  triggers in these ledgers that name an owner were both confirmed
  with that owner directly.)
- ITS SIBLING FOR REVIEWS: A REVIEW REQUEST NAMES THE TREE THE CODE
  IS IN. "It is in your file, for your review" is false whenever the
  relevant half lives on the ASKER's branch, and it happened twice in
  one night — a `Hole` field and an `inert` column, both absent from
  main, both sent as changes to files this lane owns. THE FAILURE MODE
  IS A FABRICATED REVIEW: the reviewer cannot open the code, and the
  cheapest reply is "looks right", which is then banked as a review
  that happened. Both were caught by `grep`ping for the symbol before
  answering, which is a one-command habit and the whole defence. The
  reviewer's obligation is to check, and the asker's is to say WHICH
  TREE — a review of code you cannot see is worth less than silence,
  because silence does not get quoted back.
  AND THE CONSTRAINT IS SOMETIMES THE BETTER DESIGN: unable to
  re-mark a column that was not here, the keeper for it landed FIRST
  and passes vacuously, so the column arrives into a guarded tree and
  is certified from its first gated commit instead of being blessed
  and corrected later. Ask what the absence makes possible before
  waiting for the code.
- A RECEIPT FROM ANOTHER TREE IS LABELLED AS ONE. The laws here carry
  instances because an instance is what makes a law APPLIED rather
  than agreed with — so the instances have to stay checkable. One
  probed in this tree reads as fact; one from a lane's own tree is
  named as that lane's and stays ATTRIBUTED until the code lands
  here — AND THE LABEL EXPIRES WITH THE LANDING, or it sends the
  reader away for a receipt in front of them (the two-hats law's
  sqlite half). Mixing the two silently is how a file of receipts
  decays into claims, and even the true lines stop being trusted.
- A COUNT FROM A PACKAGE SWEEP IS LINES, NOT SITES. Checking one
  package reports its DEPENDENCIES' warnings too, so summing the
  twelve counts every shared site once per package that reaches it:
  F2040 read 361 by the sum and 191 deduped by `file:line`, and a
  single package's figure quoted as "the tree" is a third number
  again. DEDUP BY IDENTITY BEFORE A NUMBER ENTERS A LEDGER — a count
  is a claim, and this one bit two lanes the same day, in opposite
  directions, one of them while correcting the other's scope.
  THE GENERAL FORM: A MEASUREMENT GENERALISED PAST WHAT IT MEASURED
  IS A CLAIM, NOT A FINDING. The sqlite lane measured a PROGRAM,
  where an entry exists, and reported that a LIBRARY never lowers its
  uncalled exports — but `union` seeds from every declared body
  exactly when `entry == null`, which is what a library is, so
  `check` over a package already lowers all of them. The probe was
  real and the sentence it became was not. Name the scope a
  measurement covered, and the generalisation past it turns back into
  a question.
- MEASURE WHAT A THING DOES BEFORE EXPLAINING WHY TWO DIFFER. The
  tree is built of parallel structures that mostly agree — sibling
  grammar rules, registry tables, exhaustive matches, doctrine
  lists — so a difference between two of them READS as drift, and
  the reading is often wrong. Four times in one day: `p: mut ptr`
  refused, so "a `mut` seat does not parse" (the spelling is `mut`
  before the NAME, and half the pass fns in the tree carry one);
  three parameter rules differed, so "two siblings drifted" (a
  `once fn` takes NO parameters, by a law that speaks — its rule
  accepts a list only so that law can reach the mistake, which is
  the design, not the drift). And once with a state rather than a pair:
  twelve builder names matched twelve arms with nothing checking
  them, so "nothing catches a mismatch" — a mismatch fails the build
  28 times with the offending name printed, which is the consequence
  nobody traced. Every time a probe was one command away and cheaper
  than the sentence explaining the difference.
  PROFILE, DON'T REASON is this rule for memory; this is the same
  rule for meaning. THE TELL: an explanation of why two constructs
  differ, written before either was run. THE STANDARD, which "The
  subset today" already holds each of its entries to: a finding that
  survives quotes the OUTPUT, not the code that produced it.
