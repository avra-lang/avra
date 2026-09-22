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

THE BAR (tools/idioms.py) rests on five laws, and the first three
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
  5. THE ROOTS ARE THE PACKAGES, ASKED OF THE TREE. The scan list was
     hand-kept, so std-http, std-net and std-sqlite were never on it
     and the bar reported ZERO DEBT over three packages it had never
     opened — 71 unlicensed sites, including three `xs[xs.length - 1]`
     that I7 has ratcheted for four milestones. A check that examined
     nothing is not a check that passed, so the roots are read from
     `packages/*/src` and the run PRINTS WHAT IT LOOKED AT (389 files
     in 16 packages today). The same disease has two other known
     hosts: the Makefile's two link sites, and any keeper whose
     subject list a new arrival does not join.

Matchers are MULTI-LINE where the smell is: the old greps required
the loop and its push on ONE line, catching the rare shape (11
sites) while 14 ordinary multi-line loops were invisible.

A CITATION IS RATCHETED TOO, by a different keeper: `make cited`
refuses a name or a path this file or CLAUDE.md cites that the
tree cannot answer, and a bare `file.av:NNN`, which the next edit
of that file moves. It reaches a THIRD of doctrine rot — an audit
of 99 laws found 17 stale decorations, 5 of them names a grep
finds and 12 counts, line numbers and attributions no tool can
see. Licences live in `tools/cited.allow`, each with its reason.

Ratcheted: `python3 tools/idioms.py --rules` answers, from the tool's own
`RULES` keys — never a hand copy here.
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
- I2  RETIRED: the evaluated-payload chain. It died with the eval
      collapse — no site can exist to catch, so the matcher is gone.
      The number stays retired.
- I3  (ratcheted) a for-loop whose whole body is one PUSH — that is
      a comprehension, or a `concat`. The most-licensed rule in the
      tree, and the licenses are the honest half: a walk whose OUTPUT
      ACCUMULATES across several branches (one `made` filled by six
      of them), a push through a FIELD ALIAS (a concat would rebind
      the local), an INDEX SCAN where the position is the answer, and
      a fold whose pushes must be EMITTED in order. What is no longer
      licensed: "the paired form does not parse" and "a comprehension
      over a RANGE is our own sugar backlog" — both landed, and the
      loops that cited them are comprehensions now.
- I4  hand-rolled scans that ARE `find`/`index_of`/`any` — SWEPT:
      the scan is `xs.index_of(x)` (returns -1 on a miss — wrap to
      `int?`), as `core/modules.av` reads a key's cut.
- I5  the dedupe/union fold — NAMED: core `distinct(xs)` (STRING-
      only on purpose — `contains` compares non-strings by
      identity). The grammar's own folds use it — `first.av`,
      `diagnostics.av`, `ast.av`;
      validate's and coherence's `seen` folds are duplicate
      DETECTION (they emit on the dup), a different concept, left.
