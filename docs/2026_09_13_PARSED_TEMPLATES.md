# Parsed templates — a quote is a tree, parsed where it is written

> 2026-09-13, lane comptime/templates, over lane/comptime at 32fcaf0
> (S4r: text templates parsed at the splice). This doc is the design
> the campaign lands; the design doc's §3.5 is its charter. Status
> lines at the bottom move as slices land.

## 0. What changes for a derive author

Today a quote is TEXT with origins, parsed when it is spliced. After
this campaign a quote is PARSED WHERE IT IS WRITTEN, and every hole
knows its position:

```avra
// a hole in a NAME: one identifier, the hole's origin
quote { fn ${f}_wrapped() -> int { ${body} } }
// a hole in a TYPE, an EXPRESSION, an ARM LIST, a DECLARATION list
quote { impl ${t} { fn eq(other: ${t}) -> bool { match self { ${arms} } } } }
```

What that buys, in the order it is proved:

1. A wrong-shape hole refuses AT THE QUOTE, in the library, with no
   user of it: `${xs}` in a type position with `xs: List<int>` is
   refused when the library is checked, not when someone derives.
2. A hole in a name (`${f}_wrapped`, `l${i}`) is ONE identifier
   wearing the hole's origin. The "first byte" rule is gone.
3. Origin hygiene is by construction: a copied template node keeps
   the writing file as its origin; a filled node wears the target's.
   `Segment`, `quote_starts`, `Piece`, `quoted/spliced/joined` die.
4. `avra expand` names the template beside `// from @derive on …`.

The text of a quote is still available (`c.text()`) — a PROJECTION of
the tree for printing, never what the compiler reads.

## 1. The node model

`Expr.Quote(parts: List<string>, stmts: List<StmtId>, arms: List<Arm>, holes: List<ExprId>)`

- `stmts` or `arms` hold the parsed body, in the WRITING file's own
  store — the body is ordinary Avra parsed by the ordinary grammar.
- `holes` are the hole expressions, in body order.
- `parts` are the runs of source between holes (one longer than
  `holes`): the printing projection, and the quote's own text for
  `text()`. The compiler never parses them.

**The body's KIND is what parsed** (§3.5's ordered choice):

| body | kind | the quote answers |
|---|---|---|
| one or more match arms | arms | `@std.meta.Arms` |
| statements, every one a declaration (`fn`, `type`, `enum`, `impl`, `trait`) | decls | `Decls` |
| statements whose tail is an expression | expression | `Code` (one statement: the expression itself; more: a `Block`) |
| statements with no value | statements | `Stmts` |

**A hole is a NAME the program cannot write.** The lexer hands every
hole to the grammar as a token of kind `Hole` whose text is `${k}`
with `k` the hole's index in the quote — `${0}_wrapped`, `l${2}`,
`${1}`. A `Hole` token matches wherever the grammar wants a `NAME`,
so every builder mints its ordinary node with a placeholder name:
`Stmt.FnDecl("${0}_wrapped", …)`, `TypeRef { name: "${1}" }`,
`Pat.Bind("${3}")`, `Expr.Ident("${4}")`. No builder changes; no
hole node variants. `hole_name(text) -> HoleName?` (core) is the one
reader: `parts` and the indices.

**A hole's KIND is its position**, classified at build time by ONE
tree walk over the body (`Rebuilder`, §7 — the same registry the
splice copies with) and kept as a store fact per quote
(`hole_kinds_of(e) -> List<HoleKind>`):

