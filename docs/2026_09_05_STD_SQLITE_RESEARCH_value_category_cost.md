# The cost of a core value category — a file-by-file census

**Scope.** What it takes to add `float` (IEEE-754 binary64), `Bytes` (an
arbitrary byte string) and `decimal` (exact base-10) to Avra, traced by
following the three categories that already exist end to end: `bool` and
`int` (unmanaged machine words) and `string` (a headered heap box). The
differences between those three are the map.

**Method.** Every claim below either quotes compiler OUTPUT from a
sub-second `./avra check` probe of a scratch file, quotes a linked run of
this tree's own `build/avra_runtime.o`, or names a file and line the
reader can open. Nothing here is reasoned from the shape of the code
alone (CLAUDE.md, MEASURE WHAT A THING DOES).

**Baseline.** `main` at 6491ac1, `build/avra` of 2026-09-05 17:52.

---

## 0. The three today, in one probe each

```
$ ./avra check t.av          # fn f(x: float) -> int { 1 }
error[F2001]: `float` names no type
  ╭─[t.av:1:1]
1 │ fn f(x: float) -> int { 1 }
  · ┬
  · ╰── in this signature
──╯
help: the types today are `int`, `string`, `bool`, and your declared types
```

```
$ ./avra check t.av          # let x = 1.5
error[F0100]: expected BREAK while parsing `stmt`
  ╭─[t.av:1:10]
1 │ let x = 1.5
  ·          ┬
  ·          ╰──
──╯
```

Column 10 is the `.`. The lexer scanned `1` as a `Num` token and stopped;
`.5` is `Op(".")` then `Num("5")`, and `stmt` wanted a `BREAK`.

`Bytes` reads identically to `float`: `fn f(b: Bytes) -> int { 1 }` is
`F2001` "`Bytes` names no type". `decimal` likewise. Every other spelling
probed (`1e9`, `.5`, `1_000`, `1.5d`, `1.5m`) is `F0100 expected BREAK`,
at the first character the number scanner will not eat — for `1_000` that
is column 10, the `_`, because `_` is `is_name_cont` and `_000` lexes as
a `Name`.

Two things that are **free** today:

- `float`, `decimal` and `Bytes` are not reserved words
  (`language/resolve.av:22`, `reserved()`), and `let float = 3` /
  `fn int() -> int { 1 }` both check clean. Only a **type declaration**
  collides: `type int = { v: int }` is `F3008` "`int` is a built-in
  type … help: choose another name — `int`, `string` and `bool` are the
  language's". So promoting `float` to a builtin type name silently
  re-classifies any existing `float` **binding** — there are none in the
  tree, verified by grep.
- `1.foo` **parses today** as a property read: `error[F2003]: no property
  `foo` on `int``. This is the disambiguation constraint for the lexer
  (§1).

Two existing tests **assert on today's absence** and will go red the day
`float` lands. They are the canonical "unknown type" fixtures:

- `packages/std-avrac/src/features/fns/tests/fns_test.av:85-88` —
  `analyze_source("fn f(x: float) -> int { 1 }\nf(1)")` asserting
  `"`float` names no type"` **and**
  `"the types today are `int`, `string`, `bool`, and your declared types"`.
- `packages/std-avrac/src/features/type_expr/tests/type_expr_test.av:37` —
  `refused_with("fn f(x: float?) -> int { 1 }\nf(1)", "`float` names no type")`.

Both need a different unknown-type name (`quaternion`) plus the help
string in `language/typing_declare.av:405` rewritten. Trivial, but it is
the first thing that breaks, and it breaks in two packages.

---

## 1. The lexer and the grammar

### 1.1 Where a literal is recognised

One file: `packages/std-avrac/src/grammar/lexer.av`.

| site | line | what it does |
|---|---|---|
| `enum TokenKind` | 25 | `{ Name, Num, Str, IStrBegin, IStrMid, IStrEnd, Op, Break, Eof, Pkg }` |
| `Token.lit_matches` | 34 | the **only exhaustive** `TokenKind` match in the tree |
| `Token.int_value() -> int?` | 45 | digits → value; overflow answers `null` |
| `numbered(text, lo, hi)` | 109 | builds the `Num` token, attaches `F0001` on overflow |
| `two_char_of(a, b)` | 280 | `..` munches before `.` — this is what keeps `1..5` a range |
| `is_single_op_code` | 70 | `.` (46) is a single-char op |
| `scan_step` `is_digit` arm | 319 | `scan_while(src, n, i + 1, is_digit)` — a bare digit run |

`is_digit` itself is `core/chars.av:20` — `c >= 48 && c <= 57`, no `_`,
no `.`, no `e`.

The grammar side is one line, `features/expr_spine/mod.av`:

```
primary = v:NUMBER -> int_lit(v) | n:NAME -> ident(n) | "(" e:expression ")" @expect(")", …) -> e
```

`NUMBER` maps to `TokenKind.Num` in `grammar/validate.av:14` (`term_kind`,
a `_ -> null` projection — adding a terminal name is one row, and the
build does **not** demand it). The builder is
`features/expr_spine/builders.av:6`, `build_int_lit`, whose whole body is
`b.make_expr(Expr.IntLit(t.int_value() ?? 0))`.

### 1.2 What it takes to lex a float

The number scanner grows from a digit run to a small state machine. The
**hard constraint measured above** is that `1.foo` must keep meaning
"property `foo` of `1`" and `1..5` must keep meaning a range. Both fall
out of one rule:

> A `.` continues a number **only when the next character is a digit.**

That single rule settles all three cases: `1.5` (float), `1..5` (`.` then
`.` — the two-char munch at `two_char_of` already wins because
`two_char_at` is consulted before `is_single_op_code`, but the number
scanner never even sees the second `.` since `.` is not followed by a
digit), and `1.foo` (`.` then a letter → stop the number).

Concretely, in `scan_step`'s `is_digit` arm:

```
digits [ "_" digits ]*  [ "." digits [ "_" digits ]* ]  [ ("e"|"E") ["+"|"-"] digits ]
```

- **`1_000`** — accept `_` **between** digits only (never leading, never
  trailing, never doubled), and strip them before `int_value()`. This is a
  change to the INT path too, and it is worth landing on its own, before
  float, because it is independently useful and cannot break anything: no
  program can contain `1_000` today (`F0100`).
- **`.5`** — do **not** accept it. A leading `.` is `Op(".")` and the
  postfix ladder (`postfix = v:primary ( q:( "?." | "." ) p:NAME …`)
  already owns that character. Accepting `.5` would mean the lexer must
  know whether a `.` follows a value or opens a literal, which it cannot,
  and `xs.0` / a future tuple index would collide. Spell it `0.5`. This is
  a **language decision** and belongs in the spec, not in the lexer.
- **`1e-9`** — accept, but only after a digit. `1e9` today lexes as
  `Num("1")` then `Name("e9")` and fails at the `Name`; nothing can break.
- **`1.` (trailing dot)** — refuse (it is `F0100` today). The rule above
  gives this for free.

### 1.3 The token kind

Two honest options.

