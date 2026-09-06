# The cost of a CORE VALUE CATEGORY

What it takes to add `float`, `Bytes` and (if it is one at all)
`decimal` to Avra, read out of the compiler file by file.

Every claim below cites a path and a line in
`/Users/tristan/projects/tristanMatthias/avra-lane-sqlite` (paths are
written relative to it), a spec section in
`../forge-crafting-intepreters/docs/2026_04_18_FULL_SPEC.md`, or is
marked as inference with its confidence. Nothing here was run: the
tree is read-only for this pass.

---

## 0. The shape of the answer

A value category is FOUR registries and one bootstrap question.

1. **The type surface** — one `Type` variant, and every exhaustive
   dispatch over `Type` gains an arm. There are **thirty** of them
   (§2.1). They break the build; none can be forgotten.
2. **The literal** — one `Expr` variant, one feature directory, one
   grammar branch, one lexer rule, and **four** exhaustive dispatches
   over `Expr` (§2.2).
3. **The instruction** — zero or one `Ins` variant. If one, **eight**
   consumers, enforced by `tools/vocab.sh`.
4. **The runtime** — for a MANAGED category, a box kind, a reclaim
   arm and an accounting arm; for a scalar, an LLVM type and a
   calling convention.

Plus the sites that DO NOT break: positive `is .Int` tests scattered
through typing and lowering (§2.4). Those are the whole risk. The
compiler will build green with a half-landed category and be
silently wrong.

The bootstrap question is §7.1 and it is the most important finding
in this document: **`float` can land without the compiler's own
source ever holding a `float` value.**

---

## 1. Two models, traced end to end

### 1.1 `bool` — a scalar with a literal, a text projection and its own comparison rules

Fourteen sites. This is the floor for any new category.

| # | Site | What it is |
|---|---|---|
| 1 | `packages/std-avrac/src/grammar/lexer.av:314-317` | `true`/`false` lex as `TokenKind.Name` — no lexer change; keywords derive from grammar literals |
| 2 | `packages/std-avrac/src/features/bool_lit/mod.av:16-18` | the gram fragment: `primary = "true" -> true_lit() \| "false" -> false_lit()` |
| 3 | `packages/std-avrac/src/features/bool_lit/mod.av:8-12` | the `BuilderRow` table naming both builders |
| 4 | `packages/std-avrac/src/features/bool_lit/builders.av:5-11` | parse lowering to `Expr.BoolLit(true/false)` |
| 5 | `packages/std-avrac/src/core/nodes.av:166` | `Expr.BoolLit(value: bool)` |
| 6 | `packages/std-avrac/src/core/nodes.av:268-273` | the value protocol's projection `bool_of` |
| 7 | `packages/std-avrac/src/core/types.av:16` | `Type.Bool` |
| 8 | `packages/std-avrac/src/features/bool_lit/semantics.av:10-12` | `type_of` answers `Type.Bool` |
| 9 | `packages/std-avrac/src/features/bool_lit/semantics.av:14-20` | `lower` emits `Ins.ConstBool` |
| 10 | `packages/std-avrac/src/core/ir.av:52` | `Ins.ConstBool(dst, v)` — its OWN instruction, not a `ConstInt` |
| 11 | `packages/std-avrac/src/language/llvm.av:203` | `ll_type_of` answers `i1` |
| 12 | `packages/std-avrac/src/language/interp.av:18` | `Val.B(v: bool)` |
| 13 | `packages/std-avrac/src/language/mod.av:132` | `bool_lit()` in `language_features()` — feature order IS branch order |
| 14 | `packages/std-avrac/src/language/program.av:45` | `bools: BoolSemantics { }` in `new_dispatch` |

`bool` also owns three behaviours no other scalar has, each a
separate site:

- **Its own `Bin` path in the interpreter.** `bin_val`
  (`language/interp.av:296-320`) tests `is .B && is .B` FIRST and
  routes to `bool_eq_val` (`:334-343`), because `int_val` on a
  `Val.B` would defect. A float needs the same guard, in the same
  place, before the int fallthrough.
- **Its own coercion at the runtime seam.** `rt_arg`
  (`language/llvm.av:432-446`) zero-extends an `i1` into an `I64`
  slot; `call_rt_value` (`:383-394`) narrows an `i64` answer back to
  `i1` with `icmp ne 0`.
- **Its own zero.** `hollow_of` (`features/values.av:365-372`)
  special-cases `.Bool` to emit `ConstBool(false)` because `zeroed`
  (`:260-263`) emits `Ins.ConstInt(z, 0)`, which is the wrong LLVM
  type for an `i1` register.

That last one is the template for every scalar that is not an `i64`.
**A new scalar category that skips `hollow_of` produces an LLVM phi
with mismatched incoming types and the verifier kills the build**
(HIGH — the arm exists precisely because `bool` hit it).

### 1.2 `string` — the MANAGED model

Everything above, plus:

| Site | What it is |
|---|---|
| `core/types.av:18` | `Type.Str`, doc'd as "the first MANAGED value: a headered box the runtime reclaims at count zero" |
| `core/types.av:120-122` | `ptr_shape` says `.Str -> true` |
| `language/memory.av:32` | `is_managed` says `.Str -> true` — the retain/release law |
| `language/llvm.av:206-207` | `ll_type_of` answers `avra_llvm_pointer_type` |
| `language/interp.av:19` | `Val.S(v: string)` |
| `core/ir.av:51` | `Ins.ConstStr(dst, s)` |
| `backend/llvm_wrapper.c:460-483` | the constant's emission: a HEADERED global (tag `AVRA_TAG`, kind `-1` STATIC, rc 0, len) with the payload pointer GEP'd sixteen bytes in |
| `runtime/avra_runtime.c:264-268` | `str_box` — the allocation shape |
| `runtime/avra_runtime.c:271-275` | `str_len` — the header's length |
| `runtime/avra_runtime.c:277-281` | `box_bytes` — `KIND_STR` is `len + 1`, everything else `len` |
| `runtime/avra_runtime.c:234-236` | `acc_kind_of` — which accounting bucket |
| `features/values.av:54-64` | `same_value` — `==` routes to `avra_streq`, not `Ins.Bin` |
| `features/str_lit/lower.av:33-43` | `hole_reg` — the interpolation text projection |
| `language/lower_walk.av:126-160` | `print_lowering` — the program-answer text projection |
| `core/runtime_api.av:50-64` | fourteen `RtSig` rows for the text vocabulary |
| `features/str_lit/mod.av:20-36` | ten `MethodRow`s and one `PropertyRow` |

The managed delta over `bool` is exactly: **one `ptr_shape` arm, one
`is_managed` arm, one box kind, one `box_bytes` arm, one
`acc_kind_of` arm, one `same_value` branch, and a `ConstX`
instruction whose backend emission builds a headered global.**

---

## 2. The four registries, enumerated

### 2.1 The thirty exhaustive `Type` dispatches

Every one of these has no `_ ->`. A new `Type` variant breaks all
thirty at compile time. This list is the authoritative answer to
"what does a new type cost"; it was derived by grepping for
`.EmptyMap` (the last variant added, which every exhaustive match
must therefore name).

| File:line | Fn | What it decides |
|---|---|---|
| `core/types.av:118-125` | `ptr_shape` | does the value ride a pointer |
| `core/types.av:130-153` | `TypeRegistry.canon` | the interning key — **a new variant needs a fresh key string; `"0"`..`"18"` and `"ptr"` are taken, next free is `"19"`** |
| `core/types.av:263-281` | `substituted` | generic substitution (a leaf passes through) |
| `core/types.av:284-307` | `name_of` | THE printing projection — the type's surface word |
| `core/types.av:311-321` | `args_of` | the type's positional arguments |
| `features/unify.av:31-46` | `unify` | Var binding; a leaf unifies by interned id |
| `features/unify.av:84-92` | `elem_unifies` | list element |
| `features/unify.av:95-103` | `value_unifies` | map value |
| `features/unify.av:110-118` | `carried_unifies` | nullable payload |
| `features/unify.av:131-143` | `slot_worthy` | may a box slot hold it |
| `features/unify.av:149-161` | `unlawful_side` | re-judged representation after substitution |
| `features/unify.av:172-187` | `fully_bound` | are all Vars pinned |
| `features/contexts.av:11-18` | `fields_of_type` | a record's fields |
| `features/contexts.av:22-31` | `variants_of_type` | an enum's variants |
| `features/contexts.av:143-151` | `declared_decl` | which declaration a shape names |
| `features/variants.av:68-79` | `wants_decl` | is this type that declaration's |
| `features/values.av:425-436` | `length_word` | the runtime measure verb |
| `features/expr_spine/check.av:117-126` | `wears` | does a shape satisfy an operator's want |
| `features/expr_spine/check.av:158-173` | `compare_help` | the refusal's remedy |
| `features/enums/mod.av:65-73` | `on_enum` | the property row's receiver test |
| `features/impls/callee.av:~30-45` | (method receiver) | can this shape carry an impl |
| `features/impls/callee.av:~55-68` | (method receiver, 2nd) | ditto |
| `features/str_lit/lower.av:33-43` | `hole_reg` | the interpolation text projection |
| `language/memory.av:31-45` | `is_managed` | THE ownership law |
| `language/lower_walk.av:87-95` | `boxed_decl` | which declaration a `dyn` box carries |
| `language/lower_walk.av:126-146` | `print_lowering` (unprintable) | does the answer have a text projection |
| `language/lower_walk.av:147-158` | `print_lowering` (text) | which projection |
| `language/llvm.av:198-209` | `ll_type_of` | the machine type |
| `language/receivers.av:186-194` | `writable` | can a callee write back through this seat |
| `language/receivers.av:239-252` | `callee_of` | what a name on this shape calls |

Rule of thumb from this table: **a scalar answers "no/false/null" in
about twenty-two of the thirty and needs a real answer in eight** —
`canon`, `name_of`, `ll_type_of`, `is_managed`, `ptr_shape`,
`slot_worthy`, `print_lowering` twice. A managed category needs real
answers in eleven (add `length_word`, `hole_reg`, `writable`).

### 2.2 The four exhaustive `Expr` dispatches

Only needed if the category has its own LITERAL node.

| File:line | Fn | Owed |
|---|---|---|
| `core/nodes.av:676-690` | `NodeStore.place_step` | a literal is not a place — the `null` or-run |
| `core/nodes.av:727-760` | `NodeStore.pronoun_rides` | a literal carries no `it` — the `false` or-run |
| `core/nodes.av:774-830` | `NodeStore.fingerprint_expr` | a FRESH tag. **The comment at `:776` says "the next free tag is 52" and is STALE — tags 1–60 are in use (29 and 41 skipped) plus 61 at `Comp`. Next genuinely free: 62.** |
| `features/dispatch.av:54-74` | `semantics_of` | route to the owning feature's boxed semantics |

`semantics_of` routing also means a field on `Dispatch`
(`features/dispatch.av:12-48`) and a line in `new_dispatch`
(`language/program.av:43-56`).

One near-miss that does NOT break: `NodeStore.inert`
(`core/parts.av:64-69`) uses `_ -> false`. A new literal falls into
"may act", so `defer 3.14` would not earn the inert warning. Cosmetic.

### 2.3 The eight exhaustive `Ins` consumers

Only if the category needs an instruction (§7). `tools/vocab.sh`
holds the authoritative list and FAILS the gate if any of them grows
a `_ ->`:

| File | Fn | Decides |
|---|---|---|
| `core/ir.av:151-174` | `dst_of` | the register it defines |
| `core/ir.av:180-194` | `body_symbol` | the program body it names |
| `core/ir.av:199-214` | `hosted_symbol` | the hosted fn it calls |
| `language/interp.av:157-182` | `step` | its meaning, interpreted |
| `language/memory.av:60-200` | `memory_ins` | its ownership effect |
| `language/ir_text.av:20-96` | `body_lines` | its human projection |
| `language/llvm.av:268-300` | `emit_ins` | its machine projection |
| `features/facts.av:335-357` | `Emitter.give` | whether the runtime registry validates it |