- I6  head-plus-tail list builds — `concat`/`flatten` today, spread
      literals when the sugar lands (backlog). AND `concat` COSTS THE
      WHOLE LIST, so this entry must never be read as "append one
      element with it": building n items by appending one at a time
      copies a growing list n times, which is quadratic. MEASURED
      (2026-09-17), 20,000 appends: through a LOCAL `mut` binding
      0.002s (the push is in place); through a RECORD FIELD of a
      shared value, or through a `Cell`'s `get`→`push`→`set`, 0.45s
      — the whole list copied per element. So `concat` JOINS TWO
      LISTS, and a loop that appends builds through a local `mut`
      binding or is a comprehension. The two worst sites in the tree
      were both this shape: `Db.record_dep` (97% of the `bodies`
      phase) and `Decls.note_origins` (97% of `resolve`). AND THE
      COST IS NOT THE COPY-ON-WRITE — a push on a local that shares
      its list with another binding is in place, measured at the
      same 0.002s. It is that a write reaching a list through a
      field of a shared value, or a `Cell` round trip, cannot keep
      the unique copy, so no write is ever the one that pays.
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
      it now demands the real thing — `== n` or `refused_with(`.
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
      GREW 2026-09-05: the LICENSE IS NOW A SPELLING, not a comment.
      `rest ->` says in the LANGUAGE what `// LICENSED I22` said in
      prose — the compiler reads it (F2040 goes quiet), the ratchet
      reads it (`_ ->` is what it looks for), and a reader sees the
      deliberate remainder without a tooling footnote. The old law
      fired at 191 sites tree-wide and none was the defect it names.
      All 42 prose
      licenses were measured DEAD the day the compiler's own law
      started counting answering arms: 15 became `rest ->` and 27
      were licensing a one-arm PROJECTION, which was never a
      violation. Their reasons stayed as plain comments; the claim of
      an approved deviation went. A rule with two enforcers keeps the
      one that can SEE — the grep still fails the gate on a new `_
      ->`, the compiler names the variants it forgets.
      THE PROSE LICENSE STAYS AVAILABLE, and one shape needs it: a
      registry hole that BINDS (`other -> f(other)`) cannot be
      spelled `rest`, which binds nothing. The compiler says so at
      that site rather than giving advice that will not compile, and
      `// LICENSED I22` is the exit left for it. A spelling that
      covers most cases does not get to close the escape hatch for
      the rest (P8).

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
      THE LICENSED CASE HAS A SPELLING, and it is I22's lesson one
      rule over: a parameter a SEAT owns and the body never reads is
      named `_q`, not annotated. The matcher has always skipped a
      leading underscore and nothing in the tree had ever written one,
      so nineteen route handlers — whose signature `routed`/`fixed`/
      `tailed` owns — were each facing a comment. The spelling says
      "unread by contract" in the language, where a reader sees it
      without a tooling footnote.
      ITS MATCHER READ A LAMBDA'S SEAT AS THE FN'S OWN: the parameter
      list was taken to the line's LAST `)`, so a one-line body
      holding `f(line, (q: Request) -> ...)` put `q` in the fn's list
      and the rule accused a parameter that was never declared. Ten
      hits across std-http and std-sqlite were that, against nineteen
      true ones — the list ends at its MATCHING paren now.
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
replacing a shape hand-spelled at 131 sites. A `refused_n` for the
shapes where a cascade is today's truth — pinning the count so a
later improvement is VISIBLE, every malformed fn signature being
exactly 2 — LANDED with the comptime lane, and HOW it landed is the
lesson: THREE test modules each wrote their own (two over a `Program`,
one over a source) while this paragraph still said it had never
landed. A WANT RECORDED AS ABSENT IS READ AS ABSENT — nobody greps
for a fn the rulebook says does not exist — so three authors wrote it
instead of one moving it. `testing/mod.av` exports it now, with
`said` (everything a program said — its files' diagnostics, the
workspace's voices, its defects) and `refused_in` beside it. Spell a
cascade `refused_n(p, phrase, n)` or `refusals(src) == n`.

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
      variant-lit/method clash was the breaking case). The dot-call
      is the exemplar since 2026-09-05: `impls/callee.av` decides
      WHO ANSWERS once (`Callee`), and typing and lowering each match
      it exhaustively — a new receiver kind breaks both passes at
      compile time.
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
- I27 RETIRED (2026-09-05): a STRING's `.length` re-measured in a
      loop condition. It was `strlen`, so a re-measure was O(length)
      per turn and the rule ratcheted the hoists. Lane A gave the
      string box a length in its header, so the measure is a load and
      the re-measure costs nothing; the hoists that stand are
      harmless. The number stays retired.
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
- I38 (ratcheted) a GRAMMAR comma list with no trailing-comma
      option. CLAUDE.md's grammar law says a repeated `( "," x )*`
      ends `","?` before its closer, in every rule — a list that
      refuses the comma is a defect, not a style. The law was
      written when nine spots were fixed at once and then went
      unenforced, which is the same gap I3 sat in: a rule the spec
      states and no tool implements. All fifteen comply today, so
      the ratchet exists to catch DRIFT — a rule copied from a
      sibling and quietly diverging, which is how two of the three
      `fn`-shaped rules came to differ on `mut`. Lane B named the
      class; this is the first tool that can see an instance of it.
