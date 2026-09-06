# Avra's numeric tower — `float` and `decimal`, the design brief

Lane sqlite research, 2026-09-05. Companion to
`2026_09_05_STD_SQLITE_RESEARCH_prior_art.md` (blocker **B5**) and
`2026_09_05_STD_SQLITE_RESEARCH_probe_log.md`.

Scope: what the spec already decided, what `float` (IEEE-754 binary64) is in
this tree, what `decimal` is and where it lives, how both survive a SQLite
write/read cycle, and the order to land them.

The spec is LAW. Where this report proposes, it says so; where the spec
already answered, the campaign implements THAT.

---

## 0. The one-paragraph answer

`float` is a CORE value category the spec already specified in full (Axis 31.2)
and the campaign implements verbatim: binary64, no implicit int↔float
conversion, IEEE comparison, `float / float = float`, a literal that must carry
a point or an exponent. `decimal` is **not in the spec** — Axis 31.3 decided
that exact base-10 is `BigDecimal` in `@std/numbers`, a LIBRARY type, and
`Money` in `@std/money` above it. That decision survives contact with this
tree's doctrine: a float is a machine register (21 exhaustive `Type` matches, a
new ABI kind, a new LLVM type) and a decimal is a heap box with no machine shape
(zero new arms in `ll_type_of`, `rt_kind_of`, or `Val`). The one thing a core
`decimal` would buy that a library type cannot have today is OPERATORS — and
the answer to that is operator traits, which serve every library type (P17), not
one. SQLite has no decimal storage class; a decimal round-trips as TEXT in a
**TEXT-affinity** column, and the affinity rules make that a hard requirement,
not a preference.

---

## 1. WHAT THE SPEC ALREADY DECIDES

All quotations from `docs/2026_04_18_FULL_SPEC.md`, **Axis 31: Numerical
Types**, lines 6232–6406, unless noted.

### 1.1 Integer types (31.1, spec:6234–6272)

> **Decision:** **(c) `int` (pointer-sized) at app level, explicit sizes at
> systems level**

- `int` — "signed, pointer-sized (i64 on 64-bit platforms, i32 on 32-bit). The
  default integer type for all app-level code." (spec:6241)
- `uint` — "unsigned, pointer-sized." (spec:6242) — "That's it. No `i8`, no
  `u32`, no size soup." (spec:6243)
- Systems level: `i8 i16 i32 i64 i128 isize`, `u8 u16 u32 u64 u128 usize`
  (spec:6245–6246).
- "**No silent narrowing:** conversions between int sizes are always explicit.
  `let small: i32 = big_int.to_i32()?` — returns a Result because the conversion
  can overflow." (spec:6270)
- "**Default literal type:** integer literals without context default to `int`."
  (spec:6271)