Plus, per `core/ir.av:40`, a corpus program proving eval == native
and an IR golden. `avra new ins <Name>` prints the checklist
(`packages/cli/src/commands/new.av:75`).

`Ins` has 29 variants today. CLAUDE.md's protocol says re-measure the
"one spec file per instruction" question at ~40; two more (§7) does
not reach it.

### 2.4 THE SILENT SITES — what will NOT break the build

This is the list that matters. Each is a positive `is .Int` /
`is .Str` test. A new category simply falls through, and the compiler
builds green with wrong behaviour.

| File:line | Fn | Silent failure if a new scalar is not added |
|---|---|---|
| `features/checks.av:424-428` | `comparable` | `==` on the new type is refused with "compares scalars for now" — visible, at least, but wrong |
| `features/values.av:54-64` | `same_value` | falls to `Ins.Bin(Eq)` — for `Bytes` that compares POINTERS and silently answers `false` for two equal blobs. This is the divergence class `features/expr_spine/check.av:203-206` records as having bitten once already |
| `features/str_lit/check.av:7-17` | `interp_type` | `"${x}"` refuses the new type — visible |
| `features/expr_spine/check.av:93-96` | `added_type` | `+` routes to the INT law: `1.5 + 2.5` refuses with "`+` needs `int` operands" |
| `features/expr_spine/lower.av:102-115` | `binary_reg` | `==`/`!=` for a managed category never reaches the value-equality verb |
| `features/loops/check.av:37-44` | `range_bound` | `for x in 0.0..1.0` refuses — correct, and should stay so |
| `features/maps/methods.av:117` | (map key) | map keys stay `Str` — correct |
| `language/lower_walk.av:175-178` | `list_text_callee` | **`List<float>` would print through `avra_ints_text`, showing bit patterns as integers.** The nastiest silent site in the tree: a two-line if-ladder with an int default |
| `features/lists/methods.av:140` | `check_join` | `join` refuses non-text lists — correct |
| `runtime/avra_runtime.c:234-236` | `acc_kind_of` | a new box kind lands in the `records` accounting bucket — a reporting error only |

**Recommendation, and it is cheap:** before landing either category,
convert `comparable`, `same_value`'s branch and `list_text_callee`
from positive tests into exhaustive matches. They are three small
edits and they turn the whole silent class into compile errors. Do
this FIRST, as a standalone slice, so the category's own slice cannot
regress them.

---

## 3. The LEXER

`packages/std-avrac/src/grammar/lexer.av`, 508 lines. It is the only
file that changes.

**Today** (`:303-339`, `scan_step`), the ordered `when`:

```
c == 10            -> Break
is_space(c)        -> skip
"//"               -> skip to line end
is_name_start(c)   -> Name
is_digit(c)        -> { j = scan_while(src, n, i + 1, is_digit); numbered(...) }
'"""' / '"'        -> Str / IStr pieces
'@'                -> Pkg
two_char_at(...)   -> Op          // "->" "==" ".." "!=" "<=" ">=" "&&" "||" "??" "?."
is_single_op_code  -> Op
_                  -> refused
```

So today, with HIGH confidence (read directly from the scanner):

| Source | Tokens today |
|---|---|
| `1.5` | `Num("1")` `Op(".")` `Num("5")` |
| `1e9` | `Num("1")` `Name("e9")` |
| `1_000` | `Num("1")` `Name("_000")` |
| `1..5` | `Num("1")` `Op("..")` `Num("5")` — the range, and it must keep working |
| `.5` | `Op(".")` `Num("5")` |
| `0x2A` | `Num("0")` `Name("x2A")` |

`1.5` then parses as a postfix `.` step (`features/expr_spine/mod.av:40`
wants `p:NAME` after the dot) against a `Num` token, which fails
(MEDIUM — the exact refusal text was not probed; the token sequence
is HIGH).

**What changes.** ONE arm, replacing the `is_digit` arm at `:318-322`:

```
is_digit(c) -> scan_number(src, n, i)
```

`scan_number` is a new fn beside `numbered` (`:109-117`). Its
contract, driven by spec §31.5 (`FULL_SPEC.md:6364-6404`):

1. Scan the integer run, accepting `_` between digits (never leading,
   never trailing, never doubled).
2. A `.` is part of the number **only if the next character is a
   digit.** This is the whole rule that keeps `1..5` a range. `.5`
   therefore stays two tokens — matching the spec, whose float
   examples all lead with a digit.
3. After the optional fraction, `e`/`E` with an optional `+`/`-` and
   at least one digit is the exponent. `1e9` must consume the `e9`,
   which today lexes as a `Name` — this is the arm's second job.
4. Prefixes `0x`/`0o`/`0b` scan integers only, no fraction, no
   exponent (spec explicitly forbids implicit octal — `077` is 77).
5. Suffixes `f32`/`f64`/`float`/`i64`/… — reserve the SHAPE now,
   accept `float` only if you want it; systems-level widths are
   spec-reserved for v1.x, so refuse the rest with a named
   diagnostic rather than lexing them as an adjacent `Name`.

**Which token kind.** Two options; take the second.

- (a) Reuse `TokenKind.Num` and let the builder read the text.
  Cheapest. But `grammar/first.av:150-158` (`subsuming_term`) maps
  any digit-leading literal to `"NUMBER"`, and the dead-branch gate
  would then see `NUMBER` matching both `int_lit` and `float_lit` in
  `primary` — an ordered-choice overlap the assembly refuses
  (`grammar/validate.av`, `first_defects`). MEDIUM confidence it
  actually fires; the risk is real and the fix costs nothing.
- (b) **A new `TokenKind.Float`.** Then `primary = v:FLOAT ->
  float_lit(v)` is a distinct terminal and the first-set gate is
  satisfied by construction.

Option (b)'s cost, exhaustively:

| File:line | Edit |
|---|---|
| `grammar/lexer.av:25` | `TokenKind` gains `Float` |
| `grammar/lexer.av:34-39` | `Token.lit_matches` — an exhaustive match over `TokenKind`; `Float` joins the `Name or Num or Op or Break or Pkg` text-equality run |
| `grammar/lexer.av:45-56` | `Token.int_value` stays; a sibling `float_bits()` is added (§7.1) |
| `grammar/lexer.av:109-117` | `numbered` keeps the int-overflow refusal; `scan_number` calls it for integers |
| `grammar/validate.av:11-25` | `term_kind` gains `"FLOAT" -> TokenKind.Float` |
| `grammar/first.av:150-158` | `subsuming_term` — leave alone; the new terminal is not literal-subsumed |

`grammar/executor.av` needs nothing: it matches terminals by kind
(`:500`), and `grammar/ast.av:83-88`'s `Prim.Named` carries the term
name as data.

