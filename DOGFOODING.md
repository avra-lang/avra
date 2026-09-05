# Dogfooding Avra

Patterns proven in this tree — reach for these before writing the
C-style version. Probe unfamiliar features in scratch first; known
gaps live in CLAUDE.md "The subset today".


### A write reaches a PLACE, never a value

A fn changes its caller's data only through a PARAMETER'S FIELD
PATH (`mut rows = o.inner.rows; rows.push(v)`) or through its own
RECEIVER (`self.rows.push(v)`). A list handed over as an argument
is a VALUE — writing to it changes nothing the caller can see — and
so is an ELEMENT read out of a container (`mut r = xs[i]`), which
is why a mutated element must be written BACK (`xs.set(i, r)`).

So a mutable out-parameter is a one-field STRUCT, never a bare
list: `Pins { slots }` for the unifier's bindings, `Frames { stack }`
for a narrowing bracket, `Table<T> { rows }` for every memo. The
struct's field is the place; the bare list was only ever bs2's
aliasing in disguise.

Discovered by self-hosting: every one of these sites worked under
bs2 and silently did nothing under Avra's own semantics.

## The idiom registry

This file is the RULEBOOK of the future idiom engine (ROADMAP, Era
IV): every entry below is a lint rule being written by hand. The
mechanically-greppable subset is ENFORCED today by the ratchet
(`make idioms`, wired into the gate — smells may never rise;
deliberate exceptions bump `tools/idioms.baseline` in the same
commit). When a review round or a milestone discovers a NEW idiom,
it lands here AT DISCOVERY, with its smell, its licensed
exceptions, and — where greppable — a ratchet rule.

THE BAR (tools/idioms.py) rests on four laws, and the first three
exist because the old ratchet had a hole under each:

  1. THE BASELINE LISTS SITES, NEVER COUNTS. The old tool compared
     totals, so fixing one smell while adding another passed
     silently — a net-zero swap. Now a new site fails on its own.
  2. NO TOOL PATH ADDS TO THE BASELINE. `--accept` only PRUNES what
     is gone, so the debt can only fall. The old escape hatch was
     "bump the pinned number", which is how a ratchet becomes
     theatre: I1 drifted 39 -> 41 -> 40 -> 41 -> 43 across four
     milestones, each bump self-licensed in its own commit.
  3. A LICENSE LIVES AT THE SITE: `// LICENSED I3: a ZIP of
     parallel captures`. The reason sits where the code is,
     forever, instead of as an integer nobody reads. A new
     violation therefore has two honest exits — write the
     idiomatic form, or say why it cannot be written.
  4. THE REGISTRY MAY NOT OUTRUN THE RATCHET. Every I-code here
     must have a matcher or an entry in the tool's UNRATCHETED with
     its reason; the tool fails otherwise. New idioms arrive with
     enforcement or with a written admission of why they cannot.

Matchers are MULTI-LINE where the smell is: the old greps required
the loop and its push on ONE line, catching the rare shape (11
sites) while 14 ordinary multi-line loops were invisible.

