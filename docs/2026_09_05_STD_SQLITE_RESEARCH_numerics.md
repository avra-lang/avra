# `float` and `decimal` — the numerics research report

Lane sqlite research, 2026-09-05.

Companion to `2026_09_05_STD_SQLITE_RESEARCH_numeric_tower.md` (which
independently covers the spec reading, the lexer trap inventory and the
`Type`-arm cost). This report is the deeper pass on the six questions that one
leaves open: **literal adoption**, **IEEE equality**, **printing**,
**parsing**, **the decimal design space**, and **the database mapping**. Where
the two reports disagree I say so at the site.

The spec is LAW. Where I propose an amendment I mark it **AMENDMENT** and argue
it explicitly, as instructed.

**Every claim about behaviour in this report was MEASURED**, not reasoned. The
commands are quoted. Where I could not measure (other languages' toolchains are
not installed here) I say "documented, not measured".

---

## 0. The one-paragraph answer

`float` is binary64 and the spec already specified it completely (Axis 31.2);
we implement it verbatim. `decimal` is **not in the spec** — Axis 31.3 decided
exact base-10 is `BigDecimal` in `@std/numbers`, a library type — and I
recommend keeping that decision, with one amendment: the type is *spelled*
`decimal`, and a pointed literal in a `decimal` seat is converted **from its
source text**, exactly, never through a double. That amendment is nearly free,
because the lexer already carries a numeric literal's TEXT
(`grammar/lexer.av:321`), and it is the difference between `let price: decimal
= 19.99` being right and being the money bug. The deepest finding in this
report is architectural: **the compiler never needs to hold a float value at
all.** LLVM's C API takes a constant's decimal TEXT
(`LLVMConstRealOfString`), and the interpreter can carry a float as its 64-bit
BIT PATTERN inside the existing `Val.I`. So `float` can land without a single
`float` appearing in the compiler's own source — which dissolves the bootstrap
ordering problem that would otherwise gate the whole campaign. Printing is the
real work, and the honest first landing is SQLite's own algorithm (try 15
digits, verify by re-parsing, else 17), which I measured: it never fails to
round-trip and is one digit longer than shortest for 11.1% of human-shaped
values. And the measured trap for the ORM: **a `DECIMAL(10,2)` column in SQLite
has NUMERIC affinity and silently converts your exact text to a double** —
`123456789012345678901.25` came back as `1.23456789012346e+20` in a probe below.
The driver must refuse that declaration by name.

---

## 1. WHAT THE SPEC ALREADY SAYS

All quotations from `../forge-crafting-intepreters/docs/2026_04_18_FULL_SPEC.md`,
**Axis 31: Numerical Types**, lines 6235–6411.

### 1.1 The axis exists and it is detailed

The lead's brief said "there IS an axis on the numeric tower; find it and treat
it as law". There is: **Axis 31**, five sub-decisions, ~180 lines. It is the
most completely-specified axis this campaign touches. It answers nearly every
question in the brief.

### 1.2 Integer sizes (31.1, spec:6237–6277)

> **Decision:** **(c) `int` (pointer-sized) at app level, explicit sizes at
> systems level**

- `int` — "signed, pointer-sized (i64 on 64-bit platforms, i32 on 32-bit). The
  default integer type for all app-level code." (spec:6250)
- `uint` — "unsigned, pointer-sized." (spec:6251); "That's it. No `i8`, no
  `u32`, no size soup." (spec:6252)
- "**No silent narrowing:** conversions between int sizes are always explicit.
  `let small: i32 = big_int.to_i32()?` — returns a Result because the conversion
  can overflow." (spec:6275)
- "**Default literal type:** integer literals without context default to `int`."
  (spec:6276)

Nothing in the campaign needs `uint` or the sized ints. SQLite's INTEGER storage
class is int64; `int` carries it exactly.

### 1.3 Float (31.2, spec:6279–6298) — decided in full, verbatim

> **Decision:** **(c) `float` (64-bit IEEE 754) at app level, `f32` and `f64` at
> systems level**

The load-bearing lines, quoted exactly:

- "**`float`** — 64-bit IEEE 754 double-precision" (spec:6288)
- "No `double` alias (`float` IS double at app level)" (spec:6289)
- "**`f32`** — 32-bit single-precision"; "**`f64`** — 64-bit double-precision
  (same as app-level `float`)"; "**`f16`** (reserved)" (spec:6291–6293)
- "**Special values:** IEEE 754 semantics — `NaN`, `Infinity`, `-Infinity` are
  valid values. Available as `Float.nan`, `Float.infinity`,
  `Float.neg_infinity`. Comparisons with NaN follow IEEE rules (NaN != NaN)."
  (spec:6294)
- "**No implicit int-float conversion:** `let x: float = 5` is a compile error.
  Write `let x: float = 5.0` or `let x: float = (5).to_float()`. This prevents
  silent loss of precision and matches strong static typing." (spec:6295)
- "**Float literals:** must have a decimal point or exponent: `5.0`, `1e10`,
  `2.5e-3`. `5` alone is an integer literal." (spec:6296)
