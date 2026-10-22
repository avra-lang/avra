# Proposal: integer overflow, and int → float

Status: APPROVED by the owner 2026-10-21. Tickets avra-8sb5.11.161 and .212.
Probed at `693638fc`+, `avra run` (eval) and `avra build` (native), same output.

## 1. Integer overflow is silent

```
add  9223372036854775807 + 1        -> -9223372036854775808   (eval == native)
sub  smallest - 1                   ->  9223372036854775807
mul  (1 << 62) * 2                  -> -9223372036854775808
shl  1 << 63                        -> -9223372036854775808
neg  0 - smallest                   -> -9223372036854775808
div  smallest / -1                  -> -9223372036854775808   (spelled to wrap, runtime avra_int_div)
const folded = 9223372036854775807 + 1   -> -9223372036854775808  (compile time, no word)
```

The language already traps on the neighbouring hazards: `/` and `%` by zero
(`avra_trap("division by zero")`) and a shift count outside 0..63
(`type.shift_count` at compile time, a trap at run time). Overflow is the one
arithmetic hazard that still answers a wrong number silently. Wanting sites:
std-http's HPACK integer decode bounds each step by hand. The graph's money
and stock derivations need hand-written `difference`/`total` helpers.

**Recommend: trap by default, with wrapping and checked forms as named verbs.**

- `+ - * <<`, unary `-` and `/` (for smallest / -1) TRAP on overflow:
  `avra: integer overflow — 9223372036854775807 + 1`, exit 2. A const that
  overflows is refused when it settles, at its own line. The law is the
  same in both engines because one guarded definition serves both, as
  `avra_int_shl` already does.
- Wrapping is asked for by name: `a.wrapping_add(b)`, `wrapping_sub`,
  `wrapping_mul`, `wrapping_shl`. Hashes and fingerprints use these
  (`core/fp.av`'s `fp`, `core/digest.av`'s `mix_final`, the FNV folds in
  std-http `route.av` and the gallery).
- Checked arithmetic answers absence: `a.checked_add(b) -> int?`, likewise
  `checked_sub`, `checked_mul` and `checked_shl`. A parser that must report
  overflow, such as HPACK, writes `x.checked_mul(128) ?? fail …`.

This is P6. A trap is the right default for code that never thought about
overflow, which is most code (P1). A program that means wrapping, or wants to
answer the overflow itself, says so at the site. Nobody has to choose a
global mode.

**Cost (P4).** Native code lowers to `llvm.sadd/ssub/smul.with.overflow`: one
flag test per operation, with the trap call out of line, `cold` and
`noreturn`, per the cold-path law, so the hot path gains no frame. The
evaluator's arms add one comparison. Overflow checks can block
vectorisation of tight integer loops, and those loops are the hashes, which
move to the wrapping verbs and pay nothing. **Before landing,** measure with
`make census` plus a stopwatch on `check packages/cli`, before and after.
The expected figure is around 1–2%; it is a guess until measured.

**Migration.** Every site that relies on wrapping stops on the trap by name
the first time it runs. The compiler's self-build and the gate are the
census. Land it in two rungs: first the wrapping verbs and their adoption at
the hash sites, then the trap.

## 2. int → float has no spelling

```
n.to_float()       -> type.method   "`.to_float(…)` calls a method, and `int` has none"
float(n)           -> type.lambda   "`float` is not callable — it holds a `type float`"
n * 1.0            -> type.mismatch "`*` needs `int` operands, found `float`"
n as float         -> parse.expected
f.floor()          -> Result<int, ToInt>   (the opposite direction exists: floor/ceil/round/trunc)
parse_float("9007199254740993.0")! -> 9007199254740992.0   (eval == native: nearest float)
```

Today's workaround in the graph's `rank.av` is `parse_float("${n}.0")`: a
string round trip per count.

**Recommend: `n.float() -> float`, which is total, answers the nearest float
(ties to even), and is exact for |n| ≤ 2^53.** Mixed arithmetic stays
refused, so a widening is always written at its site (P9).

- **Why total and not a `Result`.** Every int has a nearest float, so there
  is no failure to report. Only precision is at stake, and only above 2^53,
  where `parse_float` already rounds the same way. The reverse direction is
  a `Result` (`ToInt`) because there a float can have no int at all (NaN,
  out of range). The asymmetry follows what can actually fail.
- **The name.** It reads as the receiver's word, like `floor`/`round`, with
  no `to_` prefix. The rounding is stated in its doc, and a witness pins
  `9007199254740993.float() == 9007199254740992.0` in both engines.
- **Lowering.** One `sitofp` instruction; the evaluator calls the C cast.
  It needs one `MethodRow` in `features/floats/mod.av`, beside the four
  roundings.
- **Not proposed now.** An exact form, `n.float_exact() -> float?`, waits
  until a wanting site appears.

The JSON half of .212 (fractions into a `float` field) is separate. Since
the ticket was filed, `@std/json` reads fractions as `Float`
(`json_float_test.av`) and `parse_float` has landed in `@std/text`. Any gap
left is in std-validate's decoder, and it needs no language change.
