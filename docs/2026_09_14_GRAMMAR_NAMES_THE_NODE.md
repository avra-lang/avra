# The grammar names the node

> RATIFIED 2026-09-14, phase D of THE PERFECT COMPILER §2. The claim: a
> rule that maps its captures into a node's payloads says so, and the
> builder is derived. What stays hand-written is what COMPUTES.
>
> STATUS. D0 landed the surface (`05563b4`): the dotted `-> Expr.StrLit`
> grammar, the binding at assembly, `bool_lit` and `str_lit` converted.
> D1 landed the rows (2026-09-15): `@derive(Grammar)` on `Expr`, `Pat`
> and `Stmt`, the row carried on `Builder`, readers by payload NAME, and
> a differential against the hand transcription. §11's blocking ask is
> CLOSED. §4's placement decision was REFUTED by implementing it and is
> corrected in place — read its note before building on it. The three
> builders in `node_scaffold.av` are what remains, blocked on
> avra-8sb5.11.100.

## 1. What is written twice today

A feature writes its rule and then writes, by hand, the function that
turns that rule's captures into a node:

```avra
gram = grammar { stmt = "mut" n:NAME ( ":" t:type )? "=" v:expression END -> mut_stmt(n, t, v) }
```

```avra
fn build_mut(mut b: Builder) -> Result<LangNode, string> {
    let n = b.token(0)?
    let t = b.type_refs(1)?
    let v = b.expr(2)?
    b.make_stmt(Stmt.MutLet(Scoped(n.text), t.first(), v))
}
```

Every line of that body is implied by two declarations the compiler
already holds: the rule (which capture is where) and

```avra
MutLet(name: Scoped, ty: TypeRef?, value: ExprId)
```

(what each payload is). The builder adds nothing but the OPPORTUNITY
to disagree with them — a reordered pair of same-typed captures is a
silent wrong tree, and 77 hand builders across 30 files each carry
that opportunity.

## 2. The surface

The rule names the node it builds, and a capture LABEL is a PAYLOAD
NAME:

```avra
stmt    = "mut" name:NAME ( ":" ty:type )? "=" value:expression END -> Stmt.MutLet
primary = value:STRING -> Expr.StrLit
primary = "[" elem:expression "for" ( index:NAME "," )? name:NAME "in" source:expression
          ( ".." hi:expression )? ( "if" cond:expression )? "]" -> Expr.Comp
```

Order in the rule is free; the payload's NAME is the join. A rule that
computes keeps what it has (`-> fold_binary(l, op, r)`) and says why
in its feature's builders.av doc line.

## 3. What a label converts to