**(a) A new `TokenKind.Float`.** Cost: exactly **two** edits —
`lit_matches` (line 37, joins the `-> false` run: a grammar `Lit` is never
a float's text) and `term_kind` (validate.av:14, one row `"FLOAT" ->
TokenKind.Float`). Then `primary = f:FLOAT -> float_lit(f)` as an ordered
alternative. This is the tree's own doctrine — "No string tags or
string-matching to detect behavior" — and it costs almost nothing because
`TokenKind` has exactly **one** exhaustive consumer.

**(b) Keep `TokenKind.Num` and let the builder read the text.** Cheaper
in the lexer, but `build_int_lit` would then `contains(".")` to decide
which node to make. That is string-matching to detect behaviour, at the
one place the doctrine names. **Take (a).**

`first.av:156`'s `subsuming_term` (`is_digit(c) -> "NUMBER"`) governs
grammar **literals** that would also match a token class. No grammar
fragment writes a float literal, so it needs no change; leaving it is
correct.

### 1.4 The grammar-authoring laws that bite here

From CLAUDE.md, in order of how likely they are to cost a day:

- **Keyword anchors merge before NAME-headed branches.** `FLOAT` is a
  *token class*, not a keyword, so it does **not** collide with the
  `fns` ordering hazard that ate `if (c)`. But it must merge **into
  `primary` ahead of** `NUMBER`? No — `FLOAT` and `NUMBER` are disjoint
  token classes, so branch order between them is irrelevant. A new
  literal feature (`float_lit`) therefore lands anywhere before
  `expr_stmt`, exactly like `bool_lit` does at
  `language/mod.av:138`. Put it beside `bool_lit`.
- **`@expect` attaches only at a sequence's TAIL.** A single-item branch
  (`primary = f:FLOAT -> float_lit(f)`) has no mid-sequence position, so
  this cannot bite.
- **Every comma list takes a trailing comma.** No new comma list.
- **A greedy star cannot be told to stop early.** No new star.
- **Only the LAST branch sharing an anchor may `@recover`.** No recovery
  on a literal branch.
- **expr_stmt is the floor.** `float_lit()` goes before it in
  `language_features()`.

The grammar work for float is genuinely one line plus one builder. **The
lexer is the whole grammar cost.**

### 1.5 A decimal literal spelling

Three candidates, with what each costs:

| spelling | lexer cost | reads well? | verdict |
|---|---|---|---|
| `1.5d` / `1.5m` | the number scanner must consume a trailing suffix letter and then **not** let `1.5dx` through; `1.5d` currently lexes as `Num(1)`, `Op(.)`, `Num(5)`, `Name(d)` so nothing breaks | `1.5m` reads as "money"; `1.5d` reads as "double" to every C programmer, which is exactly backwards | **`1.5m`**, if a literal is wanted |
| `decimal("1.5")` | **zero** — it is an ordinary call | ceremony (P3), no constant folding, and `const` refuses it (§3.3) | fallback |
| `1.5` under a `decimal` want | zero new syntax; the expected-type channel picks the type | the *same* literal means two types depending on context, which is the one thing an LLM-first language (P1) must not do | **no** |

**Recommendation: no decimal literal in v1.** `decimal` arrives as
`decimal_of("1.5")` (an ordinary fn), and a literal suffix `1.5m` is a
later, separable slice. Rationale: the decimal *representation* is the
hard part (§11), and coupling it to a lexer change triples the blast
radius for no user-visible gain. Record `1.5m` in the sugar backlog with
the wanting site when it appears.

### 1.6 A byte-string literal

**Recommendation: none, ever, in v1** — and this is not conservatism, it
is a correctness argument the tree already documents. A `b"ab\x00cd"`
literal's payload would have to travel through the compiler as an Avra
`string`, and the compiler's own `==`, `contains`, `index_of`, `split`
and `replace` on that string stop at the first NUL. Measured, against
this tree's own runtime object:

```
$ cc -O0 -o nul nul.c build/avra_runtime.o && ./nul
len("ab\0cd")      = 5
streq(ab\0cd,"ab")  = 1
contains(...,"cd")  = 0
len(empty substring) = 0
len(from_codepoint(0)) = 1
```

A five-byte text **compares equal** to its own two-byte prefix, and
`contains("cd")` answers **false** about text that ends in `cd`. That is
ROADMAP H1, reproduced here. Giving the compiler a literal whose payload
it cannot compare correctly is how a wrong answer ships. `Bytes` values
come from *runtime sources* (a file, a column, a conversion from a
string) until H1 is decided.

---

## 2. The type surface

### 2.1 How a primitive type is represented

`packages/std-avrac/src/core/types.av`.

- `export type TypeId = { index: int }` (line 8) — an opaque handle. A
  single-field struct, so it is **flat**: it travels as its `int` field.
- `export enum Type` (line 12) — the shapes. The four "words" are `Int`,
  `Bool`, `Str`, `Ptr`; `Str` is annotated as "the first MANAGED value".
- `export type TypeRegistry = { shapes: List<Type>, ids: Map<string, TypeId>, flats: List<FlatRow> }`
  (line ~117). `intern` (160) is one map probe on a canonical key.
- `canon` (134) builds that key. **Every variant has a distinct numeric
  prefix**, hand-assigned: `"0"` Int, `"ptr"` Ptr, `"1"` Error, `"2"` Str,
  `"3"` Bool, `"4:"` List … `"18"` EmptyMap. A new scalar takes the next
  free string; there is no counter, so **pick a fresh one by reading the
  match** (the tree has no keeper for this — a duplicate key would
  silently alias two types, exactly the class of bug the `I33` duplicate
  idiom number caused in `make idioms`).

### 2.2 What breaks when `Type` grows

Adding a variant to `Type` breaks **36 exhaustive matches across 16
files**, every one at compile time. This is the census (the two extra
`EmptyMap` hits are the enum declaration itself and a doc comment):

| file | fn | line |
|---|---|---|
| `core/types.av` | `ptr_shape` | 126 |
| | `canon` | 149 |
| | `substituted` | 287 |
| | `name_of` | 312 |
| | `args_of` | 327 |
| `features/unify.av` | `unify` | 44 |
| | `var_binds` | 73 |
| | `elem_unifies` | 88 |
| | `value_unifies` | 98 |
| | `carried_unifies` | 114 |
| | `slot_worthy` | 141 |
| | `unlawful_side` | 155 |
| | `fully_bound` | 179 |
| `features/contexts.av` | `fields_of_type` | 17 |
| | `variants_of_type` | 30 |
| | `declared_decl` | 149 |
| `features/maps/methods.av` | `on_map` | 12 |
| | `value_held` | 37 |
| | `check_map_length` | 125 |
| `features/maps/check.av` | `map_type` | 11 |
| `features/expr_spine/check.av` | `wears` | 124 |
| | `compare_help` | 165 |
| `features/impls/callee.av` | `through_a_contract` | 40 |
| | `declared` | 63 |
| `features/checks.av` | `empty_adopted` | 154 |
| `features/values.av` | `length_word` | 434 |
| `features/variants.av` | `wants_decl` | 77 |
| `features/enums/mod.av` | `on_enum` | 69 |
| `features/str_lit/lower.av` | `hole_reg` | 41 |
| `language/memory.av` | `is_managed` | 37 |
| `language/receivers.av` | `writable` | 192 |
| | `callee_of` | 250 |
| `language/lower_walk.av` | `boxed_decl` | 93 |
| | `print_lowering` (unprintable) | 144 |
| | `print_lowering` (text) | 155 |
| `language/llvm.av` | `ll_type_of` | 207 |

Of these, **five are decisions** and the rest are one-word joins:

1. `ptr_shape` (types.av:126) — float `false`, Bytes `true`, decimal
   `true` if boxed.
2. `is_managed` (memory.av:37) — float joins the `-> false` run; Bytes
   joins the `-> true` run. **Omit the float join and the memory pass
   retains and releases a number.** ROADMAP already records this line as
   the one a new scalar must join; it is verified above.
3. `slot_worthy` (unify.av:141) — can this type ride a list element / map
   value / Result side / enum payload? Float **yes** (via the bitcast
   seam of §5.4); Bytes **yes** (a pointer).
4. `length_word` (values.av:434) — Bytes answers `"avra_bytes_len"`;
   float answers `null`.
5. `print_lowering` / `hole_reg` — the text projection (§8).

### 2.3 Interning, printing, comparing

- **Printing**: `name_of` (types.av:292), the one place a type becomes
  text. One arm each.
- **Comparing**: type identity is `id.index == id.index` — see the
  `// LICENSED I9` sites in `unify.av:41` and `types.av:274`. Nothing to
  do.
- **Unifying**: `unify` (unify.av:31) dispatches on the *want*'s shape;
  a new scalar joins the identity run (`want.index == got.index`). Four
  more matches (`elem_unifies`, `value_unifies`, `carried_unifies`,
  `fully_bound`) need the new name in a `-> false` / `-> true` run.
  **No new unification rule** — a scalar unifies by identity.

  Caveat worth stating: there is **no implicit int→float widening** in
  this design and there must not be, because `accepts` records lifts at
  one door (`agreed`, checks.av) and every existing lift is either
  identity or a *box* mint. An `int → float` lift is a `sitofp`, a
  genuine value conversion, and it would be the first non-identity,
  non-boxing widen in the language. `2 + 1.5` therefore refuses; the
  spelling is `2.0 + 1.5` or `float_of(2) + 1.5`. This is the P1 answer
  anyway (an LLM that writes `2 * 0.5` should be told, not guessed at).

### 2.4 Nullability and the niche

`features/values.av:213-232` is the seam, and it is exact:

```
enum Repr { Niche, Pair, Boxed }

fn inner_repr(cx: LowerCx, inner: TypeId) -> Repr {
    if cx.view.types.is_flat(inner) { return Repr.Boxed }
    if cx.view.types.rides_pointer(inner) { return Repr.Niche }
    Repr.Pair
}
```

- **The niche is for pointers only.** "A nullable pointer IS its own
  value, absence is the null pointer" (CLAUDE.md). There is **no niche
  for `int`** — `int?` is a `Pair`, an LLVM first-class
  `{ i1, i64 }` aggregate that lives in registers
  (`llvm.av:222`, `opt_ll_type`). There is likewise no niche for `bool`.
- **So `float?` is a `Pair`**: `{ i1, double }`. No NaN-payload niche, no
  signalling-NaN trick, nothing clever. That is the right answer and it
  is free: `opt_ll_type` already builds `{ i1, ll_type_of(inner) }`.
- **`Bytes?` is a `Niche`** — a null pointer, exactly like `string?`.
  And this is the place CLAUDE.md's law bites at the C boundary: a
  runtime row answering `NULL` to mean *empty blob* is indistinguishable
  from *SQL NULL*. **A row answers an EMPTY BOX for empty and NULL only
  for absent.** This is not advice for @std/sqlite; it is a constraint on
  every `Bytes`-answering runtime row the campaign writes.
- `opt_rides_pointer` (types.av:192) and `rides_pointer` (256) are the
  registry's answers and **must agree with `inner_repr`** — the comment
  at values.av:222 says so explicitly ("The two answers must never
  disagree — they are the same layout").

### 2.5 The landmine in the `Pair` path

`values.av:365`, `hollow_of`:

```
export fn hollow_of(mut cx: LowerCx, inner: TypeId) -> Reg {
    if cx.view.types.shape_of(inner) is .Bool {
        let z = cx.mint_ty(inner)
        cx.emit(Ins.ConstBool(z, false))
        return z
    }
    zeroed(cx, cx.mint_ty(inner))
}
```

`zeroed` (values.av:260) emits `Ins.ConstInt(z, 0)`. An absent `float?`
takes `absent_pair` → `flagged_pair(…, hollow_of(carried))` → **`ConstInt
0` into a `double` register.** In the backend `const_int_value`
(llvm.av:307) would build `i64 0` and hand it to an `insertvalue` whose
element type is `double` — LLVM verification failure at best, a bitcast
of `0` at worst (which happens to be `+0.0`, so it would *work* and hide
the hole until the day someone changes it). **`hollow_of` needs a float
arm, exactly as it has a bool arm, and for exactly the same reason.**
This is the single highest-value line in this document.

---

## 3. The value protocol

### 3.1 What it is

`core/nodes.av:266-306`, under the header "The VALUE PROTOCOL: a literal
node's payload, one projection per value category — what features read
instead of matching a variant, their own included."

| member | line | answers |
|---|---|---|
| `bool_of(e) -> bool?` | 268 | `.BoolLit(v) -> v` |
| `int_of(e) -> int?` | 278 | `.IntLit(v) -> v` |
| `text_of(e) -> string?` | 285 | `.StrLit(v) -> v` |
| `pairs_of(e) -> MapPairs?` | 296 | `.MapLit(keys, values)` |
| `elems_of(e) -> List<ExprId>?` | 303 | `.ListLit(elems)` |

CLAUDE.md's rule: **"Int has none: its only reader binds it in its own
dispatch match, so the projection was dead; add one at the second
reader."** `int_of` exists now because a second reader arrived (the const
path). The protocol grows **per value category**, as a core event, and
there is no unified return — "N variants need N projections — payload
types differ, and a unified return would be the parallel Value enum the
doctrine refuses."

**A protocol read is never `?? <a plausible default>`** — absence is a
defect (`lower_defect`), because the dispatch guaranteed the payload.
`bool_lit/semantics.av:18` is the exemplar.

### 3.2 What a new category owes it

- `float_of(e) -> float?` — **but only at the second reader.** The first
  reader is `float_lit/semantics.av`'s own dispatch; adding a projection
  before a second reader exists would land dead code and violate the rule
  above. Practically the second reader arrives immediately (§3.3), so
  plan for it.
- `bytes_of` — **not needed**, because there is no `Bytes` literal (§1.6).
  `Bytes` never joins the value protocol at all. This is a real saving.
- `decimal_of` — not needed under the `decimal_of("…")` design.

### 3.3 The two consumers a float literal must reach, one of which the compiler will NOT tell you about

Both read the protocol, and they are the "second reader":

1. **`features/contexts.av:205`, `literal_shape`** — the const path's
   type:
   ```
   fn literal_shape(value: Expr) -> Type? {
       if int_of(value) != null { return Type.Int }
       if text_of(value) != null { return Type.Str }
       if bool_of(value) != null { return Type.Bool }
       null
   }
   ```
2. **`language/lower_state.av:120`, `constant_reg`** — the const path's
   register, same three-way ladder ending in `ConstBool`.

Both are `null`-returning ladders, **not** exhaustive matches, so the
compiler will not break on them. Miss them and `const PI = 3.14159`
silently becomes "not a compile-time constant".

And the third, which is the same class:

3. **`features/consts/check.av:41`, `literal`** —
   `.IntLit(_) or .StrLit(_) or .BoolLit(_) -> true, _ -> false`. A
   catch-all over `Expr`. Miss it and `const PI = 3.14` refuses with
   `F2…` "a const's value must be known at compile time" — a wrong,
   confusing refusal with no compiler help pointing anywhere near the
   cause.

Also silent, and the same shape:

4. **`core/parts.av:68`, `inert`** —
   `.IntLit(_) or .StrLit(_) or … -> true, _ -> false`. A float literal
   left out reads as "may act", so `defer 1.5` would be *allowed* where
   `defer 1` is refused.

**These four are the whole hidden cost of the value protocol** and they
are precisely the failure mode CLAUDE.md's `_ ->` doctrine predicts: two
or more answering arms means a registry, and a catch-all there silently
forgets the next variant. Each of these has 3 answering arms.

---

## 4. The IR and its eight consumers

### 4.1 The vocabulary and its keeper

`core/ir.av:50`, `export enum Ins`, with the eight consumers named at the
definition site. `tools/vocab.sh` is the keeper: it greps each of the
eight dispatch functions and **fails the gate if any grows a `_ ->`**,
printing "A catch-all here lets the NEXT instruction ship unimplemented."
`avra new ins <Name>` prints the same checklist (`packages/cli/src/commands/new.av:74-114`).

| # | file | fn | line |
|---|---|---|---|
| 1 | `core/ir.av` | `dst_of` | 153 |
| 2 | `core/ir.av` | `body_symbol` | 182 |
| 3 | `core/ir.av` | `hosted_symbol` | 201 |
| 4 | `language/interp.av` | `step` | 157 |
| 5 | `language/memory.av` | `memory_ins` | 59 |
| 6 | `language/ir_text.av` | `body_lines` | 20 |
| 7 | `language/llvm.av` | `emit_ins` | 268 |
| 8 | `features/facts.av` | `give` | 335 |

Plus a corpus program proving `eval == native` and an `avra ir` golden.

### 4.2 The honest answer for float — running the 4-step protocol

**Step 1, JUSTIFY.** The doctrine's own list of justifying reasons opens
with "a new control shape, **a new value category**, a new memory
boundary, or a MACHINE SHAPE the backend can exploit and cannot reliably
infer". A float constant is a new value category by definition. But the
protocol also says "Not justified when an existing shape says it", so the
question is real, not ceremonial.

**Could a float constant ride `ConstInt`?** Technically yes, and there is
a precedent *in the code*: `llvm.av:307`'s `const_int_value` already
reinterprets `ConstInt` by the **destination's** type —

```
fn const_int_value(dst: Reg, v: int) -> ptr {
    if self.types.rides_pointer(self.tys[dst.index]) {
        return avra_llvm_const_pointer_null(avra_llvm_pointer_type(self.lc))
    }
    avra_llvm_const_int(avra_llvm_int64_type(self.lc), v, 1)
}
```

— and `interp.av:190`'s `const_int_val` is its twin. So `ConstInt(dst,
bits)` with a float destination could bitcast. It would work.

**It should not be done, for one reason that is not aesthetics.** The IR
text is a **golden** (`ir_text.av:61`, `r${d} = int ${v}`), and P7 says
visible magic. `2.0` would print as `r5 = int 4611686018427387904`. A
golden nobody can read is a golden nobody checks, and the eval-vs-native
proof for float lives in exactly those goldens. Second reason: `ConstInt`
already carries one destination-typed reinterpretation (the null
pointer); a second one makes the instruction mean three things, which is
how a curated vocabulary becomes a cluster.

**Step 2, GENERALIZE BEFORE ADDING.** This is where most of the win is,
and the answer is emphatic:

- **`Bin` does NOT grow.** `Bin(dst, op, a, b)` already means "the eager
  binary op over same-typed operands", and both engines already dispatch
  on operand *kind*: `interp.av:292`'s `bin_val` branches to
  `null_eq_val` and `bool_eq_val` before the int path, and
  `llvm.av:352`'s `bin_value` is a straight op table. Float is a **third
  operand branch in each**, not a `BinF` variant. This is `SwitchStart`
  reusing `ArmEnd`/`RegionEnd` again: one mechanism, two engines.
- **`Un` does not grow.** `UnOp` is `{ Not }` today. Float negation is
  `0.0 - x` or a new `UnOp.Neg` — a `UnOp` variant, not an `Ins` variant,
  and `UnOp` has only two consumers (`un_symbol` in ir.av:22 and the two
  engines' `un_value`/`un_val`).
- **Conversions ride `CallRt`.** `float_of(n)` / `int_of(f)` are runtime
  rows, not instructions — "value-producing runtime needs ride CallRt".
  The backend may later peephole them to `sitofp`/`fptosi`; that is an
  optimisation, not a vocabulary question.
- **Text, parsing, formatting all ride `CallRt`.** No question.

**Step 3, PAY THE EIGHT.** For `ConstFloat`:

| consumer | the arm |
|---|---|
| `dst_of` | `.ConstFloat(d, _) -> d,` |
| `body_symbol` | joins the `-> null` run |
| `hosted_symbol` | joins the `-> null` run |
| `interp.step` | `.ConstFloat(d, bits) -> self.put_at(d, Val.F(bits), pc),` |
| `memory_ins` | joins the plain group beside `ConstInt`/`ConstBool` |
| `body_lines` | `r${d} = float ${…}` — **must print the decimal text**, which means `ir_text.av` calls a runtime row to render it (§8) |
| `emit_ins` | `.ConstFloat(_, bits) -> self.define(self.const_double_bits(bits)),` |
| `facts.give` | joins the non-calling run |

Plus `corpus/floats.av` + `.expected` proving eval == native, and an IR
golden showing `r0 = float 1.5`.

**Step 4, THE GUARANTEE.** All eight stay catch-all free; `make vocab`
enforces it.

**Verdict: exactly one new `Ins` variant for the whole float campaign —
`ConstFloat`.**

### 4.3 The bootstrap constraint that decides `ConstFloat`'s payload

**The compiler is written in Avra.** `Ins.ConstFloat(dst: Reg, v: float)`
would put a `float` in the compiler's own source, which the **standing
binary cannot parse**. CLAUDE.md's syntax-change order ("write the new
grammar in the OLD spelling, SAVE the standing binary aside, build the
product with it, rewrite the tree by script, build again") exists for
exactly this, but here there is a cleaner answer that avoids the
two-phase dance entirely:

> **`ConstFloat(dst: Reg, bits: int)`** — the IEEE-754 bit pattern as an
> `int`.

- The compiler's own source never contains a float literal.
- Both engines see the **same 64 bits**, so eval == native is true by
  construction rather than by agreement of two parsers.
- The builder computes the bits by calling a runtime row
  (`avra_f_parse(text) -> int`), so the *lexer*'s text and the *backend*'s
  constant cannot drift.
- The interpreter's `Val.F(bits: int)` needs no float in the interpreter
  either (§6).

The same reasoning applies to `Val`, to `reg_types`, and to every
compiler-internal float. **The compiler manipulates float *bits*; only
the compiled program manipulates *floats*.** This is the single design
decision that makes the whole campaign a one-build change instead of a
save-the-binary-and-pray change.

### 4.4 Bytes and decimal need **zero** new instructions

- **Bytes** is a pointer-riding managed box. It builds through `CallRt`,
  reads through `CallRt`, retains and releases through `Retain`/`Release`
  like every other box. No literal (§1.6) means no `ConstBytes`.
- **decimal**, if boxed (§11), is the same story. If it is ever made a
  packed 64-bit scalar, it would want a `ConstDecimal` by the same
  argument as `ConstFloat`.

---

## 5. The backend — and the i64 audit

**This was the assignment's highest-risk unknown. The answer: the
compiler does NOT assume every value is i64 or a pointer, and the LLVM
type machinery is already fully type-driven — but there are exactly four
seams where a `double` register meets an `i64` slot, and every one of them
is a silent LLVM verification failure or a wrong answer.**

### 5.1 What is already type-driven (good news)

`llvm.av:198`, `ll_type_of`, maps `Type` → LLVM type. `Bool` is `i1`, not
`i64`. `Struct` is `flat_or_pointer`. `Opt` is `opt_ll_type`, which builds
`{ i1, <inner> }`. `Alloca` uses `self.reg_type(dst)`. `Load` uses
`self.reg_type(dst)`. `Pack` uses `avra_llvm_get_undef(self.reg_type(dst))`
and `insertvalue`. `region_end` builds the phi at `self.reg_type(dst)`.
`declare_user` types params and return from the signature's shapes.

Every one of these already handles `i1` correctly, which is the proof
that the machinery is not word-shaped: **`bool` is already a non-i64
register category, and it works.** A `double` walks the same path.

The wrapper is even more encouraging: `backend/llvm_wrapper.c:604`,
`avra_llvm_cast_to_type`, **already handles doubles** —

```c
// double ↔ i64: bitcast (preserves bits)
if (ak == LLVMDoubleTypeKind && ek == LLVMIntegerTypeKind) {
    unsigned ew = LLVMGetIntTypeWidth(expected);
    if (ew == 64) return LLVMBuildBitCast(b, val, expected, "cast");
    return LLVMBuildFPToSI(b, val, expected, "cast");
}
if (ak == LLVMIntegerTypeKind && ek == LLVMDoubleTypeKind) { … }
// ptr ↔ double: chain through i64
```

**A warning about that code, not a compliment.** The `ew == 64` branch
*bit-reinterprets* while the `ew != 64` branch *numerically converts*.
Whichever one fires is decided by an integer width the caller did not
think about. `cast_to_type` is called from `call_ptr_value` (every
indirect call's every argument) and from `open_main`. Landing float
without auditing this function is how `2.5` becomes `2` at an indirect
call. **Recommend: make the double↔integer arms of `cast_to_type` refuse
(abort with a named message) rather than guess, and put every deliberate
conversion behind an explicit `avra_llvm_build_bit_cast` /
`build_si_to_fp` / `build_fp_to_si` that the emitter calls by name.**

### 5.2 What the wrapper does NOT have

`packages/std-avrac/src/language/llvm_api.av` is the full extern wall (61
rows). **There is no double type, no float constant, no float
arithmetic, no float comparison, no conversion.** The additions:

| new wrapper fn | LLVM C API |
|---|---|
| `avra_llvm_double_type(ctx) -> ptr` | `LLVMDoubleTypeInContext` |
| `avra_llvm_const_double_bits(ctx, bits: int) -> ptr` | `LLVMConstBitCast(LLVMConstInt(i64, bits, 0), double)` |
| `avra_llvm_build_fadd/fsub/fmul/fdiv/frem` | `LLVMBuildF*` |
| `avra_llvm_build_fcmp(b, pred: int, l, r, name) -> ptr` | `LLVMBuildFCmp`; predicates `LLVMRealOEQ=1, OGT=2, OGE=3, OLT=4, OLE=5, ONE=6` — mirror the existing `icmp` "predicates by number" comment at `llvm.av:349` |
| `avra_llvm_build_si_to_fp` / `avra_llvm_build_fp_to_si` | `LLVMBuildSIToFP` / `LLVMBuildFPToSI` |
| `avra_llvm_build_bit_cast` | `LLVMBuildBitCast` |

Ten wrapper functions, ten `extern fn` rows. `avra_llvm_const_double_bits`
takes **bits**, not a double, for the §4.3 reason: `llvm_api.av` is Avra
source and cannot name a float seat until float exists.

### 5.3 `RtKind` — the one place the language really is i64-shaped

`core/ir.av:219`:

```
export enum RtKind { I64, Ptr, Void }
```

and `core/runtime_api.av:95`:

```
export fn rt_kind_of(types: TypeRegistry, ty: TypeId) -> RtKind {
    if types.shape_of(ty) is .Void { return RtKind.Void }
    if types.rides_pointer(ty) { return RtKind.Ptr }
    RtKind.I64
}
```

**Every non-void non-pointer type is declared `i64` at the C boundary.**
So today an `extern fn f(x: float) -> float` could not be *declared*
correctly even if `float` existed — it would be `declare i64 @f(i64)`,
a double passed in an integer register: silently wrong, the same class as
the extern-width bug lane A closed on 2026-09-05.

The good news, verified: **growing `RtKind` is a registry-column event,
not an eight-consumer event.**

- The only exhaustive `RtKind` match is `ll_rt_kind` (`llvm.av:175`,
  three arms) — the compiler demands the new arm.
- `rt_kind_of` *produces* rather than consumes, so it needs a decision,
  not an arm.
- **The interpreter never matches `RtKind`** — `rt_dispatch`
  (`interp.av:500`) dispatches on `RtHost`. Verified: zero `RtKind`
  matches in `interp.av`.

So `RtKind.F64` is: one enum variant, one `ll_rt_kind` arm, one
`rt_kind_of` branch. Three edits.

### 5.4 The four i64 seams a `double` must cross

These are the concrete hazards. Each is a real LLVM type mismatch today.

**Seam 1 — `rt_arg` (llvm.av:421).** Runtime `I64` params are *slots*
that carry every value category:

```
fn rt_arg(callee: string, j: int, r: Reg) -> ptr {
    …
    if !(sig!.params[j] is .I64) { return v }
    let i64t = avra_llvm_int64_type(self.lc)
    if self.types.rides_pointer(self.tys[r.index]) { return … ptr_to_int … }
    if self.types.shape_of(self.tys[r.index]) is .Bool { return … zext … }
    v
}
```

A `double` register falls through to `v` — a `double` handed to an `i64`
parameter. **Needs a float arm: `bitcast double → i64`.** This one
function covers `avra_array_push` (a `List<float>` element),
`avra_map_set` (a `Map<string, float>` value — its third param is `I64`),
`avra_slot_set` (a boxed record's float field) and
`avra_insist_scalar` (the `float?` insist, whose signature is
`[I64, I64] -> I64`).

**Seam 2 — `call_rt_value` (llvm.av:383), the mirror.** An `I64` answer
into a float destination:

```
if self.types.rides_pointer(self.tys[dst.index]) && self.answers_word(callee) {
    return … int_to_ptr …
}
raw
```

`avra_array_get`, `avra_map_get`, `avra_insist_scalar` all answer `I64`.
Into a `double` register that is an `i64` value in a `double` slot.
**Needs a float arm: `bitcast i64 → double`.**

**Seam 3 — `const_int_value` (llvm.av:307), via `hollow_of`/`zeroed`.**
Already covered in §2.5. The fix belongs in `values.av`'s `hollow_of` (a
`ConstFloat` for the zero), *not* in `const_int_value` — the emission
vocabulary owns the shape, and the backend stays a function of the IR.

**Seam 4 — `same_value` (values.av:55).**

```
export fn same_value(mut cx: LowerCx, a: Reg, b: Reg, ty: TypeId) -> Reg {
    if … is .Enum { return same_tag(cx, a, b) }
    let dst = cx.mint_shape(Type.Bool)
    if … is .Str { cx.emit(Ins.CallRt(dst, "avra_streq", [a, b])) }
    else { cx.emit(Ins.Bin(dst, BinOp.Eq, a, b)) }
    dst
}
```

A `Bin(Eq)` over two float registers becomes an **`icmp`** in
`bin_value`. Fixing `bin_value` to branch on operand type (§4.2) fixes
this seam too, and `same_value` itself needs no change — which is the
generalization argument paying off. `same_value` is reached by
`List.contains`, `List.index_of`, and **literal patterns**
(`features/enums/lower.av:189`, `.Lit(lit) -> same_value(…)`).

### 5.5 Struct field layout, list elements, map values, argument passing

- **A flat record of one float** (`type Cents = { v: float }`) IS the
  double: `flat_or_pointer` (llvm.av:214) answers
  `ll_type_of(flat_fields[0])`. Works with no change — and its
  **nullable** is `Boxed` (`inner_repr`: `is_flat` → `Repr.Boxed`), a
  one-slot heap box whose slot goes through Seams 1 and 2.
- **A boxed record's float field** — `avra_slot_set` / `avra_array_get`,
  Seams 1 and 2.
- **`List<float>`** — `int64_t* data` in `AvraArray`
  (`runtime/avra_runtime.c:514-522`). Slots are 64 bits, so a double's
  bits fit exactly; Seams 1 and 2 do the work. **But `avra_ints_text`
  would print the raw bit pattern** — a `List<float>` needs
  `avra_floats_text` and an arm in `list_text_callee`
  (`lower_walk.av:178`).
- **Argument passing to Avra fns** — `Call`/`CallPtr` pass registers
  directly with `declare_user`-derived types. No change.
- **`CallPtr`** builds the fn type from the site's registers and casts
  every seat with `cast_to_type` — see the §5.1 warning.

### 5.6 What Bytes needs from the backend

**Nothing.** A `Bytes` is a pointer. `ll_type_of` joins the
`avra_llvm_pointer_type` run; `rides_pointer` is true; `rt_arg`'s
existing `ptr_to_int` arm and `call_rt_value`'s existing `int_to_ptr` arm
already carry it. This is the cheapest of the three by an order of
magnitude on the backend side.

---

## 6. The interpreter

`language/interp.av`. `Val` at line 16:

```
enum Val { I(v: int), B(v: bool), S(v: string), A(id: int), C(id: int), M(id: int), N }
```

`Val` is matched at these sites (the ones that matter):

| fn | line | what a new variant owes |
|---|---|---|
| `truth_of` | 102 | `_ -> .Err(…)` — a projection, no change |
| `truth` | 265 | `_ ->` defect — no change |
| `text_val` | 281 | `_ ->` defect — no change |
| `whole` | 591 | `_ ->` defect — **`Val.F` must NOT be silently accepted here** |
| `bin_val` | 292 | **a float branch, beside `null_eq_val` and `bool_eq_val`** |
| `val_text` | 465 | **a `.F` arm** — the interpreter's text projection |
| `const_int_val` | 190 | the backend's twin; unchanged if `ConstFloat` exists |
| `pack_val` / `extract_val` | 201/212 | polymorphic over `Val` — no change |
| `rt_dispatch` | 500 | exhaustive over `RtHost`, not `Val` — new rows get new host arms |

**None of these is an exhaustive `Val` match**, so — unlike `Type` and
`Ins` — **the compiler will not break on a new `Val` variant.** Every one
of the four rows above is a manual edit that the build will not demand.
That asymmetry is worth naming explicitly in the campaign's checklist,
because the tree's whole safety story ("the exhaustive match IS the
registration") does not hold here.

### 6.1 `Val.F` holds bits, not a float

Per §4.3. `Val.F(bits: int)`. The arithmetic then rides the interpreter's
own extern wall — the pattern already in the file, 24 rows deep
(`interp.av:888-910`, `avra_proc_spawn` … `avra_str_from_codepoint`):

```
extern fn avra_f_add(a: int, b: int) -> int      // bits in, bits out
extern fn avra_f_lt(a: int, b: int) -> int
extern fn avra_f_text(bits: int) -> string
```

The interpreter calls the **same C the native binary's `fadd` compiles
to**, so eval == native holds for float by the same construction as
`.ProcSpawn -> Val.I(avra_proc_spawn(…))` does for processes. It is one
step weaker than the instruction-stream guarantee (LLVM's `fadd` and C's
`+` are two implementations of one IEEE operation, not the same code),
which is why a corpus program exercising NaN, ±0, ±Inf, subnormals and
round-tripping is not optional (§10).

### 6.2 `RtHost` and the runtime registry

`core/ir.av:224`, `enum RtHost` — one variant per interpreter host body,
about 60 today. `rt_dispatch` (`interp.av:500`) is **exhaustive over
`RtHost`**, so a new row with a new host **does** break the build. That
is the one place a new runtime row is compiler-enforced.

Adding one runtime fn is: one `RtSig` row in
`core/runtime_api.av:rt_sigs()`, one C body in `runtime/avra_runtime.c`,
one `RtHost` variant, one `rt_dispatch` arm, and (if the interpreter
needs to call the C directly) one `extern fn` row. Five edits, no
dispatch anywhere else — "THE VOCABULARY SEAM RULE": a runtime fn is
**DATA**, a registry row, not behaviour.

### 6.3 Bytes in the interpreter — the trap

`Val.S(v: string)` holds an **Avra** string, and the interpreter is an
Avra program, so `Val.S` inherits the NUL-lossiness measured in §1.6.
A `Bytes` value stored as `Val.S` would compare wrong **inside the
interpreter** while the native binary compares right — an eval/native
divergence that no existing test would catch.

**`Bytes` needs its own `Val` variant.** Options: `Val.Y(id: int)` with a
byte-buffer table beside `arrays`/`maps`/`cells`, or `Val.Y(box: int)`
holding the runtime pointer as an int and doing everything through the C
rows. The second is simpler and matches §6.1's discipline: the
interpreter holds a handle and never inspects the bytes.

---

## 7. The runtime

`runtime/avra_runtime.c`, 2172 lines.

### 7.1 The header

```c
enum { KIND_DEAD = -2, KIND_STATIC = -1, KIND_PLAIN = 0, KIND_ARRAY = 1, KIND_MAP = 2, KIND_STR = 3 };
#define AVRA_TAG 0x41565241u

