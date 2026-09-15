# Named types — `type Name = Shape`

The NAMED-TYPE LAW, decided 2026-09-14 (design doc §7 q1, ROADMAP's
sugar backlog): `type Name = Shape` is ALWAYS a distinct type. There
is no transparent alias. A name counts.

This doc is the model, the seams, the exact words, and the ladder.

---

## 1. The model — a name is its shape, and the shape is not the name

ONE sentence holds the whole design:

> **A NAME IS OPAQUE AT A SEAT AND TRANSPARENT AT A READ.**

A seat (a parameter, a field, a `let`'s annotation, an argument, an
operand) judges the NAME. A read (a property, a method, an index, a
`for` head, an interpolation hole) judges the SHAPE. That is P9 —
boundaries are contracts — and P6: both halves win, because they are
answering different questions.

At runtime there is nothing at all. A named type is modelled as a
FLAT RECORD over one anonymous field, and the flat law already says
"the value IS its field": `packed_lit` emits `Ins.Pack(dst, [one])`,
which both engines render as identity, and `field_read` emits
`Ins.Extract`, which both engines render as identity. A `UserId`
register holds an `i64`; a `Rows` register holds the list pointer.
The box costs nothing to use because there is no box.

### What had to grow for that to be true

The flat law was written for a record of `int` fields, and three of
its consumers answered "int" where they meant "the field's machine
form". Generalising them is behaviour-preserving on today's tree —
every existing flat record has an `int` field, so every new answer
equals the old one — and it is what lets a name stand over `string`,
`List<T>`, `float`, `bool`, a record, an enum.

| seam | was | is |
|---|---|---|
| `TypeRegistry.rides_pointer` | flat ⇒ `false` | flat ⇒ its field's answer |
| `TypeRegistry.machine_shape` | *(absent; callers read `shape_of`)* | flat ⇒ its field's machine shape |
| `memory.is_managed` (`.Struct`) | flat ⇒ not managed | flat ⇒ its field's answer |
| `memory.managed_dst` (`.Extract`) | owns `dst` | a VIEW — identity mints no reference |
| `memory` (`.Pack`) | owns `dst`, no retain | owns `dst` AND retains — a second holder |
| `values.inner_repr` | flat ⇒ `Boxed` | pointer-riding ⇒ `Niche`, else flat ⇒ `Boxed`, else `Pair` |
| `values.repr_of` / `carried_type` / `hollow_of` | `shape_of` | `seen_shape` — a name over a nullable IS that nullable |
| `statics.optional_slot` / `record_slot` | flat first | the NICHE first; a flat record's field, not the sig's |
| `lower_walk.print_lowering` | `shape_of` | `seen_shape` — printing is a read |

`managed_dst` is the sharp one, and the FIRST ANSWER WAS WRONG. Both
`Ins.Pack` and `Ins.Extract` are identity for a flat record, so both
read as VIEWS — and that is right for `Extract` and WRONG for
`Pack`. The outermost scope's yield carries the reference the scope
ALREADY HOLDS (`moved_out` runs only for an inner scope), so a
fn answering a pack whose destination owns nothing releases the part
and hands the caller freed memory. `AVRA_RC_GUARD=1` named it —
"released an already-dead box" — after the two engines disagreed on
the value (`xq` evaluated, empty natively). A PACK OWNS and retains:
the destination is a SECOND HOLDER of the part's box, the part keeps
the reference it had, and the scope settles both. `Extract` stays a
view, which is what `view_of` said all along.

### Where the name is remembered

`TypeRegistry.flats: List<FlatRow>` becomes `reps: List<RepRow>`, one
row per interned type:

```
export type RepRow = { fields: List<TypeId>, sealed: bool, stands_for: TypeId? = null }
```

`stands_for` is the NAME's shape — set once at declare, `null` for
every other type. It is kept beside `fields` and not derived from it
because `unflatten` empties `fields` and a name must survive that.

`stands_for` is IDENTITY for every type that exists today, which is
the safety property this whole slice rests on: every see-through
below is a no-op on the current tree.

---

## 2. The node — a new statement kind

A named type is NOT a `StructDecl` with a nameless field. An empty
field name would be a string tag, and the rules refuse those. It is
its own statement kind, so `stmt_semantics_of` breaks at compile
time and every exhaustive walk has to answer for it:

```
/// `type Name = <type>` — a DISTINCT type over a written shape.
/// Not an alias: the name counts at every seat. It travels as its
/// shape (a flat record of one anonymous field), so the name is
/// free at runtime.
NamedType(name: string, tparams: List<string>, of: TypeRef)
```

