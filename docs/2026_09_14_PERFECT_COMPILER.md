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
semantic arms are MARKS on the variant, read by the derive. NEEDS: annotations
on variants and fields, as data a derive can read.

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

`avra emit runtime-header` writes `runtime/avra_rt.h`; the C includes
it; a wrong width fails in the C compiler; `tools/externs.py` retires.

## 8. A diagnostic is a row, and its golden is the row rendered

```avra
diags = table<Diagnostic> {
    kind               | code    | law                                          | help
    "type.quote_hole"  | "F2075" | "a hole in ${seat} position takes ${takes}" | "fill the hole with what its seat takes"
}
```

A voice is `cx.refuse(quote_hole, at, { seat: "name", takes: "a `string`" })`;
`avra explain F2075` prints the row; the rendering test is generated from
the row and one witness program.

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
| G | C header from the runtime rows (§7); diagnostics as rows (§8) | 2 days |

B, C, E, G are independent; D and F run alone.