- I48 (ratcheted) A COMPREHENSION OVER A LIST, BUILT ONLY TO BE
      FOLDED TO A BOOL. `[writable(h) for h in r.headers].all(it)`
      builds every element and then measures what it built;
      `r.headers.all((h) -> writable(h))` stops at the first answer
      and allocates nothing. Seven sites when the rule landed, five of
      them in one campaign's two writer laws — and the file holding
      one of those spelled the scan correctly two lines further down,
      which is what makes this a habit rather than a belief. Two more
      were in a suite, where the list is a table of hostile inputs and
      the scan reads better than the fold did. LICENSED BY THE MATCHER
      and never by an annotation, in the two shapes where the scan
      cannot be written: over a RANGE (a range takes no methods, so
      the comprehension is the only form the language has — seven such
      sites stand, in route.av, format.av and interp_bytes.av), and
      under a PAIRED head (`for i, k in xs`), where the element alone
      is what native `all` hands over. Nothing in the tree matches
      today, so the ratchet is against DRIFT, as I38's is.
      THE NEAR RELATION IS NOT THE SMELL: a FILTERED comprehension
      (`[f(x) for x in xs if p(x)].any(it)`) folds a different
      question, and converting it inverts the predicate; the matcher
      does not claim it.
- I37 a FOLD written as a flag where a scan would short-circuit past
      a needed SIDE EFFECT. `all`/`any` stop at the first answer, so
      a loop whose body must run for every element — `paired_unify`
      unifies each pair for its effect of BINDING the declaration's
      Vars, including the pairs after the first miss — keeps its
      `mut ok` and says why AT the site. The smell is a flag fold
      with no annotation; the idiom is `all(...)` whenever the body
      is a pure test. UNRATCHETED: a matcher cannot see whether a
      predicate has effects, so this one is read by a human.
      (It took a TAKEN number until 2026-09-05 — it was filed as a
      second I5, so seven `LICENSED I5` sites pointed at the dedupe
      rule that is the real I5. Lane A found the collision; the tool
      now refuses a repeated number in the registry as well as in
      its own source.)
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
      every such borrow becomes the path write).
      RETIRED 2026-09-05, and the second half of that prediction was
      WRONG in a way worth keeping. S3's liveness alone did NOT
      retire it: the sweep to path writes made the compiler 3.4x
      SLOWER (7.5s to 25.6s), because a read of `self.field` goes
      through the OWNED TWIN whenever the destination is managed,
      and that +1 lives to the scope's end whatever the retain rule
      says. Liveness had to reach the TWIN CHOICE too (S3b): a
      LENDING row's answer — one the subject still holds, which the
      registry now says in a `lends` column — is a borrow unless it
      must outlive the subject. With that, the sweep is FREE (6.87s
      against 6.90s) and all 17 licenses are gone. The lesson is the
      registry's: `avra_array_pop` also has an owned twin and must
      NEVER be borrowed, because a pop HANDS OVER — declining its
      twin trapped "a managed slot popped as a scalar". Which rows
      lend is DATA, and `lends` defaults to false so a row nobody
      has thought about is safe. UNRATCHETED: the
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
- I36 (ratcheted) TEXT GROWN BY `s = s + piece` IN A LOOP. Every
      step copies what came before, so a scanner over n bytes does
      n²/2 work — the lexer's string literal, the toml scanner and
      `quoted_text` all spelled it, and the cli's padding too. The
      form: a `@std/text` builder (`mut out = builder()`, `out.push`,
      `out.built()`) that keeps pieces apart and joins once; a
      scanner pushes RUNS (`src.substring(run, j)` at each escape),
      not characters; a column is `repeat`/`pad_left`/`pad_right`.
      The matcher reads `x = x + "…"`, `x = x + (…)` and `x = x +
      y.substring(…)` — an int's `n = n + 1` never matches. Four
      sites converted at discovery (2026-09-05), none licensed.
