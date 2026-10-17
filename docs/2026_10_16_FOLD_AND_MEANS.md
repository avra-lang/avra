# `@fold` and `means()` — two seams, one law

Status: design for owner approval. Epic: avra-8sb5.89 (tasks .5.7, .5.8, .6).
Base: main 16b28a3b. Probes ran on the standing binary of `../avra-db05c-clean`
(source base: main of the same day; sha not recorded, so a probe is a claim about
behaviour, not a pin). Everything below marked PROBED was run; everything marked
PROPOSED or UNPROBED was not.

## 0. The one-paragraph answer

Both features delete code that is a **fold** or a **rewrite** written as hand
arena plumbing. They are one law seen from two sides: *a node is its shape; the
parse never invents nodes the author did not write.*

| | spelling | one line |
|---|---|---|
| fold | `( turn \| turn )* @fold(field)`, each turn ends `-> Variant` | each turn builds a node whose `field` is the value so far |
| infix table | the **landed, unadopted** `@operators { … }`, plus `"+" = Add` word fixes | the precedence ladder as one readable table |
| means | `impl Meaning for X { fn means() -> Code { quote { … ${self.f} … } } }` | the node stays; its meaning is the template |

| deletes (measured, body lines) | fold | means |
|---|---|---|
| builders | 221 (5 fns) + 78 helpers = ~300 | 93 static + ~140 computed (second tier) |
| side-table marks retired | 0 | up to 7 |
| engine/grammar/passes added (estimate) | ~60–90 in `std-grammar` | one quote kind + a rewrite table + a voice rule |

## 1. `@fold(field)`

### 1.1 What exists today (inventory, file:line, body lines)

All in `packages/std-avrac/src/features/expr_spine/`.

| fn | file:line | lines | class |
|---|---|---|---|
| `build_fold_binary` | builders.av:41 | 10 | binary fold (`\|\| && + - * / %`) |
| `build_fold_bitwise` | builders.av:65 | 12 | binary fold + unmixed-run refusal |
| `build_fold_cmp` | builders.av:107 | 11 | one optional turn + `is` (two spellings) |
| `build_fold_coalesce` | builders.av:179 | 8 | binary fold, one operator |
| `build_fold_postfix` | builders.av:197 | 180 | 14 parallel capture families, merged by span |
| **the five (= the class table's "5 / 222")** | | **221** | |
| helpers that die with postfix | `next_anchor` 19, `more_links` 24, `args_between` 8, `span_lo` 4, `span_hi` 4, `call_hi` 4, `force_link` 4, `prop_link` 4, `bitwise_symbol` 4, `mixed_bitwise` 3 | 78 | |
| stay | `binop_of` 3 (neg and bitnot read it), `asked_expr` 8 + `narrowed_expr` 5 (the `is` marks, see 1.6), `build_fold_pipe` 8 (means, section 2) | | |

Grammar rows deleted from `expr_spine/mod.av`: `fold_binary`, `fold_bitwise`,
`fold_cmp`, `fold_coalesce`, `fold_postfix` (5 of 13 `BuilderRow`s).

### 1.2 The finding that reshapes the ask: `@operators` already exists

`@operators` landed 2026-10-15 (#788, `std-grammar/src/executor.av` `climb`,
`ast.av` `Assoc.{Left,Single,Unmixed}`, `Tier`, `Suffix`) with a differential test
(`std-avrac/src/grammar/tests/operators_diff_test.av`) proving one table and the
17-rule ladder answer the same tree and the same diagnostics. `expr_spine` does
not use it yet (`grep '@operators {'` over feature `mod.av`: nothing).

So the five folds split by what they are:

| class | members | right tool |
|---|---|---|
| **infix operators** (precedence matters) | binary, bitwise, cmp, coalesce, pipe | `@operators` — the table carries precedence, `none` = the comparison never chains, `unmixed(…)` = the bitwise law, `suffix "is"` = `is` |
| **suffix chains** (no precedence, links interleave) | postfix | `@fold(field)` |

P6: "ladder vs climbing" was a false dichotomy — the table reads like the ladder
and costs per operator, not per level (ROADMAP.md:166-181 records ~9% parse cost
per added level; the climb removes eight levels). And fold-vs-table is the same
dichotomy again: both are `acc, turn -> acc`; they differ in how a turn is
*recognised* — by an operator word and a precedence (a table), or by its own
leading token and no precedence (a group). They share one engine seam, `built`
(`executor.av:662`), which `climb`'s `pair` already feeds with `l`/`op`/`r`.

### 1.3 Spelling and semantics (PROPOSED)

**`@fold(field)` attaches at a repeated group's tail** (where `@expect` and
`@trailer` already attach — no new attachment rule). Each branch of the group is a
*turn* and ends in a node build.

- `field` names a payload of every turn's variant. The label of the same name,
  captured before the group, is the seed.
- After a turn matches, its build runs with the turn's labels plus `field` bound to
  the accumulator; the result becomes the accumulator. Zero turns: the seed, unwrapped.
- Span of a turn's node = seed start .. turn end, from the engine's own consumed
  range. This deletes every hand span cursor (`next_anchor`, `call_hi`, …).