**Tree today:** `Type.Int` only (`core/types.av:14`); no `uint`, no sized ints.
`shape_named` (`language/typing.av:316`) answers `int`, `string`, `bool`,
`void`, `ptr` — five words. The campaign needs none of the sized ints; `int`
carries every SQLite INTEGER (SQLite's INTEGER is int64).

### 1.2 Float sizes (31.2, spec:6274–6293) — the whole campaign, already written

> **Decision:** **(c) `float` (64-bit IEEE 754) at app level, `f32` and `f64` at
> systems level**

- "**`float`** — 64-bit IEEE 754 double-precision" (spec:6283)
- "No `double` alias (`float` IS double at app level)" (spec:6284)
- `f32`, `f64` systems-level; "**`f16`** (reserved)" (spec:6286–6288)
- "**Special values:** IEEE 754 semantics — `NaN`, `Infinity`, `-Infinity` are
  valid values. Available as `Float.nan`, `Float.infinity`,
  `Float.neg_infinity`. Comparisons with NaN follow IEEE rules (NaN != NaN)."
  (spec:6289)
- "**No implicit int-float conversion:** `let x: float = 5` is a compile error.
  Write `let x: float = 5.0` or `let x: float = (5).to_float()`. This prevents
  silent loss of precision and matches strong static typing." (spec:6290)
- "**Float literals:** must have a decimal point or exponent: `5.0`, `1e10`,
  `2.5e-3`. `5` alone is an integer literal." (spec:6291)
- "**Division semantics:** `int / int = int` (truncating), `float / float =
  float`. Mixed arithmetic requires explicit conversion." (spec:6292)
- "**Versioning:** `float` ships in v1.0." (spec:6293)

**So: the spec names `float`, not `f64`, at app level. It answers implicit
conversion (there is none), division (same-typed, no mixing), and NaN (IEEE, so
`NaN != NaN`). The campaign implements this and argues about nothing.**

### 1.3 Arbitrary precision (31.3, spec:6295–6327) — there is NO `decimal`

> **Decision:** **(b) `BigInt` / `BigDecimal` in `@std/numbers` — explicit
> types, no silent promotion**

- "**`BigDecimal`** — arbitrary-precision decimal with explicit scale; useful
  for money, scientific data, anything where `0.1 + 0.2 == 0.3` matters"
  (spec:6305)
- "**`Rational`** — exact fractions" (spec:6306)
- Rationale: "Overflow promotion (c) makes performance unpredictable —
  innocuous-looking int arithmetic silently heap-allocates ... Explicit library
  types (b) are the Rust/Java model: `BigInt` and `BigDecimal` are standard,
  discoverable, and clearly-costed. Programmers opt in when they need the
  precision." (spec:6302)
- "**Money type:** `@std/money` provides `Money` built on `BigDecimal` with
  currency tagging — the idiomatic choice for financial apps. BigDecimal alone
  doesn't know about currencies." (spec:6307)
- "**Performance note:** every `BigInt` / `BigDecimal` operation allocates ...
  The cost is visible in the type." (spec:6326)
- The spec's own construction is from TEXT: `BigDecimal.from_str("19.99")?`
  (spec:6316).

**The word `decimal` does not appear as a type anywhere in the spec.** The
campaign's "decimal" IS spec 31.3's `BigDecimal`. Landing a core `decimal`
primitive is a SPEC AMENDMENT, which is the owner's call, not the driver's.
§3 argues the amendment is not needed.

### 1.4 Overflow, division by zero (31.4, spec:6329–6360)

- Default: "**Debug builds:** panic on overflow ... **Release builds:** wrap
  using two's-complement" (spec:6338–6339); `[build] overflow_checks =
  "always" | "debug_only" | "never"` (spec:6340).
- `checked_* saturating_* wrapping_* overflowing_*` (spec:6343–6353).
- "**Division-by-zero:** always panics (in both debug and release). Use
  `checked_div` to get a Result. Integer division by zero is never defined
  behavior — there's no sensible 'wrap' for that." (spec:6358)
- "**Float overflow:** floats don't overflow in the integer sense — they become
  `Infinity` or `-Infinity`, which is valid. No panic, no check, follows IEEE
  754." (spec:6359)

**Reading, and it is load-bearing:** 31.4's division-by-zero panic is scoped to
INTEGER division and justified by "there's no sensible 'wrap' for that." For
floats there IS a defined answer (±Infinity, and `0.0/0.0` = NaN), and 6359
says floats "follow IEEE 754" with "no panic, no check". **Therefore float
division by zero does NOT trap.** This must be spelled at the site, because
this tree's integer `Div` routes through `avra_int_div`, which traps
(`runtime/avra_runtime.c:486`, reached from `language/llvm.av:359`). A float
`Div` that reuses that path would trap where IEEE says ±∞. See §2.6.

**Tree today:** 31.4 is UNIMPLEMENTED for integers. `bin_val`
(`language/interp.av:303`) is a plain `l + r`; `bin_value` (`language/llvm.av:354`)
is a plain `LLVMBuildAdd` with no `nsw`. Integer overflow wraps silently in both
engines. That is a standing spec gap; the campaign should not silently inherit
it, but neither is it the campaign's to close. **Confidence HIGH** (read both
dispatches).

### 1.5 Literal syntax (31.5, spec:6362–6406)

```
42            42_000        1_000_000
0x2A          0o52          0b101010      0xFF_FF_FF_FF
3.14          2.5e-3        1e10          6.022_140_76e23
42i32         200u8         3.14f32       1_000_000i64    0xFF_FF_FFu32
```
- "Float suffixes: `f32`, `f64`, `float`" (spec:6400)
- "Out-of-range literals are compile errors: `256u8` → 'literal 256 does not fit
  in u8 (max 255)'" (spec:6401)
- "**No octal implicit:** unlike C, `077` is NOT octal 63 — it's the decimal
  literal 77." (spec:6406)
- `'a'` char (32-bit scalar), `b'a'` byte, `b"..."` byte string of `List<u8>`
  (spec:6403–6404, 5570).

**Tree today:** the scanner takes a bare digit run and nothing else
(`grammar/lexer.av:319-321`: `is_digit(c) -> scan_while(..., is_digit)`).
So the tree has **none** of 31.5 beyond plain decimal integers:

| Spec form | What the tree's lexer does today |
|---|---|
| `1_000` | `Num("1")` then `Name("_000")` — `_` is `is_name_start` (`core/chars.av:14`) |
| `0x2A` | `Num("0")` then `Name("x2A")` |
| `1e10` | `Num("1")` then `Name("e10")` |
| `1.5` | `Num("1")`, `Op(".")`, `Num("5")` — the probe log's `F0100 ... pointing AT the '.'` |
| `42i32` | `Num("42")` then `Name("i32")` |

**Underscores in integer literals are a spec gap nobody has recorded.**
Confidence MEDIUM (read the scanner; not probed — this session is read-only).
The campaign touches `numbered` anyway; land underscores for ints and floats in
one change.

### 1.6 Elsewhere in the spec, and two internal divergences

- "Primitives: `int`, `float`, `bool`, `string`, `byte`, `char`" (spec:4821).
- Primitives are Copy; `type Point = { x: float, y: float }` is "auto Copy"
  (spec:1376, 1384–1388).
- `type Percentage = float where 0.0 <= it && it <= 100.0` — refinement types
  over `float` (spec:2793, 5731).
- `Random.float()` (spec:2695).
- `${price:.2}` — "a format specification: `${price:.2}` for 2 decimal places"
  (spec:5557). **Not implemented:** `Expr.Interp(parts, holes)`
  (`core/nodes.av`) has no spec field. Backlog, not campaign.
- `error[F1024]: cannot use user.email in numeric context` / "`string` is not
  numeric" (spec:4288–4292) — the wording register for a numeric-operand
  refusal.

**Divergence 1 — `.float` vs `.to_float()`.** Spec:1303 writes `Point { x:
i.float, y: i.float * 2 }` — a PROPERTY. Spec:6290 writes `(5).to_float()` — a
METHOD. 31.2 is the normative sub-decision; 1303 is an illustrative memory
example. **Recommend the method** (`to_float()`), which is one `MethodRow`
(`features/mod.av`) and needs no new syntax, and record 1303 as an editorial
inconsistency.

**Divergence 2 — "numeric widening" in table literals.** Spec:5852: "all values
in a column must unify to a single type (with the usual numeric widening and
optional widening rules)". There ARE no "usual numeric widening rules": 31.2
says "No implicit int-float conversion" and "Mixed arithmetic requires explicit
conversion". **31.2 wins** (it is the numerics axis). A `table<Row>` column
holding `1` and `2.5` is a type error, not a widened `List<float>`. Flag for
the owner; the campaign implements 31.2.

---

## 2. FLOAT — the design

### 2.1 The name and the type

`float`. One word, one type, binary64. `shape_named`
(`language/typing.av:316-325`) gains `"float" -> Type.Float`; `f32`/`f64` stay
UNSPELLED (spec:6293 reserves them for systems level, and `f16` beyond that).
The tree's own refusal help — "the types today are `int`, `string`, `bool`, and
your declared types" (`language/typing_declare.av:403`) — gains `float`.

`Type.Float` joins `core/types.av:12`'s enum beside `Int`, `Bool`, `Str`, `Ptr`
— "The words: one unmanaged register each." A float IS a word: unmanaged, no
header, no refcount, `ptr_shape` false (`core/types.av:118`), `rides_pointer`
false. Nothing in the memory pass changes.

**MEASURED COST:** 21 exhaustive matches over `Type` across 16 files
(`grep -c '\.EmptyMap ->'` over non-test sources). Every one is a compile error
until answered — which is the guarantee, not the cost. The files:
`core/types.av`, `features/{variants,unify,checks,contexts,values}.av`,
`features/maps/{check,methods}.av`, `features/expr_spine/check.av`,
`features/enums/mod.av`, `features/impls/callee.av`,
`features/str_lit/lower.av`, `language/{memory,receivers,lower_walk,llvm}.av`.

### 2.2 Literal syntax — what to ACCEPT and what to REFUSE

The spec's rule (6291): "must have a decimal point or exponent". Everything
below narrows that to a lexable grammar.

**ACCEPT**

| Form | Reason |
|---|---|
| `1.5` | 6291's canonical form |
| `1e9`, `1E9` | 6291's exponent form; `6.022_140_76e23` at spec:6386 |
| `1.5e-9`, `2.5e-3`, `1e+9` | signed exponent, 6291 |
| `1_000.5`, `1.000_1`, `1e1_0` | 31.5: "underscores for readability; anywhere in the number" |
| `0.0`; `-0.0` via unary minus on `0.0` | negative zero is a value; see §2.3 |

**REFUSE**, each with a named voice and a remedy:

| Form | Refusal | Why |
|---|---|---|
| `1.` | "a float literal needs a digit after the point — write `1.0`" | **`1.to_float()` MUST keep working.** The tree parses a property/method on any primary, and `1.` greedily lexed as a float breaks every method call on an integer literal. This is the decisive, tree-grounded reason — not style. |
| `.5` | "a float literal starts with a digit — write `0.5`" | `.` in expression head position is the bare-variant sigil (`.Ok`, `.Err`). Two spellings of one value is one more thing for a generator to get wrong (P1). |
| `0x1.8p3` (hex float) | "hex floats are not a literal — `Float.from_bits(n)` writes the bits" | Sole use is bit-exact literals; the method says it plainly and needs no lexer. Backlog if a demand appears. |
| `1_.5`, `1._5`, `_1.5`, `1.5_` | "an underscore separates digits" | An underscore adjacent to the point or the edge is a typo, never an intent. |
| `1.5f32`, `3.14f64`, `1.5float` | "`f32` and `f64` arrive with the systems level" | 31.5 reserves the suffixes; 31.2 versions them to systems. `float` as a suffix is redundant. |
| `1e`, `1e+` | "an exponent needs digits" | |
| `infinity`, `nan` as literals | (they simply lex as NAMEs) | Spec:6289 gives `Float.nan`, `Float.infinity`, `Float.neg_infinity` — constants, not syntax. |

**THE `..` COLLISION — the lexer trap.** `..` is a two-char op
(`grammar/lexer.av:284`) and ranges are everywhere (`for i in 0..n`). A greedy
float scanner turns `0..10` into `Num("0.")`, `Num(".10")` or worse.

> **THE RULE: after a digit run, consume a `.` only when the NEXT character is a
> digit.** `0..10` → `Num("0")`, `Op("..")`, `Num("10")`. `1..n` likewise.

This is the same rule that refuses `1.` — the two are one rule, which is why
neither is a special case.

**THE TOKEN CLASS.** Add `TokenKind.Float` to `grammar/lexer.av:25` and
`"FLOAT" -> TokenKind.Float` to `grammar/validate.av:14`'s `term_kind`.
Do **not** reuse `TokenKind.Num`: `Token.int_value()` (`lexer.av:45`) walks
characters as `c - 48`, so a `.` (code 46) folds in as `-2` and the method
answers a silently wrong integer. A distinct class makes that impossible.
`first.av:156` classifies grammar-text literals by leading character and is
unaffected (no grammar literal is float-shaped).

**THE PAYLOAD — and the bootstrap law.**

```
Expr.FloatLit(bits: int)          // core/nodes.av, beside IntLit(value: int)
```

**The payload is the binary64 BIT PATTERN as an `int`, not a `float`.** Three
reasons, and the first is decisive:

1. **THE COMPILER CANNOT HOLD A FLOAT UNTIL A FLOAT-CAPABLE COMPILER EXISTS.**
   `build/avra` compiles the tree; a `float` field in `Expr` cannot be compiled
   by a binary with no float. Bits are an `int`, and every standing binary and
   `bootstrap/seed.ll` can carry them. The self-hosting chain is never broken.
2. `fingerprint_expr` folds ints (`core/nodes.av:779` — `.IntLit(value) ->
   fp(1, [value])`). Bits fold directly; a float payload would need a bit
   projection anyway.
3. `TypeRegistry.canon` interns by string (`core/types.av:130`). Bits stringify
   exactly; a float would need shortest-printing inside the interner, which
   inverts the dependency — the interner would depend on the text projection.

Even after a float-capable compiler exists there is no reason to change it. The
bits ARE the value; the surface text is a projection.

**COMPUTING THE BITS — one C fn, correctly rounded.** The lexer must turn
`"1.5"` into `0x3FF8000000000000`. Two ways:

- **(a) A runtime row the lexer calls as an extern.**
  `avra_str_to_double_bits(s: string) -> int` over C `strtod_l`. `strtod` on
  glibc, macOS libc and musl is correctly rounded (David Gay's algorithm and
  descendants). The precedent is exact: `language/workspace.av:26` declares
  `extern fn avra_host_env`, and `language/interp.av:888-909` declares eleven
  externs into the same runtime.
- **(b) Decimal→binary64 in Avra with integer arithmetic** (Clinger / Gay).
  Hundreds of lines and a permanent correctness liability.

**RECOMMEND (a).** One C function, and it is the SAME function `@std/text`'s
`parse_float` and the sqlite driver's TEXT→REAL path will call. One
implementation, three callers.

**THE LOCALE LAW — a real bug class, and the tree is currently safe by
accident.** `strtod` and `snprintf("%g")` are LC_NUMERIC-sensitive: under a
locale whose decimal separator is `,`, `strtod("1.5")` answers `1.0`.
`grep -n setlocale runtime/avra_runtime.c backend/llvm_wrapper.c` returns
nothing, and a C program starts in the `"C"` locale (C99 7.11.1.1), so today
every conversion is `.`-based. But `build/avra` links `libLLVM`, and a
dependency that calls `setlocale` would silently change the meaning of every
float literal the compiler reads.

> **THE LAW: no numeric conversion in this runtime reads the ambient locale.**
> Every `strtod`/`snprintf` in the float path goes through an explicit C-locale
> handle — `newlocale(LC_ALL_MASK, "C", NULL)` once at first use, then
> `strtod_l` / `snprintf_l`. Both platforms have them (macOS `<xlocale.h>`;
> glibc `<stdlib.h>` under `_GNU_SOURCE`).

### 2.3 Arithmetic and comparison — where languages lie, and where Avra will not

**Arithmetic.** `+ - * /` over two `float` operands answer `float`.
`op_over` (`features/expr_spine/check.av:100`) and `wears` (`check.av:117`)
gain a `.Float` arm; `binary_type` (`check.av:81`) routes `.Sub or .Mul or
.Div` to a float law when either side is `.Float`, and `added_type`
(`check.av:93`) gains a float branch beside its `.Str` branch.

**`%` on floats: REFUSE.** The spec says nothing about it (6292 names only
`/`), `fmod`'s sign-of-the-dividend rule surprises everybody, and IEEE's
`remainder` (round-to-nearest) is a different function with a different answer.
Refuse with a named voice pointing at `@std/math`'s `remainder`/`modulo` when
they land. Silence is not an answer; a wrong `%` is worse than none.

**`float / 0.0` does NOT trap.** Spec:6359 — floats "follow IEEE 754", "no
panic, no check". `1.0/0.0` is `inf`, `-1.0/0.0` is `-inf`, `0.0/0.0` is `nan`.
This is the trap to avoid at `llvm.av:359`, where integer `.Div` is routed
through `avra_int_div` **precisely because** `sdiv` by zero is UB and the
interpreter refuses. Float division has a defined answer in both engines and
needs no guard.

**Comparison — the honest table.** `==` on floats is `fcmp` **ordered**; `!=`
is `fcmp` **unordered**. This is the single place every implementation either
tells the truth or lies:

| Avra | LLVM predicate | int value | NaN behaviour |
|---|---|---|---|
| `a == b` | `fcmp oeq` | 1 | `nan == nan` is **false**; `nan == x` is false |
| `a != b` | `fcmp une` | 14 | `nan != nan` is **true**; `nan != x` is true |
| `a < b`  | `fcmp olt` | 4 | false against NaN |
| `a <= b` | `fcmp ole` | 5 | false against NaN |
| `a > b`  | `fcmp ogt` | 2 | false against NaN |
| `a >= b` | `fcmp oge` | 3 | false against NaN |

**THE TRAP, named:** spelling `!=` as `one` (ordered-not-equal, 6) makes
`nan != nan` FALSE and breaks the identity `(a != b) == !(a == b)`. Every
comparison is ORDERED **except `!=`**, which is UNORDERED. Write it once, in
`bin_value`, with the reason at the site. (LLVM's `LLVMRealPredicate` starts at
0; the tree already passes `LLVMIntPredicate` as raw ints — 32=EQ, 40=SLT,
`llvm.av:361-366` — so raw fcmp predicates 1–14 follow house style.)

**Negative zero.** `-0.0 == 0.0` is TRUE (IEEE, and `fcmp oeq` says so). But
`-0.0` and `0.0` are DISTINGUISHABLE: `1.0 / -0.0` is `-inf`, and the sign bit
survives every copy. So the text projection prints `-0.0`, not `0.0` (§2.4).
JavaScript's `String(-0) === "0"` is the lie; Avra does not tell it.

**Infinities.** `Float.infinity`, `Float.neg_infinity` (spec:6289). Totally
ordered against every finite value, `inf - inf` is `nan`, and none of it traps.

**A TOTAL ORDER, DISTINCT FROM `==` — YES, and it is a separate verb.**
`<` is a PARTIAL order: NaN is unordered against everything including itself, so
a sort using `<` has no defined behaviour when NaN is present — a comparison
sort whose comparator is not a strict weak ordering can produce anything,
including out-of-bounds reads in a naive implementation. IEEE 754-2008 defines
`totalOrder`, which is total:
`-nan < -inf < … < -0 < +0 < … < +inf < +nan`.

> **RECOMMEND:** `float.total_cmp(other) -> int` (−1/0/+1), one `MethodRow`,
> implemented as the standard bit trick: take each operand's bits as a signed
> i64 and XOR in `(bits >> 63) >>> 1` so negatives invert; then compare as
> signed ints. Rust ships exactly this as `f64::total_cmp`, and `f64`
> deliberately has no `Ord`.
>
> When `List.sort()` lands (CLAUDE.md lists it as missing), a `List<float>`
> sorts by `total_cmp`, NOT by `<`. `-0.0` sorts below `+0.0` under
> `total_cmp` and equal under `==` — that is the point of having both.

`0.1 + 0.2 == 0.3` is **false**, and Avra will not pretend otherwise. That is
what `decimal` is for (§3).

### 2.4 TEXT PROJECTION — the hard half

This is where a float type is won or lost. The requirement has two halves that
look opposed and are not:

1. **ROUND-TRIP:** the text, parsed back, is the same binary64. Bit-for-bit.
2. **READS NATURALLY:** `0.1` prints as `0.1`, not
   `0.1000000000000000055511151231257827`.

**They are the same requirement (P6) once one rule is added:**

> **THE PROJECTION LAW: a float's text is always a legal Avra float literal.**

That single law forces round-trip (a literal means what it says), forces
naturalness (shortest round-tripping digits), forces `1.0` to print as `1.0`
and never `1` (spec:6291 — `1` alone is an INT literal, so `1` would read back
as the wrong type), and forces `-0.0` to keep its sign. The three values that
cannot obey it — `nan`, `inf`, `-inf` — are the named exception, because no
literal spells them in any language that gives them constants.

#### The algorithm

**Shortest round-trip** means: the fewest significant decimal digits `d` such
that parsing them recovers the original binary64, and among candidates of length
`d`, the one nearest the exact value (ties to even).

The literature, in order:

| Algorithm | Year | Property | Cost |
|---|---|---|---|
| **Steele & White / Dragon4** | 1990 | Shortest, always correct | Arbitrary-precision bignum; slow |
| **Gay's `dtoa`** | 1990 | Shortest, correct; became the de-facto standard behind `printf`/`strtod` | Bignum fallback |
| **Grisu3** (Loitsch) | 2010 | Shortest, fast — but **rejects ~0.5% of inputs** and must fall back to Dragon4 | Tiny cache; ~91–99 ns |
| **Errol** | 2016 | Shortest, no fallback | Slower than Ryū |
| **Ryū** (Adams) | 2018 | Shortest, **no fallback**, correctness proof (PLDI'18) | ~22–28 ns; ~10 KB of lookup tables; Apache-2.0 / Boost |
| **Schubfach** (Giulietti) | 2020 | Shortest, no fallback, tight error analysis | Comparable to Ryū |
| **The printf loop** | — | Shortest *if* libc's `printf` and `strtod` are correctly rounded | ~1–3 µs; **zero tables, ~40 lines** |

**RECOMMEND, v1: the printf loop.**

```c
// avra_float_text(int64_t bits) -> const char*   (OWNED, headered)
double v; memcpy(&v, &bits, 8);
for (int p = 1; p <= 17; p++) {
    snprintf_l(buf, sizeof buf, c_locale, "%.*e", p - 1, v);
    if (strtod_l(buf, NULL, c_locale) == v) break;
}
// then reshape (digits, exponent) into the surface form below
```

Justification:

- **It is shortest, exactly.** `printf("%.*e")` on glibc/macOS/musl is correctly
  rounded to the requested precision, and `strtod` is correctly rounded back. So
  the first `p` that round-trips is the shortest digit count, and correct
  rounding makes those digits the nearest ones with ties to even — the same
  output Ryū produces.
- **It is ~40 lines and no tables.** Ryū is a 10 KB table plus a proof; it is
  the right body to swap in behind the same runtime row when profiling asks,
  which it will not for a text projection.
- **The cost is a text projection's cost.** Typical `p` is 1–3 (most doubles in
  a program come from short literals, or from SQLite REAL columns written by
  short literals). Worst case is 17 iterations at ~150 ns each. Compare: this
  tree's `avra_int_text` is one `snprintf` (`runtime/avra_runtime.c:496`), and
  the whole gate is 19.5 s (ROADMAP, lane A).
- **Risk, named:** it inherits libc's correctness. glibc, macOS libc (gdtoa)
  and musl are all correctly rounded; a hostile libc is not. **The mitigation is
  a test, not a different algorithm:** a golden set (every value in the table
  below, plus `Float.min_positive`, `Float.max`, and 10⁵ random bit patterns)
  asserting `parse(text(x)) == x` bit-for-bit. If that test ever fails on a
  platform, the body swaps to Ryū behind an unchanged row.

#### The surface form

Let the shortest digits be `d₁…dₙ` and let `e` be the decimal exponent with
`value = 0.d₁…dₙ × 10^e` (so the leading digit sits at `10^(e-1)`).

- **Scientific** when `e > 17` or `e ≤ -4`: `d₁[.d₂…dₙ]e[-]X` — no `+`, no
  leading zeros in the exponent. `1e21`, `1.5e-9`, `5e-324`.
- **Positional** otherwise, **always with a point and at least one fractional
  digit**: `1.0`, `100.0`, `0.0001`, `0.30000000000000004`.

The `+`-less exponent and the mandatory `.0` are what keep the output a legal
Avra literal (spec:6291 — a point *or* an exponent suffices, and `1e21` has
one). Python's `repr` cuts at `e > 16`; the one-order difference is an open call
for the owner, stated here so it is a decision and not a drift.

#### The exact strings

| Expression | Avra prints | Note |
|---|---|---|
| `0.1 + 0.2` | `0.30000000000000004` | 17 digits; the shortest that round-trips |
| `0.1` | `0.1` | 1 digit |
| `1.0` | `1.0` | never `1` — `1` is an int literal |
| `1.0 / 3.0` | `0.3333333333333333` | 16 digits |
| `1e21` | `1e21` | `e = 22 > 17` → scientific |
| `1e16` | `10000000000000000.0` | `e = 17` → positional |
| `1e-5` | `1e-5` | `e = -4` → scientific |
| `0.0001` | `0.0001` | `e = -3` → positional |
| `-0.0` | `-0.0` | the sign bit is real; JS's `"0"` is a lie |
| `0.0` | `0.0` | |
| `Float.nan` | `nan` | not a literal — the named exception |
| `Float.infinity` | `inf` | |
| `Float.neg_infinity` | `-inf` | |
| `Float.max` | `1.7976931348623157e308` | |
| `Float.min_positive` (denormal) | `5e-324` | shortest is ONE digit; `%.17g` would give `4.9406564584124654e-324` |

`nan`/`inf`/`-inf` lowercase: this tree's literal words are lowercase (`true`,
`false`, `null` — `avra_bool_text`, `runtime/avra_runtime.c:502`), and `strtod`
accepts all three case-insensitively, so `@std/text`'s `parse_float` reads them
back. The alternative (`NaN`, `Infinity`, `-Infinity`, matching spec:6289's
CONSTRUCTOR names) is defensible; pick one and never move it, because it is a
golden-test surface.

#### Where it plugs in

Three sites, all one-line arms once the row exists:

- `hole_reg` (`features/str_lit/lower.av:33-43`) — `${x}` in an interpolation:
  `.Float -> rt1(cx, e, "avra_float_text", v)`.
- `print_lowering` (`language/lower_walk.av:133-159`) — a corpus program's
  answer: `.Float -> self.text_call("avra_float_text", last)`. Note `.Float`
  must join the PRINTABLE arm of the `unprintable` match, or a float answer
  refuses with "has no text projection yet".
- `val_text` (`language/interp.av:466-474`) — the interpreter's twin:
  `.F(bits) -> avra_float_text(bits)`, calling the **same C fn** through an
  extern. Two engines, one implementation, no divergence to police.

A `List<float>` printer (`avra_floats_text`) joins `avra_ints_text` /
`avra_bools_text` / `avra_strs_text` (`runtime/avra_runtime.c:1035-1055`) —
`list_text` is already generic over an element printer, so it is one line plus a
row plus an arm in `list_text_callee` (`language/lower_walk.av:172`).

### 2.5 int ↔ float conversion

**Spec:6290 decides it: EXPLICIT, both ways, no exceptions.** `let x: float = 5`
is a compile error. `int + float` is a compile error. There is no promotion, no
widening, no "usual arithmetic conversions".

**The P1 argument, since this is the decision a generator most often gets
wrong:** implicit int→float is the C/Java/JS rule and an LLM will reach for it.
But it is precisely the rule that makes `int / int` in a float context answer
the wrong thing (`1/2` = `0`, then widened to `0.0`, in every language that has
it), and it is unsound above 2⁵³ (int64 → binary64 rounds). The spec's rule
gives a generator ONE failure mode with a mechanical fix the compiler can name:
"`+` needs `float` operands, found `int` — write `n.to_float()`". A wrong answer
has no diagnostic at all. **Explicit is correct-on-first-generation once the
diagnostic names the fix**, which is what `wrong_operand`
(`features/expr_spine/check.av:236`) already does for the existing types.

The two verbs, as `MethodRow`s:

- `n.to_float() -> float` — total. Never fails. **May round** (int64 above 2⁵³
  is not exactly representable), which is exactly why it is written and not
  inferred. Lowers to `sitofp`.
- `x.to_int() -> int?` — **absent** for `nan` and for any value outside
  `[-2⁶³, 2⁶³)`. **NEVER a raw `fptosi`:** LLVM's `fptosi` is *poison* on
  out-of-range and NaN inputs, so `(1e300).to_int()` compiled raw is undefined
  behaviour the optimizer may exploit. It goes through a runtime row
  `avra_float_to_int(bits) -> {present, value}` that range-checks first — the
  same shape as `avra_int_div`'s guard (`runtime/avra_runtime.c:486`) and for
  the same reason: **the interpreter and the native binary must agree, and UB
  agrees with nothing.**
  - Why `int?` and not `Result<int, Overflow>`: `Result` is right by spec:6270's
    precedent (`to_i32()?`), but `Result<void, E>` is refused today (F2019,
    CLAUDE.md "The subset today") and `int?` is the tree's working idiom.
    Record the `Result` form as the v1.x shape.
- Companions, all answering `float`, none failing: `trunc()`, `floor()`,
  `ceil()`, `round()` (half-away-from-zero — state it), `abs()`, `is_nan()`,
  `is_finite()`, `to_bits() -> int`, `Float.from_bits(n) -> float`.

### 2.6 The LLVM side

**Wrapper additions** — `backend/llvm_wrapper.c` + `language/llvm_api.av`
(which today declares 61 externs and has **no float anything**):

```
avra_llvm_double_type(ctx) -> ptr                  // LLVMDoubleTypeInContext
avra_llvm_const_double_bits(ty, bits) -> ptr       // LLVMConstReal on the reinterpreted bits
avra_llvm_build_fadd / fsub / fmul / fdiv          // no frem: `%` is refused
avra_llvm_build_fcmp(b, pred, lhs, rhs, name)      // pred as a raw int, house style
avra_llvm_build_si_to_fp / fp_to_si                // fp_to_si only inside the guarded row
```

`avra_llvm_const_double_bits` takes the BITS as an `int` because `llvm_api.av`
can only pass `int`/`string`/`ptr` — the C side does the `memcpy` into a
`double` and calls `LLVMConstReal`, so the emitted `.ll` reads
`double 3.140000e+00` and stays inspectable (P7).

**Machine type.** `ll_type_of` (`language/llvm.av:198-212`) gains
`.Float -> avra_llvm_double_type(lc)`.

**Already done for us.** `avra_llvm_cast_to_type`
(`backend/llvm_wrapper.c:604-647`) ALREADY handles double↔i64 (bitcast, bit
preserving), double↔pointer (chained through i64), and smaller-int↔double
(`sitofp`/`fptosi`). The wrapper anticipated floats. **But read the rule
carefully — it is a landmine:** i64↔double is a **bitcast**, not a conversion.
That is exactly right for carrying a float through a word-shaped slot (an array
slot, an `I64` runtime seat) and exactly WRONG if any emitter ever reaches for
it wanting a numeric conversion. The numeric conversions must be spelled
(`build_si_to_fp` / the guarded row), never left to `cast_to_type`.

**`bin_value` must learn the operand type.** `bin_value(op, a, b)`
(`language/llvm.av:352-370`) takes raw LLVM values and cannot tell a double from
an i64. It gains the register: `bin_value(op, a, b, floaty)` where
`floaty = self.types.shape_of(self.tys[a.index]) is .Float`, and dispatches to
`fadd/fsub/fmul/fdiv/fcmp`. **`.Div` must NOT reach `avra_int_div`** — that is
the trap named in §1.4.

**`ConstFloat` — a new IR variant, and why.** The IR protocol (CLAUDE.md, and
`core/ir.av:26-46`) demands JUSTIFY / GENERALIZE-BEFORE-ADDING / PAY THE EIGHT
CONSUMERS / THE GUARANTEE.

- **JUSTIFY:** "a new value category" is a listed justification, and float is
  one.
- **GENERALIZE:** `Ins.Bin` is NOT duplicated. There is no `FBin`, no `FAdd`.
  Float arithmetic rides the existing `Bin(dst, op, a, b)`; the register types
  say which machine op. That is the generalization the protocol asks for, and it
  means `dst_of`, `body_symbol`, `hosted_symbol`, `memory_ins` and `facts.av`'s
  `give` need no new arithmetic arms at all.
- **The one variant:** `ConstFloat(dst: Reg, bits: int)`.
  *Counter-argument, stated honestly:* `ConstInt(dst, bits)` would work —
  `const_int_value` (`llvm.av:307-312`) already types its constant by the
  destination register, exactly as it does for pointers, so a `.Float` dst could
  take a bitcast. **Rejected on P7:** `ir_text`'s `body_lines`
  (`language/ir_text.av:61`) would print `r3 = int 4614253070214989087` for
  `3.14`, and every IR golden becomes unreadable. `ConstFloat` prints
  `r3 = float 3.14` through the same projection the program uses. Eight
  one-line arms buy a readable IR forever.
- **PAY THE EIGHT:** `dst_of` (`core/ir.av:157`), `body_symbol`
  (`core/ir.av:181`), `hosted_symbol` (`core/ir.av:200`), `step`
  (`language/interp.av:159`), `memory_ins` (`language/memory.av:190`),
  `body_lines` (`language/ir_text.av:61`), `emit_ins` (`language/llvm.av:270`),
  `give` (`features/facts.av:341`) — plus a corpus program proving eval ==
  native and an IR golden. `avra new ins ConstFloat` prints the checklist.

**`RtKind.F64` — the extern ABI, and this is B5's real content.**
`RtKind { I64, Ptr, Void }` (`core/ir.av:217`). On x86-64 SysV and AArch64
AAPCS a `double` argument travels in a **floating-point register**, not an
integer one. `sqlite3_bind_double(stmt, i, 3.14)` declared with an `I64` third
seat passes the bits in `rdi`/`x2` and SQLite reads `xmm2`/`d0` — garbage, with
no diagnostic anywhere.

```
export enum RtKind { I64, F64, Ptr, Void }
```

Five sites:
- `rt_kind_of` (`core/runtime_api.av:95`) — `.Float -> RtKind.F64`, asked before
  `rides_pointer`.
- `ll_rt_kind` (`language/llvm.av:175`) — `.F64 -> avra_llvm_double_type(lc)`.
- `rt_arg` (`language/llvm.av:432`) — an `I64` seat handed a `.Float` register
  must **bitcast** (`cast_to_type` does it); an `F64` seat handed anything else
  is a defect.
- `call_rt_value` (`language/llvm.av:383-396`) — an `F64` answer into a `.Float`
  dst is identity; an `I64` answer into a `.Float` dst bitcasts.
- `extern_row_of` (`language/lower.av:52-55`) — already routes every `extern fn`
  seat through `rt_kind_of`, so a program's
  `extern fn sqlite3_column_double(s: ptr, i: int) -> float` gets `F64`
  automatically the moment `rt_kind_of` answers it.

**THE RUNTIME'S OWN ROWS TAKE BITS, NOT DOUBLES.** `avra_float_text`,
`avra_float_to_int`, `avra_str_to_double_bits` and the interpreter's arithmetic
helpers all declare `RtKind.I64` seats carrying the bit pattern. Consequence:
**the interpreter never needs an F64 ABI at all** (§2.7), and only USER externs
— which is to say, sqlite — exercise `F64`. Smaller blast radius, and the
bitcast is free (LLVM folds it).

### 2.7 The interpreter — floats without a float

`enum Val` (`language/interp.av:16-28`) gains one variant:

```
/// A binary64, carried as its BIT PATTERN — the interpreter is
/// written in a language that gains float only after it compiles one.
F(bits: int)
```

**MEASURED COST: two exhaustive `Val` matches** — `val_text` (`interp.av:466`)
and `cloned_val` (`interp.av:680`). Everything else that touches `Val` is a
projection with an honest catch-all.

`bin_val` (`interp.av:292-313`) already pre-dispatches on VALUE shape (nulls,
then bools, then ints). Floats slot in as a third pre-dispatch:
`if self.value(a) is .F && self.value(x) is .F { return self.float_bin_val(…) }`.

**And `float_bin_val` calls the SAME C the native binary calls**, through
externs declared beside the eleven already there (`interp.av:888-909` —
`avra_proc_spawn`, `avra_now_ns`, `avra_io_read`, …, under the header "the
evaluator calls the same functions the native program does, so there is one
implementation, not two that agree"):

```
extern fn avra_f64_add(a: int, b: int) -> int        // bits in, bits out
extern fn avra_f64_sub(a: int, b: int) -> int
extern fn avra_f64_mul(a: int, b: int) -> int
extern fn avra_f64_div(a: int, b: int) -> int
extern fn avra_f64_oeq(a: int, b: int) -> int        // and une, olt, ole, ogt, oge
extern fn avra_float_text(bits: int) -> string
```

**This is the P6 collapse of the campaign's hardest constraint.** "The
interpreter needs floats" and "the interpreter is written in a language without
floats" is a false dichotomy: the interpreter carries BITS and delegates every
operation to the C that the backend's `fadd` compiles to. eval == native is not
tested, it is **structural**. The precedent is the process substrate, landed by
lane B and already proving the pattern.

**The residual risk, named:** `fadd` inlined by LLVM at `-O2` and `avra_f64_add`
compiled as a separate function must agree. They do — both are IEEE binary64
with default rounding and no fast-math — *unless* someone adds `-ffast-math` to
the runtime's build line (`Makefile:65`, currently `cc -O2 -Wall -Werror`) or
LLVM contracts a multiply-add into an FMA where the interpreter does two rounded
steps. **THE LAW: no fast-math, and no FMA contraction, in the float path.**
LLVM's default is `contract=off` for non-fast-math IR, so this holds today by
default; it is written here so it is a decision.

### 2.8 The float feature, as a directory

Per CLAUDE.md ("A feature is a directory"), mirroring `features/bool_lit/` and
`features/str_lit/`:

```
features/float_lit/
  mod.av         gram: `primary = v:FLOAT -> float_lit(v)`; the builder row;
                 the diagnostic codes; the to_float/to_int/… MethodRows
  builders.av    build_float_lit — Expr.FloatLit(t.float_bits() ?? 0)
  semantics.av   the NodeSemantics one-liners
  check.av       Type.Float, the operand laws' float arms, the voices
  lower.av       ConstFloat, the Bin arms, the text projection
  tests/         spec + given/then, beside it
```

The grammar fragment lives in the float feature and registers its own builder
there (CLAUDE.md: "a builder named in feature A's grammar registers in feature
A"). `FLOAT` and `NUMBER` are disjoint token classes, so merge order does not
matter — this is not a keyword anchor and none of the anchor-ordering hazards
apply.

Prove it with `corpus/float.av` + `.expected` (CLAUDE.md: "prove it with a
corpus pair"), whose final expression is a float so `print_lowering` exercises
the projection.

---

## 3. DECIMAL — core value category, or library type?

### 3.1 The honest question, answered

**LIBRARY TYPE. `BigDecimal` in `@std/numbers`, exactly as spec 31.3 decided.**

Four arguments, in order of weight.

**(1) THE SPEC ALREADY DECIDED, AND ITS REASONING IS THIS TREE'S REASONING.**
Axis 31.3 chose "(b) `BigInt` / `BigDecimal` in `@std/numbers` — explicit types,
no silent promotion", rejecting "(c) Built-in arbitrary precision with overflow
promotion" because it "makes performance unpredictable — innocuous-looking int
arithmetic silently heap-allocates" (spec:6302). "The cost is visible in the
type" (spec:6326) is P7 (visible magic) stated in the numerics register. There
is no `decimal` keyword in the spec. Adding one is a spec amendment.

**(2) THE COST TEST SEPARATES THEM CLEANLY.** A float costs 21 exhaustive `Type`
matches, an IR variant with eight consumers, an LLVM type, a new ABI kind, and
an interpreter variant — **because it is a machine register and every layer must
know its shape.** A decimal is a heap box:

| Seam | `float` | `decimal` as a library type |
|---|---|---|
| `ll_type_of` (`llvm.av:198`) | new arm — `double` | nothing — it is a `Struct`, already `pointer` |
| `rt_kind_of` (`runtime_api.av:95`) | new `F64` kind | nothing — `Ptr` |
| `Val` (`interp.av:16`) | new `.F(bits)` | nothing — `Val.A` (an aggregate) |
| `memory.av` | nothing (unmanaged word) | nothing (an ordinary refcounted box) |
| `Ins` | `ConstFloat`, 8 consumers | nothing |
| exhaustive `Type` matches | 21 | 0 |

A core `Type.Decimal` would pay the float's price and buy **nothing the layers
need**, because there is no machine shape to teach them.

**(3) WHAT A CORE TYPE WOULD ACTUALLY BUY — and its real answer.** Exactly one
thing: **operators.** `price + tax`, `a < b`, `a == b`. `op_over`
(`features/expr_spine/check.av:100`) hard-codes wants through `wears`
(`check.av:117`), which answers only `Int`, `Bool`, `Str`. The tree's own
diagnostic already names the missing feature — `compare_help`
(`check.av:159-176`) says "a type parameter cannot compare — **operator traits
are recorded**" and "a `dyn` compares behind its contract — **operator traits
are recorded**".

The spec anticipates them: `trait Add<Rhs = Self> { type Output; fn add(self,
rhs: Rhs) -> Self.Output }` (spec:725-729), cited as the motivating case for
associated types, and spec:6317's own example writes
`price * (BigDecimal.one() + tax)`. **Operator traits serve every library type
(P17: composability over featurefulness); a core `decimal` serves one.** The
right ask is operator traits, in the sugar backlog, wanting site named:
`@std/numbers`'s `BigDecimal`.

**(4) THE LITERAL PROBLEM, WHICH A CORE TYPE DOES NOT SOLVE EITHER.** Under
spec:6291, `19.99` IS a float literal. `let price: decimal = 19.99` — core type
or not — would round the value through binary64 before the decimal ever saw it,
which is the exact bug the type exists to prevent. Spec:6316 writes
`BigDecimal.from_str("19.99")?`, and that is why.
**THE ASK (sugar backlog): a `d` suffix.** Spec 31.5 already has the suffix
mechanism (`42i32`, `3.14f32`) and its float suffix list is `f32`/`f64`/`float`.
`19.99d` would carry its DIGITS as text into the AST —
`Expr.DecimalLit(digits: string)` — never a double. That is a small, well-shaped,
spec-consistent ask, and it works identically for a library type.

**Verdict: library type. If the owner still wants the keyword, the honest form
is a spec amendment to 31.3 plus operator traits — because without operator
traits a core `decimal` is a type you cannot add.**

### 3.2 The field, surveyed

| Design | Representation | Range / precision | Division | Verdict for Avra |
|---|---|---|---|---|
| **C# `System.Decimal`** | 128 bits: 96-bit integer + 32 flag bits (sign + scale 0–28) | ±79,228,162,514,264,337,593,543,950,335; 28–29 significant digits | Yes, and **`1m/3m*3m == 0.9999999999999999999999999999`** — the docs say so themselves | **Reject.** A fixed 28-digit ceiling is an arbitrary cliff for a database column, the tree has no u128, and its division silently answers a wrong-looking number |
| **Java `BigDecimal`** | `BigInteger` unscaled value + `int` scale | Arbitrary | `divide(b)` **throws** on a non-terminating quotient unless a scale and `RoundingMode` are given | **The right division contract**, adopted below |
| **Python `Decimal`** | IBM General Decimal Arithmetic / IEEE 754-2008; coefficient + exponent + sign | Arbitrary, bounded by a **Context** (`prec`, default 28) | Rounds to context precision; signals `Inexact`, `DivisionByZero`, traps configurable | **Reject the CONTEXT.** Ambient mutable global state deciding an arithmetic answer is the opposite of P3/P7 — the scale belongs at the site |
| **IEEE 754 decimal128** | 128-bit, 34 significant digits, DPD or BID encoding | Fixed 34 digits | Full IEEE semantics | **Reject.** No hardware on our targets, two incompatible encodings, and its entire value is a bit-exact interchange format we have no peer for |
| **Postgres `NUMERIC`** | sign, `weight`, `dscale`, **base-10000 limbs** (16-bit each), trailing zeros not stored | Arbitrary (up to 131072 int / 16383 frac digits) | `numeric_div` with a computed result scale | **The right REPRESENTATION**, adapted below |
| **SQLite `ext/misc/decimal.c`** | `{ char sign; char oom; char isNull; char isInit; int nDigit; int nFrac; signed char *a; }` — **one digit per byte, most significant first** | Arbitrary | **No division at all** | The honest floor; "The focus here is on simplicity and correctness, not performance" |
| **Integer cents** | an `int`, scale by convention | ±9.2×10¹⁸ at scale 0 | Exact, by construction | **Reject as the default.** A DRIVER cannot know a column's scale; a 5%-VAT calculation needs a scale the schema does not carry. Keep it as an ORM-level option |

### 3.3 The recommendation

```
// @std/numbers
export type BigDecimal = {
    neg: bool,          // sign; a zero is never negative
    limbs: List<int>,   // base 10^4, LEAST significant first, no leading zero limb
    scale: int,         // digits after the decimal point; >= 0
}
```

**Base 10⁴, exactly Postgres's NBASE, and for exactly Postgres's reason.** A
limb product is at most `(10⁴−1)² ≈ 10⁸`, so roughly 9×10¹⁰ partial products
accumulate in an `int` (i64, max 9.22×10¹⁸) before overflow — safe for any
operand length a database column can hold. Base 10⁹ would multiply pairwise
(10¹⁸ < 9.22×10¹⁸) but **overflows on the second accumulation**, which is a
silent wrong answer in a money type. Base 10 (SQLite's byte-per-digit) is
correct and four times slower; it is the right first draft and base 10⁴ is the
second.

**Written in AVRA, not C.** It needs no machine shape, only `int` arithmetic and
`List<int>` — which is to say it is dogfooding, it runs in both engines with no
host seam, and every bug in it is a bug the compiler's own tests can catch.
Spec:6326's "every operation allocates" is honest and expected.

**SCALE IS PART OF THE VALUE.** `19.99` (scale 2) and `19.990` (scale 3) are
`cmp`-EQUAL and `to_text`-DIFFERENT. That is Java's and Postgres's rule, it is
what makes a round-trip through a database exact (§4), and it is what an ORM
needs to render a money column as the schema declared it. `==` follows `cmp`
(numeric equality); a separate `same_text` answers when the scale matters.

**Operations:**

```
from_str(s: string) -> Result<BigDecimal, DecimalError>    // the exact door
from_int(n: int) -> BigDecimal                             // total
to_text() -> string                  // canonical: no exponent, scale honoured
to_float() -> float                  // LOSSY; the name says so
add / sub / mul (b) -> BigDecimal    // exact; result scale from the operands'
neg / abs        -> BigDecimal
cmp(b) -> int                        // -1 / 0 / +1, numeric (ignores scale)
is_zero / scale / precision -> …
rescale(n: int, mode: Rounding) -> BigDecimal
```

**DIVISION — the design decision this section exists for.**

```
div(b: BigDecimal, scale: int, mode: Rounding) -> Result<BigDecimal, DecimalError>
```

**There is no `div(b)`.** `1/3` does not terminate in base 10, so any
single-argument division either guesses a scale (C# guesses 28 and hands back
`0.9999999999999999999999999999`, presenting a wrong-looking number as an
answer) or throws (Java). Avra takes the third road, which is the only one that
is both total and honest: **the scale and the rounding mode are ARGUMENTS**, so
the answer's precision is written where the division is. SQLite's `decimal.c`
ships no division at all; ours ships one that cannot lie about its precision.

`DecimalError`: `DivisionByZero`, `BadDigits(at: int)` (from `from_str`),
`NegativeScale`. **No `Inexact` signal and no trap machinery** — a division that
rounds is not an error, it is a division with a stated scale. Python's
context/flag/trap apparatus is rejected: ambient global state deciding an
arithmetic result is invisible magic (P7), and the whole point of `decimal` is
that the answer is not a surprise.

**ROUNDING MODES**, named as IEEE 754-2008 / IBM GDA name them:

| Avra | IBM GDA / IEEE | Behaviour |
|---|---|---|
| `Rounding.HalfEven` | `ROUND_HALF_EVEN` / roundTiesToEven | **THE DEFAULT.** Banker's rounding; unbiased over many operations, and IEEE's own default |
| `Rounding.HalfUp` | `ROUND_HALF_UP` | Ties away from zero — what a schoolbook and most tax authorities mean |
| `Rounding.HalfDown` | `ROUND_HALF_DOWN` | Ties toward zero |
| `Rounding.Up` | `ROUND_UP` | Away from zero always |
| `Rounding.Down` | `ROUND_DOWN` | Toward zero always (truncate) |
| `Rounding.Ceiling` | `ROUND_CEILING` | Toward +∞ |
| `Rounding.Floor` | `ROUND_FLOOR` | Toward −∞ |

Python's `ROUND_05UP` is omitted (a niche of a niche).

**`@std/money`'s `Money` (spec:6307) sits above this**, adding a currency tag and
a fixed scale from the currency's minor unit. It is the app-facing type; the ORM
binds `Money`, and `Money` binds `BigDecimal`. **Out of the campaign's scope** —
designed for, not built.

---

## 4. THE SQLITE MAPPING

### 4.1 `float` ↔ REAL — exact, with three named hazards

SQLite stores REAL "in **IEEE 754 Binary-64 format**"
(<https://www.sqlite.org/floatingpoint.html>), so `float` ↔ REAL is bit-exact in
both directions. There is no loss but our own, and there is none.

```
extern fn sqlite3_bind_double(stmt: ptr, i: int, v: float) -> int
extern fn sqlite3_column_double(stmt: ptr, i: int) -> float
```

Both need `RtKind.F64` (§2.6). That is the whole of blocker B5 on the float
side.

**HAZARD 1 — NaN IS SILENTLY DESTROYED.** `sqlite3_bind_double` converts NaN to
**NULL** before writing; ±Infinity round-trip fine. So `bind(nan)` then `read`
answers `null`, not `nan` — a `float` column is not a total round-trip, and a
`float?` column reads back absence where a value was written.
**RECOMMEND: the driver's `bind_float` REFUSES NaN** with a named voice ("a
`nan` cannot be stored — SQLite writes NULL for it; store the absence
deliberately, or store the bits with `to_bits()`"), rather than performing a
silent lossy write. A value that cannot round-trip must not be written in
silence.

**HAZARD 2 — NEVER READ A REAL AS TEXT.** As of **SQLite 3.52.0 (2026-03-06)**
the default REAL→TEXT conversion is:

> 1. Round to 15 digits. 2. Convert the text result back to binary-64.
> 3. If the binary-64 value from the previous step is different, then redo step
> (a) with 17-digit rounding.

with `sqlite3_db_config(db, SQLITE_DBCONFIG_FP_DIGITS, 15, 0)` to revert. That
guarantees round-trip but is **not shortest**: `Float.min_positive` prints as
`4.9406564584124654e-324` where Avra prints `5e-324`. So `sqlite3_column_text`
on a REAL and Avra's `${x}` will disagree on some values.
**THE DRIVER'S RULE: a REAL column is read with `sqlite3_column_double` and
projected by Avra's own printer.** `column_text` on a REAL is for diagnostics,
never for a value.

**HAZARD 3 — NUMERIC AFFINITY COLLAPSES A WHOLE FLOAT TO AN INTEGER.** "If a
floating point value that can be represented exactly as an integer is inserted
into a column with NUMERIC affinity, the value is converted into an integer"
(<https://www.sqlite.org/datatype3.html>). So `3.0` written into a
NUMERIC-affinity column reads back with `sqlite3_column_type` =
`SQLITE_INTEGER`, and a driver dispatching on the value's type sees `Int` where
it wrote `float`. **Declare float columns `REAL`** (affinity rule 4: the
declared type contains "REAL", "FLOA" or "DOUB"), which "forces integer values
into floating point representation."

### 4.2 `decimal` ↔ … — SQLite has no decimal, and the affinity rules bite

SQLite's storage classes are NULL, INTEGER, REAL, TEXT, BLOB. There is no
decimal. Three candidate encodings:

**(a) TEXT — RECOMMENDED.** Bind `d.to_text()` with `sqlite3_bind_text`; read
with `sqlite3_column_text` and `BigDecimal.from_str`. The canonical text carries
the SCALE (`19.990` stays three decimals), so `to_text ∘ from_str = id` and the
round-trip is exact in both value and scale.

> **THE AFFINITY TRAP, and it is the single most important finding in this
> section.** SQLite's five affinity rules, in order
> (<https://www.sqlite.org/datatype3.html>):
>
> 1. declared type contains `INT` → **INTEGER**
> 2. contains `CHAR`, `CLOB` or `TEXT` → **TEXT**
> 3. contains `BLOB`, or no type → **BLOB**
> 4. contains `REAL`, `FLOA` or `DOUB` → **REAL**
> 5. otherwise → **NUMERIC**
>
> **A column declared `DECIMAL(10,5)` gets NUMERIC affinity (rule 5).** And:
> "When text data is inserted into a NUMERIC column, the storage class of the
> text is converted to INTEGER or REAL (in order of preference) if the text is a
> well-formed integer or real literal."
>
> **So binding the TEXT `'19.99'` into a `DECIMAL(10,5)` column stores a REAL,
> silently, and the exactness the type exists for is gone on the way in.**
> Worse: `'100.00'` is stored as INTEGER `100` (the whole-value rule), so the
> SCALE is gone too.
>
> **THE LAW: a decimal column is declared `TEXT`.** The driver's schema helper
> REFUSES `DECIMAL`, `NUMERIC` and `MONEY` as a decimal column's declared type
> and names the reason. This is a P10 opportunity the campaign should design
> for: the compile-time-checked SQL layer can refuse the schema, not the write.

Sorting: register **`ext/misc/decimal.c`** and use its `decimal` COLLATION, so
`ORDER BY amount COLLATE decimal` sorts numerically rather than
lexicographically (`'9.00'` vs `'10.00'`). `decimal.c` also gives
`decimal_add/sub/mul`, `decimal_cmp`, `decimal_sum` (an exact aggregate — the
only correct way to `SUM` a money column) and `decimal(X[,N])` /
`decimal_exp(X[,N])` for rounding to N significant digits. **It has no
division**, which is consistent with §3.3's contract. **It is NOT part of the
amalgamation** — it ships in the CLI. Since the campaign vendors the
amalgamation with our own flags, `ext/misc/decimal.c` is one extra `.c` compiled
beside it and registered at connection open.

**(b) Scaled INTEGER.** Exact, sortable natively, and SQL can sum it. But the
scale lives outside the database, every read needs the scale from somewhere, and
a scale change is a data migration. **Offer as `Decimal.scaled(n)` for the ORM's
declared columns; never the driver's default.**

**(c) BLOB.** Affinity never converts a BLOB, so it survives any declared type —
but it loses `ORDER BY`, `SUM`, and human readability in the shell. **Reject.**

### 4.3 The value protocol at the boundary

`sqlite3_column_type` is asked FIRST and the getter follows (`SQLITE_INTEGER` 1,
`SQLITE_FLOAT` 2, `SQLITE_TEXT` 3, `SQLITE_BLOB` 4, `SQLITE_NULL` 5) — the
prior-art doc's `Value { Null | Int | Real | Text | Blob }` enum, with
`Real(float)` now spellable. Note that a value's type is per-VALUE, not
per-column (SQLite is dynamically typed), so a "REAL column" can hand back an
INTEGER (§4.1 hazard 3) and the enum is the honest reading.

---

## BLOCKERS

Each blocks the sqlite driver, is fundamentally missing from the language or the
stdlib, and carries a proposed shape.

### BLOCK-1 — No floating-point type at all (prior-art's **B5**)

**Evidence.** `Type` has no float (`core/types.av:12-88`; the words are `Int`,
`Bool`, `Str`, `Ptr`). `shape_named` answers five names
(`language/typing.av:316-325`). The lexer scans a bare digit run
(`grammar/lexer.av:319-321`), so the gap starts before the type surface: the
probe log records `let x: float = 1.0` → `F0100: expected BREAK while parsing
'stmt'`, pointing AT the `.`, and `let x: f64 = 1` → `F2001: 'f64' names no
type`.

**Shape of the fix.** §2 in full. In dependency order: `TokenKind.Float` + the
scan rule (`.` only before a digit) + `avra_str_to_double_bits` →
`Expr.FloatLit(bits: int)` + `features/float_lit/` → `Type.Float` (21 exhaustive
matches) → `Ins.ConstFloat` (8 consumers) with `Bin` reused →
`avra_llvm_double_type` / `fadd` / `fcmp` / `sitofp` in the wrapper →
`Val.F(bits)` + the interpreter's C-delegating externs → `avra_float_text` + the
three projection sites.

### BLOCK-2 — The host-call ABI has no float kind

**Evidence.** `export enum RtKind { I64, Ptr, Void }` (`core/ir.av:217`).
`ll_rt_kind` maps them to `i64` / `ptr` / `void` (`language/llvm.av:175-181`).
On x86-64 SysV and AArch64 AAPCS a `double` argument travels in a floating-point
register; an `I64`-declared seat puts the bits in an integer register.
**`sqlite3_bind_double` would receive garbage with no diagnostic anywhere in
either engine.**

**Shape of the fix.** `RtKind.F64`, five sites (§2.6): `rt_kind_of`
(`core/runtime_api.av:95`), `ll_rt_kind` (`llvm.av:175`), `rt_arg`
(`llvm.av:432`), `call_rt_value` (`llvm.av:383`), and `extern_row_of`
(`lower.av:52`) which already routes through `rt_kind_of` and needs no change.
Keep the runtime's OWN rows on `I64`-carrying-bits so the interpreter never
needs `F64` at all.

### BLOCK-3 — Float division must not reuse the integer division guard

**Evidence.** `bin_value` (`language/llvm.av:359-360`) routes `.Div` and `.Mod`
through `avra_int_div` / `avra_int_mod`, which **trap** on zero
(`runtime/avra_runtime.c:486-494`), because `sdiv` by zero is UB and the
interpreter refuses (`language/interp.av:299-302`). Spec:6359 says floats
"follow IEEE 754", "no panic, no check" — so `1.0/0.0` must be `inf`.

**Shape of the fix.** `bin_value` learns the operand type
(`bin_value(op, a, b, floaty)`) and float `.Div` emits `fdiv` directly. `.Mod`
on floats is REFUSED with a named voice.

### BLOCK-4 — `fptosi` is poison out of range; `to_int()` cannot be raw

**Evidence.** LLVM's `fptosi` yields poison for NaN and for any value outside
the destination's range. `(1e300).to_int()` compiled raw is UB the optimizer may
exploit, and the interpreter would answer *something*, so eval == native would
be untestable.

**Shape of the fix.** `to_int()` answers `int?`, lowered to a runtime row
`avra_float_to_int(bits) -> {present, value}` that range-checks first — the same
shape and the same reason as `avra_int_div`'s guard.

### BLOCK-5 — Numeric text conversion reads the ambient locale

**Evidence.** `grep -n setlocale runtime/avra_runtime.c backend/llvm_wrapper.c`
returns nothing, so today the process is in the `"C"` locale (C99 7.11.1.1) and
`strtod`/`snprintf` use `.`. But `build/avra` links `libLLVM`, and any
dependency that calls `setlocale(LC_ALL, "")` would silently change the meaning
of every float literal the compiler reads and every float the runtime prints.

**Shape of the fix.** One `newlocale(LC_ALL_MASK, "C", NULL)` handle in the
runtime, created once, used by every `strtod_l` / `snprintf_l` in the float
path. Written as a LAW beside the header law in `runtime/avra_runtime.c`'s
preamble.

### BLOCK-6 — No operator traits, so a library `BigDecimal` cannot be added

**Evidence.** `op_over` (`features/expr_spine/check.av:100`) and `wears`
(`check.av:117`) admit only `Int`, `Bool`, `Str`. `compare_help`
(`check.av:167,169`) already says "operator traits are recorded" for `Var` and
`Dyn`. Spec:725-729 shows `trait Add<Rhs = Self>` as the motivating case for
associated types, and spec:6317's own `BigDecimal` example writes
`price * (BigDecimal.one() + tax)`.

**Shape of the fix.** Sugar backlog, wanting site named. `trait Add { type
Output; fn add(self, rhs: Self) -> Self.Output }` and siblings; `binary_type`
falls back to a trait lookup when neither side is a builtin. **Does NOT block
the sqlite driver** — `BigDecimal.from_str(…)?` and `a.add(b)` work without it,
and the driver never does decimal arithmetic. It blocks `@std/money` being
pleasant.

### BLOCK-7 — A decimal column declared `DECIMAL`/`NUMERIC` silently becomes a float

**Evidence.** SQLite's affinity rule 5 gives `DECIMAL(10,5)` **NUMERIC**
affinity, and NUMERIC affinity converts a well-formed real-literal TEXT to REAL
on insert (<https://www.sqlite.org/datatype3.html>). Exactness is destroyed on
the way in, with no error.

**Shape of the fix.** The driver declares decimal columns `TEXT`; a schema
helper REFUSES `DECIMAL`/`NUMERIC`/`MONEY` for a decimal column and names the
reason; the later compile-time-checked-SQL layer (P10) refuses the schema at
compile time.

### BLOCK-8 — `sqlite3_bind_double(nan)` writes NULL

**Evidence.** SQLite converts NaN to NULL on bind; ±Inf round-trip fine (SQLite
user forum, "Binding floating point NaN, but getting NULL"; reproduced in
better-sqlite3 #1088 and Microsoft.Data.Sqlite #243).

**Shape of the fix.** `bind_float` refuses NaN with a named voice rather than
performing a silent lossy write.

### Not blockers, recorded

- **Integer literal underscores (`1_000`) do not lex.** Spec 31.5 ships them in
  v1.0. `is_name_start` includes `_` (`core/chars.av:14`), so `1_000` is
  `Num("1")` + `Name("_000")`. The campaign touches `numbered` anyway.
  Confidence MEDIUM (read, not probed).
- **Hex / octal / binary integer literals do not lex** (`0x2A` → `Num("0")` +
  `Name("x2A")`). Spec 31.5, v1.0. Not needed by the driver.
- **Integer overflow does not panic in debug** (spec 31.4). `bin_val`
  (`interp.av:303`) and `bin_value` (`llvm.av:354`) are unguarded. A standing
  spec gap the campaign inherits and should not silently adopt.
- **`${price:.2}` format specs are unimplemented.** `Expr.Interp(parts, holes)`
  has no spec field. Spec:5557; sugar backlog.
- **`Type.Decimal` is deliberately NOT a blocker.** SQLite has no decimal
  storage class, and a decimal round-trips as TEXT with zero language changes
  beyond `@std/numbers` existing.

---

## 5. LANDING ORDER

### 5.1 The MINIMUM VIABLE FLOAT that unblocks the driver

Everything the sqlite driver needs and nothing more. A REAL column reads and
binds; no arithmetic, no methods, no `@std/math`.

| # | Slice | What lands | Gate |
|---|---|---|---|
| **F0** | The word | `Type.Float` + `shape_named` + the 21 exhaustive `Type` arms + the refusal help gains `float` | `make gate`; `let x: float = …` type-checks (nothing constructs one yet) |
| **F1** | The literal | `TokenKind.Float`; the scan rule (`.` only before a digit, so `0..10` and `1.to_float()` still lex); `avra_str_to_double_bits` (C locale); `Expr.FloatLit(bits)`; `features/float_lit/`; underscores for ints and floats | lexer tests incl. `0..10`, `1.to_float()`, `1_000.5`; `.5` / `1.` / `1e` / `1.5f32` each refused by name |
| **F2** | The value | `Ins.ConstFloat` (8 consumers); `ll_type_of` → `double`; `avra_llvm_double_type` + `const_double_bits`; `Val.F(bits)` + `val_text`/`cloned_val` | `corpus/float.av`: `3.14` prints `3.14`, eval == native |
| **F3** | The text | `avra_float_text` (the printf loop, C locale, shortest); the three projection sites; `avra_floats_text` | the golden table of §2.4 verbatim, plus 10⁵ random-bit round-trip cases |
| **F4** | The ABI | `RtKind.F64`; `ll_rt_kind`; `rt_arg`; `call_rt_value` | a `double`-taking C fn called through `extern fn`; then `sqlite3_bind_double` / `sqlite3_column_double` round-trip a REAL |

**F0–F4 is the minimum.** After F4 the driver reads and binds REAL columns.
Note F3 is required even for the minimum: without a text projection,
`print_lowering` refuses a float answer ("has no text projection yet") and no
corpus program can prove F2.

### 5.2 The rest of the tower, in dependency order

| # | Slice | Notes |
|---|---|---|
| **F5** | Arithmetic + comparison | `bin_value(op, a, b, floaty)`; `fadd/fsub/fmul/fdiv`; the fcmp table (`oeq` / **`une`** / `olt` / `ole` / `ogt` / `oge`); `%` refused by name; float `/0.0` does NOT trap; the interpreter's C-delegating externs. **Gate: an adversarial suite on `nan`, `-0.0`, `inf` — `nan != nan` is true in BOTH engines** |
| **F6** | Conversions + constants | `to_float()`, `to_int() -> int?` (guarded row, never raw `fptosi`), `trunc/floor/ceil/round/abs/is_nan/is_finite/to_bits`, `Float.{nan,infinity,neg_infinity,max,min_positive,from_bits}` |
| **F7** | `total_cmp` | The bit trick; the rule that `List<float>.sort()` uses it, not `<` |
| **F8** | `@std/text`'s `parse_float` | `Result<float, …>`; accepts `nan`/`inf`/`-inf`; the same C as F1 |
| **F9** | `@std/json` fractions | `Json.Fraction(at)` (ROADMAP:1029) becomes `Json.Real(v: float)`. **The one downstream already refusing by name and waiting** |
| **F10** | `@std/numbers`' `BigDecimal` | Written in Avra; base-10⁴ limbs; `div(b, scale, mode)`; the seven rounding modes; `from_str`/`to_text` canonical |
| **F11** | `ext/misc/decimal.c` in the vendored build | The `decimal` collation for `ORDER BY`; `decimal_sum` for exact `SUM` |
| **F12** | Operator traits (**BLOCK-6**) | Sugar backlog; makes `price + tax` legal. Unblocks `@std/money` |
| **F13** | `19.99d` decimal literals | Sugar backlog; spec 31.5's suffix mechanism; `Expr.DecimalLit(digits: string)` |

**F0–F4 unblocks sqlite. F5–F9 completes `float` as a language type. F10–F11
gives the driver an exact money column. F12–F13 makes it pleasant. Nothing in
F10–F13 blocks the driver.**

### 5.3 Two ordering laws for this campaign

**A CODEGEN FIX REACHES THE PRODUCT ON THE SECOND BUILD** (CLAUDE.md). F2 and F5
change the backend, so after each: build twice, and only then trust a corpus or
a peak. A product built once carries the fix as source and was itself compiled
by the pre-fix backend.

**A SYNTAX CHANGE TO THE COMPILER'S OWN SOURCE RUNS IN ONE ORDER** (CLAUDE.md).
F1 changes the lexer. The compiler's own source contains **no float literals**
and must not gain any until F1 has landed and a product has been built with it —
which is another reason the AST payload is `bits: int` (§2.2): the compiler's own
body never needs a float, so the seed chain is never at risk.

---

## CONFIDENCE LEDGER

| # | Claim | Verified by | Confidence |
|---|---|---|---|
| 1 | Spec 31.2 names `float` (binary64) at app level, `f32`/`f64` at systems level; `f16` reserved | Read `2026_04_18_FULL_SPEC.md:6274-6293` | **HIGH** |
| 2 | Spec: no implicit int↔float conversion; float literals need a point or exponent; `int/int=int`, `float/float=float`, mixing requires explicit conversion | Quoted spec:6290-6292 | **HIGH** |
| 3 | Spec: NaN/Inf are values; "Comparisons with NaN follow IEEE rules (NaN != NaN)" | Quoted spec:6289 | **HIGH** |
| 4 | Spec 31.4: integer division by zero always panics; **float** overflow follows IEEE with no panic and no check | Quoted spec:6358-6359 | **HIGH** |
| 5 | **There is no `decimal` in the spec**; 31.3 decides `BigDecimal` in `@std/numbers`, `Money` in `@std/money` | Read spec:6295-6327; grepped the whole spec for "decimal" | **HIGH** |
| 6 | Spec 31.5 defines `1_000`, `0x2A`, `0o52`, `0b101010`, `2.5e-3`, `42i32`, `3.14f32` | Quoted spec:6362-6406 | **HIGH** |
| 7 | Two internal spec divergences: `.float` (1303) vs `.to_float()` (6290); "numeric widening" (5852) vs "no implicit conversion" (6290) | Read both sites | **HIGH** |
| 8 | Tree's `Type` enum has no float; the words are `Int`, `Bool`, `Str`, `Ptr` | Read `core/types.av:12-88` | **HIGH** |
| 9 | `shape_named` answers exactly `int`/`string`/`bool`/`void`/`ptr` | Read `language/typing.av:316-325` | **HIGH** |
| 10 | The lexer scans a bare digit run only; `1.5` → `Num`,`Op(.)`,`Num`; `1e9` → `Num`,`Name`; `1_000` → `Num`,`Name` | Read `grammar/lexer.av:319-321`, `core/chars.av:13-24` | **HIGH** |
| 11 | `..` is a two-char op, so a greedy float scanner breaks `0..10` | Read `grammar/lexer.av:284` | **HIGH** |
| 12 | `Token.int_value()` folds `c - 48` per character, so a `.` would fold as `-2` — a distinct token class is required | Read `grammar/lexer.av:45-56` | **HIGH** |
| 13 | `1.` must be refused because `1.to_float()` must keep parsing | Read `grammar/lexer.av:303-338` and the `primary` rule at `features/expr_spine/mod.av:41` | **HIGH** |
| 14 | **21 exhaustive `Type` matches across 16 non-test files** | `grep -rn '\.EmptyMap ->' packages/std-avrac/src \| grep -v /tests/ \| wc -l` | **HIGH** |
| 15 | **2 exhaustive `Val` matches** (`val_text`, `cloned_val`); the rest are catch-all projections | Read `language/interp.av:466-474, 671-684`, plus every `match v {` site | **HIGH** |
| 16 | **4 exhaustive `Expr` matches across 3 files** (`core/nodes.av`, `core/parts.av`, `features/dispatch.av`) | `grep -rn '\.NullLit or\|or .NullLit'` minus tests | **HIGH** |
| 17 | An `Ins` variant owes 8 consumers | CLAUDE.md's IR protocol; `core/ir.av:26-46` names 6 (the two same-file projections are elided there) | **HIGH** |
| 18 | `RtKind { I64, Ptr, Void }` — no float kind | Read `core/ir.av:217` | **HIGH** |
| 19 | A `double` argument travels in an FP register on x86-64 SysV and AArch64 AAPCS, so an `I64` seat passes garbage to `sqlite3_bind_double` | Platform ABI knowledge; not probed (read-only session) | **HIGH** |
| 20 | `extern_row_of` routes every extern seat through `rt_kind_of`, so `RtKind.F64` propagates automatically | Read `language/lower.av:48-55`, `core/runtime_api.av:95-101` | **HIGH** |
| 21 | `avra_llvm_cast_to_type` already handles double↔i64 (bitcast), double↔ptr, and sitofp/fptosi for narrower ints | Read `backend/llvm_wrapper.c:604-647` | **HIGH** |
| 22 | `llvm_api.av` declares 61 externs and has no float type, no fadd, no fcmp, no sitofp | Read `language/llvm_api.av:1-61` | **HIGH** |
| 23 | Integer `.Div`/`.Mod` route through `avra_int_div`/`avra_int_mod`, which trap on zero — the trap a float `Div` must avoid | Read `language/llvm.av:359-360`, `runtime/avra_runtime.c:486-494`, `language/interp.av:299-302` | **HIGH** |
| 24 | `bin_val` pre-dispatches on value shape (nulls, bools, ints), so floats slot in as a third pre-dispatch | Read `language/interp.av:292-313` | **HIGH** |
| 25 | The interpreter already declares externs into the same C the native binary calls (11 of them), so a float host arm has an exact precedent | Read `language/interp.av:884-910`, `language/workspace.av:26` | **HIGH** |
| 26 | Integer overflow is unguarded in both engines (spec 31.4 unimplemented) | Read `language/interp.av:303-308`, `language/llvm.av:354-356` | **HIGH** |
| 27 | Three text-projection sites: `hole_reg`, `print_lowering`, `val_text`; `list_text` is already generic over an element printer | Read `features/str_lit/lower.av:33-43`, `language/lower_walk.av:133-176`, `language/interp.av:466`, `runtime/avra_runtime.c:1018-1055` | **HIGH** |
| 28 | No `setlocale` anywhere in the runtime or the LLVM wrapper | `grep -n setlocale runtime/avra_runtime.c backend/llvm_wrapper.c` → empty | **HIGH** |
| 29 | A C program starts in the `"C"` locale, so `strtod`/`snprintf` are `.`-based today | C99 7.11.1.1 | **HIGH** |
| 30 | `strtod` and `printf("%.*e")` are correctly rounded on glibc, macOS libc (gdtoa) and musl | Literature; not measured this session | **MEDIUM-HIGH** — the golden test in F3 is what makes it HIGH |
| 31 | The printf-precision loop yields the SHORTEST round-tripping digits, identical to Ryū's output, given a correctly-rounded libc | Derivation from 30 (correct rounding ⇒ nearest digits, ties to even) | **MEDIUM-HIGH** |
| 32 | Ryū is shortest with no fallback, ~22–28 ns, Apache-2.0/Boost, with a correctness proof; Grisu3 rejects ~0.5% of inputs and falls back to Dragon4 | github.com/ulfjack/ryu README; ACM 10.1145/3360595; Loitsch's Grisu paper | **HIGH** |
| 33 | SQLite stores REAL as IEEE 754 binary64 | sqlite.org/floatingpoint.html | **HIGH** |
| 34 | SQLite 3.52.0 (2026-03-06) defaults REAL→TEXT to the 15-then-17-digit round-trip algorithm; `SQLITE_DBCONFIG_FP_DIGITS` reverts to 15 | sqlite.org/floatingpoint.html, quoted verbatim; release date from the 3.52 announcement | **HIGH** |
| 35 | SQLite's REAL→TEXT is round-tripping but NOT shortest (e.g. `4.9406564584124654e-324` vs `5e-324`) | Derivation from 34 (17 significant digits is a fixed count, not a minimum) | **HIGH** |
| 36 | `sqlite3_bind_double` converts NaN to NULL; ±Inf round-trip fine | SQLite user forum "Binding floating point NaN, but getting NULL"; better-sqlite3 #1088; Microsoft.Data.Sqlite #243 | **HIGH** |
| 37 | SQLite affinity: `DECIMAL(10,5)` → NUMERIC (rule 5); NUMERIC converts well-formed real-literal TEXT to REAL on insert; an exactly-integral REAL becomes INTEGER | sqlite.org/datatype3.html, all quoted | **HIGH** |
| 38 | `ext/misc/decimal.c` is `{sign, oom, isNull, isInit, nDigit, nFrac, signed char *a}` — one digit per byte, MSD first; provides add/sub/mul/cmp/sum/pow2/round and a `decimal` collation; **no division** | Read the source header and struct via raw.githubusercontent.com | **HIGH** |
| 39 | `ext/misc/decimal.c` is not in the amalgamation but is in the CLI | Search result, not source-verified | **MEDIUM** — verify against the vendored tarball |
| 40 | C# `decimal`: 128 bits = 96-bit integer + 32 flag bits (sign, scale 0–28); ±79,228,162,514,264,337,593,543,950,335; `1m/3m*3m` = `0.9999999999999999999999999999` | learn.microsoft.com/dotnet/api/system.decimal, quoted | **HIGH** |
| 41 | IEEE 754-2008 decimal128 carries 34 significant digits | IEEE 754-2008; corroborated by search | **HIGH** |
| 42 | Postgres NUMERIC is base-10000 limbs with `weight`, `dscale`, sign; trailing zeros not stored; base changed from 10 to 10000 in 2003 | postgres `src/backend/utils/adt/numeric.c`; Npgsql type-representation docs | **HIGH** |
| 43 | Base 10⁴ limbs let products accumulate ~9×10¹⁰ times in an i64 before overflow; base 10⁹ overflows on the second accumulation | Arithmetic: (10⁴−1)² ≈ 10⁸, i64 max 9.22×10¹⁸; (10⁹−1)² ≈ 10¹⁸ | **HIGH** |
| 44 | Python's `decimal` is IBM General Decimal Arithmetic with a Context (`prec` default 28, `ROUND_HALF_EVEN`), signalling Clamped/InvalidOperation/DivisionByZero/Inexact/Rounded/Subnormal/Overflow/Underflow/FloatOperation, each with a trap enabler | docs.python.org/3/library/decimal.html | **HIGH** |
| 45 | Java `BigDecimal.divide(b)` throws on a non-terminating quotient unless a scale and RoundingMode are supplied | Java library knowledge; not fetched this session | **MEDIUM-HIGH** |
| 46 | The tree has no operator traits; `wears` admits only Int/Bool/Str and `compare_help` already says "operator traits are recorded" | Read `features/expr_spine/check.av:100,117,159-176` | **HIGH** |
| 47 | Spec:725-729 shows `trait Add<Rhs = Self>` with an associated `Output`; spec:6317 writes `price * (BigDecimal.one() + tax)` | Read both | **HIGH** |
| 48 | `@std/json` refuses fractions by name (`Fraction(at)`) and is the one downstream already waiting on float | ROADMAP:1028-1031 | **HIGH** |
| 49 | `${price:.2}` format specs are unimplemented — `Expr.Interp(parts, holes)` has no spec field | Read `core/nodes.av`'s `Expr`; spec:5557 | **HIGH** |
| 50 | LLVM `fptosi` is poison for NaN and out-of-range inputs | LLVM LangRef; not fetched this session | **HIGH** |
| 51 | `TokenKind` and `term_kind` are the two places a new token class registers | Read `grammar/lexer.av:25`, `grammar/validate.av:12-25` | **HIGH** |
| 52 | The runtime is built with `cc -O2 -Wall -Werror`, no `-ffast-math`, no `-lm` | Read `Makefile:63-65` | **HIGH** |

---

## Sources

- [SQLite — Floating Point Numbers](https://www.sqlite.org/floatingpoint.html)
- [SQLite — Datatypes In SQLite (affinity rules)](https://www.sqlite.org/datatype3.html)
- [SQLite — `ext/misc/decimal.c`](https://raw.githubusercontent.com/sqlite/sqlite/master/ext/misc/decimal.c)
- [SQLite user forum — Binding floating point NaN, but getting NULL](https://sqlite.org/forum/info/f97759ec7b88be775e258b6ed768e18a7b3830f724eaaa7dcad6a09cb14a7688)
- [better-sqlite3 #1088 — NaN turns into NULL](https://github.com/WiseLibs/better-sqlite3/issues/1088)
- [Ryū — ulfjack/ryu](https://github.com/ulfjack/ryu)
- [Ryū Revisited: Printf Floating Point Conversion (ACM 10.1145/3360595)](https://dl.acm.org/doi/pdf/10.1145/3360595)
- [Loitsch — Printing Floating-Point Numbers Quickly and Accurately with Integers](https://www.cs.tufts.edu/~nr/cs257/archive/florian-loitsch/printf.pdf)
- [Russ Cox — Floating-Point Printing and Parsing Can Be Simple And Fast](https://research.swtch.com/ftoa)
- [Drachennest — algorithm comparison](https://github.com/abolz/Drachennest)
- [.NET — `System.Decimal`](https://learn.microsoft.com/en-us/dotnet/api/system.decimal)
- [Python — `decimal` module](https://docs.python.org/3/library/decimal.html)
- [PostgreSQL — `src/backend/utils/adt/numeric.c`](https://github.com/postgres/postgres/blob/master/src/backend/utils/adt/numeric.c)
- [PostgreSQL — Numeric Types](https://www.postgresql.org/docs/current/datatype-numeric.html)
- [Npgsql — PostgreSQL type representations](https://www.npgsql.org/doc/dev/type-representations.html)