Ratcheted: I3 I4 I7 I9 I11 I12 I13 I14 I15 I16 I18 I19 I20 I21 I22 I23 I24 I26 I28 I30 I33.
Unratcheted, read by a human: I5 (a matcher cannot see whether a
predicate has effects), I31 (a stolen doc and a legitimate
multi-paragraph header are the same shape).
I12 came BACK from unratcheted once its regex was repaired: it had
been reading `if x is .Error { return ... }` as a struct literal,
so it was retired for false positives that were the rule's fault,
not the code's. Requiring a `field:` pair inside the braces fixed
it, and it immediately found three constructors waiting for names
(Span's four spellings, seed's `alt`, memory's nested scope).
Not ratcheted, each with its reason in tools/idioms.py's
UNRATCHETED: I1 (the accumulator DECLARATION is a weak proxy — I3
matches the real smell), I2 (died with the eval collapse), I5
(duplicate DETECTION), I6 (subsumed by I3), I8 (the ritual and the
only legitimate use are textually identical), I10 and I17
(semantic — the review round hunts them), I12 (false-positives on
doc prose), I28 (voicehood is intent — the round hunts inline
prose; I11 catches the duplicated-wording consequence).

A RULE MUST BE ABLE TO FIRE. Every matcher carries a specimen the
tool re-checks on every run — added after I18 shipped with a regex
that could not span a nested call, which would have reported
success forever. A dead rule is the same disease as a drifting
baseline, one level up.

DEBT TODAY: ZERO. Every site is either idiomatic or licensed in
place with a reason. From here a single new violation fails the
gate — there is no amnesty left to hide in.

- I1  (ratcheted) an empty-list accumulator asks: is this loop a
      MAP? If yes, it is a comprehension (`switch_start`'s arm
      blocks). LICENSED where it cannot be: a STACK (`open_scopes`,
      ir_text's `switched`), a dual-channel fold, or a filter that
      needs the INDEX (`arm_cases` — comprehensions cannot
      destructure an enumerate).
- I4  hand-rolled scans that ARE `find`/`index_of`/`any` — SWEPT:
      `index_of_name` is `names.index_of(name)` (returns -1 on a
      miss — wrap to `int?`). `overlay_hit` stays a loop: reverse
      scan, licensed until a reversed iterator exists.
- I5  the dedupe/union fold — NAMED: core `distinct(xs)` (STRING-
      only on purpose — `contains` compares non-strings by
      identity). `Grammar.keywords` and `union_expected` use it;
      validate's and coherence's `seen` folds are duplicate
      DETECTION (they emit on the dup), a different concept, left.
- I6  head-plus-tail list builds — `concat`/`flatten` today, spread
      literals when the sugar lands (backlog).
- I7  (ratcheted) `xs[xs.length - 1]` is `xs.last()!`; `xs[0]` read
      MORE THAN ONCE binds a `head`. LICENSED exception: the
      rebind-alias mutation pattern REQUIRES index syntax — `mut
      top = xs[xs.length - 1].field` aliases for shared mutation,
      and `last()` may copy (memory.av's two sites).
- I8  the statement-value ritual is a VERB, never a two-step:
      `cx.walk_value(s)` / `cx.eval_value(s)` / `cx.lower_value(s)`
      (features/values.av) — eight spelled-out copies collapsed
      across let_stmt, expr_stmt, and mutation.
- I9  type agreement is ONE law: `types_disagree(cx, got, want)`
      (features/checks.av) — two-sided Error absorb, then interned
      ids. Its third hand-rolled copy (the call-argument check) was
      ONE-SIDED and cascaded "wants `<error>`" at the user — the
      extraction WAS the bug fix; the absorb test now counts
      diagnostics, not just contains(). The deep dive found three
      MORE hand copies (list elements, if branches, when arms) —
      six consumers now; the if-branch copy compared SHAPES with
      `==`, a latent hazard on payload shapes (List) that
      id-comparison closes. Its sibling law: `spoken(cx, d)` —
      speak and absorb, the standard refusal tail, which ten sites
      spelled as emit-then-intern.
- I10 an if-ladder mapping a value to values is a MATCH, returned
      directly — match is an expression, `_ -> null` closes a
      non-exhaustive subject (`shape_named`, `term_kind`). A TABLE
      only when the mapping is consumed AS DATA: iterated, rows
      with several fields, or queried in more than one direction
      (the operator roster, builder registries). `when` is for
      CONDITION arms — mapping one subject through `when` repeats
      the subject in every arm. (Reserved words refuse as field
      names: `shape`/`table`/`ref`/`none`.)
- I11 shared MESSAGES are fns, defined once (`hole_defect()` in the
      features root) — module-level lets do not cross imports, so a
      shared string's one definition is a fn. Four drifting copies
      collapsed. Repeat-a-string is data too:
      `joined(filled(depth, "  "), "")`.
- I12 an identical struct literal written twice is a CONSTRUCTOR
      waiting for its name (`no_first()` — the empty FirstSet was
      spelled out four times). Hunt with:
      `grep -rhoE "[A-Z][a-zA-Z]+ \{ [^{}]* \}" | sort | uniq -c`.
- I13 the same projection computed twice in ONE expression binds a
      local (`let sh = cx.shape_at(e); sh is .Int || sh is .Bool`).
      The commonest case: a diagnostic whose MESSAGE and LABEL both
      project the same value (`found \`${n}\`` … `this is a
      \`${n}\``) — twelve emit sites bound their `n`, and the two
      lines now visibly agree. LICENSED exception: a
      comprehension's filter and element cannot share a binding —
      `defs_of` computes `let_name` twice by necessity;
      comprehension bindings / `filter_map` are on the sugar
      backlog for it.
- I14 a GUARD PAIR repeated across sites is one law method
      answering bool (`refused_name` — the keyword+reserved
      refusal lived three times as when-pairs; sites now read
      `if self.refused_name(n, at) { return }`).
- I15 a PUSH/RUN/POP ritual around varying bodies is ONE bracket
      fn taking a thunk (`under_overlay(r, () -> ...)` — the
      overlay push/pop lived three times in resolve; the bracket
      now guarantees the pop). A zero-arg closure closes over what
      the body reads; a capture is a COPY (F3005 refuses a write to
      it), so state the body changes travels as the thunk's answer
      or through a receiver.
- I16 dup detection is a POSITION law, not a seen-accumulator:
      inside `for (j, x) in xs.enumerate()`, a duplicate is
      `xs.index_of(x) < j` — first occurrence earlier than here.
      Kills the `mut seen + contains + push` ritual wherever the
      list is small (structs' field laws, twice). The seen-list
      stays licensed where detection must survive ACROSS lists
      (coherence's cross-table scans).

- I17 a construct that GENERALIZES gets a general NAME. When one
      shape starts serving two masters, the special-case name
      becomes a lie the vocabulary carries forever: `Else` and
      `IfEnd` separated and closed a SWITCH's arms once regions
      went N-way, so they became `ArmEnd` and `RegionEnd` — nine
      files, zero test churn, and the compiler found every site.
      Rename AT the generalization, never later: the names are the
      published surface (`avra ir`, the IR goldens, every feature
      that emits them).

- I18 a projection the dispatch GUARANTEES, read with a plausible
      default, is a SILENT WRONG ANSWER: `truth_of(e) ?? false`
      compiles `false` into the program when the node was not a
      bool. Absence there is a DEFECT — `lower_defect(cx, e, "a
      bool literal without its value")` records it and the driver
      refuses the build. Five sites (bool, string, list, and two in
      enums/structs) said a plausible lie instead. LICENSED where
      there is no failure channel and the default is the right
      answer: `kids()` returning `[]` for a node that is not a list.
      FALSE-POSITIVE signature: a TEST line pairing an `*_of(...)`
      helper with an embedded source's own `??` (`ir_of("… f(1) ??
      0")`) trips the regex. The cure is the fixture discipline,
      not a license: name the source (`fn boxed_read() -> string`)
      and the attack line carries no `_of(` — which is how the
      adversarial files want to read anyway.

- I19 an INDEX WALK over a list is `enumerate`: `for j in
      0..xs.length` that then reads `xs[j]` should be `for (j, x) in
      xs.enumerate()`, which hands over both. It survived as prose
      for four milestones with no code, and was violated three times
      — including both zip builders, where the index is still needed
      for the PARALLEL list and enumerate serves that perfectly.
- I20a a test asserting `A || B` asserts NEITHER: if the outcome is
      uncertain, run it and pin what happens. (Found writing the
      first adversarial suite — the disjunction was hiding that I
      did not know whether forward type references worked. They do.)
- I20 a REFUSAL TEST pins the diagnostic COUNT, not just
      `contains`: `a.diagnostics.length == 1 && a.report()
      .contains(...)`. Without the count a CASCADE hides behind a
      message that happens to appear — the types_disagree bug was
      found exactly that way, and three tests still asserted
      contains alone. The matcher's first guard looked for the
      SUBSTRING `diagnostics.length`, so `>= 1` passed as a count;
      it now demands the real thing — `== n`, `refused_with(`,
      `refused_n(`.
- I30 a refusal asserted as `>= 1`: `refusals(src) >= 1`,
      `a.diagnostics.length >= 1`, `p.diagnostics >= 1`,
      `p.voices.list.length >= 1`. Each says "something was
      refused", which a cascade of five says just as well — one
      mistake earns one message, so the number IS the assertion.
      The idiomatic form pins it: `refused_with(src, phrase)` for
      the one-refusal case, `refusals(src) == n` where a cascade is
      today's truth and pinning it makes a later improvement
      VISIBLE. LICENSED only where the count is genuinely not
      deterministic (none in the tree today) — the reason at the
      site, or it is a bug being hidden.
- I21 a `mut` nothing mutates is a `let`. The reader is told to
      expect a change that never comes; two survived (a type
      registry threaded through a pass, and its test twin).
 GREW 2026-09-04 with the inout seats: a `mut` handed to a call may fill a `mut` seat, and one receiving a method may be a writing method's place — the compiler refuses a `let` at both — so the ratchet counts an argument or a receiver as mutated; the compiler's own laws now judge `mut` more exactly than the grep.
- I22 a match where TWO OR MORE variants answer is a REGISTRY, and
      a registry ending in `_ ->` silently forgets the NEXT variant.
      One answering arm is a PROJECTION and its catch-all is honest:
      the contract already pins the answer for variants that do not
      exist yet. Eight registries were hiding behind catch-alls —
      `type_decl_name` (a third type-declaring statement would never
      have reached the type namespace), the answer projection's
      unprintable shapes, `give`'s runtime-callee validation, the
      bool comparison, and four capture shapes in the grammar
      builders. LICENSED where the doctrine FORBIDS exhaustiveness:
      a feature cannot enumerate other features' variants, and
      interp's run loop delegates everything else to `step`.

- I23 a PARAMETER nothing reads: the signature lies about what the
      fn needs and every call site carries the lie (`declare` threaded
      an `lc` it never used). LICENSED where a CALLBACK contract owns
      the list — a policy fn or a test builder must match the
      signature it is passed as. The matcher was anchored at column
      0 and never read a METHOD for four milestones; it reads
      indented fns now, and excludes BY MATCHER the one shape that
      cannot drop a parameter — a method under `impl Trait for T`,
      whose signature the trait owns (fifty `nothing()` pass
      methods would otherwise each carry a license). Bodiless trait
      signatures and template text are skipped the same way.
- I herein note why I24 is MODULE-scoped: bs2 merges a module's
      files into one bundle, so an import in `program.av` serves
      `mod.av`. Per-FILE unused-import analysis is wrong and will
      delete imports that siblings depend on — it did, and the suite
      caught it.
- I24 an IMPORT nothing in the module uses. The resolver refuses
      a MISSING import (F3000) and an import of a name a module does
      not export (F3012), but an unused one is silent, so imports
      rot in that one direction — 54 had accumulated, several
      created by the same day's refactors. The matcher reads through the `mut` mark on a seat (2026-09-04): `mut cx: TypeCx` is a parameter named `cx`.

- I25 RETIRED (2026-09-04): a variant pattern writing the WRONG
      payload count. The bootstrap accepted `.A(_, _)` against a
      three-payload variant and bound the wrong things silently, so
      this rule kept the doctrine's "a new field breaks every site"
      promise by hand (and found two stale sites). Our compiler
      refuses it — F2015 "`.A` carries 3, the pattern names 2", on
      constructions too, one-line enums included — so the rule is a
      LAW now and the matcher is gone. The number stays retired.

A REFUSAL TEST THAT SAYS `>= 1` ASSERTS ALMOST NOTHING. One mistake
earns one message, so the COUNT is half the assertion — a cascade of
five passes `>= 1` silently. I20 already demands a count beside
`contains`, but it never saw this spelling, and 33 sites used it.
`refused_with(source, phrase)` in @std.avrac.testing makes the honest
form the SHORT one: it pins the count at one and the phrase together,
replacing a shape hand-spelled at 131 sites. `refused_n` is for the
shapes where a cascade is today's truth and pinning it makes a later
improvement VISIBLE — every malformed fn signature is exactly 2.

The remainder is no longer a hand-kept tally: I30 ratchets the
`>= 1` spelling and I20's guard demands a real count, so the number
is whatever `make idioms` prints and the gate refuses a new one. The
sites were converted a suite at a time — a script conversion had
FAILED, because each suite interpolates its own fixtures, so the
programs measured were not the programs the tests run, and nine
tests broke.

THE REACH LAW (learned the hard way, four times): a rule claims a
SHAPE, and one specimen proves only that its matcher is ALIVE. Four
rules shipped blind spots a single specimen walked straight past —
I7 could not see a dotted receiver, I3 could not see a one-line
loop, I4 could not see a generic with two parameters, and I26 read
`s.token!` as a local. SPECIMENS now holds EVERY spelling a rule
claims, and the self-test refuses the tool when any is missed:
reintroducing I3's blind spot names the two spellings it lost.

- I7's matcher was BLIND to a dotted receiver: it read
      `xs[xs.length - 1]` but never `m.frames[m.frames.length - 1]`,
      so six product sites hid from it — including the interpreter's
      register path, run on every instruction. Two matchers in a row
      have now been wrong in the same direction (I26 over-counted
      field unwraps; I7 under-counted dotted ones), which is the
      lesson: a rule's REACH is as much a claim as its wording, and
      both need a hit list read by eye before the rule is believed.

- ONE SURFACE, KINDS FORK AT TYPING. When two features want the
      same SPELLING, the parse stays ONE node and the meaning forks
      where knowledge exists: `X.y(args)` is MethodCall, and typing
      routes a VALUE receiver to the impl table, a TYPE NAME to
      variant construction (the shared `construct_variant` law);
      `catch`'s four surfaces fork on which CAPTURES arrived. The
      smell this kills: two grammar branches racing for one shape —
      the loser's @recover eats the winner (the let/let-else and
      for/for-each merges are the ordering lessons; the
      variant-lit/method clash was the breaking case).
- DECLARE THE WRECKAGE. A declaration that REFUSES still records a
      total, error-typed stand-in (a method without `self` declares
      every param a hole; an annotated binding records its declared
      type before refusing its value). One mistake, one message —
      and every downstream pass stays total instead of crashing on
      the gap. rt19's index-out-of-bounds is why this is a rule.
- THE INSTANTIATION RITUALS (unify.av): every generic surface
      (calls, struct lits, variant lits) shares three verbs —
      `tparams_refused` (the declaration already spoke; absorb),
      `unpinned_of` (the first open Var, voiced by the caller in
      its surface's words), `bound_closed` (ask after unpinned_of
      answered absence). The rule of three minted them: the absorb
      loop and the closing walk had each been hand-spelled three
      times before the extraction. A fourth generic surface joins
      by calling the verbs, never re-spelling the walks.
- I28 a LAW that assembles PROSE. RATCHETED since the second cruft
      round: every refusal is ONE call, `refusal(kind, at, message,
      label, help)` (diagnostics/mod.av) — 173 hand assemblies became
      that call, and `pointed(error_at(` outside the constructor is
      the greppable smell. A `spoken(cx, pointed(error_at(…`
      block inline in a rule body drowns the law in ceremony: the
      guard ladder in enums' variant_lit_type was 32 lines, 24 of
      them wording. The idiomatic form: every refusal is a NAMED
      VOICE — a fn whose whole body is the one refusal, living in
      a `── The voices ──` section at the file's tail (or shared
      in checks.av/contract.av when features share words). The LAW
      then reads as guard + verb: `if sig.tag_of(v) == null {
      return no_such_variant(cx, e, tname, v, sig) }`. Exemplars:
      enums/check.av (the refactor that minted this), nullable's
      `not_absent_able` (one voice, four operators), structs'
      field voices, fns' wrong_argument/wrong_arity. NOT the
      smell: the voice fn's own body, and a refusal spoken exactly
      once in a fn that is otherwise one guard (extraction would
      just rename it). Unratcheted — voicehood is intent, not
      text; the review round hunts it, and I11 (duplicated long
      strings) catches the worst consequence mechanically.
- I29 an EMISSION VERB that mints its answer register early. The
      lowering contract is one line — registers are numbered in
      emission order — and a shared verb that takes `dst` from its
      caller invites the caller to mint it BEFORE the verb's own
      scratch registers, which desynchronizes numbering from
      definition order and crashes the backend on a recycled
      index. The idiomatic form: the verb mints its ANSWER LAST
      (taking `e` and calling `cx.result(e)` after its scratch),
      or emits the answer's defining instruction FIRST
      (tagged_value's shape — dst minted by the caller, defined
      by the verb's first emit). Found when called_through's
      first draft took a pre-minted dst: the corpus caught native
      reading register 7 of 7. RATCHETED BY THE LOWERING itself
      (2026-09-02, after R2's three property lowerings re-hit it
      and only the red-team ladder noticed): `give` records every
      defining instruction's register and refuses a mint-order
      break as a NAMED build defect — never a native crash.
      A second specimen (2026-09-05): a mint passed as an ARGUMENT
      to a verb that `reg_of`s its operands — `measured(cx, e,
      subject, cx.result(e))` — is the answer minted early by
      another route; `reg_of` may lower lazily and mint, so the
      answer is minted after every `reg_of`, never handed in.
- I5 a FOLD written as a flag where a scan would short-circuit past
      a needed SIDE EFFECT. `all`/`any` stop at the first answer, so
      a loop whose body must run for every element — `paired_unify`
      unifies each pair for its effect of BINDING the declaration's
      Vars, including the pairs after the first miss — keeps its
      `mut ok` and says why AT the site. The smell is a flag fold
      with no annotation; the idiom is `all(...)` whenever the body
      is a pure test. UNRATCHETED: a matcher cannot see whether a
      predicate has effects, so this one is read by a human.
- I31 a `///` RUN THAT HEADS TWO DECLARATIONS. An inserted
      definition takes the doc of the one below it, and both lose:
      the newcomer wears a contract it does not have, and the
      original is left bare. Five sites the day the rule landed, all
      from one arc — `unflatten` wearing `mark_flat`'s doc,
      `flat_at` wearing three paragraphs about `field_read` and
      `slot_read`, `unified_lift` wearing THE ASSIGNMENT LAW that
      belongs to `accepts`, `flat_value` wearing `pack_value`'s, and
      `FlatRow` wearing the interner's. The smell is greppable: two
      or more `///` lines where an earlier line ENDS a sentence and a
      later one OPENS a new definition ("A ", "The ", "One ",
      "Whether ", "Mark "). NOT the smell: a multi-paragraph header
      whose continuations ELABORATE one definition (`Repr`,
      `rides_pointer`). The habit that causes it is inserting a
      definition above an existing one without moving its doc —
      which is exactly what a patch script does. UNRATCHETED: a
      stolen doc and a legitimate multi-paragraph header are the SAME
      shape — a sentence ends, the next line opens with `A`/`The`.
      The difference is whether the second paragraph ELABORATES one
      definition or DEFINES another, which is semantic. A first
      matcher printed 78 hits and the two inspected split one real
      (`workspace`'s `shown`) and one legitimate (`full_type`); a
      rule must justify every hit it prints.
- I32 A WHOLE-TABLE SCAN FOR A KEYED SUBSET. A verb asked per
      query that walks every row of a workspace-wide table to keep
      the few with one key — `[x.id for x in ws.decls.decls if
      is_impl_of(x, name)]`, asked per method dispatch — is a
      quadratic hiding as a comprehension. The idiomatic form is an
      INDEX filled where the rows are minted (`Decls.impls_by_name`,
      one lookup), or a memo per key (`Workspace.sources`: one read
      and one line index per file per run, where `source(ws, f)` had
      re-read and re-indexed the file for every declaration typed).
      Found by a `sample`, not by reading: the two frames were the
      hottest in the compiler by self time and the ledger had
      guessed elsewhere. NOT the smell: a one-shot walk that builds
      the index itself, or a scan a program performs once.
- I33 A REGION INSTRUCTION EMITTED RAW IN A FEATURE. `IfStart`,
      `ArmEnd` and `RegionEnd` were spelled by hand at 13 sites across
      seven features, each a `let dst = cx.result(e)` + emit + `dst`
      triple, while values.av held the verb under a presence-specific
      name (`close_presence`). The emission vocabulary
      (features/emit.av) speaks them — `open_region`, `arm_end`,
      `close_region`, `close_region_as` — beside `const_int`,
      `const_bool` (three copies became one) and `measured_reg` (the
      `length` lowering, three verbatim copies became one row fn).
      THE RULE: a feature's lowering emits its own VALUE shape and
      speaks every CONTROL shape; the IR of all 73 corpus programs
      was byte-identical before and after. The loop brackets
      (`loop_start`/`loop_cond`/`loop_end`) and THE WALK (`opened`
      over a list, `counted` over a range, `turn_open`/`turn_index`/
      `turn_elem`/`turn_close`) followed: the skeleton that lived in
      lists/walks.av and again by hand in loops/lower.av is one, so a
      comprehension, a `for x in xs` and an `xs.map(f)` emit one
      stream by construction. RATCHETED over regions and loop brackets
      (the matcher exempts emit.av's own body).
- I34 THE BORROW UNDER A SAME-SCOPE READ. `mut xs = self.field`
      followed by `xs.push(v)` is the alias form of a write — the
      smell is the alias where a path write (`self.field.push(v)`)
      says the same thing without a second name. It is LICENSED, and
      only there, where the SAME SCOPE has already READ the field
      (`self.field.length`, `self.field[i]`, a loop over it): today's
      memory pass holds that read's owned reference to the scope's
      end, so a path write after it finds the list SHARED and CLONES
      it (`slot_written` cloned the interpreter's whole array table
      per store — 60x slower). Two laws bound the license: the
      borrow is taken AFTER any callee that path-writes the field
      (a path write behind a live alias copies, and the alias goes
      stale — `file_id`'s borrow before `module_id` trapped), and it
      dies with liveness (S3 releases a read at its last use, and
      every such borrow becomes the path write). UNRATCHETED: the
      matcher needs the enclosing fn's scope (a read BEFORE the
      write); the read-then-write scan lives in lane C's landing.

- I26 one nullable LOCAL forced open with `!` three or more times
      in a fn. The value is already known to be there — CLAUDE.md's
      own style rule settles it ("a `let` earns its place when the
      value is read more than once"), so guard once, bind once, and
      read the name. Eleven sites when the rule landed, in code as
      old as the lexer; `annotated` had SIX `t!` in five lines.
      NOT the smell, and excluded by the matcher rather than by an
      annotation: a `mut` ACCUMULATOR (`closest`'s `best!`), which
      changes every turn — there is no one value to bind. The first
      matcher over-counted by reading `s.token!` as a local; a rule
      must justify every hit it prints.

## Lowering: MINT IN EMISSION ORDER

A register must be minted in the order its defining instruction is
emitted. The backend walks instructions once and indexes its value
table by register number, so a register minted early and emitted
late reads past the end — `index 6 out of bounds (length 6)` at
`avra build`, with the interpreter answering correctly the whole
time (it resolves by lookup, not by position). Found writing `??`:
the payload register was minted before the constant it indexes with.

```avra
let one = cx.mint_shape(Type.Int)      // mint, then emit
cx.emit(Ins.ConstInt(one, 1))
let carried = cx.mint(e)
cx.emit(Ins.CallRt(carried, "avra_array_get", [v, one]))
```

THE COMPOSITION COROLLARY (found collapsing the presence verbs,
relied on again by `flagged_pair`): a helper that mints IMMEDIATELY
before each emit is order-independent AT ITS CALL SITE — nesting
such helpers as sibling arguments (`nonzero(cx, tag_of(cx, v),
zeroed(cx, ...))`) keeps mint/emit aligned no matter which argument
evaluates first, because no register ever waits, unemitted, while
another helper runs. Helpers that mint EARLY and emit late lose
this and must stay sequential statements.

## `when` for dispatch chains

Any if/return ladder over conditions is a `when` expression:

```avra
when {
    c == 10 -> emit(token(TokenKind.Break, "", i, i + 1), i + 1)
    is_space(c) -> skip(i + 1)
    is_name_start(c) -> { ... }
    _ -> fail("unexpected character", i, i + 1)
}
```

## List comprehensions for filter/map

```avra
fn op_texts(r: LexResult) -> List<string> {
    [t.text for t in r.tokens if t.kind == TokenKind.Op]
}
```

Lists only — comprehensions cannot iterate ranges.

## The native list vocabulary

`push`, `length`, indexing, `set(i, v)`, `get`, `pop`, `insert`,
`slice`, `join`, `map`, `filter`, `reduce`, `foreach`, `enumerate`,
`zip`, `sort`, `reverse`, `contains(v)` (-> bool), `index_of(v)`,
`find(pred)` (-> `T?`), `any(pred)`, `all(pred)`, `first()`/`last()`
(-> `T?`), `is_empty()` — all native, and native closures are
mono-safe (unlike fn args through OUR generics). They work in
`<N>`-generic bodies too (`bindings.find(it.label == label)`).

A scan is never a loop:

```avra
codes.find(it.kind == kind)?.id                        // first match, projected
engine_codes().find(it.cause == c)?.kind ?? "language.defect"
f.builders.any(it.name == name)
cases.all(count_breaks(lex_grammar(it.src)) == it.breaks)
if !defects.is_empty() { return unassembled(features, defects) }
let tail: Token? = tokens.last()
```

A loop earns its keep only for: `?` propagation in the body, folds
with ordering semantics (`closest`'s tie-break), index arithmetic,
and stateful transforms.

## Absence reads STRAIGHT — the if-null rule

One of the most important patterns in this tree.
A null/`let x ->` MATCH earns its lines only when both arms carry
real payload logic — absence handling reads straight, never as a
two-arm ceremony:

```avra
if target == null { return null }     // not: match target { null -> null, let s -> ... }
self.slots[target!.index]

let f = r.farthest ?? FarthestFailure { cursor: c, expected: [p], in_rule: r }
let ptypes: List<TypeId> = sig?.params ?? []      // ?. + ?? collapse both arms
if m.label == null { repped } else { "${m.label!}:${repped}" }
```

And reach for the store's PROJECTION before writing an inline
match: `stmt_value`, `fn_parts`, and the value protocol trio exist so no caller
re-derives them. The proof case: a match enumerating statement
kinds whose arms cannot differ is pure ceremony — `stmt_value`
plus `if null` is the whole truth.

Projections come ONE PER VARIANT, never one per field: four
sibling `fn_name`/`fn_params`/`fn_ret`/`fn_body` projections were
the same match four times — `fn_parts` returns the parts struct
once and callers pick fields:

```avra
let name: string? = store.fn_parts(s)?.name
let parts: FnParts? = store.fn_parts(s)
if parts != null { declare_sig(s, parts!.params, parts!.ret) }
```

A projection that COMPOSES a pipeline gets a verb too: the
evaluated payload of a child is `cx.int_at(e)` / `cx.truth_at(e)` /
`cx.elems_at(e)` (features/values.av) — never the spelled-out
`int_of(cx.store.expr(cx.value_at(e)))`, which appeared eight times
before it was named. And after a null guard, a value read more than
once REBINDS (`let es = elems!`) so the `!` happens exactly once —
flow narrowing is on the sugar backlog; until the language absorbs
it, the rebind is the pattern.

## A pure map never mutates

An accumulate loop that only pushes `f(x)` is a MAP — write the
comprehension; the loop form is for effects, conditional pushes the
filter can't spell, and index arithmetic:

```avra
.ListLit(elems) -> fp(20, self.expr_fps(elems)),   // not: mut parts + for + push
let regs = [cx.reg_of(k) for k in elems]
```

A map the tree repeats gets a NAME (`expr_fps`, `stmt_fps`); a
mixed head-plus-tail builds with `concat`/`flatten` (spread
literals `[head, ..tail]` are on the sugar backlog); and a
two-per-item map is `flatten([[a, b] for p in ps])` — proven in
the subset (param_fps).

## `it` projection for lambdas

```avra
let names = self.rules.map(it.name)
self.ranges.find(offset >= it.lo && offset < it.hi)?.feature
cases.all(count_breaks(lex_grammar(it.src)) == it.breaks)
causes.all(cause_registered(it))
```

`it` binds at the nearest enclosing METHOD call — call wrappers and
bare-argument use inside the body are fine. A nested method call in
the body starts its own `it` scope (innermost method wins).

## Typed table literals for fixture data

```avra
type BreakCase = { src: string, breaks: int }
let cases = table<BreakCase> {
    src                    | breaks
    "a = b\n   | c\nd = e" | 2
    "\na = b"              | 1
}
```

The row type rides the literal (`table<Row>`) — the one form every
compile mode accepts. Use for pure data cases; keep named `then`
blocks where per-case failure names matter. Cells hold fn VALUES and
enum values too — a registry or an operator set is literally a table:

```avra
let rows = table<BuilderRow> {
    name          | build
    "int_lit"     | build_int_lit
    "fold_binary" | build_fold_binary
}
let ops = table<OpRow> {
    text | op
    "+"  | BinOp.Add
    "-"  | BinOp.Sub
}
```

## `with` for modified copies

```avra
cap("rules", rule_ref("rule")) with { rep: Rep.Plus }   // rare modifiers
r with { farthest: merged }                             // struct update
feature("clash", "clash_rule = NAME") with { diags: rows }  // extend a factory value
```

`with` chains, takes several fields at once, and applies to any
expression — a whole mut-reassignment ladder is one push:

```avra
ds.push(pointed(error_at(kind, at, msg), "used here")
    with { secondary: defined, help: "move the definition above this use" })
```

## Methods via `impl` (cross-file works)

```avra
impl Grammar {
    fn defects() -> List<Diagnostic> { ... }
}
// callers: g.defects()
```

A method is also the place a CONTRACT gets its name:

```avra
impl Token {
    /// Text equality, never against quoted input — data, not syntax.
    fn lit_matches(text: string) -> bool { ... }
}
```

`impl` works on enums too — derived properties live with the type:

```avra
impl Rep {
    fn suffix() -> string { match self { .One -> "", .Star -> "*", ... } }
}
impl Prim {
    fn token_name() -> string? { ... }
    fn answers_to(token: string) -> bool { ... }  // null-guarded ==
}
```

## Nullability instead of sentinels

Absence is `T?`, never `-1` or `""`: `label: string?`, `build: Build?`
(null = pass-through), `expect: Expect?`. Consume with `??`, `!`, and
null/`let x ->` match arms.

```avra
text = text + (unescape(e) ?? src.substring(j, j + 2))
```

`?.` projects a field out of an optional; with `??` it collapses the
whole "if null, default, else unwrap and read" ladder — including
directly on a nullable call's result:

```avra
fn later_def(name: string) -> StmtId? {
    self.all_defs.find(it.name == name)?.stmt
}
engine_codes().find(it.cause == c)?.kind ?? "language.defect"
```

`?.` reaches FIELDS only; mapping a present value through a fn or
constructor is a guarded `if`.

## Extractor + `want` for typed unwrapping

Per-kind extractors return `T?`; one `want` owns the Result plumbing
and the error vocabulary. `?` chains the rest:

```avra
fn want<T>(x: T?, what: string) -> Result<T, string> {
    let out: Result<T, string> = if x == null { Result.Err("expected ${what}") } else { Result.Ok(x!) }
    out
}
// let body = want(alt_of(args[1]), "an alternation")?
```

A `T?` argument is direct evidence, so `want` needs no explicit `<T>`.

## `?` propagation on Result

```avra
fn call_args(v: Captured<GrammarNode>) -> Result<List<string>, string> {
    mut out: List<string> = []
    for x in as_list(v)? {
        let t = want(tok_of(x), "an argument name")?
        out.push(t.text)
    }
    Result.Ok(out)
}
```

## Generics: what infers, what needs pins

Proven capabilities:

- Generic enums with payload fields (`Captured<N>`), generic structs
  with fn-typed fields (`MatchContext<N>.build`), generic fns taking
  fn-typed params, and generic impls (`impl Arena<N>` — methods
  specialize per instantiation) all work — including TWO
  instantiations of the same fn in one compile unit.
- A bare `T`/`T?` argument is direct evidence — `want(x: T?, what)`
  never needs `<T>` at call sites.
- Constructions infer under a typed `let` and in a fn's TAIL position
  (expected types thread through match arms, if-branches, and list
  elements) — `Captured.Many([Captured.Terminal(t), v])` needs no
  pinned intermediate, and a generic ctor works as a match-arm tail.
  Early `return`s do NOT get this — keep the typed let there. Neither
  does a construction whose only N-evidence is SIBLING fields
  (`MatchResult { status: r.status, state: state, ... }` — F1002):
  that one keeps its typed-let pin.

Pin explicitly (`f<N>(...)`) when:

- the only N-evidence rides inside a struct argument
  (`match_rule<N>(cx, ...)` — `cx: MatchContext<N>` is not enough), or
- the call happens inside another generic fn's body, even at a
  concrete type (`concat<Diagnostic>(diagnostics, r.diagnostics)`).

Never nest a generic type inside an explicit type argument —
`concat<Captured<N>>(...)` does not take (write the loop instead).
Fn-typed arguments carry no T-evidence, and pinning `<T>` over one
corrupts scalar payloads through mono — never thread fn args through
generics.

```avra
fn captured_absent<N>() -> Captured<N> { Captured.Absent }
```

## Vocabulary over ceremony

When every author would write the same wrap/unwrap stack, name it once
and the stack disappears from every call site. Bundle a call's world
into a context struct and the vocabulary becomes methods on it:

```avra
fn build_int_lit(b: Builder) -> Result<LangNode, string> {
    let t = b.token(0)?                    // not want(token_at(args, 0), "...")?
    b.make_expr(Expr.IntLit(t.int_value()))  // not Ok(Node(NExpr(alloc(..., span))))
}
```

The context carries what the engine knows (`b.span`, the store) so
authors never thread it; raw fields stay public as the escape hatch.

## Generic engine, concrete client

A generic engine takes ONE node type; a client with many node kinds
supplies a wrapper enum and unwraps behind its own accessors:

```avra
export enum GrammarNode { NGrammar(g: Grammar), NRule(r: Rule), ... }
run_grammar<GrammarNode>(g, tokens, grammar_build)
// consumers never match GrammarNode — they call grammar_result(o)
```

## First-class functions

```avra
fn scan_while(src: string, from: int, pred: fn(int) -> bool) -> int
// call: scan_while(src, i + 1, is_name_cont)
```

## Operator/escape sets as data

```avra
fn is_single_op(ch: string) -> bool { "=|()*+?:,-".contains(ch) }
```

## Map as a built-once index

`.get` returns `T?`; missing keys are honest nulls.

```avra
mut rules: Map<string, Rule> = {}
for r in g.rules { rules.set(r.name, r) }
// lookup: let found: Rule? = cx.rules.get(name)
```

## Range `for` over index windows

```avra
for i in 1..xs.length - 1 { out = "${out}, ${xs[i]}" }
```

## Rebind-alias for shared mutation

Params and captured structs are immutable, but rebinding a ptr-backed
list to a `mut` local aliases the same storage — the arena idiom:

```avra
fn alloc_expr(e: Expr, span: Span?) -> ExprId {
    mut nodes = self.exprs
    nodes.push(e)
    ExprId { index: nodes.length - 1 }
}
```

(A closure captures by VALUE: capture the `let` struct and go
through a fn like this; a write to a captured `mut` is refused.)

## Comprehension as list copy

The safe-snapshot idiom (never alias a list a rollback still holds):

```avra
mut xs = [x for x in items]
xs.push(v)
```

## `is` for single-variant questions

```avra
tail.prim is .Group && tail.rep == Rep.Star
```

A full match earns its place only when payloads are extracted.

## `or` arms for shared bodies

Same-body arms are ONE arm — the interesting variant stands alone and
the rest read as a set. Wildcards only; a binding cannot ride an `or`:

```avra
match p {
    .Group(inner) -> call_names_in_alt(inner),
    .Ref(_) or .Lit(_) or .Named(_) -> [],
}
```

## `_` by match species: projection vs dispatch

A PROJECTION asks one variant for its payload; every other arm is the
same absence or rejection. A new variant can never change the right
answer — the fn's contract pins it — so `_` is correct and
enumeration is churn:

```avra
fn node_of(v: Captured<GrammarNode>) -> GrammarNode? {
    match v {
        .Node(g) -> g,
        _ -> null,
    }
}
```

A DISPATCH decides behavior per variant — a walker's recursion, a
renderer's shapes, a checker's rules. There a new variant needs a
human decision, so `_` is banned (CLAUDE.md) and the site must break
at compile time; `or`-runs keep the enumeration one line:

```avra
match self.store.expr(e) {
    .Ident(name) -> self.use_name(e, name),
    .Binary(_, l, right) -> { ... recurse ... }
    .IntLit(_) or .Error -> self.nothing(),   // a new Expr must land HERE, visibly
}
```

Open domains (strings, codepoints, `when` chains) always take `_` —
there is nothing to enumerate.

Test assertions are projections-of-truth: "is this a Let named x,
else false" ends in `_ -> false`, so tests never break when the node
model grows. Only the PASSES' dispatch matches enumerate — those are
the sites a new variant must visibly break.

## Absence flows through, never re-matched

A mapping fn takes the OPTIONAL and passes absence through, so every
caller with a `T?` in hand maps in place instead of re-matching
(`loc_at(file, span?) -> Loc?`). Where a present value becomes 0-or-1
things, `some_list` turns the optional into a comprehension source:

```avra
let edits = [Edit { loc: l, replacement: n.name } for l in some_list(at)]
```

Both idioms end the `null -> []` / `null -> null` arms `??` cannot
reach (it defaults — yields the LEFT side when present — it does not
map).

And before reaching for either: check whether the optional should
exist at all. TWO levels of absence (`primary: Frame?` wrapping
`Frame.loc: Loc?`) forced a mapping match at every construction and
read; collapsing to ONE level (the frame is always present, only its
loc is optional — P6) deleted the matches everywhere at once:

```avra
primary: Frame { label: null, loc: loc }          // error_at: no match
d with { primary: d.primary with { label: label } }  // pointed: no match
if d.primary.loc != null { ... }                  // render: one check
```

## `enumerate` for indexed walks

```avra
for (i, m) in out.enumerate() {
    if i == idx { next.push(m with { expect: ... }) } else { next.push(m) }
}
```

## `concat` / `flatten` / `joined` / `filled` / `some_list` from core/lists

```avra
diagnostics = concat<Diagnostic>(diagnostics, r.diagnostics)
diagnostics: flatten([p.diagnostics, r.diagnostics, t.diagnostics])  // N lists, in order
"[${joined([render(x) for x in items], " ")}]"
targets: filled<StmtId?>(p.store.exprs.count(), null)   // dense-table prefill
```

Pin `concat<T>` inside generic fn bodies — mono needs the explicit
type there even when T is concrete.

## Components for self-describing bundles

A named bundle with defaulted fields is a `component` (the spec's
feature shape): only the fields that matter get spelled. Instantiation
is a STATEMENT binding the instance name — bind, then return it.

```avra
export component LanguageFeature {
    config {
        name: string,
        docs: string = "",
        gram: string = "",
        builders: List<BuilderRow> = [],
    }
}

fn let_stmt() -> LanguageFeature {
    component LanguageFeature f {
        name = "let_stmt"
        docs = "`let <name> = <expression>`, ended by the line."
        gram = """
stmt = "let" n:NAME "=" v:expression BREAK @recover(sync_to: "BREAK") -> let_stmt(n, v)
"""
        builders = rows
    }
    f
}
```

Config pairs are newline-separated; the `component`-prefixed
instantiation works cross-file (the bare form does not). A consumer
that cannot instantiate (metadata-compiled tests) goes through an
in-package factory and extends the value with `with`.

## Triple-quoted strings for embedded text

Grammar fragments, docs, fixtures, and GOLDEN test expectations —
an exact multi-line rendering compares against one `"""` block —
never `\n`-joined literals. Interpolation (`${name}`, fn calls
included) works inside them, and `\"\"\"` embeds a literal fence —
so a triple-quoted TEMPLATE can generate a file that itself
contains triple-quoted strings (the scaffolder's trick):

```avra
gram = """
expression = additive
primary = v:NUMBER -> int_lit(v) | n:NAME -> ident(n)
"""
```

In gram text, a zero-capture build is `-> f()` — bare `-> f` is a
CAPTURE reference and defects at assembly ("uncaptured label").

## Typed ids are single-field structs

`type ExprId = { index: int }`, never an int newtype — newtype scalars
corrupt through generic/mono flows (subset note). Struct ids ride
every boundary safely and stay nominally distinct.

## Match guards

```avra
match self {
    .A(n) if n > 10 -> "big",
    .A(_) -> "small",
    .B -> "none",
}
```

## Traits for contracts

A trait names a contract; types join by `impl Trait for` — across
package boundaries too. Keep mandatory methods to the one thing every
implementor must say (default bodies are not in the language yet —
CLAUDE.md, "The subset today"):

```avra
// @std.errors
export trait Error {
    fn describe() -> ErrorInfo
}

// any package
impl Error for Diag {
    fn describe() -> ErrorInfo { info(self.kind, self.message) }
}
```

Heterogeneous behaviour pairs data with `dyn Trait` — the CLI's
`Subcommand { meta: CommandSpec, body: dyn Runnable }` dispatches
each command through the one-method trait. `NodeSemantics` scales the
same shape to a MULTI-method contract: a feature's whole per-pass
behavior as one impl, and `semantics_of` — the ONE exhaustive map —
returns it directly (typed-let boxed; no strings, no lookup, no miss
possible). The impl is the completeness gate: a missing pass method
fails to compile. A method that deliberately does no work calls
`nothing()` — the decision is written, never implied. One limit: no
generic-enum returns through `dyn` — report through a capability fn
instead.

## The three seams of a pass

Every pass is standard at exactly two seams, and hand-shaped between:

1. DRIVER: `pass(p: ParsedProgram, ...upstream Facts) -> Facts` —
   facts own their diagnostics; `analyze` is the only place order
   exists.
2. FEATURE: one `NodeSemantics` method per pass, `(self, cx, e)` —
   and `StmtSemantics` is its statement twin: one impl per
   statement kind, one `<pass>_stmts` loop per driver serving top
   level and blocks alike.
3. Between them, the driver's own walk stays plain code — three
   similar 8-line visitors beat one generic walker until a fourth
   pass proves the shape.

A pass's STATE is `{ p: ParsedProgram, ...upstream Facts, ...own
tables }` — the program held as ONE immutable field, never exploded
into copied store/features/file fields. That is the "one big
context", done right: read-context is one shared value; write-state
stays owned per pass, because shared mutable context is the
god-object that makes pass order implicit and memoization
impossible. And passes are NOT a trait: their typed signatures ARE
the data-flow contract (`type_check(p, r)` cannot run without
resolution, provably); a `trait Pass` erases that and has no
consumer until the query engine memoizes passes uniformly — that is
its trigger, not before.

## Capability contexts: data + driver-wired fns

A context struct crosses layers DOWNWARD carrying fn fields the
driver wires at construction — features call capabilities without
importing the pass, and pass state stays with the pass. The engine's
`MatchContext.build` and every pass Cx are the same pattern:

```avra
let cx = TypeCx {
    store: p.store,
    type_at: (e: ExprId) -> t.of_expr[e.index],
    intern: (sh: Type) -> t.types.intern(sh),
    emit: (d: Diag) -> t.speak(d),
    ...
}
```

Closures capture the LET-bound state struct (never a `mut` local) and
mutate through it — the rebind-alias idiom underneath.

## One semantics: lowering IS the meaning

A feature defines what its constructs DO exactly once — in
lower.av. Evaluation is the IR interpreted (language/interp.av)
over the SAME instruction stream the backend compiles, so eval and
native cannot disagree by construction; the interpreter's Val enum
and runtime dispatch are the host twins of runtime/avra_runtime.c,
refusal wording included. (The earlier "values are literal nodes"
tree-walking evaluator was RETIRED by the north star's L3 collapse
— its whole per-feature eval.av layer died with it.)

## A table's read is the query

A fact table that consumers read by id (`Decls.sig(d)`) holds ONE
hook the driver arms (`ensure: fn(DeclId)`); the read calls it
first. The hook is the memoized query — it computes on first ask,
records the dependency, and detects a cycle — so every reader,
features included, asks lazily without knowing there is a kernel,
and declaration ORDER stops being a concern anywhere. The hook is a
one-slot list of a fn (the mut-cell protocol), armed after the
workspace exists; the table's default is a no-op. This is how the
four declaration rounds were deleted.

## A body's reads are its own

A body — a fn's, a method's, a field default's — is typed and
lowered as ONE unit over its own expression range, so it must never
read another body's facts. The language guarantees it with the BODY
FLOOR (resolve refuses a body's read of the top level's run-time
bindings — `F3020`, the remedy a parameter) and with one rule for
cross-module expressions: an expression another body needs is a
DECLARATION with a body of its own, and the needing body CALLS it.
A field default is the first instance (`DeclKind.Default`, `P.y`);
a struct literal that omits the field emits one `Call`. When a
feature wants to lower "that expression over there" inline, that is
the smell — mint the declaration.

## A type's methods are a namespace

Registration is the container's job (an impl block registers its
methods under the target when its own sig computes), and a name
taken twice is a CLASH computed once per table, in declaration
order, blamed at the later one — `method_clashes` beside
`module_names`, folded into the file that holds the later
declaration. A "declared twice" spoken by the second REGISTRANT is
ask-order dependent (the lone-file path asks bodies before sigs and
blamed the first block); a clash law over the finished table is not.

## A refused declaration still declares

A declaration the checker REFUSES (an orphan impl, an impl of an
undeclared type, a selfless method) still lands a signature — every
param a hole, the answer a hole — so every later walk stays total:
the body walk reads `self` from a real param list, the fn loop
finds a sig, mono finds a home. The alternative was found as a
crash: `impl Pair` on another module's type spoke its refusal and
then the body walk indexed an empty param list. One mistake, one
message, no crash downstream — `declare_wreckage(f)` in typing is
the one verb; `refused_impl` calls it for every method.

## The hunger protocol: go hungry, be fed, speak when starving

A typing rule that needs the EXPECTED type and has none does not
guess and does not refuse: it goes hungry (`cx.go_hungry(e)`,
answering the hole silently) and lets the one agreement door feed
it — `accepts` hands every hungry expression the want it meets
(`cx.feed`), and the rule runs again with it. At the walk's end
the rules still hungry run once more STARVING (`cx.starving()`)
and each speaks in its own words. Two rules ride it: the
annotation-less lambda (fed its seats) and the bare variant
literal `.name(args)` (fed its enum). The smell it replaces: a
rule refusing "cannot infer" at a site the door was about to
feed, or a driver speaking a feature's refusal. UNRATCHETED: a
placement, read for at review.

## A bodied declaration: the driver brackets, the feature judges

A declaration with a body that must answer a type — a fn, a field
default, a test case — is typed in TWO halves that never trade
places: the DRIVER brackets the walk (the declared answer pushed on
the context's `fn_ret` for exactly the walk — `walk_under`,
`case_body` — one bracket for every kind, so `return` judges where
it stands) and the FEATURE
judges the answer (`fits_default`, `fits_case`: one `accepts`, one
voice, in the feature's own check.av). The smell that names this
idiom: a `// ── voices ──` section opening in a pass driver — the
voice belongs to the feature whose code registers it. UNRATCHETED:
the shape is a placement, not a greppable token; the review round
reads for it.

## Proven but awaiting their first honest use

- **Pipe `|>`** — first real pipeline, not two-arg call rewrites.

- I20/I25 GREW 2026-09-03: a counted refusal also spells `voices.length == n` (a Program's package voices are diagnostics); the ratchet's roots now include packages/std-toml/src, so a standalone package is held to the same bar; I25 reads one variant per line (CLAUDE.md records the one-line-enum blind spot).
