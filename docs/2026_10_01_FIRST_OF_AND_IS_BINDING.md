# Two small language additions: a first-present projection and payload-binding `is`

**Status: LANDED** on branch `ui-findis`. Owner decisions: the
projection is named `find_map` (answer REQUIRED nullable `U?`, the
`it` pronoun); payload `is` is legal as an `if` condition ONLY (full
payload list, bare `is` unchanged); the AST is a PARSE-TIME DESUGAR
into `Expr.Match` — no node-arity change, no seed refresh — with the
payload pattern kept in a NodeStore side table (`is_payloads`) so the
`if` that binds desugars and enums can refuse a payload `is`
anywhere else by name. The statement form desugars with `block_of`
branches, so a branch that ANSWERS keeps its value when the guard
stands in tail position (as `chain_value` promotes a plain `if`); a
payload `is` statement's arms must therefore agree, its match law.
See ROADMAP's sugar backlog interim record for the two tickets.

Author: the `ui` lane (`ui-findis`), at the owner's request.
Base: branch `ui-findis` off `origin/main` `2b051df`.
Probes below ran on `../avra-spread/build/avra` (`a69120a`), a newer
standing binary than this worktree's, from `/tmp` (where a refusal
actually prints — CLAUDE.md, "A PROBE LIVES OUTSIDE THE TREE").

This note covers two independent asks. Each is small, each is idiomatic,
and each needs the owner's decision before any code lands.

---

## Part A — a first-present projection on `List`

### The want

Extracting one variant from a list of a payload-bearing enum is a
hand-written scan today:

```avra
enum Attribute { Level(int) Text(string) Label(string) }

fn level_of(attrs: List<Attribute>) -> int {
    for a in attrs {
        match a {
            .Level(r) -> { return r }
            .Text(_) or .Label(_) -> {}
        }
    }
    1
}
```

The obvious flat spelling does not work, because `map` answers a list of
the projection and `first` then makes the optional NEST:

```avra
attrs.map(match it { .Level(r) -> r, rest -> null }).first()
```

**Probe (p4.av), `a69120a`:**

```
error[type.mismatch]: the body answers `int??` but `level_of` declares `int?`
  ╭─[/tmp/avra-probe/p4.av:3:5]
3 │     attrs.map(match it { .Level(r) -> r, rest -> null }).first()
  ·     ┬
  ·     ╰── this is `int??`
```

The double optional is the empty-value law's own shape (`T?` over
`T = U?`): the user wants `U?`, and there is no one verb that answers it.

### Name: recommend `find_map`; `first_of` is the alternative

| name | reads as | provenance |
|------|----------|------------|
| `find_map` | "find, through a map" — the composition of two verbs the language already teaches | Rust `Iterator::find_map`; an LLM produces it correctly first try (P1) |
| `first_of` | "first present of the projection" | no precedent; collides with the tree's many user helpers already named `first_of` meaning "first matching element" (`std-http/src/tests/sse_test.av`, `std-action/src/form.av`, `compiler/rule_examples.av`) |

**Recommendation: `find_map`.** It is the composition of `find` and `map`,
which is the "generalize before adding" shape — no new concept, a
familiar name, and no collision with the `first`/`last` edge verbs.
`first_of` is defensible if the owner prefers a terse Avra verb over the
familiar one, but it would mean editing three existing user helpers or
living with two meanings of one name.

### Signature and spelling

```avra
fn find_map<U>(xs: List<T>, f: fn(T) -> U?) -> U?
```

```avra
attrs.find_map(match it { .Level(r) -> r, rest -> null }) ?? 1
```

The pronoun binds with no new machinery: `it` already binds to the
nearest method call. **Probe (p7.av), `a69120a`** — `attrs.map(match it
{ .Level(r) -> r, rest -> 0 }).first()` compiled and `avra run` answered
`3 0`. So `find_map(match it { … })` is expected to bind `it` the same
way through the shared walk prelude. The trailing-block form
`attrs.find_map { match it { … } }` should also work (the trailing builder
makes `(it) -> match it { … }`).

### Typing

A new row in `features/lists/mod.av`'s `methods` table, beside the other
walks:

```
"find_map" | on_list | check_find_map | lower_find_map | ReceiverEffect.Read | unknown_answer
```

`check_find_map` reuses the shared `walk_seat` prelude (the receiver's
element, exactly one fn, its single seat retyped to the element — the
same door `map`/`find`/`any` use). The one new law: the fn's ANSWER must
be a nullable, and the row answers that same nullable. This is the type
law that distinguishes `find_map` from `map` (whose answer is a list) and
from `find` (whose fn answers bool).

