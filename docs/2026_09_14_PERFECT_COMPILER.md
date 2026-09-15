# The perfect compiler — a model, derived

> DRAFT 2026-09-14 (task master + owner), for polishing. The principle:
> the language is a MODEL declared once (nodes, types, instructions,
> diagnostics, runtime rows) and every MECHANICAL surface — walks,
> copies, fingerprints, printers, projections, dispatch, crossings,
> builders, keepers — is DERIVED from it. Only MEANING is written by a
> person: typing rules, lowering, the memory pass, the evaluator, the
> backend, the grammar text, the words in a diagnostic, the runtime C.

## 1. The node model declares everything about a node, once

```avra
/// A name that keys a scope; a name that keys none.
type Binder = string
type Member = string

@derive(Children, Rebuild, Fingerprint, ValueProtocol)
export enum Expr {
    Ident(name: Binder)
    Prop(subject: ExprId, name: Member)
    Call(callee: Binder, pins: List<TypeRef>, args: List<ExprId>)
    Lambda(params: List<Param>, body: ExprId)
    /// its body belongs to the code it generates
    @verbatim Quote(parts: List<string>, stmts: List<StmtId>, arms: List<Arm>, holes: List<ExprId>)
    /// its expansion replaces its holes
    @expands(expansion) Sublang(word: string, body: string, holes: List<ExprId>, expansion: ExprId?)
}
```

Derived from the payload types: the child walk (`ExprId`, `List<ExprId>`,
`ExprId?` are children), the copier (`Binder` through `name`, `Member`
through `plain_name`), the fingerprint (tag + one folded value per
payload — the arity law by construction), the value protocol. The two
semantic arms are MARKS on the variant, read by the derive.

**A MARK IS DATA; AN ANNOTATION IS A CALL.** Both are written `@word`,
and that is where the likeness ends. An annotation stands before a
DECLARATION and the compiler CALLS it at compile time, so its arguments
are expressions — something evaluates them. A mark stands before a
declared MEMBER — a variant, a field — and nothing runs: it is recorded
and handed to whoever reads it, so its arguments are WORDS. The reason
is not economy, it is TIMING: a mark is read while the file's names are
still resolving, so it can reach only what the parse holds. It is the
Declares-argument law (a generated name must exist while names are
being made) one notch stricter, and it is why a mark cannot be an
annotation with a clever seat.

