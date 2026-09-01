# Dogfooding Avra

Patterns proven in this tree — reach for these before writing the
C-style version. Probe unfamiliar features in scratch first; known
gaps live in CLAUDE.md "bs2 subset notes".

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

Ratcheted: I3 I4 I7 I9 I11 I12 I13 I14 I15 I16 I18 I19 I20 I21 I22 I23 I24 I25 I26.
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
      now guarantees the pop). Zero-arg closures work in bs2 and
      mutate captured locals, so the body just closes over what it
      needs.
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
      contains alone.
- I21 a `mut` nothing mutates is a `let`. The reader is told to
      expect a change that never comes; two survived (a type
      registry threaded through a pass, and its test twin).

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
      signature it is passed as.
- I herein note why I24 is MODULE-scoped: bs2 merges a module's
      files into one bundle, so an import in `program.av` serves
      `mod.av`. Per-FILE unused-import analysis is wrong and will
      delete imports that siblings depend on — it did, and the suite
      caught it.
- I24 an IMPORT nothing in the module uses. bs2 checks neither
      direction (TECH_DEBT: no import closures), so imports are
      hand-kept truth and rot silently — 54 had accumulated, several
      created by the same day's refactors.

- I25 a variant pattern writing the WRONG payload count. bs2 does
      not check pattern arity at all: `.A(_, _)` compiles against a
      three-payload variant and binds the wrong things, silently —
      so growing a node's payload breaks NO call site, and the
      doctrine's "a new field breaks every site at compile time"
      is a promise only this rule keeps. Found two already stale:
      `semantics_of`'s `.Match(_, _, _)` and a test helper's
      `.Pattern(_, _)`, both accepted by the compiler. Only names
      with ONE arity tree-wide are judged, so `Ins.Call` and
      `Expr.Call` never confuse it.

A REFUSAL TEST THAT SAYS `>= 1` ASSERTS ALMOST NOTHING. One mistake
earns one message, so the COUNT is half the assertion — a cascade of
five passes `>= 1` silently. I20 already demands a count beside
`contains`, but it never saw this spelling, and 33 sites used it.
`refused_with(source, phrase)` in @std.avrac.testing makes the honest
form the SHORT one: it pins the count at one and the phrase together,
replacing a shape hand-spelled at 131 sites. `refused_n` is for the
shapes where a cascade is today's truth and pinning it makes a later
improvement VISIBLE — every malformed fn signature is exactly 2.

TRIGGER for the remaining 23: converting them by script FAILED — the
fixtures each suite interpolates differ, so the programs measured
were not the programs the tests run, and nine tests broke. They need
converting a suite at a time, by the round that touches that suite.

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
- THE INSTANTIATION RITUALS (checks.av): every generic surface
      (calls, struct lits, variant lits) shares three verbs —
      `tparams_refused` (the declaration already spoke; absorb),
      `unpinned_of` (the first open Var, voiced by the caller in
      its surface's words), `bound_closed` (ask after unpinned_of
      answered absence). The rule of three minted them: the absorb
      loop and the closing walk had each been hand-spelled three
      times before the extraction. A fourth generic surface joins
      by calling the verbs, never re-spelling the walks.
- I28 a LAW that assembles PROSE. A `spoken(cx, pointed(error_at(…`
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
      reading register 7 of 7. Unratcheted — mint order is
      structure, not a greppable string.
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
    fn defects(self) -> List<Diagnostic> { ... }
}
// callers: g.defects()
```

A method is also the place a CONTRACT gets its name:

```avra
impl Token {
    /// Text equality, never against quoted input — data, not syntax.
    fn lit_matches(self, text: string) -> bool { ... }
}
```

`impl` works on enums too — derived properties live with the type:

```avra
impl Rep {
    fn suffix(self) -> string { match self { .One -> "", .Star -> "*", ... } }
}
impl Prim {
    fn token_name(self) -> string? { ... }
    fn answers_to(self, token: string) -> bool { ... }  // null-guarded ==
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
fn later_def(self, name: string) -> StmtId? {
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
fn alloc_expr(self, e: Expr, span: Span?) -> ExprId {
    mut nodes = self.exprs
    nodes.push(e)
    ExprId { index: nodes.length - 1 }
}
```

(Do NOT capture a `mut` struct in a closure — bs2 emits invalid IR;
capture the `let` struct and go through a fn like this instead.)

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
    .Ident(name) -> self.resolve_name(e, name),
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
implementor must say (bs2 cannot materialize default bodies):

```avra
// @std.errors
export trait Error {
    fn describe(self) -> ErrorInfo
}

// any package
impl Error for Diag {
    fn describe(self) -> ErrorInfo { info(self.kind, self.message) }
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

## Proven but awaiting their first honest use

- **Pipe `|>`** — first real pipeline, not two-arg call rewrites.