- I35 (ratcheted) a RAW SCOPE BRACKET through a lowering context:
      `cx.emit(Ins.ScopeEnter(…))`, `cx.emit(Ins.ScopeExit(…))`,
      `lo.out.give(Ins.Scope…)`. A scope IS a `defer` frame, and the
      frames live in the walk's verbs — `scope_enter`/`scope_exit`
      for a scope, `seats_enter`/`seats_exit` for the seats' bracket
      (no statement list, so no frame), `arm_stmts` for a
      statement-list arm — so a bracket emitted raw is invisible to
      them: a `defer` written inside runs at the ENCLOSING frame's
      end (an `if` statement's branch did, landing `defer`). Eight
      sites converted at discovery (three loops, the comprehension
      walk, the block, the fn, the lambda, the entry). LICENSED at
      the four verbs that ARE the spelling; an Emitter's own `give`
      in a synthesized body (suite_entry.av) has no context and is not
      the smell.
- I39 (ratcheted) A VOCABULARY VERB AS A FREE FN TAKING A PASS
      STATE FIRST — `open_region(cx, c)`, `accepts(cx, e, want)`,
      `sig(ws, d)`. A state struct's impl IS its vocabulary, so the
      verb is a method (`cx.open_region(c)`, `ws.sig(d)`) and the
      context reads as the receiver it is: eight of nine lines of a
      lowering rule once carried `cx` as a first argument. Landed
      as sugar 1's level one (docs/2026_09_09_SUGAR_1_CONTEXT_
      RECEIVER.md): 320 verbs across the shared vocabularies
      (checks, values, emit, unify, variants, places, contexts,
      contract, namespace, builder) and the drivers (workspace,
      receivers, typing, lower, interp) became methods in one
      scripted sweep, every call site with them; the IR of 88
      programs was byte-identical before and after. THE REACH is
      the pass's own files — features/*.av and compiler/**.av —
      where the shared vocabularies live; a feature dir's rule
      bodies (`call_type(cx, e)`) are dispatch targets and stay
      free. NOT the smell: a pass ENTRY POINT taking the pass's
      INPUT (`lower(a: Analysis)`, `memory(l: Lowered)`,
      `render_ir(l)`) — that is a pass's one standard signature,
      and a constructor taking a `Host`. LICENSED where a TABLE
      ROW holds the fn as a value (`measured_reg`): a method is no
      value. THE PRONOUN TRAP the sweep hit ten times: `xs.any(
      verb(cx, it))` rewritten to `xs.any(cx.verb(it))` rebinds
      `it` to the NEAREST method call — the wrapper lambda `(k) ->
      cx.verb(k)` is the spelling, as the subset already says of
      `self.rides(it)`. And a `..` before a name is not a field's
      dot: a rewrite that refused `.name` refused `0..name` too,
      and one site read `decls` as undefined.
- I40 (ratcheted) A STRUCTURAL TYPE INTERNED BY HAND —
      `cx.view.types.intern(Type.Opt(cx.view.types.intern(Type.Str)))`,
      the type rebuilt inside out, one `intern` per level. The
      TYPE LITERAL spells it as a program does: `cx.type(string?)`,
      `cx.type(Map<string, want>)`, `types.type(fn(int) -> bool)`.
      Landed as sugar 2 (docs/2026_09_09_SUGAR_2_TYPE_LITERALS.md):
      87 sites in one scripted sweep. THE REACH is every file but
      core/types.av, whose `interned` IS the fold. NOT the smell: a
      shape the literal cannot spell — a declared type (`Enum`,
      `Struct`, `App`, `Var`, `Dyn`, `TypeName`), `Error`, `Null`,
      the empty literals' own types — and a part that is an
      EXPRESSION rather than a name (`Type.Opt(seat!.elem)`): a hole
      is a NAME, so those four sites bind a name first or stay.

- I41 (unratcheted) AN UNWRITABLE SPELLING IS A KEY — a name or a
      key that must never collide with what a program writes is
      spelled with a character the lexer refuses in that position,
      and the reader tests that one character. Three instances name
      the concept: the resolver's scope keys (`name@<file>`, `@`),
      generated declaration keys (`$`), and a template's hole
      placeholders (`${k}`, `l${2}` — `core/holes.av`, read by
      `hole_name`, whose test is `contains("$")`). THE SMELL: an
      in-band tag a program COULD write (a `__gen_` prefix, a
      numbered suffix) or a parallel side table asked "is this
      synthetic". Not ratcheted: the smell is a naming choice, not a
      shape a grep can see.

- I50 A ONE-PARAMETER LAMBDA HANDED TO A METHOD CALL IS `it` —
      `cases.any(it == null)`, `declared.find(it.word == item)`,
      `seats.all(retains_of(ins, it) == 0)`. The pronoun says the
      predicate and nothing else: no binder, no annotation, no arrow.
      THE ONE LAMBDA THAT STAYS: `it` binds at the NEAREST enclosing
      method call, so a parameter handed on to ANOTHER method call
      (`held.find((o) -> !store.has(k, o.key))`, `xs.any((k) ->
      self.rides(k))`) cannot be the pronoun — that is the language's
      own spelling, and the matcher never accuses it; nor a block body,
      a nested lambda, or a body that already says `it`. Ratcheted
      (`pronoun_lambda`). Sugar backlog: a pronoun that names its OWN
      call, which would retire the half that stays.

