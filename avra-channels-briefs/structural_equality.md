# Structural `==` / `!=`: design (CHANNELS `avra-8sb5.34.53.29`)

Status: DRAFT — held for owner confirmation before landing.

## Why

Channels slice 8 (spec §7.3, the absorption law) compares and quantifies over
user records. Today `==` refuses every aggregate but a one-scalar-field record
and a payload-free enum. The equality law in `CLAUDE.md` ("a scalar, text, a
tagged enum, or a record of one such field") widens here.

## Probes — what each shape does today (standing `build/avra`, one package per shape)

| shape | today's word |
|---|---|
| `type P = { a: int, b: int }`, `p == q` | `type.mismatch` "`==` compares by value — a scalar, text, a tagged enum, or a record of one such field"; help "compare a field instead" |
| `type S = { seen: List<int> }`, `a == b` | same; help "compare a field instead" |
| `type Outer = { i: Inner, c: int }` | same; help "compare a field instead" |
| `let xs = [1,2]; xs == ys` | same; help "compare an element or the `length` instead" |
| `List<P>`, `xs == ys` | same; help "compare an element or the `length` instead" |
| `Map<string,int>`, `m == n` | same; help "maps do not compare — ask `get`" |
| `enum E { A(x:int) B(y:int) }`, `E.A(1) == E.A(1)` | same; help "match on it instead — only an enum carrying nothing compares, by variant" |
| `let a: int? = 1; a == b` | compiles (nullable of a scalar) |
| `let a: List<int>? = [1]; a == b` | refused; help "answer the absence first — `??` gives it a value" (the inner list) |
| `let a: S? = S{...}; a == b` | refused; same |
| `type Tree = { value: int, kids: List<Tree> }`, `t == u` | refused; help "compare a field instead" |
| `List<int>.contains(2)` | compiles |
| `List<P>.contains(P{...})` | `type.list_element` "`contains` scans by value — … — and this list holds `P`"; help "spell the scan" |
| `List<P>.index_of(P{...})` | `type.list_element`, same |
| literal pattern (`match p { 1 -> … }`) | `type.pattern` "a `int` never matches `P`" |

A **cycle is constructible**: `mut kids: List<Tree> = []; let t = Tree { value: 1, kids: kids }; kids.push(t)` checks clean; `t.kids[0]` is `t`. Any deep walk must decide what a cycle does.

## Semantics

- `a == b` is a **structural value** compare, never an address compare.
- Scalars / text / bytes: unchanged.
- Unit enum: by variant (unchanged).
- **Record** (`Struct` / `App`): field by field, in declaration order, each by this same law; equal iff every field is equal.
- **List**: same length and each corresponding element equal, in order.
- **Map**: same entry count and, for every key in the left, the right holds that key with an equal value. **Order-insensitive** — insertion order is a projection (the runtime's output order), not part of a mapping's identity. (Owner call: the alternative, order-sensitive, makes two equal maps unequal by construction history and needs no key lookups; the unordered reading is what "same mapping" means and matches `m.get`.)
- **Enum with payload**: same variant (tag) and every payload equal by this law. Payload-free is the tag case.
- **Nullable `T?`**: both absent, or both present and carried values equal (existing `same_through`); reaches aggregates for free.
- A declared name is transparent at a read (existing `seen_through`).
- **Recursive types** (a type whose definition reaches itself through a field, list element, map value or payload): **REFUSED by name**. A deep walk over a cycle never ends and the runtime carries no visited set. The type still exists and its values are still constructible; only comparing one is refused.

## Cost

- A deep walk, O(size up to the first difference); no hashing (a hash would need a
  per-type digest over the whole value, memoised per box, which the runtime does not carry).
- Short-circuits: record → first differing field; list → length or first differing element;
  enum → tag; map → first missing/differing key.
- **Maps allocate**: the walk snapshots the left map's keys (`avra_map_keys`), an O(n) temporary. Acceptable; a key-by-key walk with no snapshot is a later optimisation.
- A repeated `contains`/`index_of` is O(n) deep compares.
- No identity short-circuit on the same box; a later optimisation.

## `contains` / `index_of` / literal patterns

They share the ONE `compares_by_value` predicate (and the lowered `same_value`), so
widening equality widens them together: `List<P>.contains(P{…})` scans with the
record compare, and a literal pattern asks the same law. No second equality.

## What remains refused (in its words)

- Recursive type: new voice `type.recursive_compare` — "a recursive type cannot compare — a deep walk would follow the cycle forever"; help "compare a field or a depth you bound".
- `Cell`, `Task`/`Tasks`, `Fn`, `dyn`, a type parameter, `Union`, `Range`, `Void`, `Ptr`, `Error`: the existing `type.mismatch` voice and its help.
- A list whose element cannot compare: `type.mismatch`; a `contains`/`index_of` there keeps `type.list_element`.
- A map whose value cannot compare: `type.mismatch` (or its own).
- A literal pattern whose type differs: existing `type.pattern`.

## Engines' shape / runtime surface

The whole compare is lowered to IR by the compiler: field/payload reads plus the
existing counting-loop skeleton (`Walk` / `turn_open` / `turn_elem` / `walk_done`) for
lists and maps, with a bool cell as the short-circuit result. **No new IR instruction
and no new runtime row** — the evaluator and the native backend read one stream, so
`eval == native` holds by construction.

## Acceptance

- A record of several fields, one holding a list, checks and runs `eval == native`.
- Every probed shape is supported or refused by name (table above).
- Pre-existing refusals of `Cell`/`Fn`/`dyn`/recursive are listed above.

## Evidence (a working prototype exists, NOT to be landed)

Per the owner's 2026-10-06 instruction recorded on `avra-8sb5.34.53.29` ("law
is for the future; do not build until the owner says so"), the prototype below
is preserved for the design review and MUST NOT land until the owner says so.

- **Witnessed failing then passing.** A record holding a list
  (`type S = { seen: List<int>, tag: string }`) refused before the change with
  `type.mismatch` "…a record of one such field" + help "compare a field instead"
  (standing `build/avra`); after the change it checks and runs.
- **eval == native.** A probe program comparing a record holding a list and a
  string, a nested record, a payload enum, a list of records, a map built in two
  insertion orders, and a nullable list printed the identical line
  `true false true true false false true 0 true false` under `run` (evaluator)
  and under `build` + the native binary, at base `b49a8f20`.
- **No runtime row.** The compare lowers to IR (field/payload reads + the
  existing `Walk` loop with a bool cell), so both engines read one stream by
  construction. No new `rt_sigs` row, no seed refresh.
- **Prototype files.** `features/checks.av` (the law + recursion guard +
  voices), `features/values.av` (`same_value` dispatch, `same_record`,
  `same_list`, `same_map`, `same_enum`), `features/expr_spine/lower.av`
  (dispatch for `.App`/`.List`/`.Map`), `features/lists/methods.av` (scan
  voice), and updated spec tests + one program test
  `features/expr_spine/tests/eq_structural/`.
- **Suite status at hand-off.** `avra test packages/std-avrac` was last run
  mid-verification (three spec tests had been updated to the new law); the run
  was interrupted, so the suite is NOT certified green. Treat the prototype as
  a design demonstration, not a ready change.