Voices (in `features/lists/methods.av`, alongside the existing walk
voices):

- fn answers a non-nullable `X`: "`find_map` seeks the value its fn
  answers, nullable — this answers `X`", help "answer `null` when there is
  nothing to seek".
- wrong fn arity / non-fn / wrong seat: the existing `misseated_walk`,
  `fnless_walk`, `seat_not_element`, `one_fn_wanted` — reused, not
  re-spelled.
- empty literal receiver: the existing `unknowable_walk`.

### Lowering

`lower_find_map` mirrors `lower_find` (`features/lists/walks.av`), with
one difference: `find` stores the ELEMENT when its predicate holds, while
`find_map` stores the fn's own ANSWER when that answer is present. The
loop skeleton, the absent-seeded cell, the fn box and code pointer, the
early exit (`cx.walk_done()`), and the memory law (the memory pass owns
every count; nothing here spells a retain) are identical. The presence
split on the answer rides the emission vocabulary's `presence` verb
(`features/emit.av`) rather than a raw region.

### Proof owed

- program test `features/lists/tests/find_map/find_map.av` + `.expected`
  (final expression shown; eval == native): the first present wins, an
  all-absent list answers null, and a later present element is not
  consulted.
- adversarial test `features/lists/tests/find_map_adversarial_test.av`:
  non-nullable answer (the new voice, pinned once), two arguments, zero
  arguments, a non-fn argument, an empty-literal receiver, a non-list
  receiver.
- the bad-seat refusal as a spec `then` with `refused_with` (the
  "golden" for the new voice).
- Short-circuit witness: I have not settled how to build one that cannot
  be defeated by a fold. A projection whose later element would trap
  (integer division by zero) behind the first hit is the candidate; this
  is an open test-design question (see below).

---

## Part B — payload-binding `is`

### The want

`p is .Variant` tests a bare variant and is the right idiom. Extracting
the payload currently forces a `match`, or an `is` test plus a force:

```avra
for a in attrs { if a is .Level(r) { return r } }
```

**Probe (p5.av), `a69120a`:**

```
error[parse.expected]: expected BREAK while parsing `stmt`
  ╭─[/tmp/avra-probe/p5.av:3:25]
3 │     for a in attrs { if a is .Level(r) { return r } }
  ·                         ┬
```

The same refusal fires in a general expression (p6.av, at the `(`).

**This is the SPEC's own documented form.** The full spec
(`../forge-crafting-intepreters/docs/2026_04_18_FULL_SPEC.md`, axis 2.2)
writes it as the type-narrowing idiom:

> **Type narrowing:** use `is` or pattern matching. `if r is Success(s) { ... }`
> compiles to a tag check (no reflection needed …)

So Part B is reviving a feature the spec names and the implementation
never carried — not inventing one.

### The decision to make: where may a payload appear?

Three honest shapes, in increasing scope:

1. **`if` condition only.** `if a is .V(r) { … }` is the only place a
   payload may appear; a bare boolean `is` stays everywhere. Refused in a
   general expression, in `while`, in `&&`/`||`, and in a `when` arm.
2. **Any condition head.** Also `when { a is .V(r) -> r, _ -> 0 }` and
   `while a is .V(r) { … }`. The `when` extension is genuinely attractive;
   `while` is not (the binder changes every turn).
3. **Anywhere `is` parses.** The binder would be meaningless outside a
   branch and would need a story for every context.

**Recommendation: option 1**, stated as the binding law: *a payload `is`
binds in the then-branch of an `if`, and nowhere else; every other use is
refused with a voice naming `if`.* The `when` form is a natural follow-up
and should be filed as its own sugar-backlog ask (it is the same binding
rule, one dispatch down), but shipping it in the same slice would double
the surface for one motivation.

This matches Rust (`if let`) and Swift (`if case`) in spirit — binding is
an `if`-condition privilege, never a property of the boolean operator.
It also preserves the bare form EXACTLY: default `bind == null`.

### Why bind-fresh, and the scope

Spec 10.4 decides narrowing is **bind-fresh**: the check introduces a new
immutable binding; the original name is never retyped. So `r` in the
example is a fresh immutable name scoped to the then-branch alone. It
cannot be reassigned, it cannot leak into the else, and it cannot be
carried out of the `if`.

### Implementation shape — recommended: extend `Expr.Is` with a binder

The smallest real feature is one grammar line plus a contextual scope.