- "**Division semantics:** `int / int = int` (truncating), `float / float =
  float`. Mixed arithmetic requires explicit conversion." (spec:6297)
- "**Versioning:** `float` ships in v1.0. `f32`/`f64` reserved in v1.0, ship
  with systems level." (spec:6298)

**Every question in the brief's §1 is answered by 31.2 except two: the printing
algorithm and the parsing algorithm.** The spec names neither. Those are §§4–5
of this report, and they are where the actual engineering lives.

The spec names **`float`**, not `f64`, at app level. `f32`/`f64` are *reserved*
and versioned to the systems level, which does not exist yet. So the campaign
ships exactly one float type, spelled `float`. No amendment needed, none
proposed.

### 1.4 Arbitrary precision (31.3, spec:6300–6332) — there is no `decimal`

> **Decision:** **(b) `BigInt` / `BigDecimal` in `@std/numbers` — explicit
> types, no silent promotion**

- "**`BigDecimal`** — arbitrary-precision decimal with explicit scale; useful
  for money, scientific data, anything where `0.1 + 0.2 == 0.3` matters"
  (spec:6310)
- "**Money type:** `@std/money` provides `Money` built on `BigDecimal` with
  currency tagging — the idiomatic choice for financial apps. BigDecimal alone
  doesn't know about currencies." (spec:6329)
- "**Performance note:** every `BigInt` / `BigDecimal` operation allocates. Use
  explicitly when the precision matters; stick with `int`/`float` for hot paths.
  The cost is visible in the type." (spec:6331)
- The spec's own construction is **from text**: `BigDecimal.from_str("19.99")?`
  (spec:6321).

**The word `decimal` does not appear as a type name anywhere in the spec.** The
brief's "we have decided to land `decimal`" is therefore either (a) an
implementation of 31.3's `BigDecimal` under a shorter name, or (b) a spec
amendment adding a core primitive. §6 argues for (a) plus one narrow amendment,
and against (b).

Where I **diverge from the sibling `numeric_tower.md`**: it concludes the
amendment "is not needed" and that operator traits are the whole answer. I agree
about operators. I disagree that nothing else is needed, because 31.3 leaves the
**literal** unaddressed — `BigDecimal.from_str("19.99")?` is a `Result`, in a
`?`-propagating expression, for a compile-time constant that cannot fail. That
is ceremony where the language promises zero (P3), and it is the single form an
LLM will get wrong most often. See §2.5.

### 1.5 Overflow (31.4, spec:6334–6365)

- Default: "**Debug builds:** panic on overflow"; "**Release builds:** wrap
  using two's-complement" (spec:6343–6344); `[build] overflow_checks` in
  `avra.toml` (spec:6345).
- "**Division-by-zero:** always panics (in both debug and release). ... Integer
  division by zero is never defined behavior — there's no sensible 'wrap' for
  that." (spec:6363)
- "**Float overflow:** floats don't overflow in the integer sense — they become
  `Infinity` or `-Infinity`, which is valid. No panic, no check, follows IEEE
  754." (spec:6364)

**Reading, load-bearing, and I concur with `numeric_tower.md` here:** 6363's
division-by-zero panic is scoped to INTEGER division and justified by the
absence of a defined answer. For floats there IS one (±∞, and `0.0/0.0` = NaN),
and 6364 says floats follow IEEE with "no panic, no check". **Float division by
zero must not trap.** This needs spelling at the site because the tree's integer
`Div` routes to `avra_int_div`, which traps:

```c
// runtime/avra_runtime.c:485
int64_t avra_int_mod(int64_t a, int64_t b) {
    if (b == 0) { avra_trap("division by zero"); }
```

and `bin_value` (`language/llvm.av:359-360`) routes both `Div` and `Mod` there.
A float `Div` reusing that path traps where IEEE says ±∞. See §8.4.

### 1.6 Literal syntax (31.5, spec:6367–6411)

The full accepted set, quoted:

```
42        42_000       1_000_000
0x2A      0o52         0b101010      0xFF_FF_FF_FF
3.14      2.5e-3       1e10          6.022_140_76e23
42i32     200u8        3.14f32       1_000_000i64    0xFF_FF_FFu32
```

- "Float suffixes: `f32`, `f64`, `float`" (spec:6405)
- "Out-of-range literals are compile errors: `256u8` → 'literal 256 does not fit
  in u8 (max 255)'" (spec:6406)
- "**No octal implicit:** unlike C, `077` is NOT octal 63 — it's the decimal
  literal 77." (spec:6411)
- `'a'` char, `b'a'` byte (spec:6408–6409)

**There is no `m` suffix, no decimal literal, and no untyped-constant rule in
31.5.** This is the one real gap in the axis, and it is exactly where the ORM's
money case lands. §2 fills it.

### 1.7 Two internal divergences in the spec itself

**(a) `.float` vs `.to_float()`.** spec:1303 writes `Point { x: i.float, y:
i.float * 2 }` — a property. spec:6295 writes `(5).to_float()` — a method. 31.2
is the normative sub-decision; 1303 is an illustrative memory-model example.
**Take the method.** (Concurs with `numeric_tower.md`.)

**(b) "numeric widening" in table literals.** spec:5857: "all values in a column
must unify to a single type (with the usual numeric widening and optional
widening rules)". There are **no** "usual numeric widening rules" — 31.2 says
"No implicit int-float conversion" and "Mixed arithmetic requires explicit
conversion". **31.2 wins**; a `table` column holding `1` and `2.5` is a type
error. Flag for the owner. (Concurs.)

**(c) A third, which `numeric_tower.md` does not name:** spec:5562 specifies
`${price:.2}` — "a format specification ... for 2 decimal places". A float's
interpolation is therefore specified to take a precision spec, and the tree's
`Expr.Interp` has no field for one. That is not this campaign's to build, but
it means **the default `${x}` projection is not the only projection the spec
promises**, and §4's recommendation should not paint the runtime into a corner
where a fixed-precision projection is hard to add. Ryū and the 15/17 fallback
both leave that door open (both are separate from a `%.*f` path); a shortest-only
design with no digit-generation control would not.

---

## 2. LITERAL SYNTAX

### 2.1 What the tree does today — MEASURED

Four probes, `./avra check` on one scratch file each (sub-second, no lock):

```
$ printf 'fn main() {\n    let x: float = 1.5\n    println("${x}")\n}\n' > num1.av
$ ./avra check num1.av
error[F0100]: expected BREAK while parsing `stmt`
2 │     let x: float = 1.5
  ·                     ┬          <- the caret is AT the `.`
```

```
$ printf 'fn main() { let x: float = 3 \n println("${x}") }\n' > num1.av
$ ./avra check num1.av
error[F2001]: `float` names no type
```

```
$ printf 'fn f() -> int { 1e10 }\n' > num1.av
error[F0100]: expected BREAK while parsing `stmt`
1 │ fn f() -> int { 1e10 }
  ·                  ┬               <- at the `e`

$ printf 'fn f() -> int { 1_000 }\n' > num1.av
error[F0100]: expected BREAK while parsing `stmt`
  ·                  ┬               <- at the `_`

$ printf 'fn f() -> bool { [1.0].length > 0 }\n' > num1.av
error[F0100]: expected `]` to close the list
```

So: no float type, no float literal, **no exponent literal, and no underscore
separator** — the last two are spec forms (31.5) the tree lacks for *integers*
today. That is a standing spec gap nobody had recorded. Since this campaign
rewrites `numbered` anyway, land underscores and exponents for ints in the same
change.

**The decisive constraint, measured, not assumed:**

```
$ printf 'fn f(n: int) -> int { n }\nfn main() { println("${f(1.abs())}") }\n' > num1.av
error[F2030]: `.abs(…)` calls a method, and `int` has none
```

`1.abs()` **parses today** — the error is a typing error, not a parse error. A
greedy float scanner that consumes `1.` breaks every method call on an integer
literal. This is why `1.` must be refused, and the reason is tree-grounded, not
stylistic. (`numeric_tower.md` reaches the same conclusion; I have now measured
the premise it rests on.)

### 2.2 The survey

| Language | Float literal | Decimal literal | Bare `1.5` is |
|---|---|---|---|
| **C / C++** | `1.5` (double), `1.5f`, `1.5L` | none | `double` |
| **Rust** | `1.5`, `1.5f64`, `1.5f32`, `1_000.5`, `1e10` | none in std (`rust_decimal` crate: `dec!(1.5)` macro) | `{float}` — an *inference variable* defaulting to `f64` |
| **Go** | `1.5`, `1e10`, `1_000.5` | none in std (`shopspring/decimal`: `decimal.NewFromString`) | an **untyped float constant** — arbitrary precision at compile time, adopts its context, defaults to `float64` |
| **Swift** | `1.5`, `1.5e10`, `0x1.8p3` | `Foundation.Decimal`, but `Decimal(1.5)` goes **through a Double** — the famous trap; `Decimal(string: "1.5")` is the correct form | adopts via `ExpressibleByFloatLiteral`, defaults to `Double` |
| **C#** | `1.5`, `1.5d`, `1.5f` | **`1.5m`** — a first-class decimal literal, exact | `double` |
| **Java** | `1.5`, `1.5d`, `1.5f` | `new BigDecimal("1.5")` — and `new BigDecimal(1.5)` is a documented footgun giving `1.5000000000000000444089209850062616169452667236328125` | `double` |
| **Python** | `1.5`, `1e10`, `1_000.5` | `Decimal("1.5")`; `Decimal(1.5)` gives the exact binary expansion | `float` (binary64) |
| **Kotlin** | `1.5`, `1.5f` | `java.math.BigDecimal`, `"1.5".toBigDecimal()` | `Double` |
| **Zig** | `1.5`, `1e10`, `0x1.8p3` | none | **`comptime_float`** — arbitrary precision (f128 internally), coerced at use |
| **JS** | `1.5` | TC39 decimal proposal (stage 1): `1.5m` under discussion | `Number` (binary64) |
| **SQL** | `1.5` is `NUMERIC`/`DECIMAL` (exact!) per the standard; `1.5E0` is float | `1.5` **is** the decimal literal | **exact decimal** — the SQL standard's default is the opposite of every programming language's |

Two things stand out.

**The `m` suffix is the only widely-deployed decimal literal in a general-purpose
language**, and C# is where it lives. It is unambiguous, it is one character,
and it is genuinely well-known.

**SQL's default is the opposite of every host language's.** In SQL, `1.5` is
exact decimal; `1.5E0` is the float. So an ORM sits astride a genuine notational
inversion — the same five characters mean "exact" on one side of the boundary
and "binary64" on the other. Any design here must be explicit about which side
it is on.

### 2.3 The LLM-reflex test

The bar is P1: a model writes it correctly on the first generation. So the
question is not "what is elegant" but "what will a model type without thinking,
and does that reflex produce the right type?"

| The model writes | Under `float` | Under `decimal` |
|---|---|---|
| `let x = 1.5` | float. **Right.** | — |
| `let price: decimal = 19.99` | — | **This is the whole question.** |
| `let price = 19.99m` | — | right, if we take C#'s suffix — but a model trained mostly on Python/JS/Rust will *not* reach for `m` unprompted |
| `let price = decimal("19.99")` | — | right, but ceremony, and models produce `decimal(19.99)` — the unquoted form — at a high rate, because that is what `Decimal(1.5)` looks like in Python |
| `Order { total: 19.99 }` | — | the field-seat case, and the tree's hardest (see §2.6) |

The observed failure mode across Python, Java and Swift is identical and it is
the **unquoted constructor**: `Decimal(1.5)`, `new BigDecimal(1.5)`,
`Decimal(1.5)`. Each is legal, each compiles, each silently routes an exact
decimal through binary64, and each is what a model writes by reflex because the
quoted form looks like a workaround. Java's own Javadoc has carried a warning
about it for two decades. **A design whose safe form requires quotes has already
lost the P1 bar**, because the unquoted form must then either exist and be
wrong, or not exist and produce an error on the most natural spelling.

### 2.4 The P6 question: should a bare `1.5` be a float, or adopt its seat?

This is the genuine paradox the brief names. Let me take both horns seriously.

**Horn A — `1.5` IS a float.** Simple, matches the spec's phrasing, matches
Rust/Python/C#/Java, and there is exactly one answer to "what type is this
expression" with no context needed. But then `let price: decimal = 19.99` must
either be refused (and the most natural spelling of the most common ORM case is
an error) or convert — and converting means the literal was *already* a binary64
by the time the seat sees it, so `19.99` becomes
`19.989999999999998436805981327779591083526611328125`. Silent, exact-looking,
wrong. That is the money bug, at the literal, in the first line a model writes.

**Horn B — `1.5` is an untyped constant that adopts its seat** (Go, Zig, and
Swift's literal protocols). `let price: decimal = 19.99` is exact; `let x: float
= 1.5` is a float; both read naturally. But Go's untyped-constant rules are a
genuine subsystem — default types, arbitrary-precision compile-time arithmetic,
conversion and assignability rules, and the "untyped constant overflows" error
class. And it is invisible: the same five characters have two types depending on
context, which strains P7.

**The collapse.** The horns are only in tension if you assume the literal must
carry a *value* through the compiler. It does not. Look at what the lexer
already does:

```avra
// grammar/lexer.av:319-321
is_digit(c) -> {
    let j = scan_while(src, n, i + 1, is_digit)
    numbered(src.substring(i, j), i, j)
}
```

The token carries its **TEXT**. Nothing is lost at the lexer, and nothing needs
to be: a numeric literal's exact meaning is its digits. The loss happens only at
the moment someone converts the digits to a machine value — and *that moment can
be the moment the type is known*.

So the recommendation is Horn B, but implemented as a much smaller thing than
Go's untyped constants:

> **A numeric literal node keeps its digits. The type it is asked for decides
> how the digits become a value. There is no compile-time arithmetic on
> untyped constants, no defaulting subsystem, and no new inference: a literal
> with no seat takes the spec's default (`int` for a bare digit run, `float`
> for a pointed or exponent form), and a literal in a seat converts to the
> seat's type if that type is numeric.**

That is one rule, one sentence, and it is P7-visible because the projection is
literally the source text. It costs almost nothing beyond what the campaign
already builds, because the conversion must exist anyway (§5) and the lexer
already carries the text.

**What it explicitly does NOT do**, and this is what keeps it from being Go:

- no arbitrary-precision compile-time arithmetic — `1.5 + 2.5` in a `decimal`
  seat is not folded exactly; each literal adopts and the *runtime* adds. (Go
  folds. We do not, and should say so.)
- no adoption across a fn boundary or into a generic — a seat is a declared
  type, present at the site.
- no `int` literal adopting `float` — spec:6295 forbids it explicitly ("`let
  x: float = 5` is a compile error"), and that stays. Adoption is for a
  *pointed* literal into `float` or `decimal`, and a *bare* literal into `int`
  or `decimal`. `decimal` accepts both because `19` is an exact decimal.

### 2.5 The recommended spelling

**`float` literals** — implement 31.5 exactly:

| Accept | Why |
|---|---|
| `1.5`, `0.0`, `19.99` | spec:6296's canonical form |
| `1e10`, `1E10`, `2.5e-3`, `1e+9` | spec:6296's exponent form |
| `1_000.5`, `1.000_1`, `6.022_140_76e23` | spec:6386 |
| `-0.0` via unary minus on `0.0` | negative zero is a value (§3) |

| Refuse | The voice |
|---|---|
| `1.` | "a float literal needs a digit after the point — write `1.0`" (**measured reason**: `1.abs()` parses today, §2.1) |
| `.5` | "a float literal starts with a digit — write `0.5`" (`.` heads a bare variant) |
| `1.5f32`, `3.14f64` | "`f32` and `f64` arrive with the systems level" (31.2 versions them there) |
| `0x1.8p3` | "hex floats are not a literal — `Float.from_bits(n)` writes the bits" |
| `1e`, `1e+` | "an exponent needs digits" |
| `_1.5`, `1_.5`, `1._5`, `1.5_` | "an underscore separates digits" |

The `..` collision is real and `numeric_tower.md` covers it: `0..10` must not
lex as `Num("0.")`. The scanner must look ahead for a *digit* after the point,
which the "refuse `1.`" rule already requires. Measured: `0..3` lexes correctly
today (§2.1's third probe compiled past the range).

**`decimal` literals** — **AMENDMENT to 31.5**, and here is the argument.

The proposal is: **`19.99m`** (C#'s suffix) as the explicit spelling, **and**
seat adoption (§2.4) so that `let price: decimal = 19.99` is exact without it.

Why the suffix at all if adoption works? Because adoption needs a seat, and the
tree has documented places where a seat's want does not reach the value — the
struct-literal field being the one that matters most (§2.6). In those places the
suffix is the escape hatch (P8), and it is one character.

Why `m` and not `d`? `d` is C#'s *double* suffix; reusing it inverts the meaning
for anyone who knows C#. `m` is "money", it is unambiguous in Avra (no `m`
suffix exists), and it is the only decimal-literal suffix with real deployment.

Why not `decimal("19.99")` alone, per spec:6321's `BigDecimal.from_str("19.99")?`
That form must exist — it is how *runtime* text becomes a decimal, and it
correctly answers a `Result` because runtime text can be malformed. But it is
the wrong form for a *constant*: it answers a `Result` that cannot fail, forcing
`?` or `!` on a compile-time value, in a language whose Part 0 promises zero
ceremony. And, per §2.3, it is precisely the shape whose unquoted sibling is the
industry's most-repeated numeric bug.

**Refuse `decimal(19.99)` — the unquoted constructor — by name.** This is the
single highest-value diagnostic in the whole numerics landing:

```
error[F20xx]: `decimal` from a float has already lost the digits
  ╭─[order.av:12:19]
12 │   let price = decimal(19.99)
   ·                       ^^^^^ this is a `float` — 19.99 is not exactly representable in binary64
   ·
   · help: write `19.99m`, or `decimal("19.99")` for text that arrives at runtime
```

Note what that refusal does: it makes the reflex form *impossible to get wrong
silently*. The model writes the natural thing, the compiler names the trap and
hands back the two correct spellings. That is P1 and P10 in one diagnostic — the
compiler holds semantic knowledge (which decimals are representable in binary64)
that no other tool has.

### 2.6 Where adoption will NOT reach, and it must be said

CLAUDE.md's "The subset today" records, measured, that a struct-literal field
seat does not plant a want on its value: "*a comprehension there types on its
own*", and a `List<T>` never adopts a `List<T?>` want. The same machinery gates
literal adoption. So:

```avra
let price: decimal = 19.99          // adopts — a typed let plants the want
charge(19.99)                       // adopts — a call argument is a seat
Order { total: 19.99 }              // DOES NOT adopt today — the field seat
                                    // does not reach the value
```

The third line is the ORM's most common shape. Two honest answers, and the
campaign should take **both**:

1. Short term: the field seat's mismatch refusal names the fix — "field `total`
   is `decimal`, this is `float` — write `19.99m`". The suffix exists exactly
   for this.
2. Correct term: fix the field seat to plant its want. That is a typer slice
   already wanted by three other entries in the subset ledger, and the sugar
   backlog should record that **the decimal literal is the case that makes it
   load-bearing rather than merely tidy** — because everywhere else the missing
   want produces an *error*, and here it would produce a *wrong value* if
   adoption silently fell back to float.

That asymmetry is worth stating as a law:

> **A seat that fails to plant its want must REFUSE, never fall back.** For
> every other type the fallback is a type error caught downstream; for a
> decimal literal it is a silently rounded price.

---

## 3. IEEE-754 SEMANTICS AND THE EQUALITY PROBLEM

### 3.1 What IEEE-754 forces

Four facts, none negotiable if `float` is binary64:

1. **NaN ≠ NaN.** So `==` is not *reflexive*. `x == x` is false for exactly one
   class of value.
2. **+0.0 == -0.0**, but they are distinguishable — `1.0/0.0` is `+inf`,
   `1.0/-0.0` is `-inf`, and `Float.bits` differs. So `==` is not
   *substitutability*: two values compare equal yet behave differently.
3. **Comparison ordering is partial.** `<`, `<=`, `>`, `>=` all answer *false*
   when either operand is NaN. So `!(a < b)` is not `a >= b`, and there is no
   total order — a NaN is neither less than, equal to, nor greater than anything.
4. **totalOrder** (IEEE-754-2008 §5.10) *is* a total order over all 2^64 bit
   patterns, including NaNs and both zeros, and it is not `<`. Rust exposes it
   as `f64::total_cmp`.

The consequence is that a float breaks the two algebraic laws that container
and pattern machinery quietly assume: equality is an equivalence relation, and
ordering is total.

### 3.2 What that does to *this* language — and the measured P6 relief

The brief asks what this does to `==` in pattern matching, in `contains`, in map
keys, and in `find`. I measured each seam:

**Map keys — the problem cannot arise.** The tree refuses non-string keys:

```avra
// features/maps/check.av:52
"a map's keys are strings, this is `${n}`" ... "other key types are recorded — spell the key as text"
// features/maps/mod.av:17
"type.map_key"   | "F2035" | "a map's keys are strings"
```

`Type.Map`'s own doc comment (`core/types.av:46`) says "*A string-keyed,
insertion-ordered map — order is BY DESIGN, so iterating one never needs a
rule.*" **The entire f64-as-HashMap-key problem — the one Rust spent a decade
on, the one `ordered_float` exists to paper over — is structurally absent from
Avra.** This is a genuine P6 dividend that fell out of a decision made for a
different reason, and it should be *protected*: when other key types land, the
rule is that a key type must be an equivalence relation, and `float` is not one.
Write that at the site now, before the key-type slice makes the choice by
accident.

**`==` between floats — keep IEEE.** spec:6294 says "Comparisons with NaN follow
IEEE rules (NaN != NaN)". That is law and I do not propose changing it. Every
language that tried the alternative regrets it in the other direction: Java's
`Double.equals` is reflexive (NaN.equals(NaN) is true, +0.0.equals(-0.0) is
false) while Java's `==` is IEEE — so Java has **two** inconsistent equalities
on one type, and `new HashSet<Double>()` behaves differently from `==` on the
same values. Python has the same split (`float('nan') == float('nan')` is False,
but `float('nan') in [float('nan')]` can be True because `list.__contains__`
checks identity first). **Two equalities is worse than one strange one.** Keep
IEEE, keep it single, and compensate in the compiler.

**Pattern matching — REFUSE, and this is the recommendation with teeth.**

A `match` in Avra is a choice by identity, and its guarantees — arms are
disjoint, an exhaustive match answers, an earlier arm wins — all rest on
equality being an equivalence relation. Over floats they fail concretely: an
arm `0.0 -> …` also catches `-0.0`; an arm `nan -> …` catches nothing at all,
including a NaN; and no set of float literal arms is ever exhaustive. Rust
shipped float patterns, then made them a future-compatibility lint
(`illegal_floating_point_literal_pattern`) precisely because of this.

> **Recommendation: a float is not a match scrutinee and a float literal is not
> a pattern.** The voice:
>
> ```
> error[F20xx]: a `match` chooses by identity, and a float has two zeros and a
>               value unequal to itself
>   · help: compare with `<` / `>`, or ask `is_nan()` / `is_finite()`
> ```

This costs almost nothing (nobody wants to match on `3.7`), removes an entire
class of silently-wrong program, and is the kind of refusal that *teaches* — a
model that hits it learns the actual property.

**`contains` / `index_of` / a future `find` — allow, with IEEE semantics,
documented.** CLAUDE.md records these are already restricted: "*`contains` scans
by value — scalars and text for now*". A `List<float>` scan under IEEE `==` has
two documented behaviours: a NaN is never found, and `+0.0` finds `-0.0`. Both
are the *correct* IEEE answers and both surprise. They belong in the subset
ledger and in the method's docs, not in a refusal — refusing `contains` on a
list of prices would be absurd. But note the asymmetry with the match rule: a
`contains` that answers `false` is a wrong answer the caller can see and reason
about; a `match` arm that silently doesn't fire is a wrong *branch*.

**`sort` — the forward-looking one, and it must be said now.** CLAUDE.md's
subset ledger records `List.sort()` as a method the runtime lacks. When it
lands, it **must** use totalOrder, not `<`. A comparison sort given a
non-transitive comparator does not merely produce a wrong order — a naive
implementation can read out of bounds, because the "the pivot will stop the
scan" invariant fails when every comparison against NaN is false. This is a
known crash class (it is why C++'s `std::sort` with a bad comparator is UB, and
why Java rewrote `TimSort` after the 2015 proof of its broken invariant). Adding
one line to the roadmap now — *`sort` over floats uses `total_cmp`* — costs
nothing; discovering it later costs a crash.

### 3.3 What other languages did, and what they regretted

| Language | Design | Regret |
|---|---|---|
| **Rust** | `f64: PartialEq + PartialOrd`, **not** `Eq + Ord + Hash`. `total_cmp` added in 1.62. | The split is *correct* and Rust does not regret the semantics — it regrets the **ergonomics**. `f64` cannot be a `HashMap` key, cannot derive `Eq` in a struct that contains one, and `.sort()` does not exist on `[f64]` (you write `.sort_by(f64::total_cmp)`). The `ordered_float` crate exists solely to work around it and is a top-500 crate. The lesson: **the trait split is right, the missing total-order affordance was the mistake** — `total_cmp` arriving in 1.62 rather than 1.0 is the actual regret. |
| **Java** | `==` is IEEE; `Double.equals`/`compareTo` are reflexive and order NaN last, `-0.0 < 0.0`. | Two equalities on one type. `Set<Double>` disagrees with `==`. Widely documented as a trap; unfixable now. |
| **Python** | `==` is IEEE. `dict`/`set` check **identity before equality**, so `nan in [nan]` is True for the *same* NaN object and False for a different one. | Non-local, unpredictable behaviour that depends on object identity. Documented as a wart. |
| **C#** | `==` IEEE; `Equals` reflexive (like Java). Same split. | Same. |
| **JS** | `===` is IEEE; `Object.is` is reflexive and distinguishes zeros; `Array.prototype.includes` uses SameValueZero (reflexive for NaN, merges zeros). | **Three** equality predicates. `[NaN].indexOf(NaN)` is -1 but `[NaN].includes(NaN)` is true. Universally cited as a design failure. |
| **IEEE-754 itself** | Defines both `compareQuietEqual` (the `==` everyone ships) and `totalOrder`. | None — it was right to define both. Languages erred by exposing only one and improvising the other. |

**The pattern across all five: the regret is never "we followed IEEE for `==`".
It is always "we grew a second, inconsistent equality to make containers work,
and did not ship a total order."**

### 3.4 The recommendation

1. `==`, `!=`, `<`, `<=`, `>`, `>=` on `float` are IEEE, exactly. One equality.
   Spec law (6294), and the survey says it is the right law.
2. **Ship `Float.total_cmp(a, b) -> int` in the same slice as `==`**, not later.
   That is Rust's actual regret, and it is free to avoid.
3. Also ship, in the first slice: `is_nan()`, `is_finite()`, `is_infinite()`,
   `Float.nan`, `Float.infinity`, `Float.neg_infinity` (spec:6294 names the last
   three), and `Float.bits()` / `Float.from_bits(n)` (which §5 needs anyway).
4. **Refuse** a float as a match scrutinee or a float literal as a pattern.
5. **Keep** map keys string-only. When other key types land, the rule is written
   at the site: a key type is an equivalence relation; `float` is not.
6. `sort` over floats uses `total_cmp`. Record it now.
7. **Lint `x == x` and `x != x` on floats** — "this asks whether `x` is NaN;
   write `x.is_nan()`". But heed CLAUDE.md's own law: **measure the
   true-positive rate before shipping it.** F2040 fired 191 times with 0 real
   defects and trained readers to skip the column errors arrive in. My
   expectation is that this lint fires ~0 times in a clean tree (nobody writes
   `x == x` by accident), which makes it a *good* lint by the F2047 standard —
   but expectation is not measurement, and the rate is the lint's spec.

**What breaks, stated plainly.** With this design, `==` over floats is not an
equivalence relation, and Avra will have one type for which that is true. The
places where it leaks are: `contains`/`index_of` (documented, IEEE), a future
`find`/`any` with an `==` predicate (same), and any user-written generic that
assumes reflexivity. The places it *cannot* leak, by construction, are map keys
and match arms. That containment is the design's actual value.

---

## 4. PRINTING

### 4.1 Why this is an algorithm, not a formatting choice

There are 2^64 bit patterns and infinitely many decimal strings. The
**shortest round-trip** projection is the unique-ish decimal string that (a)
parses back to exactly this double and (b) has the fewest significant digits of
any string that does. Finding it is a real algorithm — it is not `%f` with a
precision, and no fixed precision computes it.

The lineage: **Steele & White's Dragon4** (1990) — correct, uses arbitrary-
precision integers, slow. **Grisu3** (Loitsch 2010) — fast, 64-bit fixed-point
with a cached power-of-ten table, but *fails* on ~0.5% of inputs and must fall
back to Dragon4. **Ryū** (Adams 2018) — always succeeds, no fallback, larger
tables. **Schubfach** (Giulietti 2018/2021) and **Dragonbox** (Jeon 2020) —
same guarantee, tighter analysis, and the current speed leaders. Russ Cox's
["Floating-Point Printing and Parsing Can Be Simple And Fast"](https://research.swtch.com/fp)
is the readable treatment; a [2026 experimental review in *Software: Practice
and Experience*](https://onlinelibrary.wiley.com/doi/10.1002/spe.70056) compares
them systematically and notes that Dragon4, Grisu3, Schubfach and `std::to_chars`
produce shorter average output than Grisu-Exact, Ryū and Dragonbox on some
corpora — the "shortest" guarantee is about *round-trip minimality*, and
implementations differ slightly in tie-breaking.

### 4.2 What `printf("%.17g")` gets wrong — MEASURED

```
$ python3 -c "..."   # values printed three ways
value             repr (shortest)          %.17g                      %.15g
0.1               0.1                      0.10000000000000001        0.1
0.1+0.2           0.30000000000000004      0.30000000000000004        0.3
1e16              1e+16                    10000000000000000          1e+16
1e-7              1e-07                    9.9999999999999995e-08     1e-07
-0.0              -0.0                     -0                         -0
inf               inf                      inf                        inf
nan               nan                      nan                        nan
1.0               1.0                      1                          1
1.2345678901234568e+17  (same)             1.2345678901234568e+17     1.23456789012346e+17
```

`%.17g` is **always correct** — 17 significant digits always round-trips
binary64 — and **always ugly**: `0.1` becomes `0.10000000000000001`, `1e-7`
becomes `9.9999999999999995e-08`. It also strips the point (`1.0` → `1`), which
makes a float's text indistinguishable from an int's.

`%.15g` is **pretty and WRONG**: `0.1+0.2` prints as `0.3`, which is a lie —
that value is not 0.3, and the text does not read back as the value.

### 4.3 What SQLite does — MEASURED on this machine

[SQLite's own page on the subject](https://sqlite.org/floatingpoint.html) states
the change, and I confirmed the pre-change behaviour locally:

> "Beginning with SQLite 3.52.0 (2026-03-06), solution (B) is available and is
> the default" — where (A) is "round to 15 digits, and provide answers that are
> closer to what humans expect to see" and (B) is "round to 17 digits and
> provide answers that sometimes have lots '0's or '9's after the decimal point
> but which will round-trip back to the original binary-64".

The 3.52 algorithm, quoted: "*Round to 15 digits. Convert the text result back
to binary-64. If the binary-64 value from the previous step is different, then:
Redo step (a) with 17-digit rounding.*" Configurable via
`sqlite3_db_config(db, SQLITE_DBCONFIG_FP_DIGITS, 15, 0)` or `.dbconfig
fp_digits 15`.

**Correcting the brief's premise:** the brief said "the 3.41 change to that".
The change is **3.52.0 (2026-03-06)**, not 3.41. This matters operationally,
because the sqlite3 on this machine is **3.51.0** — pre-change — and I measured
what that means:

```
$ sqlite3 --version
3.51.0 2025-06-12 ...
$ sqlite3 :memory: "select 0.1, 0.1+0.2, 1e16, 1e-7, -0.0, 1.0, 123456789012345678.0;"
0.1|0.3|1.0e+16|1.0e-07|0.0|1.0|1.23456789012346e+17
```

Three defects visible in one row, on the version we have: `0.1+0.2` renders as
**`0.3`** (a lie), `-0.0` loses its sign (renders `0.0`), and
`123456789012345678.0` renders as `1.23456789012346e+17`, which **does not
round-trip**.

Two things follow. First, **the campaign must not rely on SQLite's text
rendering of a REAL for anything** — bind and read doubles through
`sqlite3_bind_double` / `sqlite3_column_double`, which are exact, and never
through `sqlite3_column_text` on a REAL column. Second, one detail of SQLite's
formatter is worth *copying*: it renders `1.0` as `1.0` and `1e16` as `1.0e+16`
— **the mantissa always carries a point**. A REAL never renders as something
that reads back as an integer.

### 4.4 What other languages print

Measured here where the toolchain exists; documented otherwise.

| value | Python (measured) | JS (measured) | Rust (documented) | Go (documented) | Swift (documented) |
|---|---|---|---|---|---|
| `0.1` | `0.1` | `0.1` | `0.1` | `0.1` | `0.1` |
| `0.1+0.2` | `0.30000000000000004` | `0.30000000000000004` | `0.30000000000000004` | `0.30000000000000004` | `0.30000000000000004` |
| `1e16` | `1e+16` | `10000000000000000` | `10000000000000000` | `1e+16` | `1e+16` |
| `1e-7` | `1e-07` | `1e-7` | `0.0000001` | `1e-07` | `1e-07` |
| `-0.0` | `-0.0` | `0` ⚠ | `-0` | `-0` | `-0.0` |
| `inf` | `inf` | `Infinity` | `inf` | `+Inf` | `inf` |
| `nan` | `nan` | `NaN` | `NaN` | `NaN` | `nan` |
| `1.0` | `1.0` | `1` | `1` | `1` | `1.0` |

All five agree on the **digits** (they all ship shortest round-trip) and
disagree on **presentation** — when to use an exponent, whether to keep the
trailing `.0`, and how to spell the specials. Rust's Display never uses
exponent notation at all; JS's `String(-0)` famously drops the sign (`Object.is`
exists partly because of it).

Measured JSON behaviour, which §4.7 needs:

```
$ node -e "console.log(JSON.stringify({a:0.1, b:1.0, c:Infinity, d:NaN, e:-0.0}))"
{"a":0.1,"b":1,"c":null,"d":null,"e":0}
```

`JSON.stringify` turns `Infinity` and `NaN` into `null` — silently — and drops
`-0.0`'s sign.

### 4.5 The recommendation for our runtime

**Target: Ryū (binary64 only).** Of the always-succeeds family it is the most
widely ported, the most thoroughly tested, and the one whose reference C
implementation is a single file. "Always succeeds" is worth a lot here: Grisu3
is faster on the common path but requires shipping *a second complete
algorithm* (Dragon4, with bignum arithmetic) for the ~0.5% it cannot handle, and
a runtime that must maintain a bignum path for float printing alone is a poor
trade for a language that has no bignum yet.

Honest size estimate for `avra_f64_text`, from the reference implementation's
shape:

| | |
|---|---|
| Power-of-5 tables | `DOUBLE_POW5_INV_SPLIT` 292 × 16 B + `DOUBLE_POW5_SPLIT` 326 × 16 B ≈ **9.9 KB** of `.rodata` |
| Code | ~350–450 lines of C (the d2d core, the 128-bit multiply helpers, the digit emitter) |
| Dependencies | `__uint128_t` (clang/gcc have it on the targets we build for) or a 64×64→128 helper |
| Fallback | none — that is the point |

Add ~40 lines for **presentation** (§4.6), which Ryū does not decide for you.

**Schubfach/Dragonbox** would be defensible and are faster, but their reference
implementations are C++ and the porting risk is not worth the margin for a
compiler runtime that prints floats at human rates, not gigabyte rates.

### 4.6 The fallback for a first landing, and exactly what it gets wrong

**Use SQLite 3.52's own algorithm**: `%.15g`; parse the result back with
`strtod`; if it does not equal the original, use `%.17g`. Then post-process for
presentation.

```c
// ~15 lines. Always round-trips. Not always shortest.
const char* avra_f64_text(double v) {
    char buf[32];
    int n = snprintf(buf, sizeof buf, "%.15g", v);
    if (strtod(buf, NULL) != v) n = snprintf(buf, sizeof buf, "%.17g", v);
    /* presentation pass, then str_owned(buf, n) — see below */
}
```

Why this fallback and not `%.17g` alone: `%.17g` renders `0.1` as
`0.10000000000000001`, which is *correct* and *unusable* — every price in every
program would print with sixteen noise digits, and the campaign's corpus goldens
would be unreadable. The two-step version costs one extra `snprintf` and one
`strtod` on the ~40% of values where 15 digits is not enough, and it prints
`0.1` as `0.1`.

**What it gets WRONG, precisely — MEASURED.** I compared the fallback's output
to true shortest (Python's `repr`, which has been shortest-round-trip since 3.1)
over two corpora:

```
uniform random 64-bit patterns, n = 200000
  fallback fails to round-trip:      0
  fallback longer than shortest:     79082  (39.54%)
  max extra digits:                  1
  mean significant digits:           fallback 16.791, shortest 16.397

human-shaped values (n/100 prices, n/3 ratios, uniform(-1e6,1e6)), n = 299998
  fallback fails to round-trip:      0
  fallback longer than shortest:     33406  (11.135%)
```

Examples of the difference:

```
   fallback 0.33333333333333331      shortest 0.3333333333333333
   fallback 0.66666666666666663      shortest 0.6666666666666666
   fallback 8.3333333333333339       shortest 8.333333333333334
```

So the honest characterisation is:

> **The fallback is never wrong about the VALUE and is sometimes wrong about
> the LENGTH — by exactly one digit, on values whose shortest form needs 16
> significant digits. It never fails to round-trip. Every price of the form
> `n/100` prints exactly right, because those round-trip at 15 digits.**

That is a documentable, bounded defect and it is acceptable for a first landing.
It is *not* acceptable to document it as "approximate", because it is not
approximate — it is exact and occasionally verbose. Say that.

The one thing to check before shipping the fallback: `strtod` must be correctly
rounded on our targets (glibc and macOS libc both are; see §5). If it is not,
the round-trip verification is unsound and the algorithm silently degrades to
`%.15g`.

### 4.7 Presentation — decide these now, they are not the algorithm's business

Ryū and the fallback both give you digits and an exponent. The remaining
choices:

1. **Always a point or an exponent.** `1.0` prints `1.0`, never `1`. Rationale:
   P12 — the text projection round-trips to the *source syntax*, so a float's
   text is a valid float literal and is never mistaken for an int. SQLite does
   this (`1.0`, `1.0e+16`, measured); Python and Swift do; Rust, Go and JS do
   not. Take SQLite's side — it is the boundary we live on.
2. **Exponent threshold.** Recommend Python's: exponent form when the decimal
   exponent is < -4 or ≥ 16. Rust's never-exponent rule makes `1e300` a
   301-character string.
3. **The specials.** `inf`, `-inf`, `nan` (lowercase, matching Python/Swift and
   the C `%g` the fallback already produces). `NaN` has no sign in the
   projection — a signed NaN is a bit pattern, and `Float.bits` is where that
   lives.
4. **Negative zero prints `-0.0`.** It is a distinguishable value (§3.1) and
   dropping the sign is JS's documented wart. `%.17g` already gives `-0`; the
   presentation pass adds the `.0`.
5. **JSON must refuse the specials.** RFC 8259 has no `Infinity` and no `NaN`.
   `JSON.stringify` emits `null` for both (measured, §4.4) — a silent data
   change. `@std/json`'s writer should **fail** with a named error
   (`JsonError.NotFinite`) rather than emit `null`. This is the encoding law
   from CLAUDE.md in its usual shape: the writer must handle the non-finite case
   *first*, in the diff, or it will emit something.

---

## 5. PARSING — the inverse problem

### 5.1 Why the naive parse is wrong

The naive algorithm — accumulate the digits into an integer, then multiply or
divide by a power of ten — is wrong for most inputs, and it is wrong for a
subtle reason: **each floating-point step rounds, and two roundings are not one
rounding.** Parsing `8.98846567431158e307` by computing `898846567431158.0 *
1e293` rounds twice (once when `1e293` is itself rounded to a double, once at
the multiply) and lands on a neighbouring double. Even with an *exact* table of
powers of ten, the single multiply rounds, and the correctly-rounded answer
requires knowing the bits below the rounding position.

Getting it right means computing the exact rational value of the decimal string
and rounding once, to nearest-even. `strtod` is *specified* to do this (C99
§7.20.1.3 requires correct rounding when `FLT_ROUNDS == 1`), and glibc, musl and
Apple's libc all do. Some embedded and older libcs do not, which is why
`fast_float`, Go and Rust all ship their own.

### 5.2 The Eisel-Lemire algorithm

The modern answer, from Michael Eisel's idea and
[Daniel Lemire's 2020 write-up](https://lemire.me/blog/2020/03/10/fast-float-parsing-in-practice/)
(published as "Number Parsing at a Gigabyte per Second", 2021;
[Nigel Tao's explanation](https://nigeltao.github.io/blog/2020/eisel-lemire.html)
is the clearest): parse the significand as a `u64`, look up a 128-bit
approximation of `5^q` from a table, do one 128-bit multiply, and check whether
the result determines the rounding. It succeeds on ~99.99% of real inputs and is
reported around **9× faster than `strtod`**; the remaining cases (more than 19
significant digits, ambiguous rounding halfway cases, subnormals) fall back to a
slower exact path. Go adopted it in 1.16; Rust's `dec2flt` uses it; `fast_float`
is built around it.

**We do not need it.** Avra parses float literals at compile time (a handful per
program) and at `@std/json` / SQLite-TEXT boundaries (thousands, not billions).
`strtod` is correct on our targets and is already linked. Record Eisel-Lemire in
the roadmap as the optimisation to reach for if a JSON-parsing profile ever
names `strtod`; do not build it now. (P4 is about the shapes that matter; a
literal parsed once at compile time is not one.)

### 5.3 What the lexer must do — and the finding that dissolves the bootstrap problem

The brief asks: what must our lexer do so that `0.1` in source and the value
read from a SQLite REAL column are bit-identical?

The naive answer is "call the same correctly-rounded parser at both ends". The
better answer starts from a problem: **our compiler is written in Avra, and Avra
has no `float`.** The lexer cannot hold `0.1` as a value. Neither can any AST
node, any type-registry entry, or any IR constant. `Val` in the interpreter is:

```avra
// language/interp.av:16
enum Val { I(v: int), B(v: bool), S(v: string), A(id: int), C(id: int), M(id: int), N }
```

— no float variant, and `bin_val` (`interp.av:292`) funnels every arithmetic
operand through `self.int_val(a)`.

Naively this is a bootstrap deadlock: to put `Val.F(v: float)` in `interp.av`
you need a compiler that accepts `float`, and that compiler is built from a
source tree that would contain `Val.F`. The way out is normally a careful ladder
(land float without the interpreter, rebuild, then add `Val.F`, rebuild,
refresh the seed — and CLAUDE.md's working discipline warns that a codegen fix
reaches the product only on the *second* build).

**The finding: the ladder is unnecessary, because the compiler never needs a
float value at all.**

1. **The lexer keeps the TEXT.** It already does — `numbered(src.substring(i,
   j), i, j)` at `lexer.av:321`. Nothing is lost.
2. **The backend hands the TEXT to LLVM.** The LLVM C API has
   `LLVMConstRealOfString(LLVMTypeRef, const char*)`, which parses with LLVM's
   `APFloat::convertFromString` — arbitrary-precision and correctly rounded to
   nearest-even. So the shim is `avra_llvm_const_real_of_string(ty, text)` and
   the compiler passes the literal's digits straight through. **Zero floats in
   the compiler.**
3. **The interpreter carries the BIT PATTERN in the existing `Val.I`.** A float
   register holds its 64 bits as an `int`; every float operation is a runtime
   row (`avra_f64_add(bits, bits) -> bits`, etc.) whose C body bit-casts,
   operates, and bit-casts back. **No new `Val` variant, no float in
   `interp.av`.** The interpreter pays a call per float op, which is
   irrelevant — it is an interpreter — and the native backend pays nothing,
   because it emits real `fadd`/`fmul` (§8.5).
4. **The runtime's own text→double is `strtod`**, in `avra_f64_from_text`.

Then bit-identity is a two-parser question: LLVM's `APFloat` (compile time) and
libc's `strtod` (runtime, and SQLite's own parser). All three are correctly
rounded to nearest-even, so all three agree — but **that must be a test, not a
belief**. The corpus program:

```avra
// prints 4609434218613702656 for 1.5, 4591870180066957722 for 0.1
fn main() { println("${Float.bits(0.1)}") }
```

`0.1`'s bits are `0x3FB999999999999A` = 4591870180066957722 (measured:
`struct.unpack('<Q', struct.pack('<d', 0.1))` → `0x3fb999999999999a`). One
corpus program covering `0.1`, `0.3`, `1e308`, `5e-324` (the smallest
subnormal), `1e-323`, and a 17-digit value proves the compile-time parser; the
same program run under `avra run` (the interpreter, which gets its constants
from... see below) proves the two engines agree.

**One wrinkle to resolve in the design, not in this report:** the interpreter
does *not* go through LLVM, so it needs the literal's bits from somewhere. Two
options — (a) the lowering stores the bits in the IR constant, computed once via
an `avra_f64_from_text` runtime row (which means the *compiler* calls the
runtime, which it already does for `once` and for text), or (b) the interpreter
calls `avra_f64_from_text` on the text at each `ConstFloat`. Option (a) is
better: it computes the bits once, in one place, from one parser, and both
engines then read the same integer — which makes the two engines agree *by
construction* rather than by two parsers happening to match. **Recommend (a),
and then the compile-time parser is `strtod`, not LLVM's APFloat, and
`LLVMConstRealOfString` is not needed** — the backend emits
`LLVMConstBitCast(LLVMConstInt(i64, bits), double)` or
`LLVMConstReal` from the already-computed bits. One parser, one answer, no
agreement to prove. That is the stronger design and it is the recommendation.

### 5.4 What the lexer must reject, so the parser never sees nonsense

`strtod` accepts more than 31.5 does: leading whitespace, `inf`, `infinity`,
`nan`, `nan(chars)`, hex floats `0x1.8p3`, and a locale-dependent decimal point.
**The lexer must have already validated the digit shape**, and the runtime's
`avra_f64_from_text` must not be handed raw user text without validation — a
SQLite TEXT column containing `"inf"` must not silently become an infinity when
read into a float. Two entry points, two contracts:

- `avra_f64_from_literal(text)` — the compiler's, called on text the lexer has
  already validated. May assume well-formedness.
- `avra_f64_parse(text) -> Result<float, ParseError>` — the program's, called
  on runtime text. Validates the grammar itself, refuses `inf`/`nan`/hex/
  whitespace/empty, and answers a `Result`. **The empty case first**, per
  CLAUDE.md's encoding law: `avra_f64_parse("")` is an error, not `0.0`, and
  that is the first test written.

Also set `LC_NUMERIC` or use `strtod_l` with the C locale — a `,` decimal
separator under a European locale would parse `19.99` as `19`. This is a real,
shipped bug class in C programs and it is one line to prevent.

---

## 6. DECIMAL — the design space

### 6.1 The four candidates

| | **IEEE-754 decimal128** | **Scaled 128-bit int** (C# `decimal`, SQL Server) | **Arbitrary precision** (Python `Decimal`, Java `BigDecimal`) | **Integer minor units** |
|---|---|---|---|---|
| Representation | 16 B, BID or DPD encoded | 16 B: 96-bit magnitude + sign + scale 0–28 | heap: digit vector + scale + sign, unbounded | one `int` |
| Precision | 34 decimal digits | 28–29 digits | unbounded (context-limited) | 19 digits total |
| Range | 1e-6143 … 1e+6144 | ±7.9e28, scale 0–28 | unbounded | ±9.2e18 minor units |
| Fits a register? | No (128-bit; Avra has no i128) | No (128-bit) | No (heap by definition) | **Yes — one i64** |
| In our runtime | heap box, `rides_pointer` | heap box | heap box | **a flat newtype over `int` — zero allocation** |
| Allocation per op | 1 | 1 | 1+, grows | **0** |
| Software cost | Intel BID library ≈ 200+ KB, or DPD tables; encode/decode is nontrivial | ~600 lines C: 128-bit add/mul/div, scale alignment, rounding | ~1500+ lines: digit vectors, Knuth division, a context | ~0 — it is integer arithmetic |
| Hardware | POWER6+ only; x86/ARM software | software | software | **native** |
| `1/3` | inexact, rounds to 34 digits, sets the Inexact flag | throws / rounds to 28 digits | rounds per context, `DivisionImpossible` if exact division is demanded | integer division, truncates |

### 6.2 The case that kills naive designs: `1/3`

Every exact-decimal design must answer: what is `decimal(1) / decimal(3)`?

There is no exact answer. A decimal type that promises exactness and offers `/`
must therefore either (a) round to some precision, which means division has a
**context** the type does not carry, (b) refuse, which means `/` is fallible and
returns a `Result`, or (c) become a rational, which is a different type.

What the field does:

- **Java `BigDecimal.divide(BigDecimal)`** with no context throws
  `ArithmeticException("Non-terminating decimal expansion; no exact
  representable decimal result")`. You must pass a `MathContext` or a scale +
  `RoundingMode`. This is the *honest* design and it is universally described
  as annoying.
- **Python `Decimal`** divides under a thread-local `getcontext()` with default
  precision 28 — so `Decimal(1)/Decimal(3)` silently answers 28 digits, and the
  precision is *ambient state*, which is a P7 violation of the first order.
- **C# `decimal`** divides to 28–29 significant digits and rounds; no context,
  no exception, silent.
- **SQL** `NUMERIC` division has implementation-defined scale (SQL Server has a
  documented formula; PostgreSQL uses a heuristic).

**The recommendation, and it is a P6 collapse:** `decimal` has **no bare `/`**.
Division is a named method that takes its rounding: `a.div(b, scale: 2, rounding:
.HalfEven)` — or, for the money case that is 95% of real use,
`a.div_exact(b) -> Result<decimal, DecimalError>` which succeeds exactly when the
division terminates. Then:

- the exact case reads exactly, with no ceremony and no ambient state;
- the inexact case is *impossible to write by accident* — there is no operator
  to reach for;
- the diagnostic writes itself: `` `/` on a `decimal` needs a rounding — write
  `a.div(b, scale: 2)` or `a.div_exact(b)?` ``.

This is strictly better than all four prior-art designs, it costs one refusal,
and it is exactly the temperament of a language that refuses implicit narrowing
elsewhere. Note that `+`, `-`, `*` are all exact on decimals (the scale of a
product is the sum of the scales) and need no such treatment — only `/` does.

### 6.3 The "just use integer minor units" argument

This is the strongest competitor and it deserves a real hearing, because for the
ORM's actual case it is *better* on every axis this language cares about: exact,
register-resident, zero allocation, natively storable in SQLite's INTEGER
storage class, exactly sortable and summable in SQL, and it needs no new type
system machinery at all.

Where it fails:

1. **Multi-currency.** The minor-unit exponent is not 2 everywhere — JPY and KRW
   are 0, BHD/KWD/JOD are 3, and CLF is 4. A bare `int` of "cents" is wrong the
   moment a second currency appears, and the bug is silent.
2. **Intermediate precision.** A 8.25% tax on $19.99 is $1.649175 — you need
   more than two decimals *during* the computation and must round once, at the
   end, per a rule the business specifies. Minor units force you to round early
   or to hand-roll a scaled integer, which is a decimal with the scale in a
   comment.
3. **Division and rates.** Interest, proration, unit prices, currency
   conversion — all produce non-terminating results that need a rounding
   decision (§6.2).
4. **Data you did not choose the shape of.** A `NUMERIC(18,6)` column in a
   database someone else designed does not fit "cents".

So: minor units are right for *money* and wrong for *decimal*. They are not
competitors; they are different types.

### 6.4 The recommendation

**Two types, and this is the paradox collapse.**

> **`decimal` is a heap value — the spec's `BigDecimal`, spelled shorter —
> implemented first as a scaled 128-bit integer, in `@std/numbers`.**
>
> **`Money` is a FLAT newtype over `int` minor units with the currency in the
> type — a register, zero allocation — in `@std/money`.**

Answering the brief's question directly: **`decimal` must be a heap value in our
runtime; it cannot be a pair of registers.** The reason is measurable, not
aesthetic. Avra's value model has exactly three layouts (`features/values.av:5`:
"*Three layouts today, four vocabularies*") — the tagged slot array, the niche
nullable, and the scalar pair — and the scalar pair exists *only* for
nullables (`{present: i1, value}`, built by `opt_ll_type` at `llvm.av:222`).
There is no general two-register value, no i128, and no tuple. A 128-bit decimal
is a 2-slot box; `rides_pointer` answers true; `is_managed` (`language/memory.av:29`)
counts it. That is spec:6331's own prediction — "*every `BigInt` / `BigDecimal`
operation allocates ... The cost is visible in the type*" — and it is fine,
because it is opt-in.

`Money`, by contrast, **is** a register, because CLAUDE.md records that a record
of one scalar field is flattened: "*a newtype over `int` is an `int`, so it
rides every seat the field rides*" (`llvm.av:211-217`). So
`type Money = { minor: int }` costs nothing, and the currency rides the *type*
(`Usd`, `Jpy` as distinct flat newtypes, or a `Money<C>` once generics over a
currency tag are comfortable). Adding two `Usd` values is one `add`
instruction. Adding a `Usd` to a `Jpy` is a type error. That is P4 and P9 at
once.

Why **scaled 128-bit int** rather than IEEE decimal128 for the first
implementation: identical storage size, but the arithmetic is ordinary 128-bit
integer work (~600 lines) instead of BID/DPD encode-decode plus Intel's library
(hundreds of KB, and a build dependency). decimal128 buys wire-format interop
with... almost nothing we touch. SQLite has no decimal storage class at all
(§7); the `sqlite3decimal` extension can store decimal128 blobs but is a
third-party extension we are not adopting.

Why bounded-128 rather than arbitrary precision first: **the API is identical
and the migration is invisible.** `decimal` is a heap box either way, so
widening the payload later changes no call site, no type, no seat, and no
diagnostic. Ship 28 digits, which covers every financial application, and record
"arbitrary precision" as a payload change. This is the opposite of the `float`
decision, where the representation is the type.

**The API surface the first landing must expose:**

```
decimal("19.99")            -> Result<decimal, DecimalError>   // runtime text
19.99m                      -> decimal                          // literal (§2.5)
a + b, a - b, a * b         -> decimal                           // exact
a.div(b, scale, rounding)   -> decimal
a.div_exact(b)              -> Result<decimal, DecimalError>     // §6.2
a.round(scale, rounding)    -> decimal
a.scale()                   -> int
a.to_text()                 -> string                            // exact, always
a.compare(b)                -> int                               // TOTAL — §6.5
a.to_float()                -> float                             // explicit, lossy
decimal.from_int(n)         -> decimal                           // exact
a.to_int()                  -> Result<int, DecimalError>         // fallible
```

Rounding modes, at minimum: `HalfEven` (banker's, the default and the IEEE
default), `HalfUp` (what most tax law specifies), `Down`/`Truncate`, `Up`,
`Ceiling`, `Floor`. Default `HalfEven`.

### 6.5 Decimal's equality is an equivalence relation — and that is the point

Unlike `float`, `decimal` has no NaN and no signed zero. `==` is reflexive, `<`
is total. So `decimal` **can** be a match scrutinee, a map key (when key types
land), and a `sort` key with no special comparator.

One subtlety worth deciding at the site: is `1.50m == 1.5m`? They have different
*scales* but the same *value*. Java's `BigDecimal.equals` says **no** (scale is
part of identity) while `compareTo` says equal — the same two-equalities trap as
`Double` (§3.3), and Java's own Javadoc flags it. **Do not repeat it.** `==`
compares **values**, ignoring scale; `scale()` is how you ask about scale. One
equality.