typedef struct { uint32_t tag; int32_t kind; int32_t rc; uint32_t len; } Header;
```

`hdr(p)` (line 67) refuses an unaligned or sub-image address before
reading anything, then checks the tag. `avra_rc_release` (417) reads the
kind first, then dispatches: `KIND_ARRAY` → `array_reclaim`, `KIND_MAP` →
`map_reclaim`, otherwise `box_free`.

### 7.2 Verifying CLAUDE.md's claim about `str_len`

Read directly (lines 244-276):

```c
static void* box_alloc(size_t size, int32_t kind) {
    size_t bytes = size > 0 ? size : 1;
    …
    h->len = (uint32_t)bytes;
    …
}

static char* str_box(size_t n, int32_t kind) {
    char* buf = (char*)box_alloc(n + 1, kind == KIND_PLAIN ? KIND_STR : kind);
    ((Header*)buf - 1)->len = (uint32_t)n;
    return buf;
}

static size_t str_len(const char* s) {
    Header* h = hdr((void*)s);
    return (h && h->len) ? h->len : strlen(s);
}

static size_t box_bytes(Header* h) {
    return h->kind == KIND_STR ? (size_t)h->len + 1 : (size_t)h->len;
}
```

**Confirmed, with three separate consequences, not one:**

1. **`str_len` distrusts a zero.** An empty string answers 0 only because
   `str_box(0)` allocated 1 byte and `str_owned` (1122) writes
   `buf[n] = '\0'` into it, so `strlen` reads the sentinel. Measured:
   `len(empty substring) = 0`. A box allocated at **exactly** n has no
   such byte, and `strlen` walks into the next allocation.
2. **`box_alloc` clamps zero to one and records the clamp.**
   `box_alloc(0, K)` sets `h->len = 1`, not 0. An empty `Bytes` box built
   naively would report **length 1**. This is CLAUDE.md's "AN ENCODING
   SPENDS THE EMPTY VALUE, so WRITE THE EMPTY CASE FIRST", verbatim, in
   `box_alloc` itself. `str_box` already works around it by overwriting
   `len` after the call; a Bytes constructor must do the same.
3. **`box_bytes` adds one for `KIND_STR` only.** Get the kind wrong and
   the size class is wrong, so a freed box lands on the wrong free list
   and the next `box_alloc` of that class hands out a buffer one byte too
   small. Note also that with `len` correctly 0, `class_of(0) == 0` →
   `box_free` calls `free()` while `box_alloc(1)` came from free list 1
   — an asymmetry that leaks the recycling (not memory). A Bytes
   `box_bytes` arm should answer `len > 0 ? len : 1`.

And a fourth the ROADMAP does not name:

4. **`avra_str_concat` (1253) reads one byte past its second argument**:
   `memcpy(buf + n, b, m + 1)`. It is correct for strings by the same
   spare-byte convention. Any Bytes primitive written by copy-paste from
   the string vocabulary inherits the overread.

### 7.3 What a `Bytes` box looks like

```c
enum { …, KIND_STR = 3, KIND_BYTES = 4 };