The payload's declared TYPE decides, and the table is the one
`@derive(Rebuild)` already reads (core/rebuild_derive.av's `verb_of`),
keyed the same way:

| payload type                  | the capture is           |
| ----------------------------- | ------------------------ |
| `ExprId` / `ExprId?`          | an expression / optional |
| `List<ExprId>`                | a repeated expression    |
| `StmtId` / `List<StmtId>`     | statements (a recovery hole becomes `Stmt.Error`) |
| `PatId` / `List<PatId>`       | patterns                 |
| `TypeRef` / `?` / `List<>`    | written types            |
| `List<Arm>` `List<Case>` `List<Param>` `List<Variant>` | those records |
| `Scoped` / `?` / `List<>`     | a token's text, as a scope-keying name |
| `Plain` / `Nominal` / lists   | a token's text, in its namespace |
| `string` / `List<string>`     | a token's text, verbatim |
| `int`                         | a token's text, as a number |
| `bool`                        | never a capture — a rule LITERAL (§7) |

THE ARITY RULE, which is what makes an absent capture honest: a
`List<X>` payload with no label is `[]`, an `X?` payload with no label
is `null`, and ANY OTHER payload with no label REFUSES THE ASSEMBLY.
That is what lets `-> Expr.MapLit` cover both `{ }` and `{ k: v, … }`
without a second builder, and it is the SAME LAW the empty-value
doctrine asks for: the empty case is the first case the table writes.

A REPEATED LABEL fills one list in source order. It already does — the
engine accumulates a label across a `*` group and across a branch's
head-plus-tail (`maps` captures `k:` twice today) — so

```avra
primary = "[" ( elems:expression ( "," elems:expression )* ","? )? "]" -> Expr.ListLit
```

is the whole list literal, and interpolation's four captures collapse
to two:

```avra
primary = parts:ISTR_BEGIN holes:expression ( parts:ISTR_MID holes:expression )* parts:ISTR_END -> Expr.Interp
```

and it needed ONE engine change, which this document's first draft got
WRONG and is worth keeping wrong-then-right. It claimed the engine
already accumulated a label bound BEFORE a star, INSIDE it and AFTER
it, citing the DSL's own `seq` rule (`annots`) and `maps` (`k`/`v`).
BOTH CITATIONS ARE REAL AND BOTH ARE THE WRONG SHAPE: `annots` is
starred in *both* positions, and `maps`' last occurrence sits INSIDE
the star. The engine replaced rather than accumulated whenever the
binding was not under a repetition (`bind_label`'s `else { v }`), so
the rule above collected BEGIN and every MID and was then OVERWRITTEN
BY ISTR_END ALONE — `Expr.Interp` got one part beside one hole and
lowering read past the end (`index 1 is out of bounds (length 1)`, on
every package).

THE REPLACE BRANCH HAD NEVER BEEN REACHED BY A COLLECTED LABEL. In
every rule in the tree the final occurrence of a repeated label was
under the repetition, so nothing could tell "a repeated label
collects" from "a label collects while the last match is inside a
star" — the two read identically for as long as no rule ended
outside one. The claim was asserted from code that LOOKED like the
case rather than run against it.

THE FIX IS A LAW, resolved once at `ready`:

> A label that CAN BIND MORE THAN ONCE in one match COLLECTS; one
> that binds once carries its value.

Counted along the sequence — ALTERNATIVES TAKE THE MOST ANY ONE OF
THEM BINDS (only one runs) and a REPETITION BINDS MANY — and stored
as `Item.listed`, resolved and never authored, exactly as
`Item.expect` already is. The alternatives half is load-bearing:
`if_expr`'s `( e:block | e:if_expr )` binds `e` once whichever branch
runs and must stay a scalar, while `if_stmt`'s
`( "{" ( e:stmt | BREAK )* "}" | e:if_stmt )` reaches many through
its starred alternative and collects. Pinned by the program test
`str_lit/tests/interp_arity` at 0, 1, 2 and 3 holes, holes at both
ends, and adjacent holes.

The collapse also RETIRES that builder's hand-written zip check
(`zip_defect_of("interpolation pieces")`): the payload's arity is the
grammar's, so the two lists cannot disagree.

## 4. Where the knowledge comes from — the derive, and the reason

Two candidates, and the prompt asks for the reason, not the pick.

**A generic builder** — one `built(variant, captures)` reading the
node model at parse time — CANNOT be written here, and the seam says
why: a builder is registered as a `BuilderRow { name, build }` whose
`build` is a plain `fn(mut Builder) -> Result<LangNode, string>`. A fn
value carries no captures, so one generic builder cannot know WHICH
variant it is building except from a runtime string — which is the
string-tag dispatch the doctrine refuses, and it would defer to run
time a question the declaration answers at compile time.

**`@derive(Grammar)` on `Expr`, `Stmt` and `Pat`** mints ONE builder
per variant plus one table row describing it. It is the honest one on
its own merits:

- it keeps the exhaustive guarantee — a new variant gets a builder and
  a row with nobody typing anything, and cannot be half-added;
- it reads the DECLARATION (payload names and types), at compile time,
  which is the same source `Rebuild` and `ValueProtocol` read;
- the generated builder's body is exactly today's hand body, so the
  seam under it (`Builder`'s readers, `make_expr`) does not move.

DECIDED: the derive. It generates, per enum,

```avra
export fn grammar_payloads_Expr() -> List<PayloadRow>   // LANDED in D1
export fn grammar_rows_Expr() -> List<BuilderRow>       // NOT landed — see §4's note
fn build_Expr_MutLet(mut b: Builder) -> Result<LangNode, string> { … }
```

`PayloadRow` is the mapping's own registry, and it is what §5 reads. It
is DATA — rows queried by one consumer — so it is a registry, never a
dispatch (THE VOCABULARY SEAM RULE).

> SHAPE CORRECTED IN D1. This section proposed `{ owner, variant,
> names: List<string>, types: List<string> }` — TWO PARALLEL LISTS that
> must stay in step, which is the shape the tree has already paid for
> twice (the `TypeRef` default-field bug, and the law "a promise added
> as a second list doubles every mark site and drops silently wherever
> a site forgets it"). A payload's name and its spelling are ONE value.
> What landed is `{ owner, variant, payloads: List<Payload> }` with
> `Payload { name, ty }`, so a payload cannot lose half of itself and
> the derive writes one run instead of two that could differ in length.

### WHERE THE DERIVE EMITS, and why it is not where the enum lives

> CORRECTED 2026-09-15, in D1, by the first implementer. What this
> section decided — "the derive is applied features-side, to a
> declaration that NAMES the core enum" — HAS NO SPELLING, and the
> paragraphs below now record what was MEASURED instead. The original
> reasoning read perfectly and failed on first contact; that is the
> locally-coherent-defect law, and the section is left standing with
> its correction rather than deleted, so the next reader sees the trap
> and not just the answer.

A derive emits at the DECLARATION it annotates. `Expr`, `Stmt` and
`Pat` live in `core/`, and the code a grammar BUILDER must write names
`Builder`, `LangNode` and `BuilderRow` — all of them `features/`. Both
ways out of that were probed, and both are shut:

**A DERIVE IS ONLY EVER HANDED THE TYPE IT SITS ON.** There is no
spelling for annotating a features-side declaration that merely names
a core enum. Measured at `7ab84f1`:

- `@ann` on `type Alias = Expr` is **F2066** — "`peek` takes `Type`,
  and this is a type", help "`Fn` crosses a fn, `Type` a record or an
  enum, `Named` any declaration". A named type is not crossed as an
  enum at all, so it carries no variants.
- `Named`, the "any declaration" seat, is `{ name: string, at: Loc? }`
  — identity only.
- `@std/meta` has no lookup-by-name, so nothing turns the string
  `"Expr"` into that enum's `Type`.

The original premise — "it is handed a `Type`, not a file" — is true
and does not help: it is handed the ANNOTATED declaration's Type, and
for a naming declaration that Type has no variants.

**AND A DERIVE'S OUTPUT IS FILE-LOCAL**, which the original section did
not consider at all. Not module-local: a SIBLING FILE in the same
module cannot call what a derive made — an enum carrying the derive in
`src/m/a.av` and a sibling `src/m/b.av` calling the generated fn
answers F3000 "no `fn rows_of_Color` is defined", while the same call
from the annotated file works. So even a derive that COULD read
`Expr` from features would still emit into a file that cannot name
`Expr`'s variants.

MOVING `Builder`/`LangNode` INTO CORE IS REFUSED, and this still
stands. `core/` is infrastructure only, and the layering is one-way —
core knows nothing of features, and a parse-lowering vocabulary is a
feature concern wearing an infrastructure address. Moving it would buy
one derive a convenient home by making every future core file able to
reach for a features type, which is the whole of what the rule
prevents.

SO THE DERIVE SITS ON THE CORE ENUMS AND EMITS WHAT CORE CAN NAME: the
PAYLOAD ROWS, `@derive(Grammar)` on `Expr`, `Pat` and `Stmt`, with
`Payload`/`PayloadRow` in `core/` where the node model's own
declaration belongs. Two consequences are paid in D1 and worth seeing:

- `node_payload_rows()` — the union of the three generated fns — is
  written BY HAND in `core/nodes.av`, because that is the only file
  that can see them. Three lines that regenerate nothing when a fourth
  node enum arrives.
- The BUILDERS do not move. Each is one expression naming a CORE
  constructor and FEATURES verbs (`b.make_expr(Expr.StrLit(...))`),
  which neither layer can write alone, so `node_scaffold.av` shrinks to
  its builders instead of dying. The exhaustive guarantee survives for
  the ROWS and not yet for the builders.

**THE CAPABILITY THAT WOULD CLOSE IT** is avra-8sb5.11.100: a derive
may be handed another declaration's Type by NAMING it in the
annotation (`@derive(Grammar(Expr))`, the argument a source-spelled
type name), AND emit where the reader is. Both halves are required —
reading without emitting buys nothing here. That shape obeys the
standing law that a declares-annotation's argument comes from the
source alone, adds no currency, and grows no vocabulary.

**CONSIDERED AND REFUSED: a core-level payload-value union**
(`fn built_Expr(variant, vs: List<NodeArg>) -> Expr?`), which would let
one generic features-side builder construct any variant. It is the
parallel value enum the value protocol already refused, wearing an
argument's clothes instead of a return's: it would grow with every
payload type the node model gains, and every constructor would unpack
it with a RUNTIME check the compiler does STATICALLY today — trading a
compile-time guarantee for a runtime one, in the phase whose whole
subject is that the declaration is the source of truth. Recorded here
so it is not relitigated.

AND THE ORIGINAL SECTION'S OTHER CLAIM SURVIVES INTACT: a generic
builder cannot replace the per-variant ones, for the reason given
below — `BuilderRow.build` is a plain `fn(mut Builder) -> …` and a fn
value carries no captures, so the callee cannot learn which variant it
is. That objection was right; only the placement was wrong.

## 5. The seam: the ordering happens at assembly, not at parse

The DSL's `build` rule grows a dotted form and an argument that may
state a value:

```
build     = NAME ( "." NAME )? ( "(" ( arg ("," arg)* ","? )? ")" )?
build_arg = NAME ( "=" ( NAME | NUMBER | STRING ) )?
```

so `-> Expr.MutLet` parses into a new `Build.Node`, and a LANGUAGE-side
pass fills its SLOTS — one per payload, in payload order — before the
engine ever runs:

```avra
export enum Build {
    Var(name: string)
    Call(name: string, args: List<string>)
    Node(owner: string, variant: string, fixed: List<Fixed>, slots: List<Slot>?)
}
export enum Slot { Label(name: string), Fixed(text: string), Empty }
```

`slots` is NULL UNTIL BOUND, so "unresolved" is a value rather than an
accident: the engine refuses a null-slotted node in its own voice
instead of indexing an empty argument list and trapping. So:

- the engine stays language-agnostic — it never learns what a node is;
- the parse hot path is untouched (one index lookup, as today);
- the label→slot question is answered ONCE per grammar, not per parse.

`node_builder_name(owner, variant)` is ONE definition in `ast.av`,
read by the engine that calls it and by the language that registers
it. Two spellings of that convention would have nothing to keep them
in step.

### Why `Build.Call` does NOT grow an argument type

This document's first draft had `Build.Call(name, args: List<Arg>)`,
with fixed values riding the SHARED argument type. `grammar_lit` is
what refuses it, and the reason generalises.

A `grammar { … }` block is PURE SUGAR: its builder parses the DSL at
COMPILE time and expands it into constructor calls written into the
feature's own file. Widening `Build.Call`'s arguments makes that
expansion emit `Arg.Label(…)` at every build in the tree — so every
feature's `use grammar.{…}` line would need a type it never spells,
and, worse, a USER package writing a sublanguage
(`grammar { … -> f(a) }`) would have to import one too. The cost of
widening a shared type is paid by everyone who already uses it,
including people who will never use the new capability.

Riding the NEW variant costs nobody: only a rule that names a node
carries slots, and only a feature that STATES a payload imports
`Fixed` (today, `bool_lit` alone).

## 6. The three refusals, at the assembly

They live where the resolution does, in first.av's voice — a NAMED
VOICE fn each, stating the law and not the symptom:

1. `rule `primary` names `foo`, and `Expr.Comp` has no such payload`
   — help: the payloads it has.
2. `rule `stmt` builds `Stmt.MutLet` and names no `value` — only a
   list or a nullable payload may go unnamed`
3. `rule `primary` gives `Expr.Comp`'s `source` a NAME token, and it
   holds an expression`
4. (and the free one) `no `Expr.Quotte` is declared` — a misspelled
   variant cannot reach the dispatch's "no feature owns builder" any
   more; it is refused against the enum.

Each is an ASSEMBLY defect, like `references undefined rule`: the
grammar refuses to run, so no parse can reach a wrong tree.

## 7. What the rule cannot say, and what it gets

`Expr.BoolLit(value: bool)` has two rules and no capture — the payload
is in the KEYWORD. Two honest options:

- **(a)** the two-line builders stay (`build_true`, `build_false`);
- **(b)** a rule may FIX a payload: `primary = "true" -> Expr.BoolLit(value = true)`.

CHOSEN: (b). Not to save four lines — because D2 needs it. A printer
derived from the rules must choose, for `BoolLit(true)`, WHICH branch
prints it, and a fixed payload is the only thing in the rule that can
answer. The same mechanism covers any future keyword-carried payload.
`Expr.NullLit` and `Expr.Receiver` need nothing: no payload, one rule.

## 8. The mapping — measured

77 builder fns across 30 `builders.av` files, 1542 lines. Classified
by hand against the node model (the exact split lands with D1; this is
the estimate D0 commits to and D1 reports actuals against):

| | count | |
| --- | --- | --- |
| plain capture→payload maps, go | ~50 | `str_lit` `interp` `const` `mut` `fail` `null` `match_opt` `if` `if_stmt` `map` `map_empty` `list` `comp` `struct_lit` `for_each` `let_else` `when` `use` … |
| COMPUTE, stay | ~27 | below |

What stays, and the reason each is a rule and not a map:

- **the expression spine's folds** (~11): `fold_binary`, `fold_cmp`,
  `fold_with`, `fold_coalesce`, `fold_postfix`, `trailing`, `catch`,
  `neg`, `bitnot` — a flat repetition becomes a LEFT-NESTED tree. The
  grammar states the run; the ASSOCIATIVITY is the rule.
- **the block law** (`build_block`): a block's value is its tail
  statement's expression, and a scope holding nothing but its value IS
  the value. A node may not be minted.
- **window alignment** (`build_fn`, `marked_fn`, `build_impl`,
  `build_type_decl`, `build_enum_decl`): a `mut` token marks the seat
  whose name follows it, and a default finds its field by POSITION.
  Two flat captures re-aligned by span — computation, and the place
  where the flat-concatenation hazard already lives.
- **desugars** (`build_for`): `cond` and `step` are real nodes the
  grammar never wrote.
- **text slicing** (`build_quote`, `build_sublang`, `build_table`,
  `build_grammar_lit`, `build_component_*`): the payload is a RUN OF
  SOURCE, measured from spans.
- **marks** (`build_export`, `build_once_fn`, `build_mut_fn`,
  `build_static_fn`, `build_annotated`, `build_quote`'s
  `mark_quote_at`, `build_sublang`'s `mark_sublang`): §9.

## 9. Marks — the D1 seam, designed honestly

Nine sites write a side-table mark from a builder. THREE are a
wrapper and nothing else — `build_export`, `build_mut_fn`,
`build_static_fn`:

```avra
fn build_mut_fn(mut b: Builder) -> … { let s = marked_fn(b)?; b.store.mark_mutating(s); .Ok(…) }
```

A mark IS a fact about the node the rule states, so the rule states
it. `@mark(w)` marks THE BUILD'S RESULT, whatever the build was —
which makes it one mechanism over both shapes rather than a
pass-through special case:

```avra
stmt    = "mut" s:fn_sig -> s @mark(mutating)     # a pass-through, marked
primary = "quote" "{" … "}" -> Expr.Quote @mark(quote_at)   # a node build, marked
```

`@mark(w)` names a row in the feature's own mark table (word → the
store verb), so a feature may not mark through another's word and the
assembly refuses an unregistered one.

The remaining six keep hand builders because their BUILD computes
(§8), not because of the mark — and two mark something a rule cannot
state at all: `build_annotated` assembles an `Annotation` record from
captures, and `mark_sublang` records a byte OFFSET measured from a
span. Those two say so at the site.

DEFERRED TO D1'S SWEEP, on a measurement taken while building D0 —
recorded here as the reason it waited rather than as a change of mind.
Of the nine sites, three are pure wrappers, and of those only `export`
sits on a rule that would OTHERWISE BE DERIVED: `mut fn` and `static
fn` wrap `marked_fn`, which is shared COMPUTATION, not a capture. So
`@mark` today retires about one hand builder and adds a per-feature
mark registry to do it. Its payoff is a function of how many derived
rules want a mark, which is exactly what D1's sweep measures — so it
is built when the sweep names them, and not before.

D1 decides this against the real nine; D0 commits only to the shape.

## 10. The printer (D2) — the staging, and the open question

> AUDITED 2026-09-15 before writing D2. Two corrections and one
> sharpening; the section's staging is otherwise right.
>
> **THE DERIVATION'S COVERAGE IS THE DOTTED MIGRATION'S COVERAGE, and
> this section does not say so.** A rule can only be run backwards
> where it NAMES its node — a `Build.Node` — because only then is the
> capture↔payload join known. For `-> mut_stmt(n, t, v)` only the
> builder's BODY knows that `n` fills `name`, and assuming positional
> correspondence is the silent wrong tree D0 exists to prevent.
> MEASURED at `c3a5d3b`: **5** dotted node builds against **230**
> hand-builder arrows over 28 `builders.av` and 90 `build_` fns. A
> printer derived today covers ~2%. AND THE MIGRATION THAT WOULD FIX
> IT IS ITSELF BLOCKED: converting a rule needs a builder for that
> variant, builders cannot be generated across the layer (§4), so each
> rule converted before avra-8sb5.11.100 lands ADDS a hand builder to
> the file the migration exists to delete. The chain is
> avra-8sb5.11.100 → derivable builders → bulk conversion → derived
> printer, and only the last of those is this section's subject.
>
> The `If` count and its resolution were also wrong — three rules
> claimed, two measured, and the proposed disambiguator settling the
> wrong half — and both are CORRECTED IN THE BODY below rather than
> noted here, along with the check that replaces uniqueness.


A rule run backwards prints: its literals print, a capture prints its
payload, and precedence is the rule LADDER, so `source_text.av`'s four
hand-named tiers (`atom_tier`, `unary_tier`, … `loosest_tier`) come
from how deeply a rule sits in the `expression → … → primary` chain
rather than from a scale a person keeps in step by hand.

THE OPEN QUESTION, named now because it decides D2's size: **the
grammar does not carry LAYOUT.** `"{" ( s:stmt | BREAK )* "}"` says
nothing about indentation, about which lists break across lines, or
about the blank line between top-level declarations — and D2's receipt
is `avra expand`'s output BYTE-IDENTICAL before and after. So the
derived printer answers the TOKEN SEQUENCE and a LAYOUT POLICY answers
the whitespace; the policy is one hand-written value (depth, breaking
rules per construct), not one arm per node. D2 lands in that order —
tokens derived first, measured against the golden, policy fitted to
the diff — and if the policy turns out to need per-variant knowledge
after all, THAT is the finding to report, not a reformatted tree.

A second question D2 must answer: SEVERAL RULES CAN BUILD ONE NODE, and
a printer run backwards must pick one. The candidates are the rules
whose FIXED payloads match and whose captures are all present.

THE FIRST CHECK IS NOT UNIQUENESS. It is whether the candidate rules
PRINT THE SAME TOKEN SEQUENCE — and that is the design, not a
refinement of it. `if` is the worked example, measured at `c3a5d3b`:
FIVE rules anchor on the keyword, and **two** of them build `Expr.If`
(`features/if_expr/mod.av:19` and `:20`), while `:18` builds
`Stmt.IfStmt` and `features/nullable/mod.av:41` builds the `if let`
match. So deciding by the node's own kind — the resolution this
section first proposed — separates the STATEMENT and leaves behind
exactly the pair it was meant to settle. Those two rules are textually
identical but for an `@expect`, so either one prints the same tokens
and the ambiguity is HARMLESS.

A uniqueness test reports a false conflict there, and a false conflict
is worse than none: it would send D2 to invent a disambiguating mark
for a pair that needs no decision. So the check D2 runs first over all
~40 rules asks what the printer actually depends on — do the
candidates AGREE on the tokens — and only a disagreement is a real
ambiguity needing a mark. D2 names those.

## 11. ~~THE BLOCKING ASK~~ — payload names in `@std/meta`: LANDED

> LANDED 2026-09-14 by phase H's B2c (`3cad0d9`), and CONSUMED by D1 on
> 2026-09-15. `Variant` grows `fields: List<Field>` BESIDE `payload`,
> rather than replacing it as this section proposed — a growth the rule
> took in one `make avra`, where the replacement below would have cost
> the two-commit ladder a SHRINK of a checked shape requires. The
> section is kept for its reasoning; the ask is closed.
>
> Two notes D1 paid for. `payload` and `fields` are built by ONE writer,
> so the keepers `paired` and `named` assert their agreement and CANNOT
> currently fail — they are a consistency check between two copies, not
> an oracle, which is why D1's differential uses the HAND transcription
> instead. And collapsing `payload` into a projection of `fields` is
> filed as avra-6ndp with its three consumers named; both lists stand
> meanwhile.


A derive sees a variant through `@std.meta.Variant`:

```avra
export type Variant = { name: string, payload: List<string>, at: Loc? }
```

`payload` is the type SPELLINGS only. **The names are dropped at the
crossing** — `core.Variant` holds `payloads: List<Param>`, and
`features/crossing.av`'s `meta_of_variant` keeps `p` and discards
`p.name`. Without the names there is no label→payload join and §2 does
not exist: three `ExprId` payloads (`If(cond, on_true, on_false)`) are
indistinguishable by type.

The change is small and shared: `Variant.payload: List<string>` →
`payloads: List<Field>` (`Field { name, ty, at }` already exists and
already crosses), plus its `MetaShape` row and `meta_of_variant` in
crossing.av, plus `rebuild_derive`'s two readers.

~~**crossing.av and @std/meta's contract belong to phase H/B2b this
week.** Phase D is BLOCKED on this one field and will not touch those
files. The task master routes it: phase H lands it, or phase H hands
phase D a window.~~ — SPENT. Phase H landed it at `3cad0d9`; phase D
consumed it in D1. Struck rather than deleted because it is a ROUTING
INSTRUCTION, and a stale one does not sit there being wrong, it
recruits. Everything else in this document is phase D's own.

## 12. Leave-alones, with triggers

> AUDITED 2026-09-15. Trigger 1 is PARTLY SPENT, trigger 2 has NOT
> fired but its condition is SUPERSEDED, trigger 3 holds as written.
>
> Triggers 1 and 2 are CORRECTED IN THE BULLETS below rather than
> noted here — a note above a wrong condition leaves the wrong
> condition readable, and a trigger is written to be acted on.
> Trigger 2's replacement is a filed ticket (avra-9tfi); the `Kind`
> retirement was deliberately NOT taken in D1, since it would have
> changed the differential's subject mid-slice and `rebuild_derive.av`
> is not phase D's file.
>
> **3 — holds exactly as written.** `grammar/validate.av` still does not
> and cannot check builder names; the node refusals live in the
> language's assembly (`bind_nodes`, called from `compiler/mod.av`),
> which is where D0 put them and where D1 left them.

- **The engine's `Captured` stays; the `Builder`'s READERS did not.**
  Nothing about the capture protocol moves — `Captured` is untouched by
  D0 and D1, and that is the half of this leave-alone that held. The
  reading surface DID move: D1 gave `Builder` a `payloads` field and
  four NAME-keyed readers (`text_of`, `flag_of`, `texts_of`,
  `exprs_of`) and deleted the three index readers (`text`, `texts`,
  `flag`), because an index is a human counting declaration order where
  a name is the declaration answering.
  TRIGGER, corrected: **a rule converting to a variant whose payload
  has no reader** — `List<Arm>`, `List<Case>`, `MapPairs`, `TypeRef`
  and the rest. The original condition ("a payload type the table
  cannot name") points at the wrong moment: the rows name every payload
  type already, since D1 derives them for every variant of `Expr`,
  `Pat` and `Stmt`. It is CONVERSION that needs a reader, not naming.
- **The payload-type table exists TWICE, and the trigger for it is
  SUPERSEDED — see avra-9tfi.** The two copies are `verb_of` in
  `rebuild_derive.av` and `text_types`/`element_of`/`wanted_carrier` in
  `features/node_grammar.av`, both keyed on a type SPELLING
  (`fingerprint.av` keys on nothing of the sort; counted at `c3a5d3b`).
  This entry waited for a THIRD copy to name the concept. That
  condition will never be the right one again: B2c (`3cad0d9`) landed
  `@std.meta.Kind`, a STRUCTURED type shape, and `workspace.av`'s
  `crossed_field` POPULATES it on every enum payload — so both tables
  are retirable onto a shape TODAY, at two copies, rather than at
  three. `Kind`'s own doc names this as its purpose: "telling
  `List<int>` from a type named `Listen` was a substring test before
  this".
  TRIGGER: none — it is a filed ticket, avra-9tfi, not a condition to
  wait on. A trigger that is already spent should stop reading as
  future work.
- **`grammar/validate.av` does not check builder names** and cannot —
  it is language-agnostic. The node refusals go in the language's
  assembly beside `compose_grammar`, not in `validate.av`. Trigger:
  none; this is the layering.
