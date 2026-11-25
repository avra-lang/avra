# Error unions, Phase 1 — named unions only

**Status:** design, awaiting PERF's sign-off on §5 (layout) before implementation.
**Date:** 2026-09-25
**Scope:** `Result<T, A or B>`, hand-written. NOT in scope: inferred
`Result<T, _>` (avra-8sb5.40.10.2 — needs a new body-collecting walk
with no existing precedent) or catch-chain narrowing (avra-8sb5.9.29 —
needs §4's subtract operation, which this doc designs but a later
ticket wires into chained `catch`).

Every claim below is checked against a full research pass of the
current type system (no union mechanism exists anywhere today — `T?`
is a cardinality-2 niche trick that doesn't generalize, `dyn Trait` is
an open existential, the opposite shape from a closed enumerable set).

## 1. Type representation

`Type.Union(members: List<TypeId>)`, joining `core/types.av`'s `Type`
enum. Construction always flattens and dedupes: unioning a `Union`
into anything absorbs its members rather than nesting
(`(A or B) or C` interns identically to `A or B or C`), and a member
appearing twice collapses to one. This is genuinely new — every
existing composite (`List`, `Map`, `Res`, `App`) is a fixed positional
tuple with no post-construction dedup — but it's the only way `A or B`
and `B or A` (and every other reassociation/reordering) can be the
same interned type, which they must be for `accepts`/subset-checking
to work by identity rather than by re-deriving membership every time.