- I51 A MATCH ANSWERING ONLY true/false IS `is` — `match x { .Ready
      -> true, _ -> false }` becomes `x is .Ready`; with the arms
      swapped it becomes `!(x is .Ready)`. THE ONE MATCH THAT STAYS:
      the untested side must be the WILDCARD (`_`/`rest`) — it
      already answers for every variant not yet written, exactly as
      `is`'s complement does. An `or`-run there instead SPELLS a
      registry's remaining variants by name (`rides_fp`,
      `answers_word` in llvm.av — RtKind is a registry, and folding
      it to a boolean forgets the next variant exactly as a
      catch-all would), so the matcher never accuses one; nor an arm
      carrying a payload, nor a match of more than two arms, nor one
      over a nullable enum (`is` there is F2013) or over a literal.
      Ratcheted (`bool_variant_match`).

- I52 A NULL TEST THAT PICKS THE VALUE OR A DEFAULT IS `??` —
      `if x == null { d } else { x! }` is `x ?? d`, and with the arms
      swapped on `!= null` it is the same thing. THE ONE TERNARY THAT
      STAYS: a present branch that does anything MORE than `x!`
      (`x!.text()`, `f(x!)`) — `??` hands back `x` itself, never a
      derived value, so those stay written out. Restricted to ONE
      PHYSICAL LINE, which is what keeps a default from ever being a
      block of statements (a statement cannot span a `;`) and a
      subject from ever being a call written twice (a call's parens
      are never part of the matched name).
      Ratcheted (`if_null_ternary`).

- I53 A LITERAL COPYING EVERY OTHER FIELD FROM ONE VALUE IS `with` —
      `Scope { tier: top.tier, managed: top.managed.concat([r]),
      cells: top.cells }` becomes `top with { managed:
      top.managed.concat([r]) }`. THIS SMELL CAN SILENTLY CHANGE
      BEHAVIOUR: a literal built from a DIFFERENT type than `v` only
      happens to share field NAMES (`Directive { twin: "", name:
      t.name, at: t.at, source: … }` where `t: MetaType` — the
      annotation-crossing convention throughout `core/*_derive.av`),
      so the matcher traces `v`'s DECLARED type — an enclosing
      `impl`'s receiver, a parameter's annotation, a `let`'s
      annotation, or one hop through a bare `x!` unwrap — and
      accuses only when it can CONFIRM that type equals the
      literal's own; an unknown or a mismatched type is never
      accused, nor a literal spanning more than one line (the whole
      field list must be in hand at once to judge it). Ratcheted
      (`modified_copy_literal`).

- I54 AN if/else-if LADDER OF 3+ ARMS ANSWERING A VALUE IS `when` —
      `let base = if a { x } else if b { y } else { z }` becomes
      `let base = when { a -> x, b -> y, _ -> z }`, and the same
      reads over a match arm's `->`, a `return`, or a fn's tail. THE
      ONE LADDER THAT STAYS: an arm that is not a single-line VALUE
      — a `return`/`fail`/`break`/`continue`, an assignment, a
      nested `if`, or a body spanning more than one line — since
      `when`'s arms are values and this never combines a nested
      condition into one; a ladder of only two arms; and a bare
      `if` mid-body that closes some OTHER block (a `while`, a
      `for`) rather than standing as its own fn's tail. Ratcheted
      (`when_ladder`).

- I55 `let x = E` GUARDED BY AN IMMEDIATE ABSENCE EXIT IS `let x? = E
      else { … }` — `let held = get()` then `if held == null { return
      null }` becomes `let held? = get() else { return null }`, and
      every later `held!` in the same block reads `held`. THE ONE
      GUARD THAT STAYS: `x` that is a `mut` binding, a parameter, or
      a field/path (`self.store == null`) — only an adjacent
      immutable `let`; a later use of `x` that is not an unwrap
      (passed to a `T?` seat, compared to null again, `x?.f`) — the
      rewrite makes `x` non-null for the rest of the block, so a
      surviving nullable read would refuse or silently change
      meaning; a guard with `||`/`&&`; a `let` with an explicit
      NON-nullable annotation; and a name a LATER binding in the
      same block could SHADOW (a lambda or `for` parameter, a nested
      `let`/`mut` of the same name) — a text scan cannot then tell
      which binding a later `x!` names. Ratcheted (`let_else_guard`).