// A blob of exactly n bytes. The header's length is AUTHORITATIVE —
// zero is a real length, and nothing here calls strlen.
static void* bytes_box(size_t n) {
    void* p = box_alloc(n, KIND_BYTES);   // clamps 0 -> 1 byte of storage
    ((Header*)p - 1)->len = (uint32_t)n;  // …and the clamp is corrected here
    return p;
}
int64_t avra_bytes_len(const void* b) { Header* h = hdr((void*)b); return h ? (int64_t)h->len : 0; }
```

Plus arms in `box_bytes` (line 280; KIND_BYTES → `len > 0 ? len : 1`) and
`acc_kind_of` (line 234, so `AVRA_MEM_STATS=1` counts blobs as blobs and
not as records).

**The 4 GiB ceiling.** `uint32_t len` caps a box at 4 294 967 295 bytes.
For text that is academic; for a BLOB it is a real limit and a **silent
truncation** — `(uint32_t)n` wraps. A `Bytes` constructor must refuse
`n >= 2^32` with a named trap, or the header must widen. Refusing is
cheaper and honest; widening the header is a change to every box in the
system.

**Bytes must not reuse the string vocabulary.** `avra_streq` is
`strcmp` (line 475) — measured to answer **1** for `"ab\0cd" == "ab"` (§1.6).
Bytes equality is `memcmp` over both header lengths. Same for
`contains`, `index_of`, `split`, `replace`. And `avra_puts` is
`fputs` (lines 463-470), which truncates — printing a blob needs
`fwrite(s, 1, len, stdout)`, or (better) no direct print at all, only a
hex/base64 projection (§8.3).

### 7.4 What float needs from the runtime

No box at all — a double is a machine word. What it needs is a handful
of rows, all `RtKind.F64`/`I64`:

- `avra_f_text(double) -> const char*` — the hard one (§8.1)
- `avra_f_parse(const char*) -> double` (or `-> int64_t` bits, for the
  builder)
- `avra_floats_text(void* arr) -> const char*`
- `avra_f_from_int(int64_t) -> double`, `avra_f_to_int(double) -> int64_t`
  (with a documented rounding mode)
- the interpreter's bit-level twins (§6.1)

**And a `make externs` hole to close.** `tools/externs.py` checks only
`t == "int"`:

```python
narrow = [(n, t, w) for n, t, w in ours
          if t == "int" and not WIDE.search(bodies[n][0])]
