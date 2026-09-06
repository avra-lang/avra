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
refuses a registry entry that has neither), under the NEXT FREE
NUMBER: two lanes numbered a new idiom the same day, both landed
I33, and the duplicate key silently dropped the earlier rule while
`make idioms` kept reporting success. The tool now reads its own
source and refuses a repeated number.

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
  AND A VOICE STATES THE LAW, NOT THE SYMPTOM. "a pointer's only
  constant is null" is the rule; "both engines read it as null" was
  the observation that happened to hold the day it was written. A
  symptom-worded refusal goes STALE the moment the mechanism moves,
  and until then it reads as a workaround for a quirk rather than a
  rule to obey — so it teaches the reader to look for the quirk. The
  law's wording outlives its own implementation, which is what makes
  it worth pinning in the golden (lower.av's pointer-constant guard).
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
  keep that affordable. Ratcheted as I22 AND held by the compiler:
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
  The keeper is `make vocab`, which names each registry's consumers
  and refuses BOTH shapes inside them; it covers `Ins` and `RtKind`,
  and a registry it does not name is unguarded. Naming the next one
  IS how this law is enforced.
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
  the day it was written and never grew, so nothing ever tested the
  assumption. A KEEPER THAT HAS ONLY EVER GUARDED A STATIC ENUM IS
  UNTESTED — the first widening is its first real test, and that is
  the worst moment to learn it was only ever looking for one shape.
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
- A RUNTIME ROW BORROWS ITS ARGUMENTS — callee-cleans is the AVRA
  call's convention, not the registry's. `retained_args` retains for
  `.Call` and `.CallPtr` alone; a `CallRt`/`CallRtVoid` argument
  arrives borrowed, which is why `avra_array_push_owned` exists as a
  TWIN and why `avra_slot_set_owned` retains at the pack. A C body
  that KEEPS what it was handed takes its OWN reference
  (`avra_rc_retain`), and one that answers a value it keeps answers
  it retained (`owns_result: true`, as `avra_insist` does). A body
  written to the Avra convention instead — releasing what it was
  handed, storing what it never retained — leaves the cache holding
  freed memory, and the next reader segfaults (the once cache, first
  draft).
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
  `strlen` (safe only because every text box carries a spare byte
  its callers fill); and the niche — a nullable pointer IS its own
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
- ALLOCATION HERE IS CHEAP, so avoiding one is a trade, not a win.
  The size-class free lists made a box cost less than the scan or
  the branch that would dodge it: deduplicating `far_merge`'s
  expected sets measured 3% SLOWER, and skipping an empty
  `concat` measured neutral. Measure before removing an allocation.
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
  hole closed as a consequence rather than as the goal. The sqlite
  driver lane reports the second at a different boundary — under
  `SQLITE_USE_URI` a path handed to `sqlite3_open_v2` is a filename
  AND a URI parsed for `?mode=`, so a user's path beginning `file:`
  changes meaning with nobody writing a line. The RESOLUTION is the
  same shape, which is what makes it a law and not a coincidence:
  SPLIT THE VERB, one per grammar. `open(path)` is always a filename
  and names its sibling when refusing a `file:` prefix; a separate
  verb takes a URI deliberately. The capability was never the
  problem, the AMBIGUITY was. THE TEST: when a value crosses a
  boundary, ask whether the CALLEE will parse it — if it will, the
  value wears two hats and the design owes a SPLIT, not an escape.
  Ask it of format strings, glob patterns, regexes, and the next
  `[link]`-shaped manifest row.
- ITS SIBLING, AND THE SHARPER ONE: A GUARD AND THE THING IT GUARDS
  MUST READ THE SAME BYTES. Our own primitives disagree about one
  value — `avra_str_from_codepoint(0) + "x"` has `.length` 2 AND
  compares EQUAL to `""`, because `.length` reads the header while
  `==` is a C call that stops at the NUL (probed here). So a door
  built from `is_empty`/`==`/`starts_with` and a callee reading the
  C string are inspecting DIFFERENT VALUES, and the trap the door
  exists to stop walks straight through it. The sqlite lane's
  empty-path door is the instance, attributed: an empty path opens a
  PRIVATE TEMPORARY database deleted at close, so every write
  succeeds and the data is silently gone. The guard was not weak —
  it was reading a different string than the callee.
  AND THE NEAR-MISS IS THE HALF TO REMEMBER: one hostile case was
  refused BEFORE the fix, by accident, because `==` truncated it
  into a match. Right answer, wrong reason — a suite written that
  day goes green and ships the door broken. Recording it as a
  near-miss rather than counting it as a pass is what separates a
  red team from a demo. The NUL facts below read like a correctness
  footnote until someone builds a DOOR out of the lossy half.
- Every module has `spec`/`given`/`then` tests in `tests/` beside it.
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
  `pass(p: ParsedProgram, ...upstream Facts) -> Facts` — the program
  first, prior passes' facts next, its own Facts (which OWN its
  diagnostics) out. A pass OWNS its fact tables — NodeStore is
  parse-owned and never accretes pass facts. `analyze` is the only
  place pass order exists; consumers hold ONE Analysis. A source is
  ONE value (`SourceFile`: name + text + line index) — never a loose
  (file, text) pair.
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
- Every diagnostic names a registered kind (its F-code is the
  registry's projection), carries help or a structured fix where
  expressible, and has a golden rendering test.
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
  apart.
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
  ROW: `rt_sigs()` is ONE PLACE holding rows and five consumers
  QUERY it;
  adding is one row plus one C body, nothing dispatches. ITS
  SPELLING IS NOT `table<Row>`, and reading "table" as the literal
  cost a lane a design round: `rt_sigs`'s 78 WIDE rows are struct
  literals in a list, while `width_rows`'s three NARROW ones are a
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
  THE PERFORMANCE RATIONALE IS GONE as of S3b: liveness reaches the
  OWNED TWIN choice too, so a path write no longer finds its own
  read's +1 and no longer clones — sweeping 34 borrow sites to direct
  writes measured FREE (6.87s against 6.90s, inside the noise) and
  all 17 I34 licenses retired. SO A BORROW IS WRITTEN FOR ITS
  ALIASING AND NEVER FOR SPEED. The mechanism survives because nine
  sites still need the aliasing — deleting it emptied the declaration
  tables, since a borrow that becomes a copy pushes into the copy —
  and that same aliasing is H3's silent channel: a write through a
  borrowed local still reports nothing at all.
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
- BITWISE OPERATORS, all six, and the refusals come in TWO TIERS
  which is the useful half: `|`, `<<` and `>>` LEX and have no
  grammar ("expected BREAK while parsing `stmt`", at the operator),
  while `&`, `^` and `~` are not lexed at all ("unexpected
  character"). So a flag word for a C API has no spelling but a SUM
  — @std/sqlite's `flags_of` adds its contributors, and a sum equals
  an OR only while every contributor is a distinct bit. The language
  gives no way to state that, so a test is the only place the
  invariant is said aloud.
- A RANGE TAKES NO METHODS: `(0..n).any(it == 2)` is "expected `)`
  to close the group", AT the `..`. A range is a `for`-head and a
  comprehension's iterable, nothing more — so the idiom bar's "scan
  with `any`/`find`" reaches a range only THROUGH a comprehension
  (`[f(i) for i in 0..n].any(…)`), which is worth knowing because
  the doctrine sends you at a form the parser refuses.
- `export use`, a re-export: F3014 "`export use` — a re-export —
  arrives with a later slice". Without it a package's FILE LAYOUT is
  its public API, so moving a type between files breaks every
  caller. A loose scratch file DOES reproduce it: F3015 "this file is
  not in a package — `use` needs a root" fires first and F3014
  follows six lines down — read the whole output, both are there.
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
- A TRAILING-LAMBDA call (`tx { 42 }` where `tx` takes `fn() ->
  int`): "expected BREAK while parsing `stmt`", pointing at the `{`.
  The lambda in an ARGUMENT seat is fine (`tx(() -> 42)`), so every
  scoped-resource verb spells `db.tx(() -> { … })` and never
  `db.tx { … }` — worth listing because the braced form is the one
  that gets written first.
- A GENERIC FN AS A VALUE (`let f: fn(int) -> int = ident<int>`, the
  pinned call unapplied): "expected BREAK while parsing `stmt`" — a
  pinned call is a CALL in the grammar, so a generic fn cannot be
  stored, and a generic `mut`-seat fn cannot fill a fn-typed seat.
- `@comptime`: refuses at the `@` ("expected `mod`, `use`, … while
  parsing `stmt`").
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
- A `\u` ESCAPE in a string literal: `"\uFFFD"` is not refused — the
  lexer keeps an unknown escape as its two characters, so the text
  holds a backslash and a `u`. Spell a code point with `@std/text`'s
  `from_codepoint(65533)` (sugar backlog: `\u{…}` escapes).
- A match arm whose body is a bare STATEMENT (`.Unknown(t) -> fail
  E.Bad(t),`): "expected `}` to close the `match`", and every later
  declaration cascades. An arm's body is an expression — brace it:
  `.Unknown(t) -> { fail E.Bad(t) },` (a block that leaves joins the
  other arms).
- `?` then a field on a Result (`get(i)?.name`): lexes as `?.` —
  F2023 "`?.` reaches into a nullable, this is `Result<P, E>`".
  `(get(i)?).name` says it, in a comprehension element too.
- `export let` / `export const`: F3014 "`export` marks a fn, type,
  enum or trait — not this statement" — a constant crosses modules
  as a fn.
- `is` with a PAYLOAD pattern (`p is .Bind(_)`): "expected BREAK
  while parsing `stmt`" — `is` takes a BARE variant. A one-arm
  match is the projection (`.Bind(_) -> true, _ -> false`).
- `Result<void, E>` as a fn's answer: F2019 "a `Result` slot cannot
  hold this yet" (help: "nullable slots arrive with ownership's next
  slice"). A writing verb answers what it wrote instead —
  `@std/io`'s `write_text`/`make_dirs`/`remove` answer the path.
- `const` in a MODULE file (a library's `const PIPE_IN: int = 1`):
  F0902 "a module file holds declarations — only the entry runs
  statements" — a library's constant is a fn (`fn pipe_in() -> int
  { 1 }`; @std/process's flag words).
- A METHOD after `?` on a Result (`shell(line)?.run()`): F2023
  "`?.` reaches into a nullable, this is `Result<R, string>`". The
  chain DOES call methods now (`a?.m(args)` on a nullable), which is
  why a Result there reads as one `?.` and is refused for its type,
  not its shape. Parenthesise the propagation — `(shell(line)?).run()`
  — or bind it first. The field twin (`x()?.out`) is the same
  refusal; its help says "write `.out`", wrong for propagate-then-read.
- `fail` inside a `catch` ARM's block (`x catch e -> { cleanup(); fail
  e }`): F2029 "a `catch` arm answers the ok side: `T`, this is
  `Result<…>`" — the arm's block is not read as diverging. Write the
  statement `match` (`.Err(e) -> { cleanup(); fail e }, .Ok(v) -> …`),
  which is (@std/process's three drivers).
- A `null` LITERAL as a list element under `List<T?>` (`[null for c in
  cs]`, `T` a struct): F2006 "a list element cannot hold this yet" —
  lane C's PAIRS IN SLOTS. A `T?`-answering fn fills the slot
  (`[nothing_yet() for c in cs]`).

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
  under `let x: dyn Show = …` and select among the lets. Nor into a
  CALL's seat: `refused(e)` with `fn refused(e: dyn Error)` and a
  `ProcessError` in hand is F2000 "argument 1 of `refused` wants
  `dyn Error`, found `ProcessError`" — bind `let boxed: dyn Error =
  e` first, or take what the trait answers (the message) instead.
- A trait impl over a GENERIC type (`impl Show for Box<T>`): F2031
  "`P` is generic — a trait impl over a generic type is recorded,
  not landed". Inherent generic impls (`impl Box<T>`) land.
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
- `it` through a self-method wrapper (`xs.any(self.rides(it))`):
  F2033 "`it` has no element here — this seat takes `int`, not a
  fn" — `it` binds to the NEAREST call; write `(k) ->
  self.rides(k)`. `it is .A` binds fine.
- `is` takes a BARE variant, never a payload pattern: `e is
  .TimedOut(_, _)` refuses at the `(`, and the wording follows the
  context ("expected BREAK while parsing `stmt`", "expected `}` to
  close the `match`", "expected EOF while parsing `program`").
  `e is .TimedOut` is the test; a payload question is a two-arm
  `match` hoisted into a named predicate.
- `join` over a list that is not text: `[1, 2].join(",")` is F2005
  "`join` reads a list of text, this one holds `int`" — map to text
  first.
- `==` between lists, `contains`/`index_of` over structs or enums:
  F2000 "`==` compares scalars for now"; F2005 "`contains` scans by
  value — scalars and text for now, this list holds `K`" — spell
  the scan (`xs.any(same(it))`). ENUMS SPLIT ON THE PAYLOAD, which
  nobody had written down: a payload-FREE enum compares fine
  (`.Timeout == .Refused` answers false), and one CARRYING a payload
  is F2000 with the help "match on it instead — only an enum carrying
  nothing compares, by variant".

Methods the runtime lacks (F2030 "`.reverse(…)` calls a method, and
`List<int>` has none" — the others read alike — or the map's F2000):
- `List.reverse()` / `sort()` — core's `reversed` is the helper
  (and a copy: nothing here mutates in place).
- `List.find_index(pred)` — builders.av's `attach` is LICENSED I4
  for it.
- `m["k"]` on a map: F2000 "`[...]` indexes a `List`, found
  `Map<string, int>`" — `.get(k)`, which answers `T?`.
- An EMPTY LITERAL does not adopt a NULLABLE aggregate want: `let
  xs: List<int>? = []` is F2024 "`xs` declares `List<int>?`, this is
  `[]`", `{}` under a `Map<K, V>?` reads alike, and a fn tail says
  "the body answers `[]?` but … declares `List<int>?`". Bind the
  empty at its own type first (`let none: List<int> = []`). An
  empty STRING adopts `string?` fine.
- A struct-literal FIELD seat does not plant a want on its value
  (the value is walked before the field's want exists): a
  comprehension there types on its own, so `Pins { slots: [b ??
  args[j] for j, b in xs] }` under `slots: List<TypeId?>` is F2010
  "field `slots` is `List<TypeId?>`, this is `List<TypeId>`" — a
  typed let plants it. A `List<T>` never adopts a `List<T?>` want: `let tys: List<TypeRef?>
  = [t for t in refs]` is F2024 "`tys` declares `List<TypeRef?>`,
  this is `List<TypeRef>`" — the element's nullable is not widened
  through the list. Align by span, or build the nullable list
  directly.

Runtime facts, ours to ratify:
- A STRING's `.length` is a LOAD — the header carries the length
  (lane A), as a list's does; `while i < s.length` costs a load per
  turn, and I27 retired with the strlen it ratcheted. WITH ONE
  CAVEAT worth knowing before a new box type lands: `str_len` reads
  `(h && h->len) ? h->len : strlen(s)`, so a ZERO length is not
  trusted — it falls back to `strlen`. That is safe today only
  because every text box is minted through `str_box(n)`, which
  allocates n+1, and every caller writes the trailing NUL, so the
  fallback reads a sentinel and answers 0 (lane B probed all eight
  ways to make an empty string, both engines). The safety is a
  CONVENTION OF THE CALLERS, not a property of the function: a box
  allocated at exactly n, which is what a `Bytes` value would be,
  makes it a live bug.
- `split` DROPS a trailing empty segment and keeps a leading one:
  `"a.".split(".")` is one element, `".a".split(".")` two,
  `"".split(".")` is `[]`.
- A STRING HOLDS A NUL ONLY HALF-WAY, and the failing half is
  SILENT. A NUL cannot be written as a LITERAL (`\0` is not an
  escape — `"ab\0cd"` is six characters), but a program MINTS one
  with no foreign input at all: `@std/text`'s `from_codepoint(0)`
  answers a one-byte NUL, `from_codepoints` weaves it, and `+` and
  interpolation both carry it. It also arrives from outside — a
  file, an env var, a process's output, a database blob. Either
  way the primitives split. Reading the header's length,
  and so NUL-safe: `.length`, `char_code`, `starts_with`,
  `ends_with`, `trim`, `+`. Stopping at the first NUL, because they
  are C string calls: `==`, `contains`, `index_of`, `split`,
  `replace`. So a five-byte text READS EQUAL to its own two-byte
  prefix — `read_text` of `ab\0cd` `== "ab"` answers true, while
  `.length` answers 5 — and `contains("cd")` answers false about
  text that ends with `cd`. Lane B found it and fixed the one write
  that truncated; the five lossy primitives are a LANGUAGE decision,
  not a package's, and they are exactly the scope a `Bytes` value
  would carve out. Probed both engines, minted and foreign alike.
- `avra run` INTERPRETS, and recursion past 400 calls traps
  ("recursion too deep — 400 nested calls", exit 1); `avra test`
  and `avra build` are native and have no such floor (5000 deep
  runs). The limit is what keeps a runaway a trap; measure, never
  guess, when it moves.

## Working discipline

- MEASURE, THEN CHANGE. `make census CMD="check <pkg>"` gives EXACT
  retain/release/list-write counts and, with the per-caller tables,
  who causes them; `AVRA_SAMPLE=<secs> sh tools/watch.sh 4000 ./avra
  …` samples. Trust the census over the sample — and read
  `sample`'s output with its tree characters (`+ ! : |`) in mind,
  since parsing it as plain indentation reports the wrong fn.
- ONE HEAVY PROCESS AT A TIME, in the FOREGROUND, under the
  watchdog: `sh tools/watch.sh 4000 make gate`. The machine is
  shared with a loaded desktop and has panicked twice under this
  tree — three concurrent `make test` runs once, and a background
  gate with other compiler runs beside it (a WindowServer watchdog
  panic). A gate is ~0.3 GB for twenty seconds; nothing else heavy runs
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
  sampled, beside two lanes' gated steps — and lane B's bare `./avra
  test <pkg>` runs the same night were the other bypass: a package
  suite is a whole-package compile plus a linked binary spawning
  children, never a probe. `AVRA_RC_GUARD=1` only on
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
- A CODEGEN FIX REACHES THE PRODUCT ON THE SECOND BUILD. `make avra`
  compiles the source with the STANDING binary, so a product built
  right after merging a memory-pass fix carries the fix as SOURCE
  but its own body was compiled by the pre-fix pass — it runs with
  the bug it knows how to fix. Lane A's loop-condition fix merged
  so: my product compiled the suite at 7 GB (main's at 1.2 GB), and
  its second build was killed at 4.2 GB — the leaky product could
  not even compile the cli. The way out is a binary that already
  HAS the fix (main's `../avra/build/avra build packages/cli`, then
  `cp` to build/avra), then `make avra` once more to prove the fixed
  point (1.1 GB both times). Two rules: after merging a pass change,
  build TWICE before trusting a peak; and run a bare `build/avra`
  from another worktree with `LLVM_PREFIX` exported — the Makefile
  exports it, a bare shell does not, and the `[link]` row's
  `-L${LLVM_PREFIX}/lib` then names `/lib` ("clang failed linking")
  — and after `make build/avra_runtime.o`, since a bare binary links
  the OBJECT on disk, which a merge may have left behind the source
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
  gate's third leg does not rescue it: a corpus `.expected` is
  written by the same author from the same understanding, so it joins
  the consensus rather than breaking it. TWO MORE, from the sqlite
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
  spellings, and no such fn has ever existed — `testing/mod.av`
  exports `refused_with` and `refused_at_run` and nothing of that
  name. A DEAD ALTERNATIVE: accepted by nobody, protecting nothing,
  quietly widening what the keeper permits, and invisible to every
  fixture that makes the keeper fail, because the keeper was working.
  So exercise each alternative a keeper ACCEPTS as well as one that
  breaks it — a matcher with N spellings needs N positive fixtures,
  or the dead one sits there for as long as nobody greps it.
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
- A RECEIPT FROM ANOTHER TREE IS LABELLED AS ONE. The laws here carry
  instances because an instance is what makes a law APPLIED rather
  than agreed with — so the instances have to stay checkable. One
  probed in this tree reads as fact; one from a lane's own tree is
  named as that lane's and stays ATTRIBUTED until the code lands
  here. The two-hats law carries one of each, deliberately. Mixing
  them silently is how a file of receipts decays into a file of
  claims, and the reader loses the ability to tell which line to
  trust — including the lines that are true.
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