**Canon key**: sort member `TypeId.index`es ascending, join
(`"20:${sorted.join(".")}"`, tag 20 or whatever's next free). Sorting
is the mechanical fix for order-independence; nothing else in `canon`
needs it because nothing else has members that commute.

**A one-member union is not a union** — `Union([x])` never gets
minted; the constructor answers `x` directly. This keeps `Result<T, E>`
for a plain `E` exactly as it is today (no wrapper, no perf cost, no
new code path for the overwhelmingly common case).

## 2. Grammar and surface AST

**Spelled `or`, not `|`** (owner's call, 2026-09-25) — `or` is already
this language's alternation keyword (pattern arms: `.A or .B or .C ->
...`), so type alternation reuses the same word for the same concept
rather than introducing a second spelling. Not even a new reserved
word: `or` is already one.

Extend `features/type_expr/mod.av`'s `type` rule with a trailing
repetition, not an infix rule (avoids PEG left-recursion): today's
whole `type` production becomes `type_atom`, and the new top-level
`type` is:
```
type = t:type_atom ( "or" t2:type_atom )+ -> union_type(t, t2)
type = t:type_atom -> t
```
`?` binds tighter than `or` (`A or B?` parses as `A or (B?)`), matching
every other place `?` already binds to the immediately preceding name.

`core/nodes.av`'s `TypeRef` gains one field:
`alternatives: List<TypeRef> = []`. Non-empty means this `TypeRef` is
a union; `name`/`args`/`optional`/`dynamic`/`arrow` on the outer
`TypeRef` are unused in that case, and `alternatives` holds the 2+
member `TypeRef`s (each an ordinary single type, resolved the existing
way). Extending the existing shape rather than forking a parallel node
— `TypeRef` has absorbed exactly this kind of orthogonal addition
before (`dynamic`, `arrow`, `marks`).

## 3. Widening (fail / construction / `?` propagation)

The one law every check below reduces to: **treat every type as "a set
of member ids"** — a plain type is a 1-element set, a `Union` is its
own member set. Then:

- `fail v` where the promised err side is a union: accepted when `v`'s
  type is IN the set (today's `types_disagree`'s `got.index ==
  want.index` becomes `want_set.contains(got.index)`).
- `?` propagation (`nullable/check.av`'s `propagate_res_type`): accepted
  when the callee's error set is a SUBSET of the caller's error set —
  not equality. A plain-type callee into a plain-type caller is the
  existing behavior exactly (both 1-element sets, subset ⟺ equal).
  A plain-type callee into a union caller is "is this one member in
  the set." A union callee into a union caller (calling a fn that
  itself returns a union error into a fn with a wider union) is real
  subset checking, term for term.
- Widening a value of one union type into a WIDER union (adding a
  member the value's own type doesn't need) is the same subset check
  in the other direction — always legal, since the runtime already
  carries a tag for its actual member; only the caller's own
  compile-time promise widens.

## 4. `catch` over a union — a new pattern form

No existing pattern can select "which of N unrelated declared types
is this" — enum-variant coverage is keyed to one `EnumSig`'s name/tag
table, not to member `TypeId`s. Phase 1 adds a type-qualified bind:
```
result catch e: NotFound -> ...
       catch e: Timeout  -> ...
```
Each arm's `e: Member` narrows `e` to that member's own type inside
the arm body (an ordinary bind, typed at the member, not at the whole
union). Coverage is UNION-MEMBERSHIP coverage: total when every member
is named (in any order) or a catch-all `e -> ...` arm exists; selective
otherwise, in which case the answer's error side is `want_set MINUS
covered_members` — a genuine new `Union` (or a plain type, if exactly
one member remains, or `T` alone with no error side, if none remain —
though a Result that can't fail is a compound question for a later
pass, not solved here). This subtract-and-reinterned-as-a-narrower-
Union operation is what avra-8sb5.9.29 (catch-chain narrowing) needs;
this ticket builds the operation, that ticket wires it into chained
`.catch`.

## 5. Runtime layout — boxed by default, register optimization deferred

**Simplified, 2026-09-25: no blocking dependency.** `Union`'s
`side_word` answers "not one word" unconditionally — the same
conservative fallback every non-word-sized type already gets today.
`Result<T, A or B>` therefore boxes exactly like `Result<T, SomeStruct>`
already does, with zero new runtime code. This makes Phase 1 fully
buildable now, independent of `r15a`/avra-8sb5.34.26 landing.

**A real trap this does NOT dodge on its own, caught by PERF**: a
boxed union value needs its own discriminant (which member it actually
is — `catch`/match must be able to tell an `A` from a `B` at runtime),
so a boxed `Union` value is NOT bit-identical to a bare boxed `A`.
`features/values.av`'s `propagated` passes a value through unchanged
whenever `valued(from) == valued(into)` — both `false` for two boxed
Results, so today's guard would hand a `?`-widened `Result<T, A>` into
`Result<T, A or B>` straight through as an unwrapped `A` where the caller
expects a tagged union box. Silent wrong read, no diagnostic. Phase 1's
`propagated` change must be "same Result TYPE" (not "both boxed"), and
route every real mismatch — including box-to-box — through an explicit
lift that constructs the union's own tagged box from the plain value.
Add a program test pinning this exactly: `fn f() -> Result<int, A>`
failing, `fn g() -> Result<int, A or B> { f()? }`, match the `A` arm in
`g`'s own caller, eval == native.

The generalized-tag-space idea below (extending `Result`'s own tag
space to `1+N` so a union whose members all fit in a word stays in
registers) is a real, worthwhile follow-up — filed separately so it
doesn't block correctness. Kept below for whoever picks that up.

### Deferred optimization — FOR PERF'S REVIEW, not blocking

Per the existing layout law (`side_word`/`judge_result`, `docs/
2026_09_23_REUSE_IN_PLACE.md` §19–23): a `Result` rides `{tag, word}`
registers only when both sides are one word, judged once at intern.

**Proposal: generalize `Result`'s own tag space, not a boxed
sub-enum.** Today `Result<T, E>` is tag 0 (Ok) / tag 1 (Err), and if
`E` needs a discriminant it's `E`'s OWN tag living inside the payload
word. For `Result<T, A or B or ...>`, extend the OUTER tag space instead:
tag 0 = Ok, tag 1..N = Err-via-member-1..Err-via-member-N. This reuses
the value-enum machinery's existing per-tag counted-mask support
(already generalized for N tags, not just 2) rather than inventing a
boxed-union representation — `side_word`'s judgment for the union
"side" becomes "the union rides a word iff EVERY member does," with
`judge_result` iterating N+1 tags (1 Ok + N Err-members) the same way
a value enum already iterates its own variant count.

`?` propagation between two DIFFERENT unions (subset widening, §3) is
therefore a real re-tag (the member's position in the callee's tag
space almost never matches its position in the caller's wider union's
tag space) — never an identity pass-through, matching `propagated`'s
existing re-wrap-on-layout-mismatch behavior.

**Open question for PERF specifically**: does extending `Result`'s own
tag space to `1+N` (rather than always 2) interact with anything
`r15a`/avra-8sb5.34.26 assumes is fixed at exactly 2 (Ok/Err) when
judging `side_word`/`judge_result`? If the two-tag assumption is baked
in structurally rather than incidentally, the alternative (a boxed
"ErrUnion" sub-value, always one counted pointer, Result stays exactly
2-tag) is a fallback — simpler, but boxes on every union error even
when every member would individually fit in a word. Prefer the
generalized-tag-space version unless it's a real fight with the
just-landed layout work.

## Sequencing

Waiting on `r15a` (avra-8sb5.34.26) to land on main before touching
`Type.Res`/`side_word`/`judge_result` at all, per PERF's request.
Everything in §1–4 (representation, grammar, widening, catch) is
independent of the layout question and can be designed/reviewed now;
only §5's actual code waits on the merge.