```

and its `WIDE` regex does not include `double`. So an
`extern fn f() -> float` backed by a C **`float`** (32-bit) would pass the
gate and return garbage — the exact class the keeper exists to refuse.
**Adding `float` to the language requires adding a `float`/`double` row
to `tools/externs.py` in the same slice.**

---

## 8. Text projection

Two sites in the compiler, both exhaustive `Type` matches, both already
in the §2.2 census:

- **`language/lower_walk.av:144-160`, `print_lowering`** — the program's
  answer. Two matches: `unprintable` (which types have no projection) and
  the projection itself (`.Int -> self.text_call("avra_int_text", last)`).
  Note the comment: "An answer with NO projection refuses HERE, before
  either engine — so eval and native cannot diverge on it."
- **`features/str_lit/lower.av:36-44`, `hole_reg`** — `${x}` in an
  interpolation. Today: `.Str -> v`, `.Int -> avra_int_text`,
  `.Bool -> avra_bool_text`, everything else falls through raw.
- **`lower_walk.av:177`, `list_text_callee`** — `avra_ints_text` /
  `avra_bools_text` / `avra_strs_text`.
- **The interpreter's twin: `interp.av:465`, `val_text`.** These two must
  agree character for character or the corpus goes red.

### 8.1 What a float owes: shortest round-trip

This is the genuinely hard part of the float slice, and it is a **runtime**
problem, not a compiler one.

The requirement: `text(x)` must produce the **shortest decimal string
that parses back to exactly `x`**, so `0.1` prints as `0.1` and not
`0.1000000000000000055511151231257827`. `%.17g` always round-trips but is
unreadable; `%g` (6 digits) is readable but loses values.

**The 12-line answer that is correct and needs no Ryū:**

```c
const char* avra_f_text(double v) {
    if (v != v)            return str_static("NaN");
    if (v == 1.0/0.0)      return str_static("Infinity");
    if (v == -1.0/0.0)     return str_static("-Infinity");
    char buf[40];
    for (int p = 15; p <= 17; p++) {
        snprintf(buf, sizeof buf, "%.*g", p, v);
        if (strtod(buf, NULL) == v) break;      // shortest that round-trips
    }
    …ensure a '.' or an 'e' is present so `2.0` does not print as `2`…
    return str_owned(buf, strlen(buf));
}
```

Three decisions ride on it and each needs a spec line, not a default:

1. **Does `2.0` print as `2` or `2.0`?** `%g` gives `2`. Printing `2`
   makes a float indistinguishable from an int in output, which breaks
   the corpus's whole idea (a `.expected` file that reads `2` for a float
   program). **Print `2.0`.**
2. **`NaN` / `Infinity` spellings.** Pick once, put them in the
   divergence registry, and make both engines read the same constants.
3. **`-0.0`.** `%g` prints `-0`. With the `2.0` rule that becomes `-0.0`.
   Keep it — hiding the sign is a lie about the value.

The interpreter's `val_text` must call the **same C function**, not
reimplement it. `.Text -> Val.S(self.val_text(vals[0]))` already routes
every text projection through one place; a `.F` arm in `val_text` calling
`avra_f_text` keeps the two engines identical by construction.

### 8.2 What decimal owes

Exact, always. A decimal's text projection is *easier* than a float's —
it is the mantissa's digits with the scale's point inserted, no
round-tripping question at all. It is the arithmetic that is hard (§11).

### 8.3 What Bytes owes

**`Bytes` should have no default text projection at all**, and
`print_lowering`'s `unprintable` arm should name it. Reasons:

- The bytes are arbitrary; `fputs` truncates at the first NUL (§7.3).
- Any lossy projection ("<12 bytes>") is the kind of magic P7 forbids.
- A program that wants to see a blob asks: `b.hex()`, `b.base64()`, or
  `b.text()` (which validates UTF-8 and answers `string?`).

`print_lowering`'s refusal already reads well for this:
"the program's answer is a `Bytes`, which has no text projection yet …
project a field instead". Give it a Bytes-specific help naming `.hex()`.

---

## 9. Equality and ordering

### 9.1 Today

`features/expr_spine/check.av`:

- `binary_type` (line 82) — `.Sub or .Mul or .Div or .Mod -> op_over(…, Type.Int, Type.Int)`;
  `.Lt or .Le or .Gt or .Ge -> op_over(…, Type.Int, Type.Bool)`;
  `.Add -> added_type` (Str **or** Int, decided by the left side).
- `wears` (124) — "Whether a shape IS the scalar an operator wants — the
  three the operators speak": `.Int`, `.Bool`, `.Str`, everything else
  false.
- `features/checks.av:454`, `comparable` — `sh is .Int || sh is .Bool || sh is .Str`.
- Lowering: `values.av:55`, `same_value` → `avra_streq` for text,
  `Bin(Eq)` otherwise; enums by tag.
- Runtime: `Bin(Eq)` → `icmp eq` (`llvm.av:357`) / `Val.B(l == r)`
  (`interp.av:313`).

### 9.2 What IEEE-754 does to it

`==` is documented as "compares scalars for now" (CLAUDE.md, quoting
`F2000`). Float breaks two properties that every existing scalar has:

- **NaN != NaN.** `x == x` is false for one value. Every `contains`,
  `index_of`, `Map` lookup and literal pattern built on `same_value`
  inherits it.
- **+0.0 == -0.0** while their bit patterns differ. So `==` and
  "same bits" stop agreeing, and any place that compares *bits* (a map
  key, a memoization key, `canon`) diverges from `==`.
- **Ordering is partial.** `a < b`, `a == b`, `a > b` can all be false.
  `sort` (which the runtime does not have — CLAUDE.md's method list) and
  any future comparator become undefined on NaN.

### 9.3 The recommendation, stated as laws

1. **`==` and `<` on floats are IEEE.** `fcmp oeq` / `fcmp olt`. Do not
   invent a "sane" equality — a language that silently makes NaN equal
   itself is lying to every numerical program, and P7 says the magic must
   be visible.
2. **Refuse float in a `match` literal pattern.** `features/enums/lower.av:189`
   routes `Pat.Lit` through `same_value`; with an IEEE `fcmp` a
   `NaN ->` arm can never fire and `0.0 ->` matches `-0.0`. Both are
   surprises inside a construct whose whole promise is exhaustiveness.
   A named refusal ("a float cannot be a pattern — compare it in a
   `when`") is one voice fn and it is the P1 answer.
3. **Refuse float as a `Map` key.** Map keys are `string` today
   (`Type.Map(key, value)` with a `string` key law at
   `features/maps/check.av:14`), so this is already true and only needs to
   stay true.
4. **`comparable` (checks.av:454) grows a `.Float` arm; `wears`
   (check.av:124) grows a `.Float` arm; `binary_type` grows a float
   branch** that mirrors `added_type`'s left-side-decides shape.
5. **`Bytes` equality is `memcmp` over both lengths**, is total, and is
   the *fix* for the H1 wrong answer rather than a new hazard. `Bytes`
   should be `comparable` and `contains`-able.
6. **`decimal` equality: 1.50 == 1.5?** Numerically yes, but the *scale*
   is data an accountant cares about. Decide and write it down;
   recommend numeric equality with a separate `same_scale` predicate.

---

## 10. Test and proof obligations

`make gate` is `vocab externs idioms tested corpus` (Makefile:143).

### 10.1 `make vocab` — `tools/vocab.sh`

Greps the eight `Ins` consumers and fails on any `_ ->`. **Cost for
float:** the eight arms of §4.2. **Cost for Bytes/decimal:** zero (no new
instruction).

### 10.2 `make externs` — `tools/externs.py`

Today: refuses a C body we own, read as `int`, that answers narrower than
64 bits. **Cost:** the keeper itself must grow a float row (§7.4) —
otherwise adding float *widens a hole in the gate*. This is a
prerequisite of the float slice, not a follow-up.

### 10.3 `make idioms` — `tools/idioms.py`

The baseline lists **sites**, never counts; `--accept` only prunes. New
code is written idiomatic or carries `// LICENSED I<n>: reason` **at the
site**. **The next free idiom number is I39** (I1–I38 are taken;
`I33` was double-allocated once and the tool now refuses a repeated
number by reading its own source). Two idioms this campaign is likely to
discover and must register **at discovery, with a matcher**:

- the value-protocol ladder (`if int_of(v) != null … if text_of(v) != null …`)
  that silently forgets a category — §3.3's four sites are its exemplars;
- the i64-slot crossing (`rt_arg`/`call_rt_value`) that must name every
  register category it coerces.

### 10.4 `make tested` — the spec/given/then suites

81 `*_test.av` files in `std-avrac` alone; 12 packages in `SUITES`.
Every module has tests beside it in `tests/`.

**A new value category owes, at minimum:**

| module | what it must prove |
|---|---|
| `grammar/tests/lexer_test.av` | `1.5`, `1e-9`, `1_000`, `1_000.5` lex; `1.foo` still property; `1..5` still range; `1.` still refuses; `.5` refuses with a help naming `0.5` |
| `features/expr_spine/tests` | float typing, the refusal of `1 + 1.5`, `wears`/`comparable` |
| `features/float_lit/tests` | the feature's own spec/given/then (the scaffold writes the skeleton) |
| `core/tests/types_test.av` | interning, `name_of`, `rides_pointer`, `opt_rides_pointer` for `float?` |
| `language/tests/lower_test.av` | the `float?` pair's pack/extract shape, the `hollow_of` zero, the `ConstFloat` mint order |
| `language/tests/typing_test.av` | the annotation, `F2001` no longer firing on `float`, the *new* unknown-type fixture |
| `features/fns/tests/fns_test.av` | **fix the existing `float` fixture** (§0) |
| `features/type_expr/tests/type_expr_test.av` | **fix the existing `float?` fixture** (§0) |