---

## 7. THE DATABASE MAPPING

### 7.1 `float` ↔ REAL is exact, and is the easy half

SQLite's REAL storage class is IEEE-754 binary64 (an 8-byte big-endian double on
disk). `sqlite3_bind_double` and `sqlite3_column_double` move the bits without
conversion. So `float` ↔ REAL is **bit-exact in both directions**, with three
conditions:

1. Never round-trip a REAL through its **text** rendering (§4.3 — measured, the
   3.51 on this machine renders `0.1+0.2` as `0.3`).
2. `RtKind` must be able to *declare* a double seat. It cannot today (§10.1).
3. NaN. **SQLite cannot store a NaN**: `sqlite3_bind_double` with a NaN stores
   **NULL** (documented, and a longstanding SQLite behaviour). So a `float`
   column round-trips every value *except* NaN, which becomes NULL, and reads
   back as absence. The driver must say so — either refuse to bind a NaN with a
   named error, or document it as the one lossy value. **Recommend refusing**,
   because a silent value→NULL conversion is exactly the class of bug the "write
   the empty case first" law is about. Infinities *do* store and round-trip.

### 7.2 `decimal` — SQLite has no decimal storage class, and the obvious spelling is a trap

SQLite's five storage classes are NULL, INTEGER, REAL, TEXT, BLOB. There is no
decimal. So a decimal must be stored as TEXT, as INTEGER minor units, or as
REAL (lossy, wrong for money).