- Assembly refuses (same channel as `node_defects`): `field` is not a label
  outside the group; a turn's variant has no `field` payload, or it is not a node
  type; a turn has no build.

**`@operators` additions (PROPOSED, two):**
1. a word may carry a fixed payload: `"+" = Add` fills the tier build's `op`.
   Reuses `Fixed` (`BoolLit(value = true)` precedent); needs the enum's variant
   names at bind time (UNPROBED: `PayloadRow` carries `Kind.Named(name, args)` only;
   `meta_of_named` already crosses enums, so the names exist).
2. a tier's build may be a node build, not only a call (the validator refuses a
   node build in a tier today, validate.av:123 — lifting that is the change).

Why fixed variants and not `op:("+"|"-")` plus a text-to-enum reader: no reader
hook, no `binop_of`, no `bitwise_symbol` (the `>` `>` shift is just the word
`(">" ">") = Shr`). Cost: the grammar repeats a spelling `op_symbol` already
holds (core/nodes.av:272, "THE one projection"). A two-line keeper asserts
`op_symbol(variant) == literal` for every fixed op, so the single source survives.

### 1.4 Before / after per class

**Binary band** — `fold_binary`, `fold_bitwise`, `fold_cmp`, `fold_coalesce`, and
the eight rule lines `disjunction … multiplicative` become one block:

```avra
expression  = l:climbed ( … catch … ) -> catch_any(…)
climbed     = l:unary @operators {
    left   "||" = Or
    left   "&&" = And
    none   "==" = Eq  "!=" = Ne  "<=" = Le  ">=" = Ge  "<" = Lt  ">" = Gt   suffix "is" is_test
    left   "??" -> Expr.Coalesce
    left   "|>" -> Expr.Pipe
    unmixed(mixed_bitwise)  "|" = BitOr  "^" = BitXor  "&" = BitAnd  "<<" = Shl  (">" ">") = Shr
    left   "+" = Add  "-" = Sub
    left   "*" = Mul  "/" = Div  "%" = Mod
} -> Expr.Binary
```

(the table is the precedence documentation, P7; `mixed_bitwise` stays as the one
voice, `Assoc.Unmixed(refusal)` already carries it.) Deleted: `build_fold_binary`,
`_bitwise`, `_cmp`, `_coalesce`, `bitwise_symbol`, four rows; the eight band rules
(`disjunction` … `multiplicative`) become one.

**Postfix** — 180 lines of cursor merging become one rule (sketch; payload names
are assumed, the real ones are `Expr.Prop/MethodCall/Index/CallValue/Force/Propagate`):

```avra
postfix = subject:primary (
      "." "type" "(" ty:type ")" @expect(")", "expected `)` to close the type literal")   -> Expr.TypeLit
    | "?." "type" "(" ty:type ")" @expect(")", "expected `)` to close the chained type literal") -> Expr.ChainTypeLit
    | "." name:NAME "(" args:call_args ")"        -> Expr.MethodCall
    | "." name:NAME                               -> Expr.Prop
    | "?." name:NAME "(" args:call_args ")"       -> Expr.ChainCall      // sugar, section 2
    | "?." name:NAME                              -> Expr.Chain
    | "?." "(" args:call_args ")"                 -> Expr.ChainApply     // sugar, section 2
    | "(" args:call_args ")"                      -> Expr.CallValue
    | "[" index:expression "]" @expect("]", "expected `]` to close the index") -> Expr.Index
    | "!"                                         -> Expr.Force
    | "?"                                         -> Expr.Propagate
    | blocks:trailing ( "else" else_block:trailing )? @trailer(blocks) -> Expr.Trailed
)* @fold(subject)
call_args = ( a:argument ( "," a:argument )* ","? )?
```