| the placeholder sits as | kind | fills with |
|---|---|---|
| a lone `Expr.Ident` in expression position | `Expression` | `Code`; `int`/`float`/`bool` (a literal) |
| part of any name (`l${i}`, `${f}_wrapped`), or a whole non-expression name: a fn/type/enum/trait/let/impl name, a prop, a method, a variant, a field, a param | `Name` | `string`, `int` (its digits), a named meta value (`Type`, `Field`, `Variant`, `Fn`, `Named` — its `name`) |
| a lone `Pat.Bind` under a variant's payload | `Binder` | as `Name`; also `List<string>` (one binder per element) |
| `TypeRef.name` (a param, an annotation, a return, an impl target, a field, a payload, a pin) | `Type` | `Type` (its name), `string` (a spelling) |
| a lone `Expr.Ident` as a whole statement of a block or an impl body | `Statement` | `Stmts`, `Decls`, `Code` (an expression is a statement), and lists of them |
| a lone `Pat.Bind` as a whole match arm (the builder's arm-hole) | `Arm` | `Arms`, `List<Arms>` |

A `string` in EXPRESSION position is REFUSED: `literal(s)` spells a
string literal and `name(s)` an identifier, and guessing either is a
silent wrong program. The refusal names both.

**Kinds are enums.** `MetaKind` (`Code`/`Stmts`/`Arms`/`Decls`) is
what a template value wears and what a quote answers; `meta_name` is
the ONE projection to text, for the door that finds `@std/meta`'s
declarations by name. What a hole's value IS is a `FillClass`
(`Template(kind)`, `Templates(kind)`, `Number`, `Text`, `Texts`,
`Named`), and `fits(class, seat)` is the ONE seat law, read by typing
at the quote; the splice materializes a fill BY its seat's kind, so a
fill of another shape there is the compiler's own disagreement and is
SPOKEN as a defect (`Rebuilder.misfits`), never spliced quietly.

**A body of nothing but holes** takes its FIRST hole's kind (several
expressions being statements), and every other hole must agree or the
quote refuses a mix — position, not a guess. Its holes' seats follow
that kind; at the splice such a template takes the seat it is put in.

## 2. The lexer — what it still takes whole

Today `quote {` puts the lexer into a RAW scan (`scan_quote_part`).
After: `quote {` opens a QUOTE FRAME and the body is tokenized
normally, with three rules:

1. **A hole is `${` … `}` in code position.** The inner tokens are
   NOT emitted in place: they are collected into the frame's DEFERRED
   groups and emitted after the quote's closing `}`, each group as
   `HOLE_BEGIN … HOLE_END`. In their place the lexer emits ONE `Hole`
   token. A string literal's `${` inside the body is the GENERATED
   program's interpolation (§3.5) and lexes as today (ISTR tokens);
   inside THAT hole we are in code position again, so `"${self.${f}}"`
   is an interpolation whose expression carries a quote hole.
2. **Name characters adjacent to a hole join it**: `l${i}`, `${f}_w`,
   `${a}${b}` are each ONE `Hole` token; its text is the placeholder
   with the holes' indices (`l${2}`), its runs are the name pieces.
3. **The frame's `}` closes the quote**: emitted as a token (the S4r
   law — the stream stays balanced), then the deferred groups.

Nested quotes inside holes work by the frame stack: a token's sink is
the innermost frame whose hole is open; a frame's deferred groups are
its own. `"${quote { x }}"` and `quote { ${quote { y }} }` (the
adversarial pins) hold.

What the lexer STILL takes whole: a `grammar { … }` body (unchanged),
and a string literal (unchanged). A quote body is not raw any more —
which is the whole point.

## 3. The grammar (three lines)

```
primary = "quote" "{" ( a:arm ( "," | BREAK )* )+ "}" ( HOLE_BEGIN h:expression HOLE_END )* -> quote_arms(a, h)
        | "quote" "{" ( s:stmt | BREAK )* "}" ( HOLE_BEGIN h:expression HOLE_END )* -> quote_stmts(s, h)
arm = p:pattern ( "or" p:pattern )* ( "->" v:expression )? -> match_arm(p, v)
```

The arm's `->` becomes optional so a lone hole can stand as an arm;
the BUILDER refuses a missing `->` on anything but a lone hole
pattern (the law the grammar cannot state). `HOLE`, `HOLE_BEGIN`,
`HOLE_END` join `term_kind`; a `Hole` token satisfies a `NAME` prim
(`Token.kind_matches`, one place) and matches no literal.

## 4. The value — `@std/meta`

```avra
export enum Node {
    Template(file: string, at: int, parts: List<string>, fills: List<Node>)
    Name(text: string)          // an identifier
    Text(text: string)          // a string literal
    Int(value: int)
    Float(bits: int)
    Bool(value: bool)
    Interp(parts: List<string>, holes: List<Node>)   // a generated interpolation
    Many(items: List<Node>)                          // arms, decls, statements, binders
}
export type Code  = { node: Node }   // an expression
export type Stmts = { node: Node }   // statements
export type Arms  = { node: Node }   // one or more match arms
export type Decls = { node: Node }   // one or more declarations
```

