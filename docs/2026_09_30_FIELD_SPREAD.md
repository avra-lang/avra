# Field spread — `..Record` in a record's fields

> 2026-09-30. Decided with the owner (UI.md §19.3, C1). Branch lane/spread.

## What a user writes

```avra
export type Common = {
    /// How the component looks.
    style: Style = Style {},
    attrs: Attrs = Attrs {},
}

export component text(content: string) {
    ..Common
    selectable: bool = true
}

type Page<T> = { items: List<T>, next: string? = null }
type Orders = { ..Page<Order>, total: int }       // items: List<Order>, next, total
```

## Meaning

- `..R` in a `type` record or a `component` body places R's fields
  there, in order: names, types, defaults, marks, docs.
- **Copy only.** The spreader is its own type; nothing converts
  between it and R (P9). A shared ability is a trait.
- **Generic.** `..R<A>` substitutes A for R's parameters in every
  field; `..R<T>` inside a generic declaration passes its own T.
- **Never in a head.** A head is positional; a spread would let
  another type's edit move `text "Hi"`'s meaning.
- **Never in a literal.** `x with { … }` is the one spelling.

## Refusals — one mistake, one message

| Case | Voice (the law) |
|---|---|
| a field named twice by a spread and a declaration, or two spreads | a field is declared once — `style` comes from `..Common` and from line N |
| `A` spreads `B` spreads `A` | a spread cannot reach its own record |
| `..E` where E is an enum, a scalar, a named or generic parameter | a spread takes a record's fields — `E` is an enum |
| `..R` with the wrong number of type arguments | the ordinary arity refusal |
| `..x` in a record literal | a literal spells its base with `with` |
| `..` in a component head | a head is positional — spread settings into the body |

## How it is built — resolved, never pasted

Pasting R's field nodes into the spreader would type them in the
SPREADER's scope: `style: Style` spread into a file that never
imported `Style` would not resolve. So a spread is resolved against
R's SIGNATURE, which R's own scope already typed:

1. Grammar: `..NAME` (with optional type args) as a field entry in the
   `type` and `component` rules, beside the template `..HOLE`.
2. Declare (`declare_struct_sig`): a spread entry asks R's sig
   (declaration-order law: ask, never read mid-flight), substitutes
   type arguments, and splices R's names and types. Its DEFAULTS are
   R's own `Default` decls (`default_named(R, f)`), typed in R's scope.
3. Every reader of a record's fields reads the SIG, not the AST:
   literal checks (structs/semantics.av), default minting
   (decls_mint.av — a spread mints nothing; R's defaults exist),
   `@std/meta`'s `Type.fields` (expand.av `crossed_fields`), docs.
4. Hash: the spreader's signature hash covers R's resolved fields, so
   an edit to R invalidates every spreader.

## Tests

A program test in both engines (spread, generic spread, defaults
read across files and packages, `@derive` over a spreader seeing the
fields flat); a golden per refusal; a hash test (editing R changes
the spreader's fingerprint).