**For `Bytes`:** the literal is `b"..."` (spec §28.3,
`FULL_SPEC.md:5570`). `b` is `is_name_start`, so today `b"x"` lexes
as `Name("b")` then `Str("x")`. The lexer needs a lookahead in the
`is_name_start` arm: a single `b` immediately followed by `"` opens a
byte string. Escapes: spec says "no escape processing beyond the
usual", so `\x41` and `\0` must both work — and `\0` is exactly the
embedded NUL the whole `Bytes` category exists for. Note the tree's
`unescape` (`grammar/lexer.av:192-202`) knows five escapes and keeps
an unknown one as its two raw characters (this is the already-recorded
`\u` gap in CLAUDE.md's subset list). `\x` and `\0` are new arms
there.

---

## 4. The GRAMMAR and the feature directory

Yes — one directory per literal category. `features/bool_lit/` is
three files and 55 lines; `features/str_lit/` is four files and 211.

`avra new feature <name>` scaffolds it
(`packages/cli/src/commands/new.av:45-62`), and the scaffolder's own
output is a gate case (`Makefile:138-141`).

**`features/float_lit/mod.av`** — the manifest:

```
export fn float_lit() -> LanguageFeature {
    let rows = table<BuilderRow> {
        name        | build
        "float_lit" | build_float_lit
    }
    component LanguageFeature f {
        name = "float_lit"
        docs = "IEEE-754 double literals — `3.14`, `2.5e-3`; the float vocabulary."
        gram = grammar {
            primary = v:FLOAT -> float_lit(v)
        }
        builders = rows
        diags = codes
        methods = methods
    }
    f
}
```

`LanguageFeature`'s config is at `features/mod.av:112-124`: `name`,
`docs`, `gram`, `builders`, `diags`, `methods`, `types`,
`properties`, `remedies`.

**`builders.av`** — `build_float_lit(mut b: Builder) ->
Result<LangNode, string>`, mirroring
`features/expr_spine/builders.av:6-11`.

**`semantics.av`** — `impl NodeSemantics for FloatSemantics` with
`type_of` answering `Type.Float` and `lower` emitting `Ins.ConstFloat`,
mirroring `features/bool_lit/semantics.av`.

**`check.av` / `lower.av`** — the method rows (`to_int`, `abs`,
`is_nan`, …) and their lowerings, by concern, as `str_lit` splits
them.

**Registration**, two lines: `use features.float_lit.{float_lit}` and
a position in `language_features()` (`language/mod.av:118-165`).
**Position matters and it is easy.** `FLOAT` is not NAME-headed and
not keyword-anchored, so it goes beside `expr_spine()` — after every
keyword anchor, before the `expr_stmt()` floor. Put it immediately
after `expr_spine()`.

`bytes_lit` is the same shape. Its literal is `b"..."`, which IS
NAME-headed in the raw text but not in tokens once the lexer owns
`b"` (§3) — the terminal is `BYTES`, so the same position works.

**Grammar-authoring traps that apply here** (CLAUDE.md, all already
paid for by other features): a `@expect` attaches only at a
sequence's tail; only the LAST branch sharing an anchor may
`@recover`; a keyword anchor merges before every NAME-headed branch.
A one-branch `primary = v:FLOAT -> float_lit(v)` trips none of them.

---

## 5. `core/types.av` — the type surface

335 lines, and every part of it is touched.

- **The variant.** `Type.Float` beside `Int`/`Bool`/`Str`/`Ptr`
  (`:13-21`, the "one unmanaged register each" block). `Type.Bytes`
  goes beside `Str` in the MANAGED comment's company.
- **`TypeId`** (`:7`) is `{ index: int }` — nothing to do.
- **`canon`** (`:130-153`) — a fresh key. Taken: `"0"` Int, `"ptr"`,
  `"1"` Error, `"2"` Str, `"3"` Bool, `"4"`–`"18"` composites. Use
  `"19"` for Float, `"20"` for Bytes. **A repeated key silently
  aliases two types into one id** — the same class of bug the idiom
  tool's duplicate-number check was written for (CLAUDE.md).
- **`intern`** (`:156-168`) — generic, no change; the parallel
  `flats` table gets its blank row automatically.
- **`ptr_shape`** (`:118-125`) — `Float` joins the `false` run,
  `Bytes` the `true` run.
- **`rides_pointer`** (`:248-258`) — delegates to `ptr_shape`, no
  change.
- **`name_of`** (`:284-307`) — `"float"`, `"Bytes"`. This is THE
  printing projection; every diagnostic's type word comes from here.
- **`args_of`** (`:311-321`), **`substituted`** (`:263-281`) — both
  leaf arms.
- **The registration of a primitive TYPE NAME** is NOT in this file:
  it is `shape_named` in `language/typing.av:315-323`, a five-arm
  match (`"int"`, `"string"`, `"bool"`, `"void"`, `"ptr"`). Add
  `"float" -> Type.Float`. `builtin_type_name` (`:309-312`) reads it,
  and F3008 ("a built-in type name cannot be redeclared") starts
  firing on the word.

**Two existing tests break the moment `float` becomes a type word,
and they are the canary:**

- `packages/std-avrac/src/features/fns/tests/fns_test.av:85-87` —
  asserts `analyze_source("fn f(x: float) -> int { 1 }\nf(1)")`
  reports `` `float` names no type ``.
- `packages/std-avrac/src/features/type_expr/tests/type_expr_test.av:37`
  — the same assertion for `float?`.

Both use `float` as the canonical "not a type" word. Rewrite them
with a word that stays unknown (`quaternion`).

**`TypeRow`** (`features/mod.av:73`) is the OTHER way to add a type —
a generic constructor (`List`, `Map`, `Result`) with an arity and a
`builds` fn. `float` and `Bytes` are arity-0 primitives, so they are
`shape_named` entries, not `TypeRow`s. HIGH confidence: every
existing arity-0 primitive lives in `shape_named`.

---

## 6. The VALUE PROTOCOL

`core/nodes.av:266-306`. Five projections today: `bool_of`,
`int_of`, `text_of`, `pairs_of`, `elems_of`.

CLAUDE.md states the law and its reason: *"A protocol read is NEVER
`?? <a plausible default>`"* and *"N variants need N projections —
payload types differ, and a unified return would be the parallel
Value enum the doctrine refuses."* That is literal: `bool_of` answers
`bool?`, `text_of` answers `string?`, `elems_of` answers
`List<ExprId>?`. Avra has no sum-of-payloads to unify them into that
is not the `Expr` enum itself.

So each new category owes at most one projection — **and only at its
SECOND reader.** The doctrine is explicit that `int_of` was added
when the const feature became a second reader, and that a projection
with one reader is dead code (`core/nodes.av:274-277`).

- `float_of(e: Expr) -> int?` — answering the BIT PATTERN, not a
  float (§7.1). First reader is `features/float_lit/semantics.av`'s
  `lower`. Second reader is `features/contexts.av:196-201`
  (`literal_shape`, which settles a `const`'s type from its literal)
  — so it earns the projection immediately, on the same slice.
- `bytes_of(e: Expr) -> string?` — the raw payload. Same two readers.

`features/contexts.av:196-201` `literal_shape` is the site to watch:

```
fn literal_shape(value: Expr) -> Type? {
    if int_of(value) != null { return Type.Int }
    if text_of(value) != null { return Type.Str }
    if bool_of(value) != null { return Type.Bool }
    null
}
```

Miss it and `const PI = 3.14159` types as the absorbing Error — a
silent site, not a build break.

---

## 7. `core/ir.av` — and the VOCABULARY SEAM decision

### 7.1 THE BOOTSTRAP FINDING — carry BITS, not floats

The compiler is written in Avra and compiled by the standing
`build/avra`. Therefore:

**`Expr.FloatLit(value: float)` cannot be written until `float`
already exists.** Nor can `Ins.ConstFloat(dst, v: float)`, nor
`Val.F(v: float)` in the interpreter, nor `Token.float_value() ->
float?` in the lexer. Every one of them is a chicken-and-egg.

CLAUDE.md's working discipline names the general escape ("A SYNTAX
CHANGE TO THE COMPILER'S OWN SOURCE runs in one order: write the new
grammar in the OLD spelling, save the standing binary aside, build
the product with it, rewrite the tree by script, build again"). That
works for SYNTAX. It does not work for a new VALUE, because the
intermediate product would have to hold float values in its own
tables before it can compile them.

**The way through: the compiler never holds a float. It holds the
IEEE-754 bit pattern as an `int`, plus the literal's source text.**

```
Expr.FloatLit(bits: int, text: string)
Ins.ConstFloat(dst: Reg, bits: int)
Val.F(bits: int)                        // the interpreter
Token.float_bits() -> int?              // the lexer
```

- `text` rides along so `avra ir` and every diagnostic can print
  `3.14` rather than `4614253070214989087`, and so a future exact
  round-trip has the writer's own spelling to fall back on.
- Decimal-text to bits is `strtod`, correctly rounded, once, in C:
  one `RtSig` row `avra_f64_parse(ptr) -> I64` (§11). The compiler is
  a native binary that links the runtime, so its lexer can call it.
  Under `avra run` it is hosted like any other row.
- The interpreter's arithmetic is `avra_f64_add(a_bits, b_bits) ->
  bits` and friends: the SAME C the native binary's `fadd` computes,
  so eval == native holds by IEEE, not by hope.
- Native codegen bitcasts once at the constant
  (`LLVMConstBitCast(i64 bits, double)`) and then uses real
  `fadd`/`fmul`/`fcmp` — full speed, no boxing, P4 intact.

Cost of this choice: **zero.** Nothing in the language's SURFACE
changes; `let x: float = 3.14` is a float everywhere a program can
see. Only the compiler's own internal payload is an int. And it is
permanently defensible — bits are the canonical representation, and
carrying them removes the whole class of "the compiler's float and
the target's float disagree" cross-compilation bugs.

**Recommendation: ship it this way and do not plan a stage 2.**
Rewriting `FloatLit(bits)` to `FloatLit(value: float)` later buys
nothing and costs a whole-tree migration.

### 7.2 DATA or BEHAVIOR? — the seam rule applied

CLAUDE.md: *"is the item DATA or BEHAVIOR? DATA (a runtime fn: name,
param kinds, ownership) -> a REGISTRY ROW. BEHAVIOR (an instruction:
five different per-pass meanings) -> the ENUM plus exhaustive
dispatch."*

Three separate questions, three different answers.

**(a) The float CONSTANT — an instruction. `Ins.ConstFloat(dst, bits)`.**

The tempting alternative is to reuse `Ins.ConstInt(dst, bits)` and let
the DESTINATION'S TYPE decide the meaning — which is exactly what the
tree already does for the null pointer:

```
// language/llvm.av:307-312
fn const_int_value(dst: Reg, v: int) -> ptr {
    if self.types.rides_pointer(self.tys[dst.index]) {
        return avra_llvm_const_pointer_null(...)
    }
    avra_llvm_const_int(avra_llvm_int64_type(self.lc), v, 1)
}
// language/interp.av:189-192 — the twin
```

It would work, and it costs zero consumers. **Reject it, for P7.**
`avra ir` would print `r3 = int 4614253070214989087` where the source
said `3.14`, and the IR is the tree's inspectability contract. The
protocol's JUSTIFY clause 1 names "a new value category" as a
qualifying reason, so `ConstFloat` is licensed on its face.
`ir_text.av` then prints `r3 = float 3.14` from the carried text.

**(b) Float ARITHMETIC — NOT an instruction. Reuse `Bin`.**

This is GENERALIZE BEFORE ADDING, and it is the same move
`SwitchStart` made by reusing `ArmEnd`/`RegionEnd`. `Ins.Bin(dst, op,
a, b)` already carries the operator; the OPERAND'S STATIC TYPE decides
whether the machine emits `add` or `fadd`. Adding `FAdd`/`FSub`/… as
seven more `BinOp`s would double every `bin_value` and `bin_val`
dispatch for no gain.

The consequence is a signature change:

- `language/llvm.av:352-370` — `bin_value(op, a, b)` today receives
  only LLVM values and cannot know the type. It must become
  `bin_value(op, a_reg, b_reg)` (or take a `TypeId`) so it can ask
  `self.tys[a.index]`. The call site is `emit_ins`'s
  `.Bin(_, op, a, x)` arm at `:273`, which currently discards the
  registers.
- `language/interp.av:296-320` — `bin_val` already dispatches on the
  VALUE (`is .N`, then `is .B`, then int). A `is .F && is .F` guard
  slots in before the int fallthrough, exactly where `bool_eq_val`'s
  guard sits.

**This is CLAUDE.md's "A READ WEARS THE TYPE OF WHAT IS READ" law in
its fifth instance:** the opcode wears the OPERAND'S type, never the
instruction's or the destination's.

**(c) The float RUNTIME VERBS — registry rows.** `avra_f64_parse`,
`avra_f64_text`, `avra_f64_from_int`, `avra_f64_to_int`,
`avra_f64_add/sub/mul/div` (the interpreter's arithmetic host),
`avra_f64_eq/lt`. Each is one row in `rt_sigs()`, one C body, one
`RtHost` variant. Nothing dispatches.

**Net: exactly ONE new instruction for `float`.** `ConstBytes` makes
two if `Bytes` lands in the same campaign.

### 7.3 The eight consumers, per new instruction

For `Ins.ConstFloat(dst: Reg, bits: int)`:

| Consumer | Arm |
|---|---|
| `core/ir.av:151-174` `dst_of` | `.ConstFloat(d, _) -> d` |
| `core/ir.av:180-194` `body_symbol` | joins the `null` or-run |
| `core/ir.av:199-214` `hosted_symbol` | joins the `null` or-run |
| `language/interp.av:157-182` `step` | `.ConstFloat(d, bits) -> self.put_at(d, Val.F(bits), pc)` |
| `language/memory.av:60-200` `memory_ins` | joins the `manages(...)` or-run beside `ConstInt`/`ConstBool` — a float is unmanaged |
| `language/ir_text.av:20-96` `body_lines` | `r${d} = float ${text}` |
| `language/llvm.av:268-300` `emit_ins` | `.ConstFloat(_, bits) -> self.define(self.const_float_value(bits))` |
| `features/facts.av:335-357` `give` | joins the `null` (no callee) or-run |

Plus `corpus/float.av` + `.expected`, plus an IR golden.

---

## 8. The LLVM BACKEND

`packages/std-avrac/src/language/llvm.av` (579 lines),
`packages/std-avrac/src/language/llvm_api.av` (61 lines, the extern
wall), `backend/llvm_wrapper.c` (647 lines).

### 8.1 The wrapper is missing every float builder

`llvm_api.av` declares 59 externs. **Not one is a float builder.**
There is no `double_type`, no `const_real`, no `fadd`, no `fcmp`, no
`sitofp`. ROADMAP explains why: the review round that shrank the
wrapper from 1643 lines to 640 *"deleted 73 — a coverage subsystem, a
JIT and its `@comptime` string copier, **float and bit ops**,
`emit_object`, the `split_defines` IR splitter"*
(`ROADMAP.md:7532-7536`).

**One survivor matters enormously.**
`avra_llvm_cast_to_type` (`backend/llvm_wrapper.c:604-647`) still
handles doubles in four directions — `double` to/from `i64` by bitcast
at 64 bits, `sitofp`/`fptosi` at other widths, and `ptr` to/from
`double` chained through `i64`. So the ONE fn on the hot path of every
call argument and every `CallPtr` seat is already float-correct. That
is a real saving.

**New wrapper fns (all thin, ~4 lines each):**

| Fn | LLVM C API |
|---|---|
| `avra_llvm_double_type(ctx)` | `LLVMDoubleTypeInContext` |
| `avra_llvm_const_real_bits(ty, bits)` | `LLVMConstBitCast(LLVMConstInt(i64, bits, 0), ty)` — takes BITS, never a C `double`, so the Avra side never holds one |
| `avra_llvm_build_fadd/fsub/fmul/fdiv` | `LLVMBuildFAdd/FSub/FMul/FDiv` |
| `avra_llvm_build_fcmp(b, pred, l, r, name)` | `LLVMBuildFCmp` |
| `avra_llvm_build_si_to_fp` / `fp_to_si` | `LLVMBuildSIToFP` / `LLVMBuildFPToSI` |
| `avra_llvm_build_global_bytes_ptr(b, s, len, name)` | §8.4 |

Each is one line in `llvm_api.av` and one body in the wrapper,
compiled under `-Wall -Werror`.

### 8.2 fcmp is ORDERED/UNORDERED, not signed — and it is asymmetric

`bin_value` (`language/llvm.av:349-370`) documents icmp predicates by
number: 32 eq, 33 ne, 38 sgt, 39 sge, 40 slt, 41 sle. FCmp uses a
DIFFERENT predicate numbering (`LLVMRealPredicate`), and the choice of
predicate is a semantic decision the spec already made.

Spec §31.2 (`FULL_SPEC.md:6289`): *"IEEE 754 semantics — NaN,
Infinity, -Infinity are valid values… Comparisons with NaN follow
IEEE rules (NaN != NaN)."*

That forces an asymmetry most implementations get wrong:

| Avra | LLVM predicate | `LLVMRealPredicate` | NaN op NaN |
|---|---|---|---|
| `==` | `oeq` (ORDERED equal) | `LLVMRealOEQ` = 1 | `false` correct |
| `!=` | `une` (UNORDERED not-equal) | `LLVMRealUNE` = 14 | `true` correct |
| `<` | `olt` | `LLVMRealOLT` = 4 | `false` correct |
| `<=` | `ole` | `LLVMRealOLE` = 5 | `false` correct |
| `>` | `ogt` | `LLVMRealOGT` = 2 | `false` correct |
| `>=` | `oge` | `LLVMRealOGE` = 3 | `false` correct |

**`une` for `!=` and `oeq` for `==` is not a typo — it is IEEE.** Using
`one` (ordered not-equal) for `!=` makes `nan != nan` answer `false`,
which contradicts the spec and, worse, makes `!(a == b)` and `a != b`
disagree. (HIGH confidence on the semantics; the numeric values above
are from the LLVM-C `LLVMRealPredicate` enum and should be confirmed
against the installed headers before they are typed into a wrapper —
MEDIUM on the exact integers.)

The interpreter must agree. Since `Val.F` holds bits, its comparison
goes through C — where `==` and `!=` on `double` are the same IEEE
rules — so both engines are correct by construction if the C body is
a plain `a == b` / `a != b` on the bitcast doubles.

### 8.3 Division must not route to `avra_int_div`

`bin_value:359-360` sends `.Div`/`.Mod` to `avra_int_div` /
`avra_int_mod`, which TRAP on zero (`runtime/avra_runtime.c:486-488`;
the comment explains that raw `sdiv` by zero printed an answer and
exited 0 — a silently wrong program). Float division by zero is not a
trap: IEEE gives plus/minus Infinity. The float path emits `fdiv`
directly. The interpreter's twin guard at `interp.av:301-303` must
skip the zero-trap for `Val.F` operands.

`%` on floats: the spec does not define it. **Refuse it at typing**
(`features/expr_spine/check.av:81-89` — `.Mod` keeps its `Type.Int`
law) and say so. `fmod` can arrive as a method later.

### 8.4 `Ins.ConstStr` cannot carry a blob — a hard finding

`backend/llvm_wrapper.c:460-483`:

```c
unsigned len = (unsigned)strlen(s);
LLVMValueRef fields[5] = { AVRA_TAG, -1 /*STATIC*/, 0 /*rc*/,
                           LLVMConstInt(i32, len, 0),
                           LLVMConstStringInContext(ctx, s, len, 0) };
```

**The constant's length is `strlen`, and the header's `len` field is
that same truncated value.** A string literal holding an embedded NUL
is silently cut at emission — including the header, so nothing
downstream can recover the real length. This is the same class of bug
as the tree's most recent commit (`3c622be`, *"a write reads the
header's length, never strlen"*), one layer down.

Consequence: **`b"\x00\x01"` must NOT lower to `Ins.ConstStr`.** A
`Bytes` literal needs its own instruction with its own wrapper fn
taking an explicit length:

```
avra_llvm_build_global_bytes_ptr(b: ptr, s: string, len: int, name: string) -> ptr
```

The `len` argument comes from the Avra side as `s.length` — which
CLAUDE.md's runtime-facts section records is a header LOAD, not a
`strlen`, so it is the TRUE length even for a payload holding NULs.

(A cheaper fix exists — change the existing wrapper to take a length
and pass `s.length` at the one call site, `llvm.av:272` — and it also
fixes string constants with embedded NULs. Recommended either way,
independent of `Bytes`.)

### 8.5 `rt_arg` has no float arm

`language/llvm.av:432-446`:

```
if !(sig!.params[j] is .I64) { return v }
if self.types.rides_pointer(...) { return build_ptr_to_int(...) }
if self.types.shape_of(...) is .Bool { return build_zext(...) }
v
```

A `double` register entering an `I64` slot falls through unchanged
and hands LLVM a type mismatch. `avra_llvm_build_call`
(`backend/llvm_wrapper.c:487-501`) does no coercion of its own. So a
`List<float>` — whose elements ride `avra_array_push`'s `I64` slot
(`core/runtime_api.av:18`) — fails the verifier today.

The fix is one arm: a float register entering an `I64` slot bitcasts
(`avra_llvm_cast_to_type` already does exactly this at
`wrapper.c:630-634`, so the arm is
`avra_llvm_cast_to_type(b, v, i64t)`). And its mirror in
`call_rt_value` (`:383-394`) for a float-shaped destination reading an
`I64` answer.

**`List<float>` is therefore not free.** Budget it explicitly.

---

## 9. The INTERPRETER

`packages/std-avrac/src/language/interp.av`, 1073 lines.

`Val` (`:16-27`) has seven variants: `I`, `B`, `S`, `A` (array
handle), `C` (cell handle), `M` (map handle), `N` (null pointer). The
doc calls it *"a tiny closed enum"*.

Adding `F(bits: int)` — the arms that need one:

| File:line | Fn | Arm |
|---|---|---|
| `:157-182` | `step` | `.ConstFloat(d, bits) -> self.put_at(d, Val.F(bits), pc)` |
| `:296-320` | `bin_val` | a `is .F && is .F` guard before the int fallthrough, routing to a new `float_bin_val` |
| `:323-331` | `null_eq_val` | unchanged (its or-run is over `BinOp`, not `Val`) |
| `:334-343` | `bool_eq_val` | unchanged, but it is the TEMPLATE for `float_bin_val` |
| `:465-474` | `val_text` | `.F(bits) -> avra_f64_text(bits)` — the `${}` and `print` projection |
| `:588-600` | `whole` (int extraction) | must NOT silently accept a `.F` — a float reaching an int slot is a defect, spoken |
| `:500-570` | `rt_dispatch` | one arm per new `RtHost` variant |
| `:100-106` | `truth_of` | unchanged (`_ -> .Err`) |

`Val` is matched non-exhaustively in most places (`_ ->` with a
`defect`), so **adding a variant is largely SILENT in the
interpreter** — the opposite of `Type` and `Ins`. `bin_val` and
`val_text` are the two that matter and both fail loudly at runtime
("a non-string reached text", "an undefined register was read")
rather than at build time.

For `Bytes`: `Val.Y(v: string)` — the interpreter can hold a blob in
an Avra `string` because the VALUE survives (the header carries the
length); only strlen-based OPERATIONS truncate, and the interpreter
does not perform any on a blob it merely carries. MEDIUM confidence —
worth a probe (`corpus/native/` has the precedent for extern-only
programs).

**The extern trap.** `unhosted_extern` (`:573-577`) is the campaign's
starting point:

```
self.trapped("`${callee}` is extern — the evaluator cannot host it; build natively")
```

Note for the dlsym work: `RtKind` has no float slot (§11), so a
uniform-ABI dlsym trampoline that only knows I64/Ptr **cannot call
`sqlite3_column_double` or `sqlite3_bind_double` correctly.** On both
x86-64 SysV and AArch64 AAPCS, a `double` argument is passed in an
SSE/FP register, not an integer one, and a `double` return comes back
in `xmm0`/`d0`. Passing bits in an integer register silently reads
garbage. **`RtKind.F64` is a prerequisite for the interpreter's
extern hosting, not an optional extra.**

---

## 10. The RUNTIME

`runtime/avra_runtime.c`, 2172 lines. It contains **zero** floating
point today (verified: the only `double`/`float` occurrences are the
word "double" in comments and `%lld` in `snprintf`).

### 10.1 The header, exactly

`runtime/avra_runtime.c:56-61`:

```c
typedef struct {
    uint32_t tag;    // 0x41565241u — "AVRA"
    int32_t  kind;   // KIND_DEAD -2, KIND_STATIC -1, KIND_PLAIN 0,
                     // KIND_ARRAY 1, KIND_MAP 2, KIND_STR 3
    int32_t  rc;
    uint32_t len;    // a record's payload bytes; a string's TEXT length
} Header;            // sixteen bytes, immediately before the payload
```

`hdr(p)` (`:68-73`) refuses an unaligned address (`a & 15`) or one
below `0x100000000`, then checks the tag. `box_alloc` (`:244-260`)
recycles through per-class free lists (`CLASS_BYTES 16`, `CLASS_MAX
256`, `LIST_LIMIT 16384`). `str_box(n, kind)` (`:264-268`) allocates
`n + 1` payload bytes and then OVERWRITES `len` with `n`, so a
string's `len` is one less than its payload — which `box_bytes`
(`:277-281`) undoes for `KIND_STR` alone.

`str_owned(s, n)` (`:1122-1127`) copies `n` bytes and writes the
terminator, so **every runtime-made string is both length-headered and
NUL-terminated.** That is what makes handing one to C as a
`const char*` safe.

`str_static(s)` (`:302-307`) makes the immortal copy (`KIND_STATIC`,
rc untouched by retain/release) — the mandated shape for any C body
answering text a program must not own.

### 10.2 The `h->len == 0` hazard, exactly

`runtime/avra_runtime.c:271-275`:

```c
static size_t str_len(const char* s) {
    Header* h = hdr((void*)s);
    return (h && h->len) ? h->len : strlen(s);
}
```

**`len == 0` means "not recorded", not "empty".** For strings this is
harmless: an empty string's buffer holds `'\0'` at offset 0, so
`strlen` answers 0 and the two readings coincide.

For a BLOB it is a live hazard in two ways:

1. **A zero-length blob whose payload is not terminated.** `str_box(0,
   …)` allocates one payload byte and leaves it uninitialised (the
   free-list path recycles a used box, so the byte holds whatever the
   previous tenant left). If a `Bytes` box does not write a
   terminator, `str_len` walks off into the recycled box's old
   content and answers an arbitrary length. **A `Bytes` box must
   never be read through `str_len`.**
2. **The KIND is the discriminator, and there isn't one.** `KIND_STR`
   is 3; a blob allocated as `KIND_PLAIN` or `KIND_STR` is
   indistinguishable from a string to every reader.

**The fix, and it is small:** a `KIND_BYTES = 4` constant plus
`bytes_len(p)` that reads `h->len` UNCONDITIONALLY and refuses
(`avra_trap`) when the header is absent. Three more one-line arms:

| Site | Edit |
|---|---|
| `runtime/avra_runtime.c:48` | `KIND_BYTES = 4` in the kind enum |
| `runtime/avra_runtime.c:234-236` | `acc_kind_of` — a bucket (reuse `ACC_STR`, or add `ACC_BYTES` to `g_acc_name[]` at `:96`) |
| `runtime/avra_runtime.c:277-281` | `box_bytes` — `KIND_BYTES` answers `len` (no terminator) or `len + 1` (with one); pick ONE and write it in the comment. **Recommend keeping the terminator**: it costs one byte, makes a blob safe to hand to any C fn expecting `const char*` that also takes a length, and keeps `box_bytes` symmetrical with `KIND_STR`. |
| `runtime/avra_runtime.c:415-434` | `avra_rc_release` — **no arm needed.** The `else` branch (`box_free`) is correct: a blob holds no owned slots. Verified by reading the dispatch. |

`len` is `uint32_t` — a blob is capped at 4 GiB minus 1. SQLite's
`SQLITE_MAX_LENGTH` defaults to 1,000,000,000 and its ceiling is
2^31 - 1, so this is sufficient (HIGH — the SQLite limit is
documentation, not a tree read; verify at
`https://sqlite.org/limits.html`).

### 10.3 The NUL-truncation inventory

The campaign brief's claim, verified line by line:

| Fn | Line | Truncates? |
|---|---|---|
| `avra_streq` | `:475-478` | **YES** — `strcmp` |
| `avra_str_contains` | `:1144-1146` | **YES** — `strstr` |
| `avra_str_index_of` | `:1159-1162` | **YES** — `strstr` |
| `avra_str_replace` | `:1207-1230` | **YES** — `strlen` x3 and `strstr` |
| `avra_str_split` | `:1232-1251` | **YES** — `strlen`, `strstr`, `*r != '\0'` |
| `avra_str_starts_with` | `:1148-1150` | no — `strncmp` with `str_len(prefix)` |
| `avra_str_ends_with` | `:1152-1156` | no — `memcmp` with header lengths |
| `avra_str_substring` | `:1136-1142` | no — `str_len` + `memcpy` |
| `avra_str_char_code` | `:1177-1186` | no — `str_len` bound |
| `avra_str_len` | `:1189-1191` | no — the header |
| `avra_str_concat` | `:1253-1260` | no — `str_len` + `memcpy` (copies `m + 1` for the terminator) |

Five of eleven truncate. **This is why `Bytes` must be its own
category and not "a string you promise not to search."** A `Bytes`
vocabulary gets its own five: `avra_bytes_eq` (memcmp with lengths),
`avra_bytes_index_of`, `avra_bytes_slice`, `avra_bytes_concat`,
`avra_bytes_text` (hex or base64 for `${}`).

---

## 11. `core/runtime_api.av`

`core/ir.av:217`:

```
export enum RtKind { I64, Ptr, Void }
```

**This is the FFI blocker, and it is the single highest-priority item
in the whole campaign.** `rt_kind_of` (`core/runtime_api.av:95-99`)
maps every non-pointer, non-void type to `I64`; `extern_row`
(`:103-105`) builds an extern's signature from it
(`language/lower.av:52-55`); `ll_rt_kind` (`language/llvm.av:175-181`)
turns it into `avra_llvm_int64_type`.

So `extern fn sqlite3_column_double(stmt: ptr, i: int) -> float`
would be DECLARED to LLVM as returning `i64`, and the call would read
the integer return register where the value is in the FP one.
**Silently wrong numbers, no diagnostic, on both engines.** (HIGH on
the mechanism; the register names are the SysV/AAPCS conventions, not
a tree read.)

`RtKind.F64` costs:

| File:line | Edit |
|---|---|
| `core/ir.av:217` | the variant |
| `core/runtime_api.av:95-99` | `rt_kind_of` — `if types.shape_of(ty) is .Float { return RtKind.F64 }` |
| `language/llvm.av:175-181` | `ll_rt_kind` — a fourth arm, `avra_llvm_double_type` |
| `language/llvm.av:432-446` | `rt_arg` — a float register entering an `F64` slot passes straight; entering an `I64` slot bitcasts (§8.5) |
| `language/llvm.av:383-394` | `call_rt_value` — an `F64` answer needs no coercion; an `I64` answer into a float destination bitcasts |
| `language/interp.av:500-570` | `rt_dispatch` — the host arms read `Val.F` |

`RtKind` is matched in exactly those places (grepped: `ll_rt_kind`,
`rt_kind_of`, `answers_word` at `llvm.av:398-402`, `rt_arg`). Small.

### 11.1 New rows

Each is one line in `rt_sigs()` (`core/runtime_api.av:10-91`), one
`RtHost` variant (`core/ir.av:222-290`), one C body, one interpreter
arm.

```
avra_f64_parse   (Ptr)             -> I64   // strtod; text -> bits. NOT owned.
avra_f64_text    (I64)             -> Ptr   // bits -> shortest round-trip. OWNED.
avra_f64_add/sub/mul/div (I64,I64) -> I64   // the interpreter's arithmetic
avra_f64_eq/lt   (I64,I64)         -> I64
avra_f64_from_int(I64)             -> I64   // sitofp
avra_f64_to_int  (I64)             -> I64   // fptosi, saturating
avra_floats_text (Ptr)             -> Ptr   // List<float> printing. OWNED.
```

The `_text` rows answer OWNED (fresh `str_box`), matching
`avra_int_text` (`:45`, `owns_result: true`). `avra_bool_text` answers
BORROWED (`:46`) because it returns one of two `str_static` words
(`runtime/avra_runtime.c:505`) — a float has no such fixed vocabulary,
so it must own.

### 11.2 Shortest-round-trip printing is a REAL problem

Say it plainly: **`printf("%g")` loses digits; `printf("%.17g")`
prints `0.10000000000000001` for `0.1`.** Neither is acceptable for a
language whose corpus gate is `eval == native == expected` on exact
text.

Three options:

- **(a) Ryu or Grisu3.** Correct and fast; ~600 lines of C with
  lookup tables. Heavy for a tree whose whole runtime is 2172 lines,
  and it is a dependency-shaped thing in a codebase whose doctrine is
  *"Language semantics live in this tree, in this file — never in a
  dependency"* (`runtime/avra_runtime.c:1-7`).
- **(b) The precision ladder.** Try `snprintf("%.15g")`, then
  `"%.16g"`, then `"%.17g"`, and take the FIRST whose `strtod`
  round-trips to the same bits. ~15 lines. Exact by construction (17
  significant digits always round-trips for IEEE double). Costs up to
  three `snprintf` plus three `strtod` per printed float — irrelevant
  outside a hot print loop.
- **(c) `%.17g` always.** Ugly output, correct round-trip. Rejected on
  P3 grounds; `1.0` printing as `1` and `0.1` as
  `0.10000000000000001` in every corpus `.expected` file is not
  "gloriously declarative".

**Recommendation: (b), with a note in the C body naming (a) as the
optimisation to reach for when profiling asks.** It is exact, tiny,
and has no tables to get wrong.

Additional printing decisions the `.expected` files force you to
make, so make them once and write them at the C body:

- `1.0` prints as `1.0` (not `1`) — a float must be visibly a float,
  or `shown("1.0")` and `shown("1")` collide.
- `nan`, `inf`, `-inf` — lowercase, matching `%g`. `NaN` has no sign
  in the text.
- `-0.0` prints as `-0.0` (the sign bit is observable).
- Exponents: `1e100`, not `1e+100`, and no leading zeros in the
  exponent.

---

## 12. TYPING

### 12.1 The spec settles the hard questions

`FULL_SPEC.md:6274-6293` (§31.2), quoted:

- *"**No implicit int-float conversion:** `let x: float = 5` is a
  compile error. Write `let x: float = 5.0` or `let x: float =
  (5).to_float()`."*
- *"**Float literals:** must have a decimal point or exponent: `5.0`,
  `1e10`, `2.5e-3`. `5` alone is an integer literal."*
- *"**Division semantics:** `int / int = int` (truncating), `float /
  float = float`. Mixed arithmetic requires explicit conversion."*

**`int + float` is a COMPILE ERROR.** That is the spec, and it is
also by far the cheapest thing to implement, because
`features/expr_spine/check.av:98-113`'s `op_over` already does exactly
this: both sides must `wears` the wanted shape, or each present wrong
side speaks. The only change is `binary_type` (`:81-89`) choosing
`Type.Float` as the want when the LEFT side is a float — the same
dispatch `added_type` (`:93-96`) already performs for `Str`:

```
fn added_type(mut cx: TypeCx, op: BinOp, l: ExprId, r: ExprId) -> TypeId {
    if cx.shape_at(l) is .Str { return op_over(cx, op, l, r, Type.Str, Type.Str) }
    op_over(cx, op, l, r, Type.Int, Type.Int)
}
```

becomes a three-way. `wears` (`:117-126`) gains
`.Float -> sh is .Float`. `compare_help` (`:158-173`) gains a float arm
in the "compare scalars or strings" or-run.

**No coercion, no widening, no unification change.** `unify`
(`features/unify.av:31-46`) compares interned ids for leaves and
`Float` joins that or-run; `accepts` (`features/checks.av:91-109`)
has four widening doors — nullable lift, auto-`Ok`, empty-list/map
adoption, `dyn` boxing — and a float participates in none of them
beyond `T` to `T?`, which is generic. `agreed`
(`features/checks.av:83-88`) is untouched.

**This is the paradox collapse (P6): the spec's "no implicit
conversion" decision is simultaneously the safest semantics AND the
cheapest implementation.** Every alternative (promotion, unification
over a numeric lattice) costs a new concept in `unify` and a new
widening door in `accepts`.

### 12.2 The one wrinkle: `-3.14`

`build_neg` (`features/expr_spine/builders.av:48-55`) desugars unary
minus at PARSE time:

```
fn build_neg(mut b: Builder) -> Result<LangNode, string> {
    let v = b.expr(0)?
    let zero = b.store.alloc_expr(Expr.IntLit(0), b.span)
    let minus = want(binop_of("-"), "the minus operator")?
    b.make_expr(Expr.Binary(minus, zero, v))
}
```

So `-3.14` becomes `0 - 3.14` — an `IntLit` minus a `FloatLit` — which
under §12.1's law is a type error. Two fixes:

- **(a)** `build_neg` looks at the operand and emits a `FloatLit(0.0)`
  zero when the operand is a `FloatLit`. Works only for a literal
  operand — `-x` where `x: float` still breaks.
- **(b)** `build_neg` emits `Expr.Neg(v)` — a real unary node — and
  typing answers the operand's own type. This costs an `Expr`
  variant (the four dispatches of §2.2) and a `UnOp.Neg`
  (`core/ir.av:17` — today `UnOp` has exactly one variant, `Not`).

**Recommend (b).** `UnOp` having one variant is a smell the tree
already carries (`core/ir.av:16-24` names it "The unary operators"
plural), the `Neg` lowering is `sub 0, x` for ints and `fneg` for
floats, and (a) leaves `-x` broken for the common case of a negative
float variable. Budget it as part of the float slice, not after.

### 12.3 Diagnostics

Next free typing code: **F2056** (F2000–F2055 are taken; grepped).
The float slice needs at least:

- a refusal for a numeric literal with no `int` and no `float`
  reading (the lexer's `numbered` already owns the int-overflow
  wording at `grammar/lexer.av:114`);
- a refusal for `int` beside `float` in an operator, whose help names
  the conversion: `` "`+` needs `float` operands, found `int`" `` with
  help `` "write `(n).to_float()`" ``;
- a refusal for `%` on floats.

Each needs a golden rendering test (CLAUDE.md: *"Every diagnostic
names a registered kind…, carries help or a structured fix where
expressible, and has a golden rendering test"*).
`features/bool_lit/tests/bool_test.av:28-36` is the template — a
triple-quoted expected rendering compared against `lang.check(...)`.

---

## 13. TESTS

Three layers, all mandatory.

**Unit specs**, beside the module:
`packages/std-avrac/src/features/<name>/tests/<name>_test.av` with
`spec` / `given` / `then` (`features/bool_lit/tests/bool_test.av` is
43 lines and covers parse, type, run, and two golden refusals).
`shown(src)` (`packages/std-avrac/src/testing/mod.av:7-9`) runs a
source and answers its printed output or `"<refused>"`;
`refusals(src)` counts diagnostics, and the doc there says *"The COUNT
is half of a refusal test: a cascade hides behind `contains` alone."*

**Corpus pairs**: `corpus/<name>.av` + `corpus/<name>.expected`.
`Makefile:99-115` runs `./avra corpus corpus` (eval), then
`--native-only corpus/native` for extern programs, then for each
package-shaped corpus dir: `avra run`, diff, `avra build`, run the
binary, diff. **The bar is `eval == native == expected`.**
`corpus/eq.av` is two lines:

```
// proves: int equality, compiled to one icmp
1 + 2 == 3
```

CLAUDE.md's constraints on a corpus program: it *"shows its FINAL
statement's expression only, and only when that statement IS an
expression, and an interpolation hole prints scalars and strings only
— a list is shown through `join`, an index or `length`."*

So `corpus/float.av` needs `avra_f64_text` working before it can exist
— printing is a PREREQUISITE of the corpus proof, not a follow-up.

**IR goldens.** `core/ir.av:40` requires *"a corpus program proving
eval == native and the IR golden that shows the shape"* for each new
instruction. `avra ir` renders through `language/ir_text.av:6-8`.

**The gate**: `make gate` = `vocab idioms tested corpus`
(`Makefile:136`). `tools/vocab.sh` proves no `Ins` consumer grew a
catch-all; `tools/idioms.sh` fails on any NEW idiom violation with
zero debt to hide in.

**Machine discipline** (CLAUDE.md, and the machine has panicked
twice): one heavy process at a time, in the foreground, under
`sh tools/watch.sh 4000 make gate`. And: *"A CODEGEN FIX REACHES THE
PRODUCT ON THE SECOND BUILD"* — the float lowering changes the memory
pass's input, so build twice before trusting a peak.

---

## BLOCKERS

Ordered by what stops what. Each names its fix.

### B1 — `RtKind` has no float slot. Blocks: every SQLite double API, and the interpreter's dlsym hosting.

`core/ir.av:217` — `enum RtKind { I64, Ptr, Void }`. Every extern's
signature is built from it (`core/runtime_api.av:103-105`,
`language/lower.av:52-55`) and lowered to LLVM through
`ll_rt_kind` (`language/llvm.av:175-181`). A `float` extern param or
return is declared `i64`, so `sqlite3_bind_double` and
`sqlite3_column_double` pass and read the wrong CPU register on both
SysV and AAPCS. No diagnostic; wrong numbers.

**Fix:** add `RtKind.F64`; four arms (§11). Land it in the SAME slice
as `Type.Float` — a float that cannot cross the extern seam is not
useful to this campaign.

### B2 — The compiler cannot hold a `float`, so it cannot carry a float literal.

Bootstrap circularity: `Expr.FloatLit(value: float)`,
`Ins.ConstFloat(dst, v: float)`, `Val.F(v: float)` and
`Token.float_value() -> float?` all require the feature they
implement.

**Fix (§7.1):** carry **BITS**. `FloatLit(bits: int, text: string)`,
`ConstFloat(dst, bits: int)`, `Val.F(bits: int)`. Text to bits is one
runtime row (`avra_f64_parse`, `strtod`). Nothing in the language's
surface changes. Zero cost, permanently defensible, and it removes a
cross-compilation bug class.

### B3 — `Ins.ConstStr` truncates at the first NUL. Blocks: every `Bytes` literal.

`backend/llvm_wrapper.c:466` — `unsigned len = (unsigned)strlen(s)`,
and the header's `len` field is set from that same truncated value, so
the real length is unrecoverable downstream.

**Fix:** a new wrapper `avra_llvm_build_global_bytes_ptr(b, s, len,
name)` taking the length explicitly, from Avra's `s.length` (a header
LOAD, not a `strlen`). **Also change the existing string path the same
way** — it fixes string constants with embedded NULs for free, and it
is one call site (`language/llvm.av:272`).

### B4 — `str_len`'s `len == 0` fallback is unsafe for a blob.

`runtime/avra_runtime.c:271-275` — `len == 0` means "not recorded",
so a zero-length blob whose payload byte is a recycled free-list byte
answers an arbitrary length from `strlen`.

**Fix:** `KIND_BYTES = 4` and a `bytes_len(p)` that reads `h->len`
unconditionally and traps on a missing header. Plus a `box_bytes` arm
(`:277-281`) and an `acc_kind_of` arm (`:234-236`). `avra_rc_release`
(`:415-434`) needs nothing — the `box_free` else-branch is already
right.

### B5 — Five of eleven string runtime fns truncate at a NUL.

`avra_streq` (strcmp), `avra_str_contains` / `avra_str_index_of`
(strstr), `avra_str_replace`, `avra_str_split` (strlen + strstr).
Inventory at §10.3.

**Fix:** `Bytes` gets its OWN five verbs — `avra_bytes_eq`
(memcmp with both header lengths), `avra_bytes_index_of`,
`avra_bytes_slice`, `avra_bytes_concat`, `avra_bytes_text`. Do not
reuse the string ones; do not "promise not to search a blob."

### B6 — No float builders in the LLVM wrapper.

`language/llvm_api.av` declares 59 externs, none float. The float ops
were deliberately swept in a review round (`ROADMAP.md:7532-7536`).

**Fix:** eight new wrapper fns (§8.1), each ~4 lines. Mitigated:
`avra_llvm_cast_to_type` (`backend/llvm_wrapper.c:604-647`) already
handles all four double conversions and is on the hot path.

### B7 — `rt_arg` has no float arm, so `List<float>` fails the verifier.

`language/llvm.av:432-446` returns a `double` unchanged into an `I64`
runtime slot; `avra_llvm_build_call` does no coercion
(`backend/llvm_wrapper.c:487-501`).

**Fix:** one arm calling `avra_llvm_cast_to_type(b, v, i64t)`, plus
its mirror in `call_rt_value` (`:383-394`). Budget `List<float>`
explicitly; it is not free.

### B8 — Three SILENT sites will pass the build and be wrong.

`comparable` (`features/checks.av:424-428`), `same_value`'s branch
(`features/values.av:54-64`), `list_text_callee`
(`language/lower_walk.av:175-178`). Each is a positive `is .X` test
with a default. A `Bytes` `==` would compare POINTERS and answer
`false` for two equal blobs; a `List<float>` would print bit patterns
as integers.

**Fix, and do it FIRST as its own slice:** convert all three to
exhaustive matches over `Type`. Three small edits that turn the entire
silent class into compile errors before either category lands.

### B9 — `-3.14` desugars to `0 - 3.14` and refuses.

`features/expr_spine/builders.av:48-55` builds `Expr.IntLit(0)`.

**Fix:** `Expr.Neg(v)` + `UnOp.Neg` (§12.2). Costs the four `Expr`
dispatches and one `UnOp` arm; `UnOp` today has exactly one variant.

### B10 — `float` is the tree's canonical "unknown type" in two tests.

`features/fns/tests/fns_test.av:85-87` and
`features/type_expr/tests/type_expr_test.av:37` assert `` `float`
names no type ``.

**Fix:** rewrite both with a word that stays unknown. Trivial, but it
will be the first thing to go red and it is better to know why.

---

## A) LANDING CHECKLIST — `float`

Dependency order. Each item names its files. Nothing here requires
`Bytes`.

**A0. The silence sweep** *(standalone, lands first, no float in it)*

1. `features/checks.av:424-428` `comparable` — exhaustive match over `Type`.
2. `features/values.av:54-64` `same_value` — exhaustive dispatch on the type's shape.
3. `language/lower_walk.av:175-178` `list_text_callee` — exhaustive match over the element shape.
4. Gate. These three are now compile-forced for every future category.

**A1. The runtime's float half** *(no compiler change; the C stands alone)*

5. `runtime/avra_runtime.c` — `avra_f64_parse` (strtod to bits), `avra_f64_text` (bits to shortest round-trip via the precision ladder, §11.2), `avra_f64_add/sub/mul/div`, `avra_f64_eq/lt`, `avra_f64_from_int`, `avra_f64_to_int`, `avra_floats_text`. All take and answer BITS as `int64_t`.
6. `backend/llvm_wrapper.c` — `avra_llvm_double_type`, `avra_llvm_const_real_bits`, `build_fadd/fsub/fmul/fdiv`, `build_fcmp`, `build_si_to_fp`, `build_fp_to_si`.
7. `packages/std-avrac/src/language/llvm_api.av` — the seven new extern lines.

**A2. The type**

8. `core/types.av:13-21` — `Type.Float`.
9. `core/types.av:130-153` `canon` — key `"19"`.
10. `core/types.av:118-125` `ptr_shape` — the `false` run.
11. `core/types.av:284-307` `name_of` — `"float"`.
12. `core/types.av:263-281`, `:311-321` — leaf arms in `substituted`, `args_of`.
13. `language/typing.av:315-323` `shape_named` — `"float" -> Type.Float`.
14. The other twenty-four exhaustive `Type` dispatches (§2.1) — each answers "an unmanaged scalar". Two need real answers: `language/llvm.av:198-209` `ll_type_of` to `avra_llvm_double_type`, and `language/lower_walk.av:126-158` `print_lowering` to `avra_f64_text`.
15. `language/memory.av:31-45` `is_managed` — the `false` run. **A float is a SCALAR; nothing is retained or released.**
16. `features/unify.av:131-143` `slot_worthy` — the `true` run (a float fits a box slot as a word).
17. `features/values.av:365-372` `hollow_of` — a `.Float` arm emitting `ConstFloat(0 bits)`, exactly as `.Bool` does. **Skip this and the LLVM verifier kills any `match` whose arms include a departing float arm.**
18. Fix `features/fns/tests/fns_test.av:85-87` and `features/type_expr/tests/type_expr_test.av:37` (B10).

**A3. The extern seam** *(B1 — same slice as A2, or immediately after)*

19. `core/ir.av:217` — `RtKind.F64`.
20. `core/runtime_api.av:95-99` `rt_kind_of` — the float arm.
21. `language/llvm.av:175-181` `ll_rt_kind` — the fourth arm.
22. `language/llvm.av:432-446` `rt_arg` + `:383-394` `call_rt_value` — the bitcast coercions (B7).

**A4. The instruction**

23. `core/ir.av:48-137` — `Ins.ConstFloat(dst: Reg, bits: int, text: string)`.
24. The eight consumers (§7.3). `tools/vocab.sh` will name any you miss.
25. `features/emit.av` — `const_float(mut cx, bits, text) -> Reg`, beside `const_int` (`:11`) and `const_bool` (`:17`). **I33 ratchets the emission vocabulary: a raw `cx.emit(Ins.ConstFloat(…))` outside this file fails `make idioms`.**

**A5. The literal**

26. `grammar/lexer.av:25` — `TokenKind.Float`; `:34-39` `lit_matches`; `scan_number` replacing the `is_digit` arm at `:318-322`; `Token.float_bits()` beside `int_value` (`:45-56`).
27. `grammar/validate.av:11-25` `term_kind` — `"FLOAT"`.
28. `core/nodes.av:163-247` — `Expr.FloatLit(bits: int, text: string)`.
29. `core/nodes.av` — the four exhaustive `Expr` dispatches (§2.2). **Fingerprint tag 62, not 52; the comment at `:776` is stale.**
30. `core/nodes.av:266-306` — `float_of(e) -> int?` (the bits).
31. `features/contexts.av:196-201` `literal_shape` — the `Type.Float` arm, so `const PI = 3.14159` types.
32. `avra new feature float_lit`, then `features/float_lit/{mod,builders,semantics,check,lower}.av`.
33. `features/dispatch.av:12-48` `Dispatch` + `:54-74` `semantics_of`; `language/program.av:43-56` `new_dispatch`.
34. `language/mod.av:118-165` — `float_lit()` immediately after `expr_spine()`.

**A6. The operators**

35. `features/expr_spine/check.av:81-89` `binary_type` + `:93-96` `added_type` — the float law. `%` refuses.
36. `features/expr_spine/check.av:117-126` `wears`, `:158-173` `compare_help`.
37. `language/llvm.av:352-370` `bin_value` — takes REGISTERS now, picks `fadd`/`fcmp` by the operand's static type (§8.2's predicate table, `oeq` for `==` and `une` for `!=`).
38. `language/interp.av:296-320` `bin_val` — the `is .F` guard before the int fallthrough; a `float_bin_val` modelled on `bool_eq_val` (`:334-343`); the div-by-zero trap at `:301-303` skipped for floats.
39. `features/expr_spine/builders.av:48-55` — `Expr.Neg` and `UnOp.Neg` (B9).

**A7. The vocabulary and the proofs**

40. `features/float_lit/{check,lower}.av` — `MethodRow`s: `to_int()`, `abs()`, `is_nan()`, `is_infinite()`, `floor()`, `ceil()`, `round()`. Int's `to_float()` is a method row on `Type.Int` — put it in `float_lit`'s manifest (the feature owns the CONVERSION pair), not in `expr_spine`.
41. `features/str_lit/check.av:7-17` `interp_type` — floats print in a hole.
42. `features/str_lit/lower.av:33-43` `hole_reg` — the `.Float -> rt1(cx, e, "avra_f64_text", v)` arm.
43. `features/float_lit/tests/float_test.av` — parse, type, run, and TWO golden refusals (`int + float`; `%` on floats).
44. `corpus/float.av` + `.expected` — arithmetic, the six comparisons, printing (`1.0`, `-0.0`, `nan`, `1e100`, `0.1`).
45. An IR golden showing `r0 = float 3.14`.
46. `sh tools/watch.sh 4000 make gate`. Build twice (the CODEGEN-FIX rule).

Roughly **46 edits across 24 files**, of which ~24 are one-arm or-run
extensions the compiler demands by name.

---

## B) LANDING CHECKLIST — `Bytes`

`Bytes` is a MANAGED category — the `string` model of §1.2, not the
`bool` model. It is genuinely harder than `float` in the runtime and
genuinely easier in the type system (no operator laws, no numeric
tower, no NaN).

**B0.** A0's silence sweep, if `float` did not already land it. For
`Bytes` it is not optional: `same_value` falling through to
`Ins.Bin(Eq)` compares pointers.

**B1. The runtime's blob half**

1. `runtime/avra_runtime.c:48` — `KIND_BYTES = 4`.
2. `:277-281` `box_bytes` — the `KIND_BYTES` arm. Recommend keeping a terminator (`len + 1`), symmetric with `KIND_STR`.
3. `:234-236` `acc_kind_of` + `:96` `g_acc_name[]` — an accounting bucket.
4. `bytes_len(p)` — reads `h->len` unconditionally, traps on a missing header. **Never `str_len`** (B4).
5. `avra_bytes_new(len)`, `avra_bytes_eq` (memcmp on both header lengths), `avra_bytes_index_of`, `avra_bytes_slice`, `avra_bytes_concat`, `avra_bytes_len`, `avra_bytes_text` (hex — the `${}` projection), `avra_bytes_from_text` / `avra_bytes_to_text` (the UTF-8 boundary; the latter is fallible, so it answers a `Result` shape or a nullable).
6. `avra_rc_release` (`:415-434`) — **verified: no arm needed.**

**B2. The type**

7. `core/types.av` — `Type.Bytes`; `canon` key `"20"`; `ptr_shape` to `true`; `name_of` to `"Bytes"`.
8. `language/typing.av:315-323` `shape_named` — `"Bytes" -> Type.Bytes`.
9. `language/memory.av:31-45` `is_managed` — **`.Bytes -> true`.** This is the whole ownership story; §D.
10. `features/unify.av:131-143` `slot_worthy` — `true`.
11. `features/values.av:425-436` `length_word` — `"avra_bytes_len"`, so `.length` and `is_empty()` work through the shared property row.
12. `language/llvm.av:198-209` `ll_type_of` — pointer.
13. `language/lower_walk.av:126-158` `print_lowering` — `avra_bytes_text`.
14. `language/receivers.av:239-252` `callee_of` — `.Bytes` joins `.List / .Map / .Str` in the `Callee.Row(...)` arm, so method rows resolve.
15. `language/receivers.av:186-194` `writable` — `true` (managed).
16. The remaining exhaustive `Type` dispatches (§2.1).

**B3. The instruction**

17. `core/ir.av` — `Ins.ConstBytes(dst: Reg, payload: string)`. It cannot ride `ConstStr` (B3).
18. The eight consumers. `memory_ins` puts it where `ConstStr` sits — **`ConstStr`'s constant is a `KIND_STATIC` immortal box (`backend/llvm_wrapper.c:469`), so a bytes constant is too, and it is not retained or released.** Verify by reading the emitted global, not by assuming.
19. `backend/llvm_wrapper.c` — `avra_llvm_build_global_bytes_ptr(b, s, len, name)`, and change the string path to take a length too.
20. `features/emit.av` — `const_bytes(mut cx, payload) -> Reg`.

**B4. The literal**

21. `grammar/lexer.av` — `TokenKind.Bytes`; the `is_name_start` arm looks ahead for a lone `b` before `"`; `\x` and `\0` join `unescape` (`:192-202`).
22. `grammar/validate.av:11-25` — `"BYTES"`.
23. `core/nodes.av` — `Expr.BytesLit(payload: string)`; the four dispatches; fingerprint tag 63.
24. `core/nodes.av:266-306` — `bytes_of(e) -> string?`.
25. `features/contexts.av:196-201` `literal_shape`.
26. `features/bytes_lit/` — `avra new feature bytes_lit`.
27. `features/dispatch.av`, `language/program.av:43-56`, `language/mod.av:118-165`.

**B5. The vocabulary**

28. `MethodRow`s in `features/bytes_lit/mod.av`: `length` (property), `is_empty()`, `slice(lo, hi)`, `index_of(b)`, `concat(b)`, `to_text()`, `at(i) -> int`, `hex()`, plus `Bytes.from_text(s)`.
29. `features/values.av:54-64` `same_value` — `.Bytes -> avra_bytes_eq`.
30. `features/checks.av:424-428` `comparable` — `.Bytes -> true`.
31. `features/str_lit/check.av:7-17` — a `Bytes` hole prints as hex, or refuses with a help naming `.hex()`. **Decide and write it down**; the corpus rule ("an interpolation hole prints scalars and strings only") argues for refusing.

**B6. The proofs**

32. `features/bytes_lit/tests/bytes_test.av` — **with an embedded-NUL case that would truncate under `string`.** That case is the reason the category exists; it belongs in the first test file, not a follow-up.
33. `corpus/bytes.av` + `.expected` — build a blob with a NUL, measure it, slice it, compare two equal blobs, print its hex.
34. Gate, twice.

Roughly **34 edits across 18 files**, weighted toward C.

**Note on the spec.** `FULL_SPEC.md:5570` says byte strings are
`b"..."` of type **`List<u8>`**, not `Bytes`. The spec has no `Bytes`
type. `List<u8>` through the tree's array machinery is 8 bytes plus an
`owned` mark per byte (`runtime/avra_runtime.c:514-523`) — a 1 MB blob
becomes ~9 MB and every element read is an `avra_array_get` call.
**That is a P4 violation, and `Bytes` is therefore a spec AMENDMENT,
not an implementation of the spec.** Say so explicitly when the slice
lands: file it as a spec divergence with the measurement, and keep
`b"..."` as the literal so the surface syntax still matches §28.3.

---

## C) `decimal` — and whether it is a core value category at all

### The spec has already decided, and it decided against.

`FULL_SPEC.md:6296-6317` (§31.3), verbatim:

> **Decision:** **(b) `BigInt` / `BigDecimal` in `@std/numbers` —
> explicit types, no silent promotion**
>
> **`BigDecimal`** — arbitrary-precision decimal with explicit scale;
> useful for money, scientific data, anything where `0.1 + 0.2 == 0.3`
> matters
>
> **Money type:** `@std/money` provides `Money` built on `BigDecimal`
> with currency tagging — the idiomatic choice for financial apps.
>
> **Performance note:** every `BigInt` / `BigDecimal` operation
> allocates. Use explicitly when the precision matters; stick with
> `int`/`float` for hot paths. **The cost is visible in the type.**

The spec is LAW where anything disagrees. `decimal` is a library type
in `@std/numbers`, named `BigDecimal`, and it is not a core value
category.

### The doctrine agrees, independently, four times over

- **P17, composability over featurefulness.** A `BigDecimal` built
  from `int` (or a `Bytes` mantissa) and an `int` scale is a record
  and an impl. It needs no `Type` variant, no `Ins`, no lexer arm, no
  `RtKind`, no LLVM type. It costs 30 exhaustive-dispatch arms less
  than `float` does.
- **THE VOCABULARY SEAM RULE.** *"is the item DATA or BEHAVIOR?"*
  Decimal arithmetic is a set of FUNCTIONS over a record. Nothing
  about it needs a per-pass meaning. It is not an instruction, and it
  is not even a registry row — it is a library.
- **P7, visible magic.** A `decimal` that looked like a scalar but
  allocated on every `+` would be exactly the invisible cost the spec
  rejects in option (c) ("overflow promotion makes performance
  unpredictable"). A `BigDecimal` in the type says what it costs.
- **P4, Rust-level performance.** Every operation allocates. Putting
  that behind an operator on a core scalar is the opposite of the
  performance story.

### The one argument FOR core, and why it fails

*"SQLite has a NUMERIC affinity, and money is the ORM's first
customer."*

It fails on the facts. **SQLite has five storage classes: NULL,
INTEGER, REAL, TEXT, BLOB. There is no decimal storage class.** A
column declared `NUMERIC` or `DECIMAL(10,2)` gets NUMERIC affinity,
which stores INTEGER when the value is integral and otherwise REAL —
an IEEE double, with all its base-2 rounding. SQLite's own
recommendation for money is to store scaled integers or TEXT. (HIGH
on the storage classes and affinity rules — these are
`https://sqlite.org/datatype3.html`, documentation, not a tree read.)

So the driver's `column_*` surface is `int`, `float`, `string`,
`Bytes`, `null` — **exactly the five that `float` and `Bytes` complete,
and no more.** `decimal` never appears at the driver's boundary. It
appears in the ORM, one layer up, where a `Money` column maps to a
scaled `int` or to TEXT and back.

### RECOMMENDATION

**Do not make `decimal` a core value category. Do not build it in this
campaign at all.**

1. The driver does not need it: SQLite has no decimal storage class.
2. The spec forbids it: `BigDecimal` is `@std/numbers`, decided.
3. The doctrine forbids it: it is DATA and behaviour over a record,
   which is a library.
4. The cost is a full third registry pass (§2.1's thirty arms, four
   `Expr` arms, an instruction, a lexer arm, an `RtKind`) for
   something that composes out of what the campaign is already
   landing.

**When the ORM wants money, build `@std/numbers` with `BigDecimal` as
a record over `{ mantissa: Bytes, scale: int, negative: bool }`** —
which is a real, honest use of the `Bytes` category this campaign
lands, and a genuinely good dogfooding proof of it. If that record
turns out to WANT a language construct (operator traits, so `a + b`
works on a `BigDecimal`), **that ask goes in the ROADMAP's sugar
backlog naming the wanting site**, per CLAUDE.md's "Dogfooding is
design" rule — which is exactly what the backlog exists for, and
exactly what a core `decimal` would have short-circuited.

One thing IS worth doing in this campaign: **a literal suffix
placeholder.** Spec §31.5 reserves `f32`/`f64`/`float` suffixes. When
`scan_number` lands (§3), make it refuse an unknown suffix with a
NAMED diagnostic rather than lexing it as an adjacent `Name`. Then
`19.99d` refuses with "decimal literals arrive with `@std/numbers`"
instead of parsing as `19.99` followed by an identifier `d` — which is
the kind of silent nonsense the current lexer would produce.

---

## D) OWNERSHIP — which are managed, and what the memory pass sees

The single question is `is_managed` (`language/memory.av:31-45`), and
it decides everything: retains at call seats, releases at scope exits,
the `Alloca`/`Store`/`Load` cell protocol, and whether a value can
leak.

| Category | `ptr_shape` | `is_managed` | Header | Verdict |
|---|---|---|---|---|
| `float` | **false** | **false** | none | **SCALAR.** An unmanaged 64-bit register. |
| `Bytes` | **true** | **true** | yes, `KIND_BYTES` | **MANAGED.** Refcounted exactly like `Str`. |
| `decimal` | n/a | n/a | n/a | **Not a category.** A record; its FIELDS' management is what counts. |

### `float` — a scalar, and what that buys

- `language/memory.av:31-45` — joins the `false` or-run beside `.Int`
  and `.Bool`. **No retain, no release, ever.**
- `core/types.av:118-125` `ptr_shape` — `false`.
- `Ins.ConstFloat` joins the `manages(...)` or-run in `memory_ins`
  (`language/memory.av:190-198`) beside `ConstInt`/`ConstBool`.
- `features/unify.av:131-143` `slot_worthy` — `true`. A float fits a
  box slot as a word, so `List<float>`, `Result<float, E>` and an
  enum payload all work with no new representation.
- **`float?`** is the interesting case, and it is already solved.
  `opt_rides_pointer` (`core/types.av:184-186`) asks
  `rides_pointer(inner) || is_flat(inner)`; a float answers `false`
  to both, so `float?` is the REGISTER PAIR `{ i1 present, double
  value }` (`language/llvm.av:222-230`, `opt_ll_type`), built with
  `Ins.Pack` and read with `Ins.Extract`. Unmanaged, never allocated,
  and it is exactly how `int?` already works. `insisted_pair`
  (`features/values.av:405-411`) and `avra_insist_scalar`
  (`core/runtime_api.av:42`) carry it. **A `float?` column read —
  which is every nullable REAL in SQLite — costs nothing.**
- The one trap: `hollow_of` (`features/values.av:365-372`). Its
  default is `zeroed` to `Ins.ConstInt(z, 0)`, which is an i64
  constant in a `double` register. **This is a build-time LLVM
  verifier failure, not a silent bug** — the `.Bool` arm exists for
  the identical reason. Add the `.Float` arm.

### `Bytes` — managed, and the header law applies in full

CLAUDE.md: *"EVERY POINTER AVRA HOLDS CARRIES A HEADER… A new C fn
that answers TEXT to a program allocates it with `box_alloc`/
`str_owned`, or `str_static` when the program must never own it —
never a bare `malloc` or a C literal."*

Every `Bytes` a C body answers must therefore come from `box_alloc`
with `KIND_BYTES`. **This is the campaign's sharpest edge**, because
the natural SQLite call is:

```c
const void* p = sqlite3_column_blob(stmt, i);
int n = sqlite3_column_bytes(stmt, i);
```

`p` points into **SQLite's own memory**, which has no Avra header and
is invalidated by the next `sqlite3_step` or `sqlite3_finalize`.
Handing it to a program as a `Bytes` violates the header law
immediately: `avra_rc_retain` would read sixteen bytes before an
address that is not ours. `hdr()` (`runtime/avra_runtime.c:68-73`)
would *probably* answer NULL (its alignment and image-base guards) and
the retain would silently no-op — but "probably" is not the law, and a
16-aligned SQLite allocation whose preceding sixteen bytes happen to
spell `0x41565241` is a use-after-free with a live refcount.

**So the driver's column read is a COPY, always:** `box_alloc(n + 1,
KIND_BYTES)`, `memcpy`, terminate, answer owned
(`owns_result: true`). The same law makes `sqlite3_column_text` a copy
into a `str_owned`. That is not a performance failure — it is the same
copy every safe binding in every language makes at that boundary, and
it is what makes `Bytes` participate in refcounting at all.

The memory pass then gets `Bytes` right for free, because it is
structurally `Str`:

- retained at every managed call seat (`retained_args`,
  `language/memory.av:121-133`);
- released in reverse binding order at scope exit;
- **the mut-cell protocol** (`:143-165`) — a store retains the
  incoming value FIRST, then releases what the cell held, and the
  cell's own reference settles at its scope. CLAUDE.md records that
  `mut x: T? = null` once seeded a cell in the NULL's type and leaked
  600 MB, so **a `mut b: Bytes? = null` must seed a cell wearing
  `Bytes?`**, not `Null`;
- **THE CONDITION RUNS EVERY TURN** (`:176-187`) — a `while` whose
  condition reads a `Bytes` settles at each `LoopCond`. Already
  handled; nothing category-specific.

### `decimal` — nothing to decide

A record's management is `is_managed`'s
`.Struct(_, _) -> !types.is_flat(ty)` arm (`language/memory.av:33`). A
`BigDecimal` holding a `Bytes` mantissa is a non-flat record: boxed,
refcounted, and its slot release reclaims the mantissa by the existing
`array_reclaim` recursion (`runtime/avra_runtime.c:427-428`). **Zero
new ownership machinery.**

That is the last and strongest argument for §C's recommendation: the
category that would cost the most gains the least, and the two the
campaign actually needs pay for it.

---

## CONFIDENCE LEDGER

| # | Claim | Confidence | How verified |
|---|---|---|---|
| 1 | Thirty exhaustive `Type` dispatches; a new variant breaks all of them | HIGH | Grepped `.EmptyMap` (the last variant added) across the tree; every hit read and classified. Table at §2.1. |
| 2 | Exactly four exhaustive `Expr` dispatches | HIGH | Grepped `VariantLit` outside `features/enums/`; four match sites, each read. |
| 3 | Eight exhaustive `Ins` consumers, gate-enforced | HIGH | `tools/vocab.sh` `CONSUMERS` list, read in full; `Makefile:136` wires it into `gate`. |
| 4 | `1.5` lexes as `Num(1) Op(.) Num(5)`; `1e9` as `Num(1) Name(e9)`; `1_000` as `Num(1) Name(_000)` | HIGH | `grammar/lexer.av:303-339` `scan_step` read arm by arm, with `two_char_of` (`:280-294`) and `is_single_op_code` (`:70-74`). |
| 5 | The exact refusal text for `1.5` today | MEDIUM | Inferred from the postfix rule (`features/expr_spine/mod.av:40` wants `p:NAME`). Not probed — machine rule forbids running the compiler. |
| 6 | `RtKind` has no float slot, so a `float` extern is declared `i64` | HIGH | `core/ir.av:217`; `core/runtime_api.av:95-99`, `:103-105`; `language/lower.av:52-55`; `language/llvm.av:175-181`. |
| 7 | A `double` in an integer register is the wrong ABI on x86-64 and AArch64 | HIGH | SysV AMD64 psABI and AAPCS64 — external knowledge, not a tree read. The mechanism (which register) should be re-confirmed if anyone doubts it; the CONSEQUENCE (wrong values, no diagnostic) follows from claim 6 alone. |
| 8 | `avra_llvm_build_global_string_ptr` truncates at `strlen` and writes the truncated length into the header | HIGH | `backend/llvm_wrapper.c:460-483`, read in full. |
| 9 | The header is `{u32 tag, i32 kind, i32 rc, u32 len}`, sixteen bytes, before the payload | HIGH | `runtime/avra_runtime.c:56-61`, plus `hdr` (`:68-73`) and `box_alloc` (`:244-260`). |
| 10 | `str_len` treats `len == 0` as "not recorded" and falls back to `strlen` | HIGH | `runtime/avra_runtime.c:271-275`, verbatim. |
| 11 | A zero-length blob without a terminator would read a recycled free-list byte | MEDIUM | Follows from claim 10 plus `box_alloc`'s free-list reuse (`:246-251`) and `str_box`'s uninitialised payload (`:264-268`). Not demonstrated by running. |
| 12 | Five of eleven string runtime fns truncate at a NUL | HIGH | Each read: `:475-478`, `:1144-1146`, `:1159-1162`, `:1207-1230`, `:1232-1251`; the six that do not, likewise. |
| 13 | `avra_rc_release` needs no arm for a new plain box kind | HIGH | `runtime/avra_runtime.c:415-434` — the `else` branch is `box_free`, correct for a box with no owned slots. |
| 14 | The wrapper has no float builders; `cast_to_type` alone handles doubles | HIGH | `language/llvm_api.av` read in full (61 lines); `backend/llvm_wrapper.c:604-647` read in full; `ROADMAP.md:7532-7536` explains the sweep. |
| 15 | `rt_arg` has no float arm, so `List<float>` fails the LLVM verifier | HIGH on the missing arm (`language/llvm.av:432-446`, `backend/llvm_wrapper.c:487-501` do no coercion); MEDIUM that the failure mode is specifically the verifier rather than an earlier crash. |
| 16 | fcmp is ordered/unordered; `==` is `oeq` and `!=` is `une` | HIGH on the semantics (IEEE 754 + `FULL_SPEC.md:6289`); MEDIUM on the numeric `LLVMRealPredicate` values quoted in §8.2 — confirm against the installed LLVM-C headers before typing them. |
| 17 | The spec forbids implicit int/float conversion and requires a decimal point or exponent on float literals | HIGH | `FULL_SPEC.md:6274-6293` (§31.2), quoted verbatim. |
| 18 | The spec puts `BigDecimal` in `@std/numbers`, not the core | HIGH | `FULL_SPEC.md:6296-6317` (§31.3), quoted verbatim. |
| 19 | The spec's byte-string literal `b"..."` is typed `List<u8>`; the spec has no `Bytes` type | HIGH | `FULL_SPEC.md:5570` (§28.3); grepped `Bytes` and `u8` across the spec — no blob type anywhere. |
| 20 | SQLite has five storage classes and no decimal one; NUMERIC affinity stores INTEGER or REAL | HIGH | `https://sqlite.org/datatype3.html` — documentation, not a tree read. |
| 21 | `float?` is a register pair and costs no allocation | HIGH | `core/types.av:184-186` `opt_rides_pointer`; `language/llvm.av:222-230` `opt_ll_type`; `features/values.av:405-411` `insisted_pair`. |
| 22 | `hollow_of` would emit an i64 zero into a float register | HIGH | `features/values.av:365-372` + `zeroed` (`:260-263`). The `.Bool` arm exists for exactly this reason, which is the corroboration. |
| 23 | `build_neg` desugars `-x` to `0 - x` with an `IntLit(0)` | HIGH | `features/expr_spine/builders.av:48-55`, verbatim. |
| 24 | Two existing tests assert `` `float` names no type `` | HIGH | `features/fns/tests/fns_test.av:85-87`; `features/type_expr/tests/type_expr_test.av:37`. |
| 25 | The next free fingerprint tag is 62, not 52 as the comment says | HIGH | Extracted every `fp(N` in `core/nodes.av`: 1–60 minus {29, 41}, plus 61 in `Comp`'s conditional. Comment at `:776`. |
| 26 | Next free typing diagnostic code is F2056 | HIGH | Grepped every `"F2NNN"` literal in the tree; F2000–F2055 present, F2018 absent (reserved), F2056 free. |
| 27 | The compiler cannot hold a `float` value until `float` exists (the bootstrap circularity) | HIGH | Structural: the compiler is Avra compiled by `build/avra` (README, `Makefile:45`), and `Expr`/`Ins`/`Val` payloads are Avra types. |
| 28 | Carrying BITS resolves it at zero cost | MEDIUM-HIGH | The mechanism is sound and every piece exists (`strtod` in C, `LLVMConstBitCast` in the wrapper's `cast_to_type`, `Val.I` in the interpreter). Not implemented, so "zero cost" is a design judgement, not a measurement. |
| 29 | `%g`/`%.17g` are inadequate and the precision ladder is exact | HIGH on inadequacy (standard IEEE printing knowledge); HIGH on the ladder's exactness (17 significant decimal digits always round-trip an IEEE double); MEDIUM that ~15 lines suffices — not written. |
| 30 | `is_managed` is the single ownership decision for a new category | HIGH | `language/memory.av:31-45` is the only definition; `memory_ins` (`:60-200`) and `retained_args` are its only consumers. |
| 31 | A `sqlite3_column_blob` pointer must be COPIED, never handed over as a `Bytes` | HIGH | Follows from CLAUDE.md's header law plus `hdr`'s tag check (`runtime/avra_runtime.c:68-73`). The specific failure (a false tag match on a 16-aligned foreign allocation) is LOW-probability but unbounded, which is what makes copying the only defensible answer. |
| 32 | Feature registration is two lines and the position is beside `expr_spine()` | HIGH | `language/mod.av:118-165`, with each existing entry's positioning comment read. |
| 33 | `float` and `Bytes` are `shape_named` entries, not `TypeRow`s | HIGH | `language/typing.av:315-323` holds every arity-0 primitive; `features/mod.av:73` `TypeRow` carries an `arity` and a `builds` fn for constructors. |
| 34 | `List<u8>` costs ~9x a blob's bytes | MEDIUM | `runtime/avra_runtime.c:514-523` — `int64_t* data` plus a parallel `uint8_t* owned`, one buffer. 8 + 1 bytes per element is arithmetic on that struct; not measured. |