**Grammar** (`features/expr_spine/mod.av`'s `comparison`, one line):

```
"is" "." iv:NAME ( "(" ( b:NAME ( "," b:NAME )* ","? )? ")" )?
```

i.e. the payload list is optional and mirrors a match pattern's payload
list: names and `_`, so `if a is .V(r)`, `if a is .V(_, y)` and
`if a is .V(_)` all parse. `Expr.Is` gains an appended field
(`bind: List<PatId>` or `binds: List<string>`) carrying the payload
patterns; a bare `is` carries none.

**Typing** (`features/enums/check.av` for `Is`; `features/if_expr/check.av`
for the binding):

- `asked_type` keeps its boolean meaning for a bare `is`.
- A payload `Is` used as the DIRECT condition of an `if`/`if_stmt` binds
  the variant's payload types in the then-branch, exactly as
  `match_opt_type` binds the present arm (`features/nullable/check.av`)
  and as `walk_narrowed` narrows a presence test (`features/if_expr/check.av`).
  The then-branch walks under those binders; the else-branch does not.
- A payload `Is` anywhere else — a general expression, `while`, an
  operand of `&&`/`||`, a `when` arm — refuses with a named voice:
  "a payload `is` binds only in an `if` condition — write the `match`, or
  test the variant bare and extract under it", help "`if a is .V(r) { … }`".

**Why this over a dedicated keyword-first head.** `if let` is a dedicated
head because `? =` is not in the expression ladder; `is` already IS, so a
dedicated `if a is` head would have to parse its subject with a rule
*below* `comparison` and would re-spell the subject grammar. Extending the
existing `is` keeps ONE `is` surface and forks meaning at typing — the
tree's "one surface, kinds fork at typing" law. It also makes the
elseless guard (`if a is .V(r) { … }`, the motivating shape) just work:
the condition is already an expression in the existing `if`/`if_stmt`.

**Costs to flag before implementing:**

- Appending a field to `Expr.Is` touches 14 `Is(...)` match sites across
  10 files (mechanical; the compiler enumerates them). It changes the
  node kind's arity, so the committed seed / derive baked shapes may need
  a refresh — CLAUDE.md's boundary law ("the refresh is owed by the first
  READER") applies. If that proves expensive, the fallback is a
  parse-time desugar into `Expr.Match` using existing nodes, at the cost
  of a dedicated head and a statement-form story.
- Language change to the compiler's own source: the generation protocol
  (`cp build/avra build/avra.pre`, build with the old binary, rewrite,
  rebuild with the product) and `make bootstrap` are the way through,
  never `make avra` on a stale lane binary.

### Proof owed

- program test `features/if_expr/tests/is_binds/is_binds.av` + `.expected`
  (eval == native): the then-branch sees the payload, the else does not,
  the elseless guard works, `_` ignores a payload, multiple payloads bind
  in order.
- adversarial test: payload `is` outside `if` (expression, `while`,
  `&&`, `when`) refuses with the named voice; wrong payload count (the
  existing F2015); unknown variant (the existing weight); non-enum
  subject; duplicate binder name; binder shadowing an outer name.
- a spec `then` golden per refusal voice.

---

## Cross-cutting

- **Docs.** Remove the CLAUDE.md "The subset today" entry "`is` with a
  PAYLOAD pattern (`p is .Bind(_)`)" when Part B lands; add `find_map` to
  the List vocabulary. This note is the design record.
- **Sugar backlog.** File both asks under epic `avra-8sb5.10` with an
  `Example:` and a `Callsite:` (the `tasks` server was unreachable at
  writing time, so this note is the interim record). Part A's callsite is
  `std-http/src/jar.av`'s `last_of`/`expiry` first-match reads; Part B's
  is the `level_of` scan in this note.
- **Dogfooding.** The compiler's own source has both shapes: hand-rolled
  first-present scans in `compiler/rule_examples.av` and variant
  extraction under `is` tests. If either feature lands, the wanting sites
  convert in the same slice and the idioms registry records any new
  pattern at discovery.

## Owner decisions (resolved)

1. **Name:** `find_map`.
2. **`find_map` strictness:** the fn's answer is REQUIRED nullable.
3. **Part B scope:** an `if` condition only; `when` arms are a
   follow-up (filed in the sugar back log).
4. **Part B payload arity:** a full payload list.
5. **Part B AST:** parse-time desugar to `Expr.Match` (the recommendation
   above is superseded; the desugar preserves the else/narrowing
   semantics without a node-arity change).