Verbs: `name(text) -> Code`, `literal(text) -> Code`,
`interpolated(parts, holes: List<Code>) -> Code`, and `text()` on
all four (the printed projection: parts woven with fills). Retired:
`Piece`, `quoted`, `spliced`, `joined`. `Directive.source: Decls?`.
`Template.file`/`at` identify the quote NODE (the writing file, the
quote's byte offset); `parts` are for `text()`.

Why a `Template` carries no tree of its own: the tree lives in the
compiler (the writing file's store). The value only names it and
carries the fills. What crosses the boundary stays small (§4.3).

The compiler's lowering of a quote is ONE `template(file, at, parts,
fills)` call wrapped by the kind (`as_code`/`as_stmts`/`as_arms`/
`as_decls`), each fill coerced by its hole's kind through a meta
verb: `int_node(n)`, `name_node(s)`, `names_node(xs)`,
`code_nodes(xs)`, … — one row per (kind, accepted type), all
one-liners in meta. A named meta value coerces by a field read of its
`name` then `name_node`.

## 5. The crossing

`Decls.node_of_meta` reads a `Node` back from the meta heap: an enum
crosses as a node whose slot 0 is the tag (values.av's law), variants
by the meta enum's declaration order. A hole-free quote handed to an
annotation (`@wrapped(quote { tmp })`) crosses from the parse tree as
`Code { node: Template(file, at, parts, []) }` (values.av's
`quote_meta`, rewritten).

## 6. The splice

`admit(f, decls: Decls, ann, at, vis)` materializes a `Node` into the
target file's store:

- `Template(file, at, fills)`: find the quote node in
  `store_of(file)` by offset (`quote_at(offset)`, a store index);
  materialize each fill by ITS hole's kind (a `Filled` value: an
  `ExprId`, a name, a list of `StmtId`, arms, binders); then copy
  the body into the target store with the `Rebuilder`, substituting
  at every placeholder.
- `Name`/`Text`/`Int`/`Float`/`Bool`/`Interp` in an expression seat:
  alloc the node (no span). `Name` in a name seat: the text.
- `Many`: each item, concatenated in its seat.

A generated source can no longer FAIL TO PARSE: `expansion_voices`
keeps only F2077 (a generated name the file already declares). The
parse-refused path and `parse_into("<generated>")` die.

### Origins, by construction

Every copied node records its origin: `Decls.origins` per file, a
dense typed table per arena (`Origins.exprs/stmts/pats: List<Origin>`,
`Origin.Here | Written(file)`), the writing file — `Here` when it is
the target's own (a user's quote spliced back), and `Here` for a node
whose NAME came through a hole (`fn ${f}_wrapped`, `l${i}`: the hole's
origin is the target's). `FileView.origin_of(e)` is that lookup; the
copier hands back the typed ids it minted (`made_exprs/stmts/pats`). `keyed(name, origin)` and `Elsewhere.written_in` are
unchanged — they were always the by-construction half; the
by-segment half (`Segment`, `segments_of`, `segment_at`,
`quote_starts`) is deleted. `Generation` keeps its arena ranges and
the asking annotation's span, for homing only.

### Homing

A copied node keeps the TEMPLATE'S span (its bytes in the writing
file), so `homed` is a projection: origin present → that file at the
node's span; origin absent with a span → this file at the span (the
user's own code); no span (a synthesized fill) → the asking
annotation. No arithmetic over segments.

## 7. The Rebuilder — one registry, two roles

`Rebuilder` walks `Expr`/`Stmt`/`Pat`/`Arm`/`TypeRef`/`Param`/
`Variant` exhaustively (no `_ ->`: a new variant breaks it at compile
time) and rebuilds each node with remapped ids and names passed
through `name(site, text)`. Two roles, one recursion:

- CLASSIFY (at the quote's build): the allocator is identity, and
  `name(site, text)` records `(hole index, kind)` for every placeholder
  it meets. The parent decides a lone hole's kind before descending.
- COPY (at the splice): the allocator is the target store, and
  `name(site, text)` answers the filled name; a lone placeholder in
  an expression/statement/arm/binder seat is replaced by its fill.

The third copy of a tree walk names the concept: `post_order`,
`pronoun_rides`, `fingerprint_expr` each spell the children today;
`Rebuilder` is the first that REBUILDS, so it is new, and the
classify role is its second consumer on day one.

## 8. The laws that speak (positional typing)

Registered kinds, each with a golden, spoken at the HOLE, in the
library's own check:

| refusal | wording |
|---|---|
| wrong shape in a position | "a hole in type position takes a `Type` or a name — this is `Code`" (one line per kind, the accepted shapes named) |
| a string in expression position | "a string in expression position is ambiguous — `literal(s)` spells a string literal, `name(s)` a name" |
| a value no seat takes, in a body of holes | "a hole takes a template, a number, a name, a list of names or of templates, found `List<int>`" |
| a mix of kinds in a body of holes | "a quote of nothing but holes takes ONE kind — its first hole's — and these disagree" |
| an empty hole | "a hole is empty — `${e}` takes an expression" (the builder's word) |
| a quote without `@std/meta` | F2076, unchanged |

All under F2075 ("a hole takes what its seat takes"), each pinned in
`quote_adversarial_test.av` with its count; two are pinned by their
RENDERING (law, label, remedy). A body that does not parse speaks
ONCE, at the library: the generated fn's "body answers `void`" is
silenced for any body holding a parse recovery (`fns/check.av`'s
`holds_error`), written fns included.

## 9. `Code<T>` — §7 question 2, decided again

Typed by KIND, untyped by T. The kind (expression, statements, arms,
declarations) is known AT THE QUOTE from what parsed, so it is a
nominal type (`Code`/`Stmts`/`Arms`/`Decls`) and a hole checks it
statically — that is what "a wrong-shape hole refuses at the quote"
needs, and all it needs. The expression's T is NOT: the template body
is not typed at the quote (its holes have no types until filled, and
a `${t}` type hole makes the body's types unknowable), so `Code<int>`
would be a claim checked only where the generated code is typed
anyway — exactly S4r's argument, which the tree model does not
change. Homing pays the two-frame error. Re-open only if template
bodies are ever typed before splicing (a `Code<T>` whose holes carry
declared types — the sugar backlog's typed holes).

## 10. Provenance

`Provenance` gains `template: Loc?` — the `Template` node's file and
offset. `avra expand` prints:

```
// from @derive on Point — template @std/derive/src/derive.av:24
impl Point { … }
```

A generated declaration made of several templates names the OUTER
one (the directive's source).

## 11. The ladder

The lexer and grammar change is a FRONT-END change: the standing
binary compiles the new compiler happily and the PRODUCT is the first
to read quote bodies as trees. The compiler's own source carries two
`@derive`s whose quotes must be rewritten for the product — and the
standing binary cannot lower the rewritten ones (it emits calls to
`quoted`, which the new meta no longer has). So:

1. `cp build/avra build/avra.pre`.
2. Source S1: the new lexer/grammar/typing/lowering/splice/meta/derive,
   with nodes.av's and contract.av's `@derive` temporarily replaced
   by their hand-written accessors (no quote in compiler source).
   `make avra` with the standing binary → Gen1.
3. Source S2: the two `@derive`s back, as tree quotes. `make avra`
   with Gen1 → Gen2; `make avra` again → the fixed point.
4. `make seed` rides the commit; `sh tools/watch.sh 4000 make gate`.

The second build is the one that reads the new grammar ("the build
that succeeded was the build that lied"); a red second build is
answered by `build/avra.pre`, never by `make bootstrap` from a seed
that predates the change.

## 12. Slices, each gated

- **(a) the tree.** Everything in §1–§7 landed together, since none
  of it stands alone: the lexer, the grammar, the node, the kinds,
  the value, the crossing, the splice, the origins, `@std/derive` and
  the compiler's own derives rewritten, the seed refreshed. Receipt:
  the 15 quote tests (sources updated where they spell a retired
  verb; every assertion kept), the derive program test and
  `std-derive`, the annotations suite; `avra expand` over the derive
  test and over nodes.av/contract.av diffed before/after —
  IDENTICAL generated source. The hole law of today (F2075's
  acceptance set) is kept in (a); only the mechanism moves.
- **(b) positional refusals.** The §8 voices, one golden each, a
  library-side test that refuses with no user; F2075 retired.
- **(c) the name hole.** `${a}${b}`, `x${i}y`, an int in a name, a
  hole-named binder and its read from a template run vs from a hole
  (origins measured both ways); the design doc's first-byte prose
  retired.
- **(d) the audit.** `grep` for `Segment`, `segments_of`, `Piece`,
  `quoted(`, `spliced(`, `joined(` over the tree answers nothing
  outside history; `expansion_voices` holds one voice.
- **(e) provenance.** §10, with a golden of `avra expand`.

## 13. Asks recorded for the sugar backlog

- A hole inside a template's STRING LITERAL part (`"${f.name}: …"` as
  generated text) has no spelling — `interpolated(parts, holes)`
  builds it. A `\${…}`-shaped escape was considered and refused: two
  hole spellings in one string is the two-hats law.
- A type hole filled from a SPELLING (`-> ${v.payload[0]}?` in the
  compiler's own ValueProtocol derive) parses the spelling with the
  language's `type` rule — the one text the splice still reads,
  because `Variant.payload` and `Field.ty` ARE spellings in today's
  meta contract. Retires when `Type` values carry `Kind` (§3.6).
- A statement hole in a struct's field list and in a fn's parameter
  list: not classified; refused as "a hole cannot stand here".

## Status

- design written 2026-09-13; sent to the task master before code.
- (a) LANDED 2026-09-13 (gated on the merge with CONST's c0e5cb8).
  Sources that spelled a retired verb or the old `Code` answer were
  updated with every assertion kept, except two the mechanism moved:
  the list-in-a-hole refusal now reads "a hole in statement position
  takes …" (the seat's law), and a template that does not parse is
  refused at the LIBRARY's own parse — the second word in the target
  is the hole it left ("the body answers `void`"), no longer "no
  method `loud`". The match grammar gained `hole_arm` (a lone `HOLE`
  as an arm — the arm rule keeps its `->`). A `quote { ${x} }` of
  nothing but holes is the IDENTITY on what fills it (kind
  `Holes`): typing answers the fill's kind, the splice takes the
  seat's. The failed arm attempt on every statement-shaped line of a
  quote body leaks one pattern node (ordered choice, no lookahead) —
  recorded, not paid.
- RED-TEAMED 2026-09-13: 19 programs over the eight classes (10
  promoted to `quote/tests/*` program tests, eval == native; 11 new
  spec cases in `quote_adversarial_test.av`, 16 total). THREE
  DEFECTS, fixed: a hole-only quote typed by its first hole's type
  name and lowered a scalar as a name; two impls of one target in one
  generation shared a generated key; a template's own declaration was
  invisible to its own reads (CONST's case — `generated_named` now
  answers a template-origin read with what its template wrote, the
  declaration's identity being the template's). SURVIVED: every
  wrong-slot fill refuses in its seat's words, one diagnostic each
  (8); the cross-feature kitchen (loops, comprehensions, lambdas,
  match, `it`, a trailing block, a nullable, an interpolation whose
  hole holds a hole) copies and runs; 200 templates spliced twice run
  clean under `AVRA_RC_GUARD=1`; an empty hole and a body that does
  not parse each speak once. POOR BUT HONEST: an unclosed quote and a
  hole inside a hole cascade one extra parse word each.
- REVIEWED 2026-09-13 (the task master's bar): kinds are enums
  (`MetaKind`, `FillClass`, `fits` — one seat law, `meta_name` the
  one projection to text); origins are typed dense tables
  (`Origins`, `Origin.Here | Written`); a fill that misses its seat
  is a spoken defect (`Rebuilder.misfits`); `Node.Many` carries no
  separator (a seat is decided at the splice; `text()` prints one
  per line); a body of nothing but holes takes its first hole's kind
  and refuses a mix. The split of `Int` from `Bool` in the seat law
  FOUND a hole: a bool fit a name seat as a "number". Same receipt:
  gate green, expand byte-identical, no `.expected` changed.