- I56 (unratcheted) A MATCH ARM'S VALUE THAT IS `if c { x } else { y }`,
      WHERE ONE BRANCH ANSWERS WHAT ANOTHER ARM OF THE SAME MATCH
      ALREADY ANSWERS, IS A GUARD — the branch that duplicates becomes
      the fall-through, and the arm keeps only the branch that does
      not: `.Struct(_, _) -> if meta_type(ret, "Derived") { Derives }
      else { null }` beside a trailing `rest -> null` becomes
      `.Struct(_, _) if meta_type(ret, "Derived") -> Derives` (rest
      already answers `null` for everything else, Struct included);
      `.Variant(n, args) -> if n.of == name { padded(args, arity) }
      else { null }` beside `.Wild or .Rest or .Bind(_) or .Lit(_) or
      .Format(_, _) -> null` becomes the guarded arm plus `.Variant(_,
      _) or .Wild or …` — the payload-blind or-run widened to include
      the tested variant, since here nothing else already caught it.
      THE ONE SHAPE THAT STAYS: an arm whose EITHER branch answers a
      value no other arm shares (`.B(b) -> if b { "true" } else {
      "false" }` with no sibling saying either word) — nothing to fall
      to, so the `if`/`else` is the honest spelling; and a wide
      REGISTRY dispatch where every arm computes its own distinct
      answer (the interpreter's instruction stepper: `pc + 1` against
      `b.past_else(pc)`, `b.past_loop(pc)` — CLAUDE.md's own "wide
      REGISTRY, every arm distinct" case). UNRATCHETED: telling "this
      branch is what a DIFFERENT arm already answers" apart from two
      branches that merely LOOK similar needs reading every other
      arm's own answer and judging whether they are the same
      computation — the payload-blind or-run growing to include the
      guarded variant's own pattern is itself a per-site call a grep
      cannot make safely. Found sweeping the 52 `-> if` arm lines
      landed before arm guards existed (avra-8sb5.25.1): 23 converted,
      29 stayed — most of the survivors are the wide-registry shape,
      the rest genuinely answer two unrelated values.

- I49 (unratcheted) A PACK AND ITS UNPACK READ ONE TABLE — two
      conversions that are inverses name their categories ONCE, as a
      registry enum, and each direction is an exhaustive match over
      it, arm for arm. The word slot is the instance: `slot_form`
      says which conversion a category owes the runtime's `int64_t`
      cells, `worded` casts in and `unworded` casts back, and neither
      can learn a category the other has not. THE SMELL: each
      direction written as its own chain of `is` tests, so the two
      drift a category at a time and the gap is not a refusal — an
      unconverted value rides the wrong register file and the callee
      reads a different number. Not ratcheted: no grep links two fns
      as inverses. THE KEEPER IS `make vocab`, which names both
      directions as consumers of the SAME enum and refuses a
      catch-all or an `is` test inside either — so a hole in one
      direction fails the gate whichever direction grew it.

- I42 (unratcheted) A READ ASKS THE SEEN SHAPE, A SEAT ASKS THE
      TYPE — the named-type law (`type Rows = List<int>`) written as
      a code shape. A rule that DISPATCHES ON A SHAPE to read,
      print, measure, walk, index or compare asks `cx.seen_at(e)` /
      `types.seen_shape(ty)`; a rule that JUDGES AGREEMENT asks
      `cx.shape_at(e)` / `types.shape_of(ty)` and keeps the name.
      THE SMELL: a vocabulary row, a property row, a walk head or an
      operand law reading `shape_at` — it answers `.Struct` for
      every named value and the row then absorbs, sometimes with NO
      diagnostic (the map rows did exactly that). Every instance
      found in this slice was a READ. Not ratcheted: no grep tells a
      read site from a seat site, and both spellings are correct
      somewhere. The keeper is the adversarial suite —
      `named_adversarial_test.av` reaches every vocabulary a name
      can stand over.

- I43 (ratcheted) A FACT COLUMN SIZED BY HAND — `filled(store.
      exprs.count(), null)` beside its siblings, a `- self.lo` at
      every read, and a `concat(filled(n - xs.length, null))` where
      the arena grew. Four things live in that shape and NONE of
      them is stated: the STORAGE, the WINDOW the column covers, the
      GROWTH when new ids arrive, and what a read OUTSIDE the window
      means. `SideTable<V>` (core/side_table.av) states all four —
      `side_table(name, lo, hi, seed)` is born total, `get`/`set`
      take the id and never an offset, `grow_to` is the one door,
      and a read outside the window traps naming the TABLE and the
      ID rather than "index 1 is out of bounds (length 0)". THE
      SMELL: `filled(` with an arena `count()` in its first
      argument, and `.index - ` anywhere. NOT the smell: a
      fn-local scratch list keyed by a seat, a field or a type
      parameter (`Pins.slots`, `range_bodies`'s `lo`/`hi`) — those
      have no window and no life past the call. The KEY is a slot
      `int`, not the typed id, because a bound is spellable on a
      free fn's parameters and nowhere else; the typed door stays
      on the owner (`type_at(e: ExprId)`), which is where every
      reader already goes.

- I44 (unratcheted) A POSITIONAL BOUNDARY SPELLS ITS ORDER ONCE — a
      value crossing between two compilations of the same
      declaration travels by SLOT, so the order is a REGISTRY ROW
      carrying the name, the payload count and the reader together
      (`node_readers`, `features/crossing.av`), and the writer takes
      its tag from that same list. THE SMELL: a reader that matches
      slot names as STRINGS, a writer that spells literal tags, or a
      check that lists the expected order in a second place — each is
      the order written twice, and the two spellings part silently
      the day the other side moves a field. The row is what makes the
      boundary check and the dispatch ONE fact. Not ratcheted: no
      grep tells a boundary registry from any other list of rows; the
      keeper is the boundary check itself, whose fixtures move each
      shape and demand the refusal name it.


- I45 (unratcheted) A DERIVE STANDS ALONE IN ITS FILE — a file that
      declares a trait's associated `derive` declares that trait, its
      helpers and `use @std.meta` and NOTHING ELSE. Running the derive
      TYPES the whole declaring file, and it runs while the ANNOTATED
      file's own impls are still registering, so anything else in the
      derive's file is typed against a half-built neighbour. THE
      SMELL: a `static fn derive` beside a walk, a state record's
      impl, or any fn that reads the annotated file's types. THE
      FAILURE IS SILENT AND BLAMES THE INNOCENT — the annotated file
      loses its methods and every CALLER is diagnosed, with nothing
      said at the annotation (51 such errors, all naming a file that
      was not at fault). `core/rebuild_derive.av` is the form;
      `core/protocol.av` and `features/projections.av` already had it
      by accident. Not ratcheted: no grep tells "declares a derive and
      nothing else" from an ordinary file with a trait in it, and the
      shape that breaks it is whatever ELSE the file holds; the keeper
      is the law in CLAUDE.md and the first build that tries.
- I47 (unratcheted) A SPAN WINDOW'S ANCHOR SET HOLDS EVERY MEMBER IT
      COULD CLOSE ON. Optional pieces of a declaration are attached to
      the member they precede by WINDOWS over spans — a window opens
      at the previous anchor and closes at this one — and the whole
      correctness of that lives in the ANCHOR LIST. An anchor list
      that names only SOME of the members leaves the others' pieces
      inside a neighbour's window, so they attach to the wrong member
      SILENTLY: `aligned_marks` opened a variant's window at the
      previous variant NAME's end, which contains that variant's
      entire payload list, so the moment payloads could carry marks a
      variant's LAST payload's mark became the NEXT VARIANT'S. THE
      SMELL: a window helper whose anchors are one KIND of member
      (`List<Token>` of names) while the range it spans holds members
      of another kind (the payload types between them). THE IDIOM:
      one `MarkWindows`-shaped value carrying EVERY anchor, in any
      order, asked per anchor (`w.at(lo)`), so adding a kind of
      member that can carry the piece is adding it to the anchor list
      and nothing else. Not ratcheted: no grep tells a complete
      anchor list from a partial one — the anchors are whatever the
      grammar can put there. THE KEEPER IS THE ATTACK, and it is
      cheap: for each member kind, write the piece on the LAST member
      of one group with another group following, and read it back
      through the printer. Nine such cases round-trip at
      `annotations_adversarial_test.av`'s "payload marks — alignment";
      every one of them would have failed the partial anchor set.
- I46 (unratcheted) A PER-DECLARATION WALK ASKS A STATEMENT'S
      QUESTION TWICE. A declared MEMBER can carry a declaration of its
      own standing on its OWNER'S statement — a record field's DEFAULT
      is minted with the struct's `s` (`decls.av`'s `mint("${owner}#${field}", f, s, …)`)
      — so a law asked `for d in decls_of_file(f)` about that
      statement's members runs once per member declaration too, each
      time with a DIFFERENT view of the owner's annotations. The mark
      law shipped that way for one build: four refusals for one
      mistake, three of them computed with an empty claim set because
      the field's default decl carries none of its owner's `@derive`s.
      THE SMELL: a decl loop that reads `decl(d).stmt` and asks a
      question about the STATEMENT rather than about `d`. The idiom is
      to walk `p.stmts` and find the owning decl once. NOT the smell: a
      question genuinely about the declaration (its sig, its name, its
      own annotations). Not ratcheted — no grep tells a statement
      question from a declaration one; the keeper is a test that pins
      the COUNT (`refused_in`, one mistake one message) over a member
      that has a declaration of its own, which is a field with a
      default.

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

Lists AND ranges: `[f(i) for i in lo..hi]` counts and `[f(i, x) for
i, x in xs]` pairs — the head is the `for` statement's, so whatever
that spells, a comprehension spells too.

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

## A field default is evaluated per construction

A default that CALLS something runs at every construction, so each
value gets its own:

    type Stmt = { raw: Cell<ptr?>, done: Cell<bool> = Cell.new(false) }

Two `Stmt`s hold two cells; setting one leaves the other alone
(measured, both engines). So a default may mint a box — the shared
mutable default that bites in other languages does not exist here, and
a field whose initial value is a fresh box belongs at the field rather
than repeated at every construction site.

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

## Capability contexts: the state's impl is its vocabulary

A pass context (`TypeCx`, `LowerCx`, `ResolveCx`) is the pass's own
STATE, declared in features/contract.av and given its verbs as
METHODS: the walk's verbs where the walk lives (compiler/typing/typing.av's
`impl TypeCx`), the reads over facts (features/contexts.av), and the
shared vocabularies every feature speaks (checks.av, emit.av,
values.av, unify.av, variants.av, places.av) — so a feature's rule
reads as prose on its receiver, `cx.accepts(e, want)`,
`cx.open_region(c)`, `cx.presence(v, held, e) { cx, carried -> … }
else { … }`, and never as `accepts(cx, e, want)`. I39 ratchets it
(the pass's own files); a feature dir's rule bodies dispatch on the
context and stay free.

```avra
fn coalesce_reg(mut cx: LowerCx, e: ExprId, l: ExprId, r: ExprId) -> Reg {
    let v = cx.reg_of(l)
    let held = cx.type_at(l)
    if cx.view.types.carried(held) == null { return v }
    cx.region(cx.presence_of(v, held), e) { cx -> cx.carried_of(v, held) } else { cx -> cx.reg_of(r) }
}
```

A block handed the context takes it as a `mut` seat — heard from the
slot's `fn(mut LowerCx) -> Reg`, never captured: a capture is a copy,
and a copy's `depth` diverges from the box's list. The earlier shape
— fn fields wired at construction, captured by every closure — is
gone with the sweep (the engine's `MatchContext.build` keeps one such
field, the builder dispatch, because a grammar run IS parameterised
by its builders).

## One semantics: lowering IS the meaning

A feature defines what its constructs DO exactly once — in
lower.av. Evaluation is the IR interpreted (compiler/backend/interp.av)
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
the one verb (`typing/impls.av`), called for every method of a
refused impl.

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

- THE ROOTS GREW 2026-09-05: the ratchet reads every std package (`packages/std-time`, `std-process`, `std-io`, `std-cli`), not the compiler and the cli alone — the first sweep found 13 sites in packages written under the bar but outside the tool's eye, all paid; a new `packages/std-<name>/src` joins SRC in tools/idioms.py with its first slice.
- I20/I25 GREW 2026-09-03: a counted refusal also spells `voices.length == n` (a Program's package voices are diagnostics); the ratchet's roots now include packages/std-toml/src, so a standalone package is held to the same bar; I25 reads one variant per line (CLAUDE.md records the one-line-enum blind spot).
