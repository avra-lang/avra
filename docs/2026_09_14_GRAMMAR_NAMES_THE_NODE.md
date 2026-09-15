# The grammar names the node

> DRAFT 2026-09-14, phase D of THE PERFECT COMPILER §2. For the task
> master's ratification BEFORE code. The claim: a rule that maps its
> captures into a node's payloads says so, and the builder is derived.
> What stays hand-written is what COMPUTES.

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
fn build_Expr_MutLet(mut b: Builder) -> Result<LangNode, string> { … }   // one per variant
export fn grammar_rows_Expr() -> List<BuilderRow>                        // name -> build
export fn grammar_payloads_Expr() -> List<PayloadRow>                    // variant -> names, types
```

`PayloadRow` is the mapping's own registry (`{ owner, variant, names:
List<string>, types: List<string> }`), and it is what §5 reads. It is
DATA — rows queried by one consumer — so it is a registry, never a
dispatch (THE VOCABULARY SEAM RULE).

### WHERE THE DERIVE EMITS, and why it is not where the enum lives

A derive emits at the DECLARATION it annotates. `Expr`, `Stmt` and
`Pat` live in `core/`, and the code this derive must write names
`Builder`, `LangNode` and `BuilderRow` — all of them `features/`.
So the obvious placement is impossible by the layering, and the
tempting fix is worse than the problem:

MOVING `Builder`/`LangNode` INTO CORE IS REFUSED. `core/` is
infrastructure only, and the layering is one-way — core knows nothing
of features, and a parse-lowering vocabulary is a feature concern
wearing an infrastructure address. Moving it would buy this derive a
convenient home by making every future core file able to reach for a
features type, which is the whole of what the rule prevents.

SO THE DERIVE IS APPLIED FEATURES-SIDE, to a declaration that NAMES
the core enum. `@derive(Grammar)` sits on a features-side declaration
whose whole content is the naming, and the generated rows and builders
land beside it — the same shape `node_scaffold.av` has today, which is
why the scaffold is a faithful stand-in and its replacement is a
deletion plus an annotation rather than a move.

TWO CONSEQUENCES WORTH WRITING DOWN. The derive reads the CORE enum's
variants through `@std.meta` (it is handed a `Type`, not a file), so
naming it features-side costs nothing in fidelity. And a variant
added to `Expr` still cannot be half-added: the derive regenerates
from the enum, so the row and the builder appear with nobody typing
them — the exhaustive guarantee survives the relocation, which is the
only property that had to.

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

A second question D2 must answer: three rules build `Expr.If`
(statement, expression, chained). A printer derived from rules must
pick one. The rule the printer runs backwards is the one whose FIXED
payloads match and whose captures are all present — and for `If` the
statement/expression split is decided by the node's own kind
(`Stmt.IfStmt` vs `Expr.If`), which is already two variants. Recorded
as the check D2 runs first over all ~40 rules; a variant with two
genuinely ambiguous rules needs a mark, and D2 will name them.

## 11. THE BLOCKING ASK — payload names in `@std/meta`

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

**crossing.av and @std/meta's contract belong to phase H/B2b this
week.** Phase D is BLOCKED on this one field and will not touch those
files. The task master routes it: phase H lands it, or phase H hands
phase D a window. Everything else in this document is phase D's own.

## 12. Leave-alones, with triggers

- **The engine's `Captured` and the `Builder` methods stay.** The
  derive generates bodies that call them; nothing about the capture
  protocol moves. Trigger to revisit: a payload type the table cannot
  name.
- **The payload-type table now exists TWICE** — `verb_of` in
  `rebuild_derive.av` and the grammar derive's reader table — keyed
  identically. Two copies may wait; the THIRD names the concept
  (`core/payload.av`, a payload KIND read by every derive). Trigger:
  phase A's `Fingerprint` or `Children` derive wanting the same keys.
- **`grammar/validate.av` does not check builder names** and cannot —
  it is language-agnostic. The node refusals go in the language's
  assembly beside `compose_grammar`, not in `validate.av`. Trigger:
  none; this is the layering.