- `DeclKind.Named` — what the statement declares.
- `DeclSig.Named(sig: NamedSig)` where `NamedSig = { of: TypeId }`;
  `@derive(Projections)` mints `named_sig()`.
- `Type.Struct(decl, name)` is still the interned type. Everything
  nominal — the impl table, the slot law, printing, `dyn` — keeps
  working with no new arm.
- `fields_of_type` answers null, so there is no field to read, no
  `with`, and `Name { … }` refuses (its own voice, §6).

Fingerprint tag `122` (highest-plus-one; `make fingerprints` is the
keeper that verifies, and the one that must be ASKED rather than
grepped — a computed tag is invisible to a grep).

---

## 3. The grammar — ONE rule, an ordered choice inside it

Two `stmt` branches sharing the `type` anchor cannot both stand: the
record branch RECOVERS, and a recovering branch turns a committed
miss into a hit, so `type UserId = int` would be eaten as a hole.
The law ("among branches sharing an anchor keyword, ONLY THE LAST
may recover") is satisfied by having ONE branch:

```
stmt = "type" n:NAME ( "<" tp:NAME ( "," tp:NAME )* ","? ">" )? "="
       ( "{" BREAK? ( fs:NAME ":" ft:type ( "=" fd:expression )?
         ( "," BREAK? fs:NAME ":" ft:type ( "=" fd:expression )? )* ","? BREAK? )? "}"
       | nt:type )
       END @recover(sync_to: "END") -> type_decl(n, tp, fs, ft, fd, nt)
```

The two alternatives have disjoint first sets (`{` versus a type's
NAME/`dyn`), so the choice is unambiguous. ONE builder picks the
node — `nt` present ⇒ `NamedType`, else `StructDecl` — exactly as
`expr_stmt`'s floor picks `Assign`. One keyword claim, one recovery,
one `@recover`.

The docs string says the law out loud: **there is no alias form.**

---

## 4. The six points

### 4.1 Declaration

`declare_named` (typing_declare.av):

- the written type runs the SLOT LAW (a named type's shape is its
  record's one field, so it obeys the same law a field does);
- `mark_flat(ty, [of])` and `mark_named(ty, of)`;
- type parameters REFUSE for now (§7).

### 4.2 Construction — `Name(value)`

`Name(v)` is a CALL whose callee names a type and no fn.

- `resolve.use_call` falls through to the TYPE namespace after the
  fn namespace and the local one, binding `Binding.Decl(type)`.
- `fns/check.av`'s `valued_call` sees a `TypeName` callee that
  stands for a shape and judges it with `cx.seats_judged(e, callee,
  [of], [], named, args)`. THE ORDINARY SEAT LAW — so arity and the
  argument refuse in the CALL's own words, with no new voice:

      UserId("x")
      → argument 1 of `UserId` wants `int`, found `string`

      UserId(1, 2)
      → `UserId` takes 1 arguments, found 2

- `fns/lower.av` emits `cx.packed(e, [reg])` — one identity Pack,
  the same verb `packed_lit` uses.

### 4.2b The inverse — `value.of`

`Name(v)` wraps; `id.of` reads the shape back. A name is OPAQUE at a
seat, so a named value reaching a seat of its shape needs a word for
the crossing, and the DECLARATION supplies it: `type Name = <of>`
read backwards. It is a PROPERTY ROW (`structs/mod.av`), so it obeys
the member law — a record answers its FIELDS first, which is why a
record with a field `of` keeps it and only a name (which has no
fields) reaches the row.

    let id: UserId = 5
    take_int(id.of)                 // fn take_int(n: int)
    let xs: List<int> = rows.of     // Rows = List<int>
    let t: A = b.of                 // type B = A: ONE level

Free at runtime: a named value IS its shape, so the lowering answers
the SUBJECT'S OWN REGISTER — no instruction, no reference, nothing to
settle. An `Extract` would be wrong, and the reason is worth pinning:
a LITERAL filling a named seat records no lift, so the register wears
the SHAPE and the extract would have nothing to open.

Refusals: `p.of` on a record is "no field `of` on `P`" (the fields
answered first), `n.of` on a bare `int` is "no property `of` on
`int`", and a name standing over nothing says the law —
"`.of` reads a named type's shape, this is `X`".

### 4.3 A literal fills a named seat

`accepts` is the ONE door (`other_accepts`' fourth arm). A LITERAL
FORM under a named want re-asks against the name's shape:

```
let rows: Rows = [1, 2]        // Rows = List<int>
let id: UserId = 5
take(5)                        // fn take(id: UserId)
P { id: 5 }                     // field id: UserId
```

"A literal form" is the value protocol's question, asked in core
beside `is_literal`: a scalar, text, a list, a map, a comprehension,
`null`. Nothing COMPUTED wears a name it was not given — that is the
opacity half, and it is what makes the name worth having.

No lift is recorded, and none is needed: the machine types are equal
by construction (`ll_type_of(Rows) == ll_type_of(List<int>)`). The
`[]`/`{}` adoptions still record theirs, through the inner ask.

### 4.4 Reads forward

`stands_for` is consulted by the READ projections, so most of the
forwarding costs nothing at the sites:

- `element`, `cell_inner`, `carried`, `res_parts`, `arrow_parts` see
  through — so `rows.push(v)`, `rows[0]`, `for r in rows`,
  `rows.length` and every list row find their element with no change
  at the site. `args_of` does NOT see through: a type's arguments
  are a nominal question.
- `impls/callee.av`'s `callee_of` forwards when the named type's own
  impl has no method of that name — so `impl Rows { … }` wins and
  the shape answers after.
- `expr_spine`'s property read and interpolation ask the SEEN shape.
- A PATTERN READS ITS SUBJECT, so a LITERAL PATTERN compares through
  the name: `match id { 5 -> … }` over a `UserId` is the number,
  exactly as `id == 5` is (`enums/check.av`'s `lit_types`). The
  refusal still names the type the writer WROTE — a `string` pattern
  over a `UserId` says "a `string` never matches `UserId`". The
  lowering needed nothing: `same_value` already reads the seen shape.
  (`match`/`is` over a named ENUM stays a trigger — that is the
  variant half, and it needs the layout laws to follow.)
- `check_filter`/`concat`/`slice` answer the RECEIVER's type, so a
  `Rows` filtered is a `Rows`. That falls out; it is also right.

### 4.5 Seats stay opaque

Nothing is added for this: `types_disagree` compares ids, and a
named type's id is its own. The refusals are the ones each seat
already speaks, with the HELP widened to offer `Name(v)` as a
high-confidence Suggestion (resolve.av's `suggested` shows the
shape). §6 pins the renderings.

### 4.6 Arithmetic

Two values of ONE named type answer that named type. A LITERAL
operand adopts the other side's name — the same law as 4.3, at an
operand seat — so `id + 1` and `id == 5` read straight. `==`/`!=`
follow the same rule.

THE OTHER SIDE DECIDES WHICH REFUSAL IS TRUE, and there are three:

| the other operand | the refusal |
|---|---|
| the name's own SHAPE | "an operand of `A` meets `int` — a named type never mixes with its shape", with the `A(v)` fix |
| ANOTHER NAME | "`A` and `B` are two types — a named type never mixes with another", and NO fix: neither stands over the other, so no wrap is honest |
| anything else | the OPERATOR's own law, in its own words ("`+` needs `int` operands, found `string`") |

The first draft had one voice for all three and told `A == B` that
`B` was `A`'s shape — a refusal naming a relationship that does not
exist, and offering a wrap for it.

---

## 5. Not an alias, and why

Stated in the grammar's `docs` string, in this doc, and in the
design doc's §7 q1: a transparent alias is the one place a name
would promise nothing (P9), and it is the ambiguity a generator
cannot resolve on first generation (P1). Languages with both words
see the alias used where the newtype was meant.

---

## 6. The exact words

Point 4's renderings, pinned by golden tests:

Verbatim from `./avra check`, 2026-09-14, comptime/types:

```
take(5)                             // fn take(id: UserId)
  → accepted: a LITERAL fills a named seat

let n = 5; take(n)
error[F2000]: argument 1 of `take` wants `UserId`, found `int`
help: `UserId` is its own type — write `UserId(n)`

let other: OrderId = 5; take(other)
error[F2000]: argument 1 of `take` wants `UserId`, found `OrderId`
help: `UserId` is its own type — write `UserId(other)`

let xs: List<int> = [1]; let c: Rows = xs
error[F2024]: `c` declares `Rows`, this is `List<int>`
help: `Rows` is its own type — write `Rows(xs)`

let id: UserId = 5; id + n
error[F2000]: an operand of `UserId` meets `int` — a named type never
             mixes with its shape
help: `UserId` is its own type — write `UserId(n)`

type B = int; let b: B = 2; id == b
error[F2000]: `UserId` and `B` are two types — a named type never
             mixes with another
                                          (no help, no suggestion)
```

Each help carries a `Suggestion` at `High` confidence with the Edit
that wraps the operand.

---

## 7. Deliberately out, with triggers

- **GENERIC named types** (`type Box<T> = List<T>`). The record
  form's tparams do NOT carry over for free: `App(decl, name, args)`
  interns per instantiation, so `stands_for` would have to be
  substituted and marked at `applied_decl` rather than at declare.
  Refused with its own voice. **Trigger:** when a site wants one —
  the first is a generic typed id.
- **Sealing.** `unflatten` is a NO-OP on a named type: a name has no
  field to write through, and its whole promise is that it travels
  as its shape. `mut` seats and `mut fn` receivers were expected to
  need a refusal and DO NOT — measured, both work, and a named type
  inherits the RECORD'S standing aliasing behaviour exactly (a
  vocabulary write through a name COPIES, a `mut fn` receiver
  ALIASES, and a record's `mut fn` receiver aliases identically).
  The adversarial suite pins the PARITY, so the day the debt is paid
  both answers move together. **Trigger:** ROADMAP's RECEIVER
  ALIASING.
- **A name over an ENUM does not forward `match`/`is`.** `type K =
  Color` declares and constructs; `k is .Red` refuses cleanly ("`is`
  asks an enum for its variant, found `K`") because `variants_of_type`
  stays nominal. Forwarding it means `fields_of_type` and
  `variants_of_type` seeing through, which would also make `K { … }`
  and `w with { … }` reach a shape the LAYOUT laws do not follow.
  **Trigger:** the first site that wants a named enum.
- **`with` does not reach through a name to a record** — same cause,
  same trigger.
- **A named construction cannot fill a `const` seat.** `Name(literal)`
  is a CALL, so the settled-seat law (which reads the SOURCE) refuses
  it. **Trigger:** the first `const` seat that wants a named type.
- **The compiler's own seven `*Id = { index: int }` declarations**
  stay records. `.index` is read thousands of times; the sweep is
  mechanical only once those reads can be replaced. **Trigger:**
  when `.index` reads can be replaced mechanically — either by a
  forwarding property or by a scripted rewrite with a gated diff.

---

## 8. The ladder

A GRAMMAR change is a front-end change: the standing binary compiles
the source happily and the PRODUCT is what reads the new rule, so
the SECOND build is the proof.

1. `cp build/avra build/avra.pre`
2. `make avra` — builds with the standing binary (knows no `= int`)
3. `make avra` — the product reads its own new grammar
4. `cmp` the two products for the fixed point
5. `sh tools/watch.sh 4000 make gate`
6. `make seed` rides the slice; the gate's seed check must pass

`make recover` links the seed and stops — the way back when a
product refuses its own source.

---

## 9. Three laws this slice paid for

**A CLOSER NEVER CONTINUES A LINE.** `>` closes a type argument list
as well as wanting a right side, and the lexer's continuation rule
listed it — so `type Rows = List<int>` dropped its BREAK and
swallowed the next statement. No statement in the tree had ever
ENDED in `>` before this one (a trait's bodiless `fn a() -> List<T>`
did, and parsed only because a `}` supplied its END), which is the
"assumption nothing has ever tried to violate" law wearing the
lexer's clothes. `>` is out of `continuing_op`; `<` stays, because a
line ending in `<` is incomplete either way.

**A PROPERTY'S ROW MUST BE FOUND THE SAME WAY TWICE.** Typing asks
`member_type_of`, which tries the receiver's OWN shape and then the
shape it stands over; the LOWERING asked `seen_at` alone. For every
property that existed, the two agreed — a named type's `length` is
found under `.List` either way — so the disagreement was invisible
until `of`, which only the OWN shape answers. The two now share one
verb (`property_of`), and the chain's member read shares it too: a
row's lowering takes the subject's REGISTER and TYPE, which is what a
chain holds where the spine holds a node. (Found by `?.of` lowering
as a MEASURE and answering "a non-string reached text".)

**A NAMED TYPE'S MARK IS MADE AT ITS DECLARATION**, so a law reading
the registry mid-flight answers by declaration ORDER. The CLI signs
types first and every probe passed; `analyze_source` types the entry
first and refused every literal fill — 22 spec cases red, the CLI
green, one tree. `declared_type` now ASKS the declaration before
handing out a named type's id, which is the same remedy
`fields_of_type` has always used for a record's fields.