What goes away is the *interleaving*: today 14 families are captured in parallel
and re-zipped by span (`jn ji jc jf jb jt jq jx` cursors, `blocked`/`spelled`
flags); as turns each link is one branch with its own labels, so the zip, the
`links.length != names.length` defect, `witness paren`, and the cursors have no
referent. The two ordering laws held by `blocked`/`spelled` ("a block after a
block", "a block after a type literal") become `Expr.Trailed`'s check on its
`subject` — a refusal in the feature's `check.av`, which is step 5 slice 2.

### 1.5 Probes

- PROBED: nested builds exist in the binder — `node_grammar.av` `bound_seq`
  judges "every branch nested in its groups" against the enclosing branch's
  labels — but the executor runs a build only per top-level branch
  (`executor.av:623-640`). A turn build is new at run time, not at assembly.
- PROBED: the `climb` seam already hands a build `l`/`op`/`r` bindings
  (`executor.av:1329-1347`); `@fold` is the same call with the turn's labels.
- UNPROBED (needs the engine): whether exact turn spans change any golden.
  Interior calls today are *narrower than truth* (`call_hi`: "narrower than the
  truth rather than reaching past it"). Label underlines render from the start
  column only (probe output above), so most goldens will not move; `fmt` and
  `mark_written_close` read spans and must be run, tree-wide, before the cutover.

### 1.6 Coupled seams the fold exposes (named, not solved)

| site | want | existing record |
|---|---|---|
| `build_fold_cmp`'s `is` | `Expr.Is` carries its payload pattern as a field (`@facet` today: `mark_is_payload`) | step 5, side-table class |
| `margs_here` `b.store.pronouned(a)` | the `args` field rides the pronoun (`xs.map(it * 2)`); a `@pronoun` seat mark on the field, not a per-builder call | sugar-backlog candidate, site `build_fold_postfix` |
| `build_neg`'s literal fold (`-1` is `IntLit(-1)`) | grammar cannot say "fold only when the built operand is a literal" — `-1.abs()` must stay `-(1.abs())` | `Neg` stays hand, or lowering folds it |

### 1.7 Alternatives

| alternative | why not |
|---|---|
| **A. `@fold` for everything**, ladder kept (`( "+" r:… -> Expr.Binary(op = .Add) \| … )* @fold(l)` per band) | works, but keeps eight levels and their per-level cost, and re-states a table as eight rules |
| **B. one construct: `@operators` grows `suffix … -> Variant` for postfix** | one fewer concept (P17), but a suffix's rule would build *before* `l` exists; to fix, it needs the same "turn with an unfilled slot" seam — `@fold` renamed and moved inside a block that also drags precedence in. Revisit if a second suffix-like chain appears |
| **C. a library fn `fold_left(b, mk)` in hand builders** | deletes ~100 lines, no engine change; but the grammar stops describing the language (P11) and the printer still needs per-node arms |
| **D. status quo** | 221 + 78 lines of arena plumbing, and a span-merge that `fmt` and diagnostics both trust |

### 1.8 Risks

1. The seed: `@fold`/word fixes are *grammar DSL* read by the compiler's own
   `grammar { … }` literals, so the standing binary and the seed must understand
   the notation before `expr_spine` uses it (CLAUDE.md, "A CHANGE THE COMPILER
   CHECKS ABOUT ITS OWN SOURCE", and the grammar-alternative bootstrap trap). Hence
   three landings, section 3.
2. `climb` on the real grammar vs the test grammar: the diff test proves the
   *test* language. Adoption's receipt is the whole suite, goldens unchanged, plus
   `eval == native`; any golden that moves is read, not re-pinned.
3. Error words: a miss's "expected …" comes from `expected_from(min, spent)`, not
   from per-rule `@expect`; the diff test pins message, place and rule, which is
   the surface a program sees.

## 2. `means()`

### 2.1 The substrate already exists — this reuses it

Components expand through a path the doc for it calls "already paid"
(docs/2026_09_23_COMPONENT_EXPANSION.md §5-6, `features/components/template.av`):

| need | already there |
|---|---|
| template read off the parse, no run | `template.av`: "the one `quote` its `expand` answers and the field each hole reads" |
| holes filled by arena ids, spliced not copied | `Filled.{Expr, Exprs, Arms, Stmts, …}` (core/rebuild.av:18), `Rebuilder` |
| hygiene | "a template's names resolve where the quote was written; its binders are origin-keyed (`resolve.av`'s `keyed`)" |
| evaluation order, "once" | F2113 "the template of `made` reads `self.body` twice" |
| "must be one quote over its own fields" | the refusal "the `expand` of `made` is not one `quote` over its own fields" |
| the P7 door | `avra expand <file>` + `expansion_note` under each instance |
| the node keeps the written form | `Expr.Component(…, BodyView.Expanded(lit), …)` |

So `means()` is *the component expansion path for expression and statement nodes*.
No new evaluator: a means is **read, never run** (like `expand`), which also makes it
free of the generation ladder's run-time hazards.

### 2.2 Probes (what the current tree does)

PROBED, file `b.av`, standing binary:

| source | today's message | what is wrong |
|---|---|---|
| `if k is .A(v) { v } else { "s" }` | `a \`match\`'s arms disagree: \`string\` vs the first arm's \`int\`` | the author wrote an `if` |
| `[1, 2].map { .A(v) -> v }` | `\`match\` chooses over an enum, found \`int\`` | the author wrote a block of arms |
| `~s` (s: string) | `\`^\` needs \`int\` operands, found \`string\`` | the author wrote `~` |
| `x \|> 3` | `build.failed` at the single token `x`: "a pipe's right side is a call …" | right words, a whole-expression span would point better |
| `a?.abs()` (a: int) | `type.chain`, in the chain's own words | a different node (`Chain`); `?.m()` call form is the desugared one |

**Voice leakage is real and shipped today** (rows 1-3): the rewrite's words reach
the author, because the rewrite is all the typer ever sees.

PROBED, scratch package, `quote { 1 + ${x} }` with `x: Id`: `type.quote_hole` — "a
hole in expression position takes `Code`, an `int` or a `bool`". `@std.meta.Node`
is a closed, variant-keyed crossing (`crossing.av:144-228`) and cannot carry an
arena id. This decides the type in 2.3.

### 2.3 Spelling (PROPOSED)

```avra
@expr_node
type Bitnot = { value: ExprId }

impl Meaning for Bitnot {
    fn means() -> Rewrite { quote { ${self.value} ^ -1 } }
}
```

- **Reuses**: `impl Meaning`, `fn`, `quote`, `${…}` holes, `self.field`. New words:
  one — `Rewrite`.
- `Meaning` today requires `resolve`/`type_of`/`lower` (contract.av:480). Under
  `means`, all three become **defaults that read the rewrite**: typing types the
  rewrite and records its type for the sugar node; lowering lowers it; resolve
  resolves it. A node implements *either* `means` *or* the three, and the build
  refuses a record that implements neither or both (registry law, "no silent
  default" — a named voice, not a trait default that hides the hole).
- **`Rewrite`** is a compiler-side quote kind, a fifth beside `Code`/`Stmts`/`Arms`/
  `Decls` (`MetaKind`, quote/lower.av `wrap_verb`): same template, holes take
  `ExprId`, `List<ExprId>`, `Arm`s, `Scoped` — the `Filled` set the rebuilder
  already splices. It is **not** `Code`: the lead's spelling `-> Code?` cannot
  hold an operand (probe above) and `Node` must not grow an arena variant.
  Surface cost: quote's hole-class check, `fill_reg`, and the `MetaKind` row.
- A refusal is `-> Result<Rewrite, string>`: `Err(voice)` is the *law the writer
  broke*, carried whole — the builder-refusal channel (`Cause.Builder`, "A BUILDER'S
  WORDS ARE ITS CLAIM") — and spoken at the sugar node's whole span. This is
  what retires `no_stage`, `leading_pipe`, `arms_wrong`-class builder refusals
  into the feature's own voice section.
- **Two tiers.** *Static*: the body is one `quote` (or an `if`/`match` over `self`'s
  fields choosing between quotes) — checkable at assembly, the component rule.
  *Computed*: a quote pattern over a field plus a rewrite (`x |> f(a)` is `f(x, a)`
  needs the stage's shape; `table` needs a loop over rows). v1 ships **static
  only**; computed means recurses into the same `Rewrite` type through
  `quote` patterns (already landed, `type.quote_pat_*`) and is v2. The When
  example in NODES.md is computed (a ladder is recursive); it is not in v1.

### 2.4 The hard parts

**Where diagnostics point.** Every node a rewrite *mints* is recorded in a side
table `minted_by: ExprId -> ExprId` (a fact keyed by typed id, never on the node).
Spliced holes are the author's own nodes, shared, and keep their own spans and
words. A diagnostic whose primary node is minted:

1. is **re-homed** to the sugar node's span (the author's text, not the quote's file —
   the opposite of the component rule, where "a copied template keeps its own file's
   spans so its errors point home" is right *because the template is the library's
   code*; a sugar's template is the compiler's, and the author never wrote it);
2. gains one `note:` — "`~s` means `s ^ -1`" — taken from the same rewrite text
   `avra expand` prints. The message itself is unchanged in v1 (so `~s` still says
   "`^`", now with the note that explains it). A per-sugar `says` override (words
   keyed by a typed refusal, never a string) is recorded as the trigger when a golden
   shows the note is not enough — measure the three rows in 2.2 first.
3. hole-labelled diagnostics ("this is `string`" under `"s"`) point at the author's
   own sub-expression, exactly as today.

This is the answer step 6 calls "an error hook so a sugar's refusals speak in
its own words": refusals the sugar *states* speak by `Err(voice)`; refusals the
rewrite *causes* are re-homed with a note, not re-worded.

**How `explain` / P7 shows it.** `avra expand` prints, under each statement holding a
sugar node, one line per node: `x |> f(a)   means   f(x, a)`. It reads the same
side table the diagnostics do, so the two never disagree. The formatter and every
walk see the written node (`kids()` are the record's fields), which is what retires
the printer marks (`mark_piped`, `mark_sugar_match`, `mark_is_payload`,
`mark_trailing`, `mark_keyed_list`, `mark_table`, `mark_state`): `fmt` prints the
node, and the node *is* the source form (AST source-of-truth epic). Idiom rules
that matched the desugared shape (`Expr.Match` for `if … is`) will see the
sugar; a walk that wants the meaning asks `store.meant(e)`.

**The generation / seed ladder.** A means is read, not run, so it needs no
compile-time evaluation inside a build. What it does need is the *quote kind*
`Rewrite` and the `means` default in `Meaning` to be understood by the compiler
that compiles the source using them — so three landings: (1) the mechanism, used
by no node (standing binary compiles it); (2) `make seed`; (3) nodes move one
feature at a time, each green with goldens unchanged. The rewrite must be
*identical* to today's desugar: the receipt per node is "typed program, IR text and
`eval == native` unchanged".

**Evaluation order and hygiene of quoted names.**
- *Hygiene*: template binders are origin-keyed (EXPANSION §5), so `a?.m(v)` — where
  the author's `v` is spliced inside the template's own `v?` arm — does not
  capture. `chained_binder = "chained value"` (checks.av:1977) and its two special
  cases in `checks.av:1351` go away.
- *Order*: two assembly refusals, named voices. `means.hole_twice` (a field read
  twice — F2113's rule) and `means.order` — holes appear in the template in the
  order their labels appear in the grammar rule (source order); a template that reads
  `b` before `a` for `a OP b` is refused with "bind them in source order with a
  `let`". Both are static: the template and the rule are both read at assembly.

### 2.5 What it deletes (measured on this tree; body lines)

My count does not reproduce the class table's "31 fns / 644 lines" — it counts a
fn in several classes. This list is itemised and checkable:

| tier | fn | file:line | lines |
|---|---|---|---|
| static | `build_bitnot` | expr_spine/builders.av:98 | 6 |
| static | `chained_call`, `chained_apply` | builders.av:381, 391 | 12 |
| static | `build_if`, `bound_arms`, `desugared`, `build_if_stmt` | if_expr/builders.av:6-53 | 33 |
| static | `build_for` | loops/builders.av:10 | 12 |
| static | `build_trailing_arms` | closures/builders.av:51 | 15 |
| static | `build_instance_arms_body` (its twin; one node serves both) | components/builders.av:269 | 15 |
| | **static total** | | **93** |
| computed | `build_fold_pipe` + store `piped` 20, `called_on` 11, `stage_args` 1 | pipe.av:50; core/store.av:711-751 | 40 |
| computed | `build_neg` (literal fold stays hand — 1.6) | builders.av:156 | (10) |
| computed | `build_table` | tables/builders.av:7 | 28 |
| computed | `build_component_keyed`, `keyed_loop_body`, `keyed_child` | components/builders.av:125-193 | 61 |
| | **computed total (without neg)** | | **129** |

Plus up to seven marks and their readers (`core/store.av`: `mark_sugar_match`,
`mark_is_payload`, `mark_piped`, `mark_trailing`, `mark_keyed_list`,
`mark_table`, `mark_state`) and 31 reader sites outside the store. `build_state`
(8) is not a rewrite — it is a binding kind — and stays out.

### 2.6 Alternatives

| alternative | why not |
|---|---|
| **`node X = sugar { means … }` (NODES step 6 spelling)** | needs a `node` word and a second place a node is declared; `impl Meaning` is where the record's meaning already lives (step 2). Same semantics, one more keyword |
| **`means() -> Code?`, `Code` with arena fills** | `Node` is a closed crossing enum; an arena id there would dangle in a user's compile-time run |
| **means returns `Expr` built by constructors** | smallest change, deletes the marks and the parse/typing split, but not the plumbing (`alloc_expr`, spans, `b.span`) and gives up template readability and hygiene — it is today's builders moved |
| **run means at resolve, not at parse** | the rewrite's ids would exist only after a pass ran; `kids()`, spans and fingerprints are parse facts. Parse-time expansion is what components already do |
| **re-word the rewrite's diagnostics per sugar from day one** | words keyed by kind are string-matching; a typed refusal channel is a larger design. Re-home plus a note answers the three probed rows now |
| **keep desugar at parse (status quo)** | the source form is lost, so each sugar buys a store mark and a printer arm, and voice leakage (2.2) has no fix |

### 2.7 Risks

1. **Walks that match the desugared shape.** Idiom rules and any pass keyed on
   `Expr.Match` stop seeing `if … is` as a match. Mitigation: inventory the 31
   reader sites before each node moves; `store.meant(e)` for the ones that want meaning.
2. **A node doubles in memory only if its rewrite is kept.** It is: one extra
   subtree per sugar node, shared holes. ALLOCATION HERE IS CHEAP (CLAUDE.md), so
   price it with `make census` on `check packages/std-avrac` before and after the
   first migration, never assume.
3. **Pronoun and `Named` arguments** (1.6) ride the call protocol today at parse;
   a node that keeps its args as written must say where the wrap happens.
4. **Static-only v1 leaves `pipe`, `table`, `keyed` on hand builders** — 129
   lines stay until v2. That is deliberate: v2's shape (quote patterns as the
   selector) is easier to get right once static means is in use.

## 3. Migration order (each landing green, each deletes what it replaces)

| # | landing | proves |
|---|---|---|
| 1 | `@fold` engine + DSL + validator; no grammar uses it | `std-grammar` suite; a fixture grammar folds |
| 2 | `@operators` word fixes + node-build tiers; no grammar uses it | `operators_diff_test` extended with `= Variant` |
| 3 | `make seed` | cold bootstrap reads the notation |
| 4 | `expr_spine`: binary band → `@operators` (deletes 4 folds + `bitwise_symbol`) | goldens + `eval == native` unchanged; eight band rules → one |
| 5 | postfix → `@fold` (deletes `build_fold_postfix` + 78 helpers); ChainCall/ChainApply/Trailed arrive as plain nodes that still desugar in-builder | `fmt --check` tree-wide, span goldens read |
| 6 | `Rewrite` quote kind + `means` defaults + `minted_by`; no node uses it | `type.quote_hole` goldens; component suite unchanged |
| 7 | `make seed` | |
| 8 | static means, one node per PR: bitnot, `?.` chain pair, `if … is` (+ its 3 marks), `for`, arms-lambda | per node: IR text and `eval == native` identical; one voice golden each |
| 9 | `avra expand` prints sugar; diagnostic note | goldens for the three 2.2 rows |
| 10 | v2: computed means → pipe, table, keyed | separate design round |

Rule: a branch is rebased on `origin/main` only; landings 1+2 can be parallel,
4/5 and 8 serial (each reads the compiler's own source).

## 4. Decisions the owner must make

1. **Adopt `@operators` for the infix band** (recommended), or keep the ladder and
   use `@fold` per band (alternative A, simpler engine, no `climb` risk, eight
   levels stay).
2. **`@fold` as its own construct** (recommended) or fold postfix into
   `@operators` as suffix-with-build (alternative B).
3. **Operator spelling in the table: fixed variants (`"+" = Add`)** with a keeper
   against `op_symbol` (recommended), or `op:` captured with a text-to-enum reader.
4. **`means()` returns `Rewrite`, a new compiler-side quote kind** (recommended) —
   not `Code`, and not hand-built `Expr`.
5. **Means is read, never run; v1 is static only** (recommended); computed means
   (pipe/table/keyed) follows in v2.
6. **Diagnostics from a rewrite: re-home to the sugar's span plus a note**
   (recommended); per-sugar re-wording only when a golden shows the note is not enough.
7. **`Neg` stays a hand builder** (literal folding is data-dependent), or lowering
   learns to fold `0 - IntLit`. And whether to accept that `Pronoun` argument wrapping
   becomes a `@pronoun` seat mark (sugar-backlog entry, site `build_fold_postfix`).

---

# 5. Implementation plan: `@fold(field)` in std-grammar (owner-approved)

Read against main 16b28a3b. Everything here was read from the code; nothing in this
section was run.

## 5.1 Design shifts from sections 1.3-1.4 (corrections found while reading the engine)

| was | now | why |
|---|---|---|
| `@fold` attaches at the group's tail and marks the group | **branch-tail annotation, `Seq.fold: string?`**, exactly like `@operators` (`Seq.operators`) | the DSL attaches annotations per branch (`builders.av:225-239`, `PendingAnnot`); `@head`/`@trailer` mark by label, but a group carries no label |
| the rule answers the fold implicitly | the rule ends `-> subject` (`Build.Var`, `built` `executor.av:677`) | zero engine code for the outer value; reads as "answers the subject" |
| "the executor runs a build only per top-level branch" (1.5) | **wrong**: a group's branches go `match_alt` -> `match_seq`, which runs `built` with the branch's own `s.build` | a turn's node build needs no new build machinery; what is new is the loop and the bindings, below |

## 5.2 Spelling (final)

```avra
postfix = subject:primary ( turn | turn | … )* @fold(subject) -> subject
```

Shape is fixed and validated: exactly two items — a seed item labeled `field`
(any `rep: One`), then one `Rep.Star` group — then `@fold(field)`, then a build that
answers `field`. Every branch of the group ends in a build (node or call, below).

## 5.3 Engine (`std-grammar/src/executor.av`)

New `match_fold` beside `match_repetition` (`executor.av:774`, same speculation
rules: a non-Hit iteration ends the loop and lives only in `farthest`; Fatal
propagates; a turn that consumes nothing is the existing "repetition matched without
consuming input" defect). Called from `match_seq` in place of `match_item` for
`items[1]` when `s.fold != null`. Per turn:

1. `turn_bindings = [b.rebound(field, acc, false) for b in bindings]` — `Binding.rebound`
   exists (`executor.av:~270`); the seed label now holds the accumulator, replacing
   (not accumulating).
2. `match_alt(cx, rule_name, inner, cursor, turn_bindings, false, capped, origin)`.
   Direct call, not `match_prim`: `match_prim`'s Group arm drops an unlabeled group's
   value (`executor.av:~905`), and the turn's value IS the new accumulator.
   `acc: false` keeps a turn's labels last-wins.
3. On Hit: `acc = r.value`; `cursor = r.cursor`; **do not keep `r.bindings`** — a turn's
   labels are turn-local, so a stale `args` from one turn can never fill the next
   turn's variant (see 5.5, same rule at assembly).
4. After the loop: `bindings = rebound(field, acc)`, value `acc`. The branch's
   `-> subject` then reads it.

**Span origin.** `match_seq` computes the builder's span as `consumed_loc(entry, cursor)`
(`executor.av:~637`), `entry` being the *turn's* start. Add a parameter
`origin: int` to `match_alt` and `match_seq` only (callers: `executor.av:410`
`match_rule` and `:900` pass `cursor`; `match_fold` passes the fold branch's `entry`).
`match_seq` uses `origin` for `branch` and nothing else. A turn node thus spans seed
start .. turn end, from the engine, which is what makes every hand span cursor dead.
(Not a mutable slot on `cx`: a nested sequence inside a turn would read it.)

**Open question, check first:** the head law. `open` (`executor.av:~560`) is per
`match_seq`, so a delimiter consumed in turn 1 no longer opens turn 2's trailer.
Today the postfix star is one item inside one sequence and `opens(Group)` is false
(`:730`), so delimiters inside the group never opened either — the two should agree;
prove it with the existing head tests in `executor_test.av` before cutover.

## 5.4 Notation and records (each site, in landing order)

| file | change |
|---|---|
| `std-grammar/src/ast.av:89` | `Seq` gains `fold: string? = null` (a default, so every `Seq { … }` literal compiles) |
| `std-grammar/src/seed.av:~299-355` | `annot` rule gains `"@fold" "(" label:NAME ")"` with `expecting(lit(")"), "expected ')' to close @fold")` -> `Build.Call("build_fold", ["label"])` |
| `std-grammar/src/builders.av:~61, 233, 246, 405` | `PendingAnnot.AFold(label)`; `build_fold` row; applied in the annotation loop to set `Seq.fold`; a second `@fold` on one branch is "duplicate @fold on one branch"; add `.AFold(_)` to `operator_blocks`'s exhaustive arm |
| `std-grammar/src/validate.av` | one `fold_defects(rule_name, s)` beside `operators_defects`: not two items; first not labeled `field`; second not a Star group; a turn branch with no build; a turn build that is a pass-through |
| `std-grammar/src/render.av:~31` | print `@fold(field)` after the items (round-trip) |
| `std-avrac/src/features/grammar_lit/builders.av:82` | `seq_expr`'s field list adds `"fold"` + a `text_opt` (the `grammar { }` literal's value carries it) |
| `std-avrac/src/features/coherence.av:77` | read: it asks a branch's build names; confirm a fold branch's turn builds are reached |
| `std-avrac/src/features/node_grammar.av` | **scope rule, below** |

## 5.5 Node-build binding (`node_grammar.av`) — the one real subtlety

`bound_seq`/`judged` judge a nested build against the ENCLOSING branch's labels
(`outer.labels()`). For a fold that is wrong in two ways: a turn variant could claim a
payload filled by a *sibling* turn's label (absent at run time, so silently `null`),
and the seed would not be visible to the turn. Rule: **for a branch with `fold`, each
turn is judged against its own labels plus `field`** — `fold_scope(turn, field)` builds
that `Seq` and passes it as `outer` to `bound_seq`, `branch_defects`, `judged`. Then:

- the turn variant's payload `field` is filled `Slot.Label(field)` (the accumulator),
- the existing `unfilled_defects` / `stranger_defects` / `shape_defects` apply
  unchanged (the seed is a `Ref`, so `Carrier.Built` — a node payload, as wanted),
- a variant with no `field` payload is refused by `stranger_defects` already.

## 5.6 The `postfix` rule on main today vs after (landing B)

Turns whose variant is a plain node are `-> Expr.X`. Turns that still desugar or
widen in a hand builder use a **call build over the turn's labels**
(`Build.Call(name, args)` reads `bindings`, so `subject` = accumulator is available;
`executor.av:678`). They are one-liners that move to `means()` later:

| link | turn build now | later |
|---|---|---|
| `.name` / `?.name` | `-> Expr.Prop` / `-> Expr.Chain` | same |
| `.name(args)` | `-> method_call(subject, name, args)` (keeps `store.pronouned`) | `-> Expr.MethodCall` + `@pronoun` seat |
| `?.name(args)`, `?.(args)` | `-> chained_call(subject, name, args)`, `-> chained_apply(subject, args)` | `Expr.ChainCall`/`ChainApply` + `means` |
| `(args)` | `-> call_value(subject, args)` | `-> Expr.CallValue` |
| `[i]` | `-> Expr.Index` | same |
| `!` / `?` | `-> Expr.Force` / `-> Expr.Propagate` | same (kills `force_link`) |
| `.type(T)` / `?.type(T)` | `-> type_literal(subject, ty)` / `-> chained_type_literal(subject, ty)` (both exist, `type_lit.av`) | same |
| `{…}` (+`else {…}`) | `-> trailed(subject, blocks, else_block)` | `Expr.Trailed` + `means` |

The two state flags die as **facts of the accumulator**, no cursor: `blocked` is "the
subject is a call whose last argument `is_trailing`" and `spelled` is "the subject
`is_type_lit`" (marks `mark_trailing` / `mark_type_lit` already exist in
`core/store.av`); `trailed` refuses with its two existing words. `call_chains` /
`jx` die: `?.(` is its own branch.

## 5.7 What dies in landing B (exact)

`expr_spine/builders.av`: `build_fold_postfix` (197-376, 180), `next_anchor` (19),
`more_links` (24), `args_between` (8), `span_lo` (4), `span_hi` (4), `call_hi` (4),
`force_link` (4), `prop_link` (4) = 247 lines; `expr_spine/mod.av`: the
`"fold_postfix"` row and the 14-label `postfix` rule. `chained_call`,
`chained_apply` (12) stay until `means`. `margs_here`'s `pronouned` wrap moves into
`method_call`. `binop_of`, `asked_*`, `build_fold_pipe` stay (pipe moves with the
`@operators` lane).

## 5.8 Tests (written first, each witnessed failing without its code)

In `std-avrac/src/grammar/tests/` beside `executor_test.av`:

1. chain of 3 turns builds `((s t1) t2) t3`; zero turns answers the seed unwrapped.
2. span: a turn node covers seed start .. turn end (the test `operators_diff_test.av`
   pins place the same way).
3. **turn-local labels**: two turn kinds, the second variant lacking the first's
   label — assembly refuses the sibling claim (5.5) and run time never reads a stale one.
4. each validator refusal (5.4), plus duplicate `@fold`.
5. render round trip, and `parse_test.av`'s grammar-of-grammars row for `@fold`.
6. head law: `if f(a) { b }` keeps its brace, `g(f(a) { b })` takes the block, with a fold rule.
7. **differential** `postfix_diff_test.av`, as `operators_diff_test.av`: the hand
   `fold_postfix` grammar and the `@fold` grammar over a corpus of chains (every link
   kind, interleaved, `else`, trailing blocks, `?.`, type literals, nested args, a block
   after a block, a block after a type literal), same tree and diagnostics. Delete
   the hand builder only when it is green.

## 5.9 Landings

| # | content | gate |
|---|---|---|
| A | 5.3, 5.4, 5.5, tests 1-6; no grammar uses `@fold` | `avra test packages/std-grammar` and `std-avrac/grammar`; the standing binary builds it |
| — | `make seed` | cold `make bootstrap` reads `@fold` |
| B | the `postfix` rule (5.6), test 7, then the deletions (5.7) | whole suite, goldens unchanged, `eval == native`, `avra fmt --check` tree-wide, `make idioms` |

Risk specific to B: exact turn spans change interior calls (`call_hi` was "narrower
than the truth"); read every golden that moves, never re-pin. A branch rebased on
`origin/main` only; the `@operators` lane touches `expr_spine/mod.av` too, so B
lands after it or merges its rows.

## 5.10 As built (landing A, branch `nodes-fold-design`)

Matches 5.2-5.5 with these differences, all found by building it:

| plan | built |
|---|---|
| turns judged by their own labels (5.5) | also **the list law**: `Seq.seed` marks each turn, `Seq.scope(outer)` picks the judging branch, and `listed_seq`, `bound_prim`, `judged_seqs` and `labels()` all read it. Without it a label inside the star was "many" and a turn's `name` arrived as a list |
| validator: four refusals | six: adds "a turn captures the fold's own label again" and "a fold beside `@operators`" |
| the seed is not shape-checked | still true: the seed item sits outside the turn, so `shape_defects` skips it (`payload_shape` finds no labelled item) |
| diff test vs the 14-family builder | vs a rule of links folded by a builder (the family merge needs real spans); trees and diagnostics (message, place, expected, rule) agree on 40 written inputs, their prefixes and 1500 generated; a `?.`-misreading fold is the control |

Proofs run on `avra-nodes1b`, merge-base compiler `09de33ee` building the tree in one
generation: `std-avrac/src/grammar/tests` 147/147 (head law three ways over a fold,
spans, turn-local labels, notation, six refusals, hostile inputs, 1500-link chain,
differential) and `features/tests` green; `make avra` twice; `make cache-attacks-a`
457 builds, 0 failed; `fmt --check` clean; `check --baseline tools/idioms.baseline`
for std-grammar and std-avrac clean. Not run: the whole std-avrac suite (the PR gate's).

## 6. Follow-up plan: `@operators` words (`"+" = Add`), from nodes-operators' report

Source: nodes-operators' message (branch `nodes-operators`, 50598d9b engine,
c1874098 adoption). Not read here beyond that report; verify against their branch
before building. They adopted the table with small tier builders because the DSL
cannot say a node build in a tier. Their list, and what kills each:

| tier builder (expr_spine) | dies when |
|---|---|
| `build_binary` (builders.av:40), `build_bitwise` (:57), `binary_of` (:71) | a word fixes `op` and the tier builds `-> Expr.Binary` |
| `build_unmixed_bitwise` (:63) | stays: it is the `unmixed(…)` refusal (a voice), but loses its placeholder return once the refusal channel needs no value |
| `build_compare` (:108) | the `none` tier builds `-> Expr.Binary`; `is` goes through `suffix` with its own node build (needs the payload pattern kept as `Is`'s field, step 5 `@facet`) |
| `build_coalesce` (:175) | `left "??" -> Expr.Coalesce` |
| `build_pipe` (pipe.av:50) | stays until `means` |

Engine and DSL work, in one landing after `@fold` (shares the `built` seam, so rebase
around `climb`'s `ceil` change):

1. `Tier.words` carries a fixed variant per word: `Word = { tokens: List<string>, op: string? }`
   (one record, never a parallel list); `OpEntry` carries it. `seed.av` `word`
   rule: `word ( "=" NAME )?`; `builders.av` `build_word`/`build_tier`; `render.av`;
   `grammar_lit/builders.av` `tier_expr`.
2. `validate.av` `tier_build_defects`: accept `.Node` (lift the refusal at `:123`); a
   node build in a tier reads `l`, `op`, `r`.
3. `node_grammar.av`: bind a tier's node build against the tier's own scope: labels
   `l` and `r`, plus `op` when any word fixes one. Today `bind_nodes` never visits
   `s.operators`; this is the same "scope per build site" move as 5.5.
4. `executor.av` `pair`: bind `op` to the taken word's fixed text when it has one,
   else the operator token, and let `built` run the node build.
5. `BinOp` as a payload a rule can fill from text: `core/makers_derive.av`
   `known()`/`slot()` plus a `Slots` reader that resolves `Add` etc. (nodes-operators
   names `op_of` through `op_symbol`). Its keeper — each fixed word equals
   `op_symbol(variant)` — is their `tests/operator_words_test.av`.
6. Tests: the existing `operators_diff_test.av` extended with `= Variant` words (tree and
   diagnostics unchanged), a tier-build binding test beside `node_grammar_fold_test.av`,
   the validator refusal, render round trip, and a `parse_test.av` row.