**MEASURED — the trap, and it is worse than "there is no decimal type":**

```
$ sqlite3 aff.db "create table t(a TEXT, b NUMERIC, c DECIMAL(10,2), d REAL, e BLOB, f INTEGER);
                  insert into t values('19.99','19.99','19.99','19.99','19.99','19.99');
                  insert into t values('123456789012345678901.25', ... );
                  select typeof(a),typeof(b),typeof(c),typeof(d),typeof(e),typeof(f) from t;"
text|real|real|real|text|real

$ sqlite3 aff.db "select a,b,c,d,e,f from t;"
19.99|19.99|19.99|19.99|19.99|19.99
123456789012345678901.25|1.23456789012346e+20|1.23456789012346e+20|1.23456789012346e+20|123456789012345678901.25|1.23456789012346e+20
```

Read that second row. **A column declared `DECIMAL(10,2)` — the exact
declaration every SQL-literate model will write for a money column — has NUMERIC
affinity, which converted the exact text `123456789012345678901.25` into a
double and gave back `1.23456789012346e+20`.** The digits are gone. `typeof` says
`real`. So does `NUMERIC`, and so does `INTEGER` (integer affinity converts to
integer only when lossless, and falls through to real otherwise).

Only **TEXT** and **BLOB** affinity preserved the text. (BLOB affinity means "no
affinity" — SQLite stores whatever you give it.)

**This is the single most important finding for the ORM.** The naive,
SQL-correct-looking schema silently destroys decimals, and it does so at
*insert* time, invisibly, with no error.

**And text sorting does not work either — measured:**

```
$ sqlite3 :memory: "select a from (select '9.50' a union select '10.00' union select '100.00') order by a;"
10.00
100.00
9.50
```

Lexicographic order is not numeric order. Zero-padding fixes it:

```
$ sqlite3 :memory: "select a from (select '0009.50' a union select '0010.00' union select '0100.00') order by a;"
0009.50
0010.00
0100.00
```

but zero-padding requires knowing the maximum magnitude up front, does not
handle negatives (a `-` sorts before every digit, so negatives sort in *reverse*
magnitude order), and makes the stored text no longer the canonical decimal.

### 7.3 What serious ORMs do on SQLite

- **Ecto (`ecto_sqlite3`)** — decimals map to TEXT columns; the adapter
  documents that SQLite ignores precision and scale because "columns have no
  types", and that decimal precision/scale is handled *in the driver*, not the
  database. Elixir's `Decimal` library does the arithmetic; SQLite is storage
  only.
- **Rails / ActiveRecord (sqlite3 adapter)** — migrations with `decimal` create
  columns whose declared type carries `decimal`, and Rails casts through Ruby's
  `BigDecimal` on read/write. Because of affinity (§7.2) the *stored* value may
  well be a REAL; Rails's correctness here comes from the application-side cast,
  not from the storage.
- **Prisma** — explicitly does not solve it. Prisma's own issue tracker carries
  ["Decimal values are stored correctly but read values do not match
  (SQLite)"](https://github.com/prisma/prisma/issues/20635) and
  ["Loss of precision when creating records using
  Prisma.Decimal"](https://github.com/prisma/prisma/issues/10412); contributors
  have stated there is no reliable way to store a Decimal in SQLite. The
  community advice is "store as TEXT and convert in the application, or accept
  Float".
- **EF Core** — [issue #18756](https://github.com/aspnet/EntityFrameworkCore/issues/18756)
  is exactly this: `decimal` should map to a column SQLite will not coerce. EF
  Core maps `decimal` to **TEXT** on SQLite and warns that `decimal` comparisons
  and ordering in SQL will not work correctly.
- **Diesel** — has no SQLite `Numeric` support; the `Numeric` type is
  PostgreSQL/MySQL only. You store text or integers by hand.
- **`sqlite3decimal`** (lifepillar) — a loadable extension implementing exact
  decimal arithmetic in SQL, storing values as strings or as 16-byte IEEE
  decimal128 blobs. It exists precisely because SQLite has no answer. Not a
  dependency we should take.

**The consensus, and every one of them arrived at it independently: store the
decimal as TEXT in a column SQLite will not coerce, and do the arithmetic in the
host language. Nobody has a better answer, because there isn't one.**

### 7.4 The recommended driver mapping

| Avra type | SQLite column | Bind | Read | Exact? |
|---|---|---|---|---|
| `int` | `INTEGER` | `sqlite3_bind_int64` | `sqlite3_column_int64` | yes |
| `float` | `REAL` | `sqlite3_bind_double` | `sqlite3_column_double` | yes (except NaN → refuse, §7.1) |
| `float?` | `REAL` nullable | + `bind_null` | `column_type == SQLITE_NULL` | yes — and **free**: `float?` takes the scalar **Pair** layout (`values.av`'s `Repr.Pair`, `llvm.av:222`), an `{i1, double}` in registers, no allocation |
| `decimal` | **`TEXT`** — declared exactly `TEXT`, never `DECIMAL`/`NUMERIC` | `sqlite3_bind_text` of `to_text()` | `sqlite3_column_text` → `decimal(...)` | **yes** |
| `Money` | `INTEGER` (minor units) | `bind_int64` | `column_int64` | **yes**, and sortable/summable in SQL |

Two consequences to state loudly in the ORM's docs:

1. **A `decimal` column cannot be ordered or aggregated in SQL.** `ORDER BY
   price`, `SUM(price)`, `price > 100` — all operate on text and are wrong
   (§7.2, measured). This is not a driver defect; it is what TEXT storage costs.
   The ORM should **refuse to generate** an `ORDER BY`, a comparison, or an
   aggregate over a `decimal` column, with a diagnostic naming `Money` as the
   type that supports them. That refusal is worth more than the feature.
2. **`Money` is therefore the recommended type for a money column**, not
   `decimal` — because INTEGER minor units sort, compare, sum and index natively
   in SQL, and are exact. `decimal` is for the cases minor units cannot express
   (§6.3): foreign schemas, high-scale rates, arbitrary NUMERIC columns.

That inverts the brief's framing slightly and I want to be explicit about it:
**the ORM's money columns are the case that argues for `Money`, not for
`decimal`.** `decimal` is what `Money` is built on and what arbitrary NUMERIC
data needs; `Money` is what the schema should use.

### 7.5 The diagnostic when someone stores a decimal in a REAL column

This is the brief's specific ask, and given §7.2 it needs to fire on *three*
declarations, not one:

```
error[F4xxx]: a `decimal` cannot be stored in this column without losing digits
  ╭─[schema.av:8:12]
 8 │   price: decimal @column("DECIMAL(10,2)")
   ·                           ^^^^^^^^^^^^^^ SQLite gives this NUMERIC affinity,
   ·                                          which converts exact text to a binary64
   ·
   · note: SQLite has no decimal storage class. `DECIMAL`, `NUMERIC` and `REAL`
   ·       all coerce to REAL — 123456789012345678901.25 stores as 1.23456789012346e+20.
   ·
   · help: store it as TEXT (exact, but not sortable or summable in SQL):
   ·           price: decimal                       // the driver declares TEXT
   ·       or as INTEGER minor units (exact, and SQL can ORDER BY and SUM it):
   ·           price: Money<Usd>
```

Note the shape: it names the affinity rule, quotes the *measured* consequence
with a real value, and offers both correct spellings with their trade-off. Per
CLAUDE.md, the diagnostic is a registered kind with help and a golden rendering
test.

The mirror diagnostic, for a `float` bound where the schema says exact:

```
error[F4xxx]: a `float` in a money column has already lost the digits
   · help: `Money<Usd>` stores minor units exactly, or `decimal` stores exact text
```

---

## 8. CONVERSION AND COERCION

The temperament is set by the spec and by the tree: no implicit narrowing, no
silent precision loss, and a refusal that names the spelling. Every rule below
follows from that.

### 8.1 The table

| From → To | Rule | Why |
|---|---|---|
| `int` → `float` | **explicit**: `n.to_float()`. Never implicit. | spec:6295 verbatim: "`let x: float = 5` is a compile error". Note it is *lossy* above 2^53 — `(2^53+1).to_float()` is 2^53 — so even the "widening" direction is not exact. Answers `float`, not a `Result`: the result is always a well-defined double (the nearest one), and forcing `?` on every `to_float()` would be ceremony for a total function. |
| `float` → `int` | **explicit and fallible**: `x.to_int() -> Result<int, ConversionError>`. **Truncates toward zero** on success. | Three failure modes that are not "rounding": NaN (no integer), ±inf (no integer), and out of range (`1e300`). C's `(int)` is *undefined behaviour* for all three and returns garbage; Rust's `as` saturates silently. Neither is acceptable. Truncation (not rounding) matches every language's `to_int`, and `round()`/`floor()`/`ceil()` answer `float` for the other intents, with `.round().to_int()?` as the composed spelling. |
| `float` → `decimal` | **explicit**, and the answer is the **exact** binary value: `decimal.from_float(x)` gives `0.1` → `0.1000000000000000055511151231257827021181583404541015625`. Also offer `decimal.from_float_rounded(x, scale)`. | This is Java's `new BigDecimal(double)` and Python's `Decimal(float)` — both *correct* and both universally surprising. Making it explicit and naming it `from_float` (never a constructor overload, never adoption) is the fix. §2.5's refusal of `decimal(19.99)` is the other half. |
| `decimal` → `float` | **explicit**: `d.to_float()`, correctly rounded, lossy. Answers `float`, not a `Result` (every decimal has a nearest double, possibly ±inf). | Same shape as `int → float`. |
| `int` → `decimal` | **explicit**: `decimal.from_int(n)`, exact and infallible. Adoption covers the literal case (`let d: decimal = 5` is fine — `5` is an exact decimal). | The literal adopts (§2.4); a *value* converts explicitly, consistent with `int → float`. |
| `decimal` → `int` | **explicit and fallible**: `d.to_int() -> Result<int, DecimalError>`, exact-or-error (a fractional part is an error, not a truncation). | spec:6330's model: "`let x: int = huge.to_int()?` returns a Result that's `Err(Overflow)`". |
| literal → seat | **adopts** (§2.4): a pointed literal into `float` or `decimal`; a bare digit run into `int` or `decimal`. | The P6 collapse. |
| literal → wrong seat | **refuses**, never falls back (§2.6's law). | A fallback here is a wrong price. |
| `float` ↔ `decimal` in arithmetic | **refused**. `1.5 + d` is a type error. | spec:6297: "Mixed arithmetic requires explicit conversion." |
| `int` ↔ `float` in arithmetic | **refused**. `1 + 1.5` is a type error. | Same line. And note this is the one that will bite hardest in practice — see §8.3. |

### 8.2 What the compiler should SAY

The tree's register for a numeric operand refusal already exists (spec:4293's
`error[F1024]: cannot use user.email in numeric context` / "`string` is not
numeric"), and the tree's own voice is `wrong_operand`
(`features/expr_spine/check.av:239`):

```avra
"`${op_symbol(op)}` needs `${...}` operands, found `${n}`"
```

The mixed-arithmetic refusal should not reuse that wording, because the operand
*is* numeric — the problem is that the two sides disagree. Recommend a distinct
voice:

```
error[F20xx]: `+` does not mix `int` and `float`
  ╭─[rate.av:4:15]
 4 │   let total = count + 1.5
  ·                       ^^^ this is a `float`; `count` is an `int`
  ·
  · help: write `count.to_float() + 1.5`
```

and for the truncating direction:

```
error[F20xx]: `to_int` on a float can fail — NaN, infinity and 1e300 have no `int`
  · help: write `x.to_int()?`, or `x.round().to_int()?` to round rather than truncate
```

Both name the exact spelling. That is the P1 bar: the model reads the help and
writes the fix.

### 8.3 The honest worry about mixed arithmetic

spec:6297 is unambiguous and I am not proposing to change it. But I want to
record the cost, because it is the entry in this design most likely to generate
friction: **`x * 2` where `x` is a float will not compile.** The reflex form is
`x * 2`, in every language a model has read, and the correct Avra is `x * 2.0`.

Two mitigations that stay inside 31.2 and cost nothing:

1. **A literal adopts (§2.4), so `x * 2` where `x` is a float is fine** if the
   literal's seat is derived from the other operand. That is a *tiny* extension
   of adoption — an operator's other side is a seat — and it removes ~90% of the
   friction while keeping "no implicit int↔float *value* conversion" intact,
   because `2` here is a literal, not an `int` value. Recommend it, and mark it
   **AMENDMENT** to 31.2's "Mixed arithmetic requires explicit conversion" —
   narrowly: *a numeric literal adopts the other operand's type; two typed
   values still do not mix.*
2. If that amendment is refused, the diagnostic must be excellent, because it
   will fire constantly.

I flag this as the one place where a strict reading of the spec and the P1 bar
pull against each other, and where I think the spec should give a little.

### 8.4 Float division does not trap

Restating §1.5 as an implementation instruction, because it is easy to get wrong
by copying: `Div` and `Mod` on `int` route through `avra_int_div` /
`avra_int_mod`, which call `avra_trap("division by zero")`
(`runtime/avra_runtime.c:485`, reached from `language/llvm.av:359-360`). **Float
`Div` must emit a native `fdiv` and must not route there.** `1.0/0.0` is `inf`,
`-1.0/0.0` is `-inf`, `0.0/0.0` is NaN. spec:6364 is explicit. The interpreter
must agree — its `bin_val` currently traps on `r == 0` before dispatching
(`interp.av:299-302`), and that guard is reached for *every* operand type, so it
must become type-aware or the engines will disagree on the very first corpus
program that divides a float by zero.

That last sentence is a concrete, findable defect waiting to happen, and it is
exactly the kind the gate's eval-vs-native comparison catches. Write the corpus
program.

### 8.5 How the backend knows which instruction to emit

`bin_value` (`language/llvm.av:354`) dispatches on `BinOp` alone and emits
`LLVMBuildAdd` / `LLVMBuildICmp`. Floats need `fadd`/`fsub`/`fmul`/`fdiv` and
`fcmp oeq` (LLVM predicate `LLVMRealOEQ = 1`), not `icmp eq` (predicate 32).

The backend already carries a register type table — `self.tys[dst.index]` is
read in `call_rt_value` (`llvm.av:385-390`). So the dispatch is available. But
note **which** type it must ask: for `Add` the destination is a float, but for
`Eq` the destination is a **bool** and the operands are floats. Per CLAUDE.md's
"A READ WEARS THE TYPE OF WHAT IS READ", the witness must be `self.tys[a.index]`
— the **operand's** type — for every arm, not the destination's. Asking the
destination gets `Add` right and every comparison wrong, silently emitting
`icmp` over doubles. That is a one-line mistake with a silent-wrong-answer
outcome and it belongs in the slice's red-team list.

Do **not** solve this by matching on a runtime row's *name* — CLAUDE.md forbids
string-matching to detect behaviour. If a registry-driven design is preferred
over asking the operand type, the right shape per the VOCABULARY SEAM RULE is a
new *column* on `RtSig` (data → a registry row), not a name match.

---

## 9. THE MINIMUM HONEST LANDING

### 9.1 `float`

The question is whether arithmetic and comparison can land before shortest-
round-trip printing, with printing documented as approximate.

**Yes to landing before Ryū; no to "documented as approximate".** The
distinction matters and the measurement in §4.6 is what settles it. The
15-then-17 fallback is:

- **never wrong about the value** (0 round-trip failures in 500k measured
  values, and correct by construction given a correctly-rounded `strtod`);
- **sometimes one digit longer than necessary** (11.1% of human-shaped values,
  39.5% of uniform random bit patterns, max 1 extra digit).

So the honest documentation is not "printing is approximate" — it is "printing
is exact and occasionally one digit longer than the minimum". A language may
ship that. A language may **not** ship `%.15g` (which prints `0.3` for
`0.1+0.2`, a lie) or a naive parser (§5.1), because those are wrong about the
value, and a wrong value is not a first landing, it is a defect.

**The minimum honest `float`:**

1. `Type.Float`, `shape_named` answers `"float"`, and the refusal help
   (`language/typing_declare.av`) lists it.
2. Literal lexing per §2.5, with `1.` and `.5` refused and `1.abs()` still
   parsing (measured constraint, §2.1).
3. Literal → bits via one correctly-rounded parser, computed once at lowering
   (§5.3), so both engines read the same integer.
4. `+ - * /` and the six comparisons, IEEE, float `/` not trapping (§8.4).
5. `to_float()` / `to_int()?` per §8.
6. **`avra_f64_text` with the 15/17 fallback**, plus the presentation rules
   (§4.7) — always a point, `-0.0` keeps its sign, `inf`/`nan` spelled.
7. `is_nan`, `is_finite`, `is_infinite`, `total_cmp`, `Float.nan`,
   `Float.infinity`, `Float.neg_infinity`, `Float.bits`, `Float.from_bits`.
8. Float refused as a match scrutinee (§3.2).
9. `RtKind.F64` and the extern wall (§10.1) — without which the campaign's
   actual reason for wanting float does not work.
10. A corpus pair proving eval == native, including the bit-pattern test (§5.3)
    and the division-by-zero cases (§8.4).

What may honestly wait: Ryū, `f32`/`f64`, hex-float literals, `${x:.2}` format
specs, transcendental functions (`sqrt`, `sin`, …), and `sort`.

### 9.2 `decimal`

**The minimum honest `decimal` is larger relative to its usefulness**, because a
decimal that is not exact is not a decimal — there is no "approximate but
useful" midpoint the way there is for printing. Specifically:

- It **cannot** ship without exact `to_text()`. A decimal's text *is* its value,
  and it is also its storage format (§7.4). An inexact text projection is a data
  loss bug, not a cosmetic one.
- It **cannot** ship with a bare `/`. §6.2 — there is no non-arbitrary answer,
  and shipping one silently (Python's ambient context, C#'s 28-digit round)
  bakes in a wrong default that is then unfixable.
- It **can** ship without arbitrary precision (§6.4 — the payload widens
  invisibly later).
- It **can** ship without `Money` (which is a separate, much smaller landing).
- It **can** ship without SQL ordering/aggregation over decimal columns, so long
  as the ORM *refuses* to generate them (§7.4) rather than generating wrong ones.

**The minimum honest `decimal`:** the scaled-128 representation, `+ - *` exact,
`div`/`div_exact`, `round`, `compare`, exact `to_text`, `decimal("…")` from
runtime text with the empty case first, the `19.99m` literal and seat adoption,
the `decimal(19.99)` refusal (§2.5), and `HalfEven` + `HalfUp` rounding modes.

**And a dependency worth stating: `decimal` does not need `float` to exist.** It
needs 128-bit integer arithmetic and text, both of which the runtime can do
today. The two types are independent landings and can proceed in parallel —
except that `decimal.to_float()` / `from_float()` need both, and those are the
last pieces of each, not the first.

---

## 10. THE RECOMMENDATION — a dependency-ordered plan

### 10.1 The blocker that gates the SQLite driver, measured

Before anything else, the fact that makes this campaign's ask real:

```avra
// core/ir.av:219
export enum RtKind { I64, Ptr, Void }

// core/runtime_api.av:95
export fn rt_kind_of(types: TypeRegistry, ty: TypeId) -> RtKind {
    if types.shape_of(ty) is .Void { return RtKind.Void }
    if types.rides_pointer(ty) { return RtKind.Ptr }
    RtKind.I64
}
```

There is no float kind. `extern fn sqlite3_column_double(stmt: ptr) -> float`
would be declared to LLVM as returning **i64** — a double returned in `xmm0`
read out of `rax`. Not an error; **garbage**. This is the identical class to the
narrow-return bug the tree already fixed ("*a C `int` read as an Avra `int` is a
WRONG ANSWER*", commit `076c9d8`).

Note the shape of `rt_kind_of`: it is a *projection* with an implicit
catch-all — the final `RtKind.I64` answers for everything that is not Void and
not pointer-shaped. Per CLAUDE.md's counting rule, once `Float` exists **two or
more arms answer**, and the trailing fallthrough silently swallows the new
variant. `rt_kind_of` should become an exhaustive match over the shape as part
of this change, so the next scalar (a sized int, a `char`) cannot repeat it.

**Growing `RtKind` is small and the compiler enforces it.** The only exhaustive
match over `RtKind` in the tree is `ll_rt_kind` (`language/llvm.av:175`, three
arms) — measured:

```
$ grep -rn "RtKind" packages/std-avrac/src | grep -v runtime_api.av
core/ir.av:219  core/ir.av:299  language/test_run.av:{7,19,20,33,34}
language/llvm.av:{9,175}
```

The interpreter dispatches on `RtHost`, never on `RtKind`, so there is no
interpreter arm to pay. This concurs with the ROADMAP's own entry (lane A
recorded it at `ROADMAP.md:384-398`) and with `numeric_tower.md`.

### 10.2 The cost of `Type.Float`, measured

`Type` is matched exhaustively across the tree. Counting mentions of
`.EmptyMap` — the most recently added variant, so every exhaustive match names
it:

```
$ grep -rn "\.EmptyMap" packages/std-avrac/src | wc -l          # 36
$ grep -rn "\.EmptyMap" packages/std-avrac/src | grep -v "Type\.EmptyMap" | grep -v "is \.EmptyMap" | wc -l   # 30
$ grep -rln "\.EmptyMap" packages/std-avrac/src | wc -l         # 16 files
```

**30 pattern sites across 16 files** (`core/types.av`, `features/{variants,
unify,checks,values,contexts}.av`, `features/maps/{check,methods}.av`,
`features/expr_spine/check.av`, `features/enums/mod.av`,
`features/impls/callee.av`, `features/str_lit/lower.av`,
`language/{memory,receivers,lower_walk,llvm}.av`).

I record a **divergence from `numeric_tower.md`**, which states 21. My count is
30 by the command above. Either count is a *floor* on the same underlying set,
and the number does not change the plan — the compiler enumerates them for you
and refuses to build until every one is answered, which is the guarantee, not
the cost. But per CLAUDE.md's "dedup by identity before a number enters a
ledger", the command is quoted so the next reader can re-measure rather than
choose between two asserted numbers.

`Type.Float` joins the "words" (`core/types.av:12-21`): unmanaged, no header, no
refcount, `ptr_shape` false, `rides_pointer` false. **The memory pass does not
change** — `is_managed` (`language/memory.av:29`) has no `Str`-like arm to add,
and a float falls into the unmanaged remainder. And `float?` costs nothing: it
takes `Repr.Pair` (`features/values.av`), an `{i1, double}` in registers.

### 10.3 The plan

**Phase 0 — core seam (blocks everything).**
1. `RtKind.F64`; the `ll_rt_kind` arm; `rt_kind_of` becomes exhaustive (§10.1).
2. LLVM shims: `double_type`, `build_fadd/fsub/fmul/fdiv`, `build_fcmp`,
   `build_sitofp`, `build_fptosi`, `const_real` (from bits).
3. Runtime: `avra_f64_from_text` (strtod, C locale), `avra_f64_text`
   (15/17 fallback + presentation), `avra_f64_bits`/`from_bits`,
   `avra_f64_is_nan`.

*After phase 0 the extern wall can DECLARE a double seat. It cannot yet type
one.*

**Phase 1 — `float` the type.**
4. `Type.Float`, `shape_named`, and the 30 arms (§10.2).
5. Lexer: the float literal, plus the integer forms 31.5 already specifies and
   the tree lacks (underscores, exponent, hex/octal/binary) — measured missing
   in §2.1.
6. Lowering: the literal's bits computed once (§5.3); both engines read the
   integer.
7. Arithmetic and comparison, dispatching on the **operand's** type (§8.5);
   float `/` does not trap, in **both** engines (§8.4).
8. `to_float`/`to_int`; the mixed-arithmetic refusal (§8.2).
9. Printing, `is_nan`/`total_cmp`/the constants; float refused as a match
   scrutinee.
10. Corpus pair: eval == native, bit patterns, ±0.0, ±inf, NaN, division by
    zero, printing goldens.

**Phase 2 — the SQLite driver's float half.** Now, and only now, can the driver
honestly bind `sqlite3_bind_double` / `sqlite3_column_double`. Plus the NaN
decision (§7.1) and a `float?` for nullable REAL columns.

**Phase 3 — `decimal`.** Independent of phases 1–2 except for the two
conversions. Runtime 128-bit scaled arithmetic; `decimal` in `@std/numbers`; the
`m` literal and seat adoption; the `decimal(19.99)` refusal; exact `to_text`;
`div`/`div_exact`.

**Phase 4 — `Money` and the ORM mapping.** `Money` as a flat newtype over `int`
minor units; the driver's TEXT mapping for `decimal`; the `DECIMAL(10,2)`
refusal (§7.5); the refusal to generate `ORDER BY`/`SUM` over a decimal column.

**Phase 5 — Ryū**, replacing the fallback. One runtime function, one golden
update, no language change.

### 10.4 What must be true before the driver binds `sqlite3_column_double`

Precisely, as the brief asks:

1. `RtKind` can name a double, and `rt_kind_of` maps `Type.Float` to it
   **exhaustively** — no fallthrough (§10.1). *Without this the call compiles
   and returns garbage.*
2. `Type.Float` exists and `float` names a type (measured: it does not —
   `F2001: 'float' names no type`).
3. The backend emits a `double` return and does not coerce it through an i64
   (`call_rt_value`'s existing `int_to_ptr` coercion at `llvm.av:388` is the
   pattern to be careful around).
4. `float?` works, because a nullable REAL column is the common case
   (free — `Repr.Pair`).
5. A NaN policy (§7.1), because SQLite stores a bound NaN as **NULL**.
6. `avra_f64_text` exists and round-trips, because the driver will render values
   in error messages and goldens, and because §4.3 measured that SQLite's own
   text rendering cannot be trusted on the version we have.
7. A corpus program that writes a REAL and reads it back bit-identically, under
   **both** engines.

Items 1–3 are the hard gate. Items 4–7 are the honesty gate.

---

## Appendix — the probes

All run 2026-09-05. Single-file `./avra check` (sub-second, no lock) and
read-only shell measurements; no `make`, no build, no package-scale run.

| # | Command | Result |
|---|---|---|
| 1 | `./avra check` on `let x: float = 1.5` | `F0100: expected BREAK`, caret **at the `.`** |
| 2 | `./avra check` on `let x: float = 3` | `F2001: 'float' names no type` |
| 3 | `./avra check` on `f(1.abs())` | `F2030: '.abs(…)' calls a method, and 'int' has none` — **the literal-method form parses** |
| 4 | `./avra check` on `for i in 0..3` | compiles — the range lexes |
| 5 | `./avra check` on `1e10` | `F0100`, caret at the `e` — no exponent literal |
| 6 | `./avra check` on `1_000` | `F0100`, caret at the `_` — no underscore separator |
| 7 | `./avra check` on `[1.0]` | `F0100: expected ']' to close the list` |
| 8 | `python3` repr / `%.17g` / `%.15g` over 9 values | §4.2's table; `0.1` bits = `0x3fb999999999999a` |
| 9 | `node -e String(x)` / `JSON.stringify` | §4.4; `-0` → `0`, `Infinity`/`NaN` → `null` |
| 10 | `sqlite3 --version`; `select 0.1, 0.1+0.2, …` | **3.51.0**; `0.1+0.2` → `0.3`, `-0.0` → `0.0`, `1.23456789012346e+17` |
| 11 | 15/17 fallback vs `repr`, n=200000 random bit patterns | 0 round-trip failures; 39.54% one digit long |
| 12 | 15/17 fallback vs `repr`, n=299998 human-shaped | 0 round-trip failures; 11.14% one digit long |
| 13 | `sqlite3` affinity table, 6 column types | `DECIMAL(10,2)`/`NUMERIC`/`INTEGER` → **`real`**; only TEXT/BLOB keep the text |
| 14 | `sqlite3` text sort of `'9.50','10.00','100.00'` | `10.00, 100.00, 9.50` — lexicographic ≠ numeric |
| 15 | `grep` counts for `RtKind`, `.EmptyMap` | 1 exhaustive `RtKind` match; 30 `Type` pattern sites in 16 files |

Sources consulted:
[SQLite: Binary64 to Text](https://sqlite.org/floatingpoint.html) ·
[research!rsc: Floating-Point Printing and Parsing Can Be Simple And Fast](https://research.swtch.com/fp) ·
[Converting Binary FP to Shortest Decimal Strings: An Experimental Review (SPE 2026)](https://onlinelibrary.wiley.com/doi/10.1002/spe.70056) ·
[Lemire: Fast float parsing in practice](https://lemire.me/blog/2020/03/10/fast-float-parsing-in-practice/) ·
[Nigel Tao: The Eisel-Lemire ParseNumberF64 Algorithm](https://nigeltao.github.io/blog/2020/eisel-lemire.html) ·
[lemire/fast_double_parser](https://github.com/lemire/fast_double_parser) ·
[Rust: serialization of float minus zero](https://github.com/rust-lang/rust/issues/20596) ·
[Prisma #20635: Decimal values stored correctly but read values do not match (SQLite)](https://github.com/prisma/prisma/issues/20635) ·
[Prisma #10412: Loss of precision using Prisma.Decimal](https://github.com/prisma/prisma/issues/10412) ·
[EF Core #18756: Decimal type should be NUMERIC in Sqlite](https://github.com/aspnet/EntityFrameworkCore/issues/18756) ·
[ecto_sqlite3 adapter](https://preview.hex.pm/preview/ecto_sqlite3/show/lib/ecto/adapters/sqlite3.ex) ·
[lifepillar/sqlite3decimal](https://github.com/lifepillar/sqlite3decimal)