### 10.5 `make corpus` — eval == native == expected

`corpus/<name>.av` + `corpus/<name>.expected`, run first through the
evaluator then through one native binary (Makefile:99-101). A corpus
program shows its **final statement's expression only**, and only when
that statement IS an expression; an interpolation hole prints scalars and
strings only (a list goes through `join`, an index, or `length`).

**Float needs more than one pair**, because the eval/native agreement for
float is *weaker* than for everything else (§6.1 — LLVM's `fadd` vs C's
`+`):

- `corpus/floats.av` — arithmetic, comparison, `${x}` interpolation
- `corpus/float_edges.av` — `0.1 + 0.2`, `1.0/3.0` round-trip, `-0.0`,
  `1e308 * 10` → Infinity, `0.0/0.0` → NaN, a subnormal
- `corpus/float_nullable.av` — `float?` present/absent, `??`, `!`
- `corpus/bytes.av` — **the empty case FIRST** (CLAUDE.md's law), then a
  blob with an interior NUL proving `.length`, `==` and `contains` all
  agree

Each pair proves eval == native == expected, which is exactly the
property that would have caught the extern-width bug had the width bug
not been an *agreement*.

### 10.6 Golden diagnostic renderings

"Every diagnostic names a registered kind (its F-code is the registry's
projection), carries help or a structured fix where expressible, and has
a golden rendering test." Renderings live in
`packages/std-avrac/src/diagnostics/tests/render_test.av`.

New refusals this campaign will register, each needing a code row and a
golden:

- a float literal in a pattern
- `int` and `float` mixed in an operator (the `op_over` wording)
- a `Bytes` answer with no text projection (extend `F0901`'s help)
- a `Bytes` literal (`b"…"`), refused by name with the reason, so the
  refusal teaches instead of just failing to parse
- a blob past the 4 GiB header ceiling (a runtime trap, worded
  identically in both engines — the divergence registry pins both sides)

### 10.7 The DOGFOODING obligation

Any construct the compiler *wants* while doing this work goes in the
ROADMAP's sugar backlog **naming the wanting site**, as part of the
change that hit it. Two are already predictable: `\u{…}` escapes (already
in the backlog) and a `float` literal in the compiler's own source, which
§4.3 deliberately avoids needing.

---

## 11. The verdict

### 11.1 Ranked, dependency-ordered plan

**Slice 0 — digit separators (`1_000`). Independent, zero risk.**
`is_digit`-run → `digits ("_" digits)*`, strip before `int_value()`. One
file (`grammar/lexer.av`), one test. Nothing can break: `1_000` is
`F0100` today. Land it first because it de-risks the number scanner
rewrite by doing half of it in isolation.

**Slice 1 — `Bytes`. Cheapest, highest ratio, no lexer change at all.**
1. `Type.Bytes` + the 36 arms (mostly one-word joins; the five decisions
   are §2.2's list, and Bytes takes the "pointer, managed" answer at all
   five).
2. `KIND_BYTES = 4`, `bytes_box` writing `len` after `box_alloc`,
   `avra_bytes_len` trusting zero, `box_bytes`/`acc_kind_of` arms, and the
   4 GiB refusal.
3. The Bytes vocabulary as runtime rows: `len`, `slice`, `concat`, `eq`
   (memcmp), `index_of`, `from_string`, `to_string -> string?`, `hex`.
   Each is one `RtSig` row + one C body + one `RtHost` arm + one
   `rt_dispatch` arm.
4. `Val.Y` in the interpreter (§6.3) — the one place Bytes is not free.
5. No backend change, no IR change, no value-protocol change, no literal.

**Risk: low.** The only novel thing is a new box kind, and the runtime
already has four. The empty case is the whole test (§7.3).

**Slice 2 — `float`. The big one.** In this order, because each step
compiles and gates on its own:

1. `RtKind.F64` (three edits, §5.3) + the `tools/externs.py` row. **This
   alone unblocks `extern fn f(x: float) -> float` at the C wall** and is
   worth landing separately.
2. The wrapper: ten `avra_llvm_*` fns + ten `extern fn` rows (§5.2), plus
   the `cast_to_type` audit (§5.1).
3. `Type.Float` + the 36 arms + `shape_named` (`typing.av:316`) +
   `builtin_type_name` + the F2001/F3008 help wording + **the two broken
   fixtures**.
4. The lexer's number state machine + `TokenKind.Float` +
   `term_kind`'s `"FLOAT"` row.
5. `Expr.FloatLit(bits: int)` + fingerprint **tag 52** (the next free tag
   is stated at `core/nodes.av:776`) + the four exhaustive `Expr` sites
   (`place_step`, `pronoun_rides`, `fingerprint_expr`, `semantics_of`)
   **and the four silent ones** (`inert`, `literal`, `literal_shape`,
   `constant_reg` — §3.3).
6. `features/float_lit/` (`avra new feature float_lit`) + its spot in
   `language_features()` beside `bool_lit` + the `Dispatch` field + the
   `program.av` construction.
7. `Ins.ConstFloat(dst, bits)` + the eight consumers + `const_float` in
   the emission vocabulary (`features/emit.av`, beside `const_int`/
   `const_bool` — I33 ratchets that a feature never writes a raw
   `cx.emit(Ins.…)`).
8. **The four i64 seams** (§5.4), and `hollow_of` first among them.
9. Arithmetic and comparison: `bin_value`/`bin_val` float branches,
   `wears`, `comparable`, `binary_type`.
10. `avra_f_text` (§8.1), `print_lowering`, `hole_reg`, `val_text`,
    `avra_floats_text`, `list_text_callee`.
11. The corpus pairs and the goldens.

**Slice 3 — `decimal`. Last, and it needs a design document of its own.**
The representation is not settled and it is the whole slice:

- **Boxed 128-bit + scale** — exact for money, but a heap box means
  `is_managed`, refcounting, and a `Retain`/`Release` on every
  arithmetic result. Arithmetic becomes `CallRt` per operation. Slow, and
  P4 will notice.
- **Packed int64 mantissa + int8 scale in one word** — a scalar, fast,
  fits every existing seam that float fits, but only ~18 significant
  digits and overflow becomes a real operational concern.

**The honest scheduling note: SQLite does not need decimal.** SQLite's
five storage classes are NULL, INTEGER, REAL, TEXT, BLOB. A `decimal`
column is stored as TEXT or INTEGER-scaled by the application. So
`decimal` is **not** on the @std/sqlite critical path at all, and putting
it in the same campaign as float and Bytes is scope the lane did not ask
for. Recommend: land Slices 0–2, ship @std/sqlite, and let decimal earn
its slice from a real wanting site.

### 11.2 The riskiest step, named

**Not the backend.** The backend is already type-driven (`bool` is `i1`
and works), the wrapper already knows about doubles, and the four i64
seams are four functions in one file.

**The riskiest step is `avra_f_text` plus the corpus's `eval == native`
property.** Everywhere else in this tree, eval and native agree *by
construction* — they read the same instruction stream, and a runtime row
is one C body both engines call. Float breaks that: the native path
computes with LLVM's `fadd`, the interpreter with C's `+` through an
extern. They agree for IEEE binary64 under default rounding — but "agree
under default rounding" is a claim about the toolchain, not a
construction, and the failure mode is a corpus that goes red on someone
else's machine or after an LLVM upgrade. Mitigations, in order of value:
(a) never let the native path constant-fold differently from
`avra_f_parse` — carry **bits** from the lexer to the backend (§4.3), so
literals cannot drift; (b) an explicit `corpus/float_edges.av`; (c) no
`ffast-math` anywhere, ever, and a comment saying so beside the emitter.

**The second riskiest is the one that looks free: `hollow_of`.** It is a
five-line function that will *appear* to work (a `ConstInt 0` bitcast to
`double` is `+0.0`), and it will keep appearing to work until the day
something changes the widen. CLAUDE.md has this exact story twice
already — the flat record's nullable, and the `mut x: T? = null` cell.

**The thing that could make the whole campaign much harder than it
looks:** if anyone decides float needs an **implicit int→float widen**.
Today every widen at the `agreed` door (checks.av) is either identity or a
box mint. A `sitofp` is neither. It would mean `accepts` records a
*value conversion*, which touches `unify`, `agreed`, all three unified
seats (call argument, struct field, enum payload), the lowering that
mints the lift, and `corpus/seats.av`. That is a bigger change than
everything in Slice 2 combined. **Refuse the widen. `2 * 0.5` is a type
error with a help that says `2.0 * 0.5`.**

### 11.3 Parallel or sequential — the file collision map

**Verdict: NOT three-way parallel. Bytes and float can run in parallel
only if `core/types.av` is serialized; decimal must wait for both.**

The collisions, by file:

| file | float | Bytes | decimal | verdict |
|---|---|---|---|---|
| `core/types.av` (`Type` enum, `canon`, `ptr_shape`, `name_of`, `substituted`, `args_of`) | ✔ | ✔ | ✔ | **HARD collision** — every lane adds a variant to one enum and an arm to five matches in one file. `canon`'s hand-assigned key strings collide silently if two lanes pick the same one. |
| the 31 other exhaustive `Type` matches (§2.2) | ✔ | ✔ | ✔ | **HARD collision** — the same 31 `or`-runs, edited by three lanes |
| `language/memory.av` `is_managed` | ✔ | ✔ | ✔ | collision (one arm each, adjacent lines) |
| `language/llvm.av` `ll_type_of` | ✔ | ✔ | ✔ | collision |
| `language/lower_walk.av` `print_lowering` ×2 | ✔ | ✔ | ✔ | collision |
| `features/str_lit/lower.av` `hole_reg` | ✔ | ✔ | ✔ | collision |
| `features/unify.av` (8 matches) | ✔ | ✔ | ✔ | collision |
| `grammar/lexer.av` | ✔ | ✘ | ✘ (under `decimal_of`) | **float alone** |
| `core/ir.av` `Ins` + `dst_of`/`body_symbol`/`hosted_symbol` | ✔ | ✘ | ✘ | **float alone** |
| `language/interp.av` `step`/`bin_val`/`val_text` | ✔ | `Val.Y` only | ✘ | mostly float |
| `language/llvm.av` `rt_arg`/`call_rt_value`/`bin_value`/`const_*` | ✔ | ✘ | ✘ | **float alone** |
| `language/llvm_api.av` + `backend/llvm_wrapper.c` | ✔ | ✘ | ✘ | **float alone** |
| `core/runtime_api.av` `rt_sigs()` | ✔ | ✔ | ✔ | **append-only table** — mergeable, but `RtHost` is an enum and `rt_dispatch` is exhaustive, so two lanes adding rows conflict textually every time |
| `runtime/avra_runtime.c` | ✔ | ✔ | ✔ | append-mostly; Bytes also edits `box_bytes`, `acc_kind_of`, the KIND enum |
| `core/nodes.av` `Expr` + fingerprint tag | ✔ | ✘ | ✘ (under `decimal_of`) | **float alone** — and the tag counter ("the next free tag is 52") is a single shared integer |
| `tools/externs.py` | ✔ | ✘ | ✘ | float alone |

**The chokepoint is `core/types.av` and the 36 matches that hang off it.**
Three lanes each adding a `Type` variant means three lanes editing the
same 36 `or`-runs, and CLAUDE.md's own working discipline already warns
what happens when two lanes touch one shared registry
(the duplicate `I33`, which "silently dropped the earlier rule while
`make idioms` kept reporting success"). `canon`'s key strings are the same
hazard with no keeper at all.

**The recommended shape:**

1. **A short shared prelude slice, one agent, on main:** land *all three*
   `Type` variants (`Float`, `Bytes`, `Decimal`) with their 36 arms —
   every arm answering the conservative thing (`ptr_shape` correct,
   `is_managed` correct, everything else refusing) and `shape_named` **not
   yet** naming them, so no program can reach them. Add the `canon` keys.
   Gate. This is mechanical, takes one pass, and it converts the hard
   collision into a merged fact.
2. **Then float and Bytes in parallel**, in separate worktrees. After the
   prelude their files barely overlap: float owns `grammar/lexer.av`,
   `core/ir.av`, `llvm.av`, `llvm_api.av`, `llvm_wrapper.c`,
   `core/nodes.av`, `tools/externs.py`; Bytes owns the runtime's box
   machinery and `Val.Y`. They meet only at `rt_sigs()` (append-only) and
   `RtHost`/`rt_dispatch` (append-only), which conflict textually but
   resolve trivially.
3. **decimal after both**, and only once a wanting site outside
   @std/sqlite names it.

And two discipline notes that apply to any parallel arrangement here,
both from CLAUDE.md and both learned the hard way in this tree:

- **After the prelude merges, every lane's first build is `make
  bootstrap`, never `make avra`** — a stale lane binary cannot read the
  new tree and will fail *pointing at the new code*.
- **One heavy process at a time, in the foreground, under
  `sh tools/watch.sh 4000 make gate`.** Two lanes gating at once is one
  of the two things that has panicked this machine.

---

## Appendix — probes run for this report

All `./avra check` probes are single scratch files, sub-second, no lock
taken. The C probe links this tree's own `build/avra_runtime.o`.

| probe | result |
|---|---|
| `let x: float = 1.5` | `F0100 expected BREAK`, col 17 (the `.`) |
| `let x = 1.5` | `F0100`, col 10 |
| `let x = 1e9` / `.5` / `1_000` / `1.5d` | `F0100`, at the first unaccepted char |
| `fn f(x: float) -> int { 1 }` | `F2001 \`float\` names no type`, help "the types today are `int`, `string`, `bool`, and your declared types" |
| `fn f(b: Bytes) -> int { 1 }` | `F2001 \`Bytes\` names no type` |
| `let x = 1.foo` | `F2003 no property \`foo\` on \`int\`` — **the lexer's disambiguation constraint** |
| `[i for i in 1..5]`, `for i in 0..3`, `1 .. 5` | clean — ranges unaffected |
| `let x = 1.` | `F0100` |
| `let float = 3` / `let int = 3` / `fn int() -> int` | **clean** — no name collision today |
| `type int = { v: int }` | `F3008 \`int\` is a built-in type` |
| `let x = 9223372036854775808` | `F0001 \`…\` does not fit an \`int\`` |
| C probe vs `build/avra_runtime.o` | `len("ab\0cd") = 5`, `streq(ab\0cd,"ab") = 1`, `contains(...,"cd") = 0`, `len(empty substring) = 0`, `len(from_codepoint(0)) = 1` |