Two consequences follow, and both are laws rather than conveniences.
THE COMPILER JUDGES NO MARK: a mark's meaning lives with its reader, so
there is no registry of legal words and a package may mint its own.
AND EVERY MARK OWES A READER: a reader says which marks it claims (a
trait's `marks` beside its `derive`), and a word no reader on that
declaration claims is refused WHERE IT WAS WRITTEN. Without the second
law the first ships a silent typo — `@verbatm` sitting on a variant
forever, doing nothing, with no diagnostic anywhere. The claim set is
`List<string>?` and not `List<string>`: an empty claim set refuses every
mark, an UNANSWERABLE one must refuse none, and spending one value for
both is how the first implementation refused four marks for one
mistake.

ITS MIRROR, at the other end of the same seam: AN ANNOTATION THAT
CANNOT MEAN ITS DECLARATION MUST SAY SO THERE. `@derive` itself takes
`Named`, which fits every declaration by design, so the receiver law
passes whatever is written and the trait's OWN `derive` — which takes
`Type` — is never asked whether it fits. Landed on a fn, the crossing
hands it a record with no fields and no variants, indistinguishable
from an empty one: nothing is generated, nothing is said, and every
CALLER of the method that was never made is blamed instead (43 errors,
each naming an innocent file). The seat law reaches the second hop.

## 2. The grammar names the node; the builder and the printer are the rule

```avra
component LanguageFeature quote {
    gram = grammar {
        primary = "quote" "{" parts:STRING "}" -> Expr.Quote
                | "quote" "{" parts:ISTR_BEGIN holes:expression ( parts:ISTR_MID holes:expression )* parts:ISTR_END "}" -> Expr.Quote
    }
}
```

A label is a payload name; a repeated label fills a `List`, an optional
one a `?`; a rule that needs computation keeps `-> build_x(…)`. The
rule run backwards is the printer: literals print, a capture prints its
payload, precedence is the rule ladder — `source_text.av` and its
mirrored tiers go; `avra fmt` is `print(parse(src))`.

## 3. One meta vocabulary, one crossing each way

```avra
use @std.meta.{Type, Directive, Node}

let t: Type = described(decl)
let made: List<Directive> = lifted.answer(derive_fn, [t])
for d in made {
    match d.source {
        .Made(node) -> splice(node),
        .None -> nothing(),
        .Foreign -> …,
    }
}
```

The compiler's mirrors (`features.Directive`, `Code`, `Node`) are deleted.
Two generic verbs remain — `into_evaluator(v, ty)` and
`from_evaluator(v, ty)` — each a walk of the TYPE over headered boxes,
which static data already proved in one direction.

## 4. Type shapes carry their properties as marks

```avra
export enum Type {
    @scalar Int
    @scalar Float
    @scalar Bool
    @boxed Str
    @boxed List(elem: TypeId)
    @boxed Map(key: TypeId, value: TypeId)
    /// pointer-shaped when its inner is; a register pair otherwise
    @by(inner) Opt(inner: TypeId)
    @flat Struct(decl: DeclId, name: string)
}
```

`is_managed`, `rides_pointer`, `printable`, `texted` and ~20 exhaustive
lists become three derived predicates plus one honest hand arm per
conditional shape, marked `@by(...)` so the derive asks.

## 5. Instructions name their roles

```avra
@derive(Roles, Text)
export enum Ins {
    ConstInt(@dst dst: Reg, value: int)
    Call(@dst dst: Reg, @symbol callee: string, args: List<Reg>)
    CallRt(@dst dst: Reg, @host callee: string, args: List<Reg>)
    Retain(reg: Reg)
    IfStart(cond: Reg)
}
```

`dst_of`, `body_symbol`, `hosted_symbol`, the IR printer: derived. The
evaluator's `step`, the memory pass, `emit_ins`: written — the meaning.

## 6. Ownership is declared, not mapped

```avra
export enum Expr {
    @owned(str_lit) StrLit(value: string)
    @owned(str_lit) Interp(parts: List<string>, holes: List<ExprId>)
    @owned(quote)   Quote(…)
}
```

`semantics_of` and `Dispatch` derived; an unowned variant refuses the
build; an owner may only be a feature.

## 7. The runtime rows generate the C

```avra
export const rt_sigs: table<RtSig> {
    name              | seats        | answer | owns  | reach
    "avra_str_join"   | [Ptr, Ptr]   | Ptr    | true  | Pure
    "avra_embed"      | [Ptr]        | Ptr    | true  | Embed
}
```

`avra runtime-header` writes `runtime/avra_rt.h`; the C includes it
last, one `_Static_assert` per row; a wrong width fails in the C
compiler. LANDED (phase G).

NOT `avra emit runtime-header`: `emit` takes a FILE, so a magic string
argument makes one word mean two grammars and a real file of that name
would change what the command did — the split-the-verb law. One verb
per grammar.

AND `tools/externs.py` DOES NOT RETIRE. Measured at phase G: 83 rows
against 230 `extern fn` names the tree declares, overlapping in 32. The
other 198 — the vendored sqlite wall, @std/process, @std/io, the width
witness — are not rows, and a header generated from `rt_sigs()` has
nothing to say about them. Six of the keeper's checks are not widths
and cannot be a C prototype at any size: an extern's answer width over
VENDORED C, a parameter seat's width and the integer-cannot-fill-a-
pointer rule, an extern answering `ptr` that no C in the tree declares,
a C body that MINTS an owned box with no `owns_result` row, a body that
retains a seat its row does not mark `keeps`, and a row marked `inert`
whose body resolves a name. A replacement that checks less is a
regression wearing a simplification's clothes. Retiring the keeper is a
DIFFERENT slice — making the packages' extern walls rows — and is not a
consequence of this one.

WHAT THE HEADER HOLDS AND WHAT IT DOES NOT, measured under clang 21
with the runtime's own `-Wall -Werror`: it holds the answer's C type
exactly, the seat COUNT, and a word handed to a pointer seat or a
pointer to a word seat (five failure classes witnessed failing). It
does NOT hold an `int64_t` seat against a `double` one — C converts
silently in both directions, so no call expression can tell them apart;
the float program test covers the one f64 row. The probes are NON-ZERO
because `((int64_t)0)` is a null pointer constant, so a zero probe
fills a pointer seat silently and that check would have passed on every
row while holding nothing — the empty-value law in a C hat.

## 8. A diagnostic is a row, and its golden is the row rendered

INVERTED AT PHASE G, on two independent measurements — either alone
carries it.

THE ROW CANNOT HOLD THE PROSE. A kind keys the F-CODE, not the law:
292 voices over 118 distinct kinds, and 45 kinds carry more than one
law. `type.mismatch` alone carries 38, `type.lambda` 12, `type.method`
10. Keyed by kind the row collapses 38 laws into one; keyed by voice it
is 292 rows whose `code` column is a second copy of the kind-to-code
map the 21 feature `table<DiagCode>`s already hold.

THE HOLE MAP IS A WEAKENING. Today a voice writes
`"`${sname}` has no variant `${v}`"` and the COMPILER checks those
names are in scope. Under `cx.refuse(kind, at, { seat: … })` the law is
a string in a table and the holes are a `Map<string, string>`: a
mistyped hole name is silent, and nothing in the language checks it.
The tree's own rule is to refuse a shape that makes a voice weaker.

SO THE WITNESS MOVES INTO THE ROW, NOT THE PROSE OUT OF THE VOICE.
That is where the value was: 135 registered F-codes, 23 appearing in
any test, 112 in none — "every diagnostic has a golden rendering test"
is 17% true. The registry row gains a WITNESS, a few lines of Avra that
trigger the kind, and the golden is the compiler run over the witness,
rendered and pinned. Every voice stays compiler-checked, every
registered code gets a golden or is named as uncovered, a voice whose
wording drifts fails its golden, and `avra explain F2075` prints the
summary AND a REAL rendered diagnostic with its holes filled — which is
strictly better than printing a template. §10.7's `at` lands on the
same row later.

AND THE HAZARD THE SHAPE CREATES: a witness that no longer triggers its
kind is a green test proving nothing — the compiler moves under it, it
starts producing some other code, and the golden happily pins that
instead. So the keeper asserts THE WITNESS PRODUCED THIS CODE, and
reports coverage as the count of codes whose witness actually fired,
naming the uncovered ones. A keeper counts what it looked at.

## 9. The compiler polices itself, in Avra

```avra
use @std.avrac.language.{analyzed, fns_of, projections_in}

lint I13 "the same projection computed twice on one line" {
    for f in fns_of(analyzed(root)) {
        for line in f.lines { if projections_in(line).has_duplicate() { refuse(I13, line) } }
    }
}
```

Keepers become programs over the real tree; `make gate` is `avra lint`.

## 10. Beyond the projections — the machinery around the model

Sections 1–9 derive projections OF the model. These derive the
machinery AROUND it, and each names the bug class this branch already
paid for by keeping that machinery by hand.

### 10.1 Side tables declared, not hand-sized

```avra
export type TypeFacts = {
    of_expr: SideTable<ExprId, TypeId>,
    captures: SideTable<ExprId, Cap?>,
}
```

Storage, growth and the "unminted id" defect derive from the KEY type.
KILLS: "a table sized before the arena grew" — twice on this branch
(`resolved` materializing expansions ahead of the resolver's tables;
the names test's fill order).

### 10.2 Queries declared, result hashes derived

```avra
query sig(d: DeclId) -> DeclSig?  { … }      // memo family, deps tracked by the kernel
```

The result's hash is the `Fingerprint` derive over the result TYPE;
no family writes `sig_hash`/`program_hash`/`fp(31, …)` again. KILLS:
two of the seven fingerprint collisions (an enum sig spliced flat, a
named type's sig hash the constant `1`) and the receivers family's
flat bit list.

### 10.3 Ownership roles on instructions

```avra
export enum Ins {
    Pack(@owns dst: Reg, parts: List<Reg>)
    Extract(@view dst: Reg, subject: Reg, slot: int)
    Call(@owns dst: Reg, @symbol callee: string, @moves args: List<Reg>)
}
```

`managed_dst`, `view_of`, `retained_args` derive from the marks; the
memory pass READS the IR's declaration instead of holding a second
opinion. KILLS: the double release at the identity pack (two hand
lists disagreed on whether `Pack` owns).

### 10.4 Attacks derived from the grammar

`avra attack <feature>` generates the red team's mechanical classes —
degenerate shapes (N = 0, 1, max of every repeated capture), every
slot every wrong type (from the type model), malformed surface (delete,
duplicate, swap, keyword-replace each token) — deterministically from
the feature's rule and the model, and pins them as
`<feature>_adversarial_test.av`. A person writes only the semantic
attacks. KILLS: the survivors every red team on this branch found in
class 2/3 by hand (a `bool` fitting a NAME seat; `${}` empty hole).

### 10.5 Three hole-bearing blocks become one

`"a ${x} b"`, `quote { … }` and `sql { … }` are ONE shape: a body owned
by a named grammar, with holes — string interpolation is the `text`
sublanguage. One node (`Block(word, parts, holes)`), one lexer path,
one hole law; the string case lowers to the `join` it lowers to today.
KILLS: the three lexer paths whose brace and hole accounting diverged
(a raw body in a hole never closing; the closer never counted).

### 10.6 The runtime row is the whole binding

One `rt_sigs` row generates the C prototype (§7), the LLVM declaration
AND the evaluator's call binding. KILLS: the two link sites a hand list
let drift. NOT `tools/externs.py` — see §7: its subject is the extern
WALL, 198 declarations that are not rows, and six of its checks are not
widths.

### 10.7 A diagnostic knows where it points

```avra
"type.quote_hole" | "F2075" | at: hole | "a hole in ${seat} position takes ${takes}" | …
```

The row names the payload it blames; the location is a mark, homing
applies by construction. KILLS: a voice passing the wrong `loc_of`,
and the span-outside-its-text trap (a Loc built with the wrong file).

### 10.8 The reference manual is a projection

`avra doc`: grammar rules → the syntax reference; the diagnostics
tables → the error index; `rt_sigs` → the runtime reference; each
feature's `docs =` → its chapter; `///` → every export. Nothing is
written twice; the docs campaign's "docs as a compile target".

### The "not simpler" line

Written by hand, always: the evaluator, the memory pass's meaning, the
backend, the type rules, the lowering, the grammar's words, the words
in a diagnostic, the runtime C. Each is a DECISION. Everything else is
the model looked at from another side.

## Performance

No runtime cost: derived code is generated Avra compiled like the hand
arms; marks resolve at compile time; the crossing walks headers as static
data does; the printer is one pass. Measure the derived walk against the
hand chains (the polish round found the idiomatic form faster). Compile-
time cost is the derives, measured per settlement by the budget slice.

## The path

| phase | what | size |
|---|---|---|
| A (running) | typed name payloads, derived copier | 1 day |
| B | the crossing collapse (§3) | 3 days |
| C | children + fingerprints derived, with the variant marks (§1) | 2 days |
| D | grammar names the node: builders + printer derived, `avra fmt` (§2) | 1–2 weeks |
| E | type-shape marks, IR roles, dispatch by ownership (§4–6) | 3 days |
| F | keepers in Avra (§9) | 1 week |
| G | C header from the runtime rows (§7); diagnostics' goldens generated from a witness row (§8) | 2 days |
| H | side tables + queries declared (§10.1–2) | 3 days |
| I | ownership roles on Ins (§10.3) | 2 days |
| J | one hole-bearing block (§10.5) | 3 days, after D |
| K | `avra attack` (§10.4), `avra doc` (§10.8), the whole binding (§10.6), diagnostics' `at` (§10.7) | 1 week |

B, C, E, G, H, I are independent; D, F, J run alone.
