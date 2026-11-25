# Traits across the tree — the census, the traits it names, and the rule that keeps it

Design note, 2026-11-25, avra-8sb5.104 (centralize) with the core protocols (avra-8sb5.99.6). The
census comes before the sweep; no sweep has started.

**In one line:** most of the tree's free-fn families exist because `==`, interpolation and a
derive can't reach a trait yet. Seven of them, about 120 fns, go away once the core protocols
from the maps design (§13) land. Two pairs of duplicate derives fold into one each. A style rule
then refuses any new member of a family whose trait exists.

## 1. How it was counted

- **Typed probe (the census of record).** A probe `fact_rule` was built into a scratch compiler
  and never committed (its text is in §7). It reports every top-level fn with the type its first
  seat declares, and ran as `avra check` over all 48 packages at 5ee901c3 plus phase 1. Each fn's
  name is read back from the source line the finding points at. Tests, vendored code and caches
  are excluded.
- **Text pass for hand dispatch.** A match arm cannot be typed by that rule, so runs of three or
  more arms each calling a different fn of one verb were found textually
  (`/work/census/pre2.py`, its output beside this note's bundle).
- **Families.** A family is a verb spelled once per type: the fn's name with its first seat's type
  name (in snake case) cut out, over three or more types. Two fns of one name over different
  first-seat types also count, as one verb spelled once per module.

| what | count |
|---|---|
| top-level fns, outside tests | 15 851 |
| … whose first seat is a user type | 9 846 |
| … of those, a context the program layer passes by law (`QueryEngine` 1 366, `TypeCx` 783, `SyntaxArena` 526, `LowerCx` 526, `ItemView` 463, …) | 4 747 |
| … of those, a data type: the receiver-first fns (`Type` 328, `Fn` 183, `SignedType` 160, `Field` 143, `Kind` 111, `Loc` 103, `MetaType` 102, …) | 5 099 |
| verb families over 3+ types | 33 |
| one name over 2+ first-seat types | 473 |
| hand-dispatch matches (3+ arms, each a different fn of one verb) | 27 |

The context-first fns are not trait candidates. A query is a free fn over its engine by the
program layer's law, and `self` there would be the engine, not the data. They are left out of
everything below.

## 2. The families, ranked, and the trait each is

| rank | family | size | what it is | the trait |
|---|---|---|---|---|
| 1 | `same_<t>(a: T, b: T) -> bool` | 36 fns, 35 types; plus `same_key` over 6 | hand-written record equality: `==` refuses a record of two fields (CLAUDE.md's subset) | **`Eq`** (core, derived-only) |
| 2 | `<t>_word(x: T) -> string`, `<t>_words`, `<t>_spelled`, `spelled_<t>` | 31 + 7 + 5 fns, 37 types | an enum value's one-word spelling: `match x { .Start -> "start", … }` | **`Worded`**, one derive (below) |
| 3 | `<t>_text`, `<t>_line`, `shown_<t>`, `<t>_code` | 15 + 6 + 3 + 8 fns, 32 types | a value's display text | **`Show`**, which interpolation lowers to |
| 4 | `exact_<t>(a, b)`, derived per kind | 7 types, plus `@derive(Exact)`'s generated `exact_<kind>` | structural node equality, span-blind | **`Eq`** under the arena's view (`Exact` keeps its derive and writes `impl Eq`) |
| 5 | `<t>_json`, `<t>_wire` | 5 + 4 fns | an encoder per type | std-relation's **`@derive(Codec)`** and its bound **`Storable`**, which `@std/json` takes for its encoders |
| 6 | `<t>_hash` | 4 fns, plus `Fingerprint` (45 derives) and `Identity` (25) | an in-process hash, and a content print | **`Hash`** (core); `Fingerprint` stays apart: a print crosses processes, a hash does not (maps design §5.3) |
| 7 | `kind_of`, `kind_of_<t>`, `meta_of_<t>` | 6 + 3 + 4 fns | what kind a value is | none yet: the answers differ (`RtKind`, `DeclKind`, a string), so this is a naming cleanup, not one trait |

The rest of the 33 families (`render_`, `rule`, `bits`, `listed`, `folded`, …) are local to one
module each: a grammar's rows, a layout's axes. They stay as they are until a second module
spells the same verb.

### 2.1 The derives that make families

Three derives write free fns per type, because a derive cannot yet write `impl Trait for T` and
call it generically:
- **`Worded`** (std-avrac, core/worded_derive.av) writes `worded_<Enum>(text)` and
  `word_of_<Enum>(v)`.
- **`Words`** (std-ui, style/words.av) does the same job a second time: a variant's word as data,
  `worded`, `every`, `ordinal`.
- **`Exact`** writes `exact_<kind>(a, b)` on the arena.

Folding: `Words` and `Worded` become one `Worded` trait in `@std/derive`. The trait writes an
`impl Worded for E` with `word()`, `static fn worded(text)`, `every()` and `ordinal()`, and its 29
derive sites keep their marks. `Exact` writes `impl Eq` for a node under the arena, so `==` on two
nodes is the exact compare.

### 2.2 Hand dispatch — 27 matches

Each is a sum's variants mapped to one verb's per-variant fns. The largest:

| at | arms | verb |
|---|---|---|
| std-avrac/src/compiler/workspace.av:851 | 14 | `*_verified` |
| std-avrac/src/compiler/item_program.av:3286 | 12 | `lowered_*_question` |
| std-db/src/migrate.av:240 | 10 | `*_voice` |
| std-avrac/src/features/quote/check.av:292 | 7 | `*_voice` |
| std-avrac/src/features/impls/check.av:34 | 5 | `*_call` |
| std-avrac/src/core/side_table.av:51 | 4 | `*_window` |

A match over one enum calling one fn per arm is that enum's method, and the fix is a method on the
enum, not a trait. A trait is the fix only where the variants' payloads are distinct types that
each own the verb. That's the `*_voice` pair: a migration step's voice and a quote fault's voice
are each its type's `Voiced`. Each of the 27 is judged when its module is swept, not here.

### 2.3 Receiver-first free fns — 5 099

A free fn whose first seat is a data type its own module declares is a method in waiting. This is
a cleanup to inherent methods, not to traits, and it's the largest count. It belongs after the
traits, and it carries its own rule (§4, second row).

## 3. The traits, core protocols first, each with one generic caller

| trait | in | one method | the generic caller that replaces a family |
|---|---|---|---|
| `Eq` | prelude | `eq(other: Self) -> bool`, derived-only | `==` / `!=`, `contains`, `index_of`, a literal pattern |
| `Hash` | prelude | `hash(into: Hasher)`, derived-only | a `Map`/`Set` key |
| `Ord` | prelude | `compare(other: Self) -> Order` | `<` … `>=`, `sorted`, `min`, `max` |
| `Walk<T>`, `Len`, `Index<K, V>`, `Contains<T>` | prelude | as the maps design §13.2 | `for`, every walk verb, `.length`, `[]`, `.contains` |
| `Show` | prelude (from `@std/derive`) | `show() -> string` | interpolation: `"${x}"` lowers to `x.show()` for a type that has it |
| `Worded` | `@std/derive` (folds `Words`) | `word() -> string`, `static fn worded(text) -> Self?` | `"${e}"` of a worded enum, and reading one back |
| `Storable` (written by `@derive(Codec)`) | std-relation, taken by `@std/json` | `codec_shape`, `codec_descriptor`, and the wire it derives | one `json(x)`, one `wire(x)` over `T: Storable` |

The order of the work follows from what each family waits on:
- Families 1 and 4 (`Eq`) wait on `==` lowering to `Eq` (§13.4 of the maps design).
- 2 and 3 wait on interpolation lowering to `Show`.
- 5 waits on nothing: the trait exists.

## 4. The style rule

`trait_family`, a `fact_rule` in compiler/idioms.av, ratcheted like every idiom (baseline: today's
sites, which may only fall):

| it refuses | when | the fix it names |
|---|---|---|
| a new top-level fn spelling a family's verb with its first seat's type (`same_t(a: T, b: T) -> bool`, `t_word(x: T) -> string`, `t_text(x: T) -> string`, `t_json(x: T)`) | the family's trait exists and `T` can have it | "`T` derives `Eq` — write `a == b`" / "derive `Worded`" / "`impl Show for T`" / "`@derive(Codec)`" |
| a new top-level fn whose first seat is a data type its own module declares, named for that type | the fn is not a query (no engine or context in its first seat) | "a method on `T`" |
| a new match whose arms each call a different fn of one verb over the variants' payload types | the payload types are distinct | "a trait the payloads implement" |

The rule's table names each family once: verb pattern, trait, fix. So a family the next census
finds is a row, not a new rule.

## 5. The sweep, once the traits exist

1. `@derive(Codec)` / `Storable` for `_json`/`_wire`. It waits on nothing.
2. `Eq` derived and `==` routed to it. Then the 36 `same_*` and 6 `same_key` fns go, each site
   becoming `==`. `Exact` writes `impl Eq`.
3. `Show` with interpolation routed to it. Then `_text`, `_line`, `shown_` and `_code` go.
4. `Worded` folded into `@std/derive`. Then the 31 hand-written `_word` fns become derives, and
   std-ui's `Words` sites move.
5. The 27 hand-dispatch matches, module by module (§2.2).
6. The 5 099 receiver-first fns, by package, the largest types first (`Type`, `Fn`, `SignedType`,
   `Field`).

Each batch runs the cost slice and lands with its family's count in the rule's baseline falling.

## 6. For the lead to decide

1. Whether interpolation lowers to `Show` where a type has it (the Python `__str__` reading), or
   `Show` stays an explicit `.show()`. Recommendation: lower it; a type without `Show` keeps
   today's refusal.
2. Whether std-ui's `Words` folds into one `Worded` in `@std/derive`, or stays as UI-only data.
   Recommendation: fold. The two do the same job and the census counts both.
3. Whether the receiver-first cleanup (§2.3) rides this epic or its own. Recommendation: its own,
   after the traits.

## 7. The probe, as run (scratch only, never committed)

```avra
/// PROBE (traits census, never committed): a top-level fn and the type its first seat declares.
@keeps("1")
export fact_rule probe_free_fn_over {
    quote { ${lit} } if probe_first_seat(lit) != null -> Fix.Say(said(lit.loc(), "probe: free fn ${lit.name() ?? "?"} over ${probe_first_seat(lit) ?? "?"}", "this fn", null)),
}

/// The type a top-level fn's first seat declares, absent for any other node.
fn probe_first_seat(lit: Code) -> string? {
    let params? = lit.fn_params() else { return null }
    if !is_top_level(lit) { return null }
    let p0? = params.first() else { return null }
    let ty? = p0.decl_type() else { return null }
    ty.name
}
```

`lit.name()` answers null on a fn declaration's node, so the name is read back from the line the
finding points at. The real rule reads it off the declaration instead.
