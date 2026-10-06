# `law` declarations — design (avra-8sb5.34.53.26, phase A)

Probed with `build/avra` as seeded in `../avra-flow-law` at 0d261da, scratch files outside the tree. Paths are under `packages/std-avrac/src/`.

## 1. Grammar — PROBED
- TODAY REFUSES every spelling, at the parser: one `for` clause per line (BEND §3.1) is 3x F0100 "expected `in` while parsing `stmt`" + "expected BREAK"; `law n { for a: int, b: int …` and `law n(a: int) { … }` are "expected BREAK while parsing `stmt`". `let law = 3` and `fn f(law: int)` check clean.
- THE WORD IS SOFT, not reserved. A grammar literal becomes a keyword (`std-grammar/src/ast.av:34`) and a keyword is refused as a field, a parameter, a binding (PROBED with `given`: `resolve.reserved`) AND as an annotation (PROBED: `@const(1)` is "`const` is a keyword"). `law` is a name on 27 code lines in 15 files (counted, strings and comments stripped) — `rule`'s `law:` field and six `@law("…")` marks among them (`features/rule.av:48`, `:65`). The lexer already re-kinds `state` and `on` by position (`grammar/lexer.av:1476-1479`, `opens_state` `:1490`): add `TokenKind.Law` for `law NAME {` at `starts_statement` (`:1591`, which covers `export`), a `LAW` row in `grammar/bridge.av:43-45`. No rename, no bridge PR.
- THE RULE (new `features/laws/`): `stmt = LAW n:NAME "{" ( BREAK | "for" ps:NAME ":" pt:type ( "," ps:NAME ":" pt:type )* ","? )* v:expression BREAK* "}" END @recover(sync_to: "END") -> law_decl(n, ps, pt, v)`.
  Laws obeyed: every comma list takes a trailing comma; a statement ends at `END`; `@recover` is safe because `LAW` anchors no other rule (the shared-anchor law); it merges before the `expr_stmt` floor; no expression starts with `for`, so the binder star cannot eat the claim. Both the brief's `for a: T, b: T` and BEND's one-per-line parse. `where` is NOT in the first cut (it would reserve a word that is a name today — PROBED `let where = 3` clean).
- THE NODE IS A FN. `once fn` is `Stmt.FnDecl` plus a side mark (`features/fns/builders.av:84-97`, `core/store.av:13`). A law is `FnDecl(name, [], binders, bool, claim)` plus `mark_law`: no new `Stmt` variant (18 `.Spec(` arms outside tests) and no new `DeclKind` (45 `.Case` sites). The law is then a callable predicate (`add_assoc(1, 2, 3)` in a `then`). The mark's readers, by `is_once`'s: `core/rebuild.av:574`, `compiler/format/source_text.av:747`, `compiler/typing/declare.av:471`, and the statement fingerprint the same day (CLAUDE.md "a hash that forgets a payload").

## 2. Typing
- Binders are typed parameters, all written. The claim is ONE `bool` (`law.type`, through `cx.accepts` as `features/specs/check.av:9`), not only `lhs == rhs` — `ascending(sort(xs))` is a law.
- TODAY'S `==`, PROBED: lists, maps and two-field records are `type.mismatch` "`==` compares by value — a scalar, text, a tagged enum, or a record of one such field"; `int?`, text and floats compare. So int and string associativity need nothing. A law comparing lists or records needs structural `==` — NOT this lane's (a language equality change; owner unconfirmed, COLLECTIONS is the nearest). Until then such a law compares a projection (`.length`, `.join`).
- FLOATS type and run: `(x + 0.2) + 0.3 == x + (0.2 + 0.3)` at `x = 0.1` answers `false` (PROBED, `avra run`). The projection carries `exact: bool` (no `float` under any binder), which is what `flow.float_law` (slice 18) reads.
- REACH is `Pure`, inferred: the settler's fence is reused (`const.reach`, `compiler/lower/state.av:941`), with a law voice `law.reach`.

## 3. Generation — built-ins first
- STRUCTURAL, BY THE COMPILER, no derive and no trait. A trait cannot do it today: no type-qualified call, and `impl Arbitrary for List<T>` is F2031. The compiler knows every shape, as `text_projection` does for printing (`features/specs/lower.av:71-74`).
- LEAVES ARE AVRA, in `@std/testing` (depends on nothing — `packages/std-testing/avra.toml`): `arb_int(seed, at, size) -> int`, `arb_text`, `arb_bool` — stateless and pure, so both engines draw the same values. Edge values first (0, ±1, the two ends, `""`, a NUL-carrying text), then a mix. PROBED: `^`, `>>` and wrapping `+` are there. The package is reached the way the prelude is (`compiler/packages.av:234` `reaches`), only by a file that declares a law.
- ONE DRIVER PER LAW, lowered beside it: `check(seed: int, n: int) -> int` (the failing case, or -1). `avra test` calls it natively as it calls a case (`compiler/suite_entry.av:10-12`, `compiler/derive.av:863`); the settler runs the same instructions. FIRST CUT: `int`, `bool`, `string` — enough for associativity on ints and on strings. Next: payload-free enums, `T?`, `List<T>`, records, each one PR. A binder with no generator: `law.domain`, status `open`.
- SHRINK IS BY SIZE: a failing case is redrawn at halved `size` while it still fails. Cheap, no per-type shrinker. The failure prints the binders (text projection), the seed, the case, and the command that replays it.

## 4. Status ladder
| status | who sets it | how |
|---|---|---|
| `proven` | the compiler | every binder's domain is finite and walked whole (`bool`, payload-free enums, their products up to 4096 — ESTIMATE). SMT is a later lane. |
| `checked (n)` | the compiler | the driver held for `n` cases at a fixed seed (n = 256 — ESTIMATE, under the settler's budget) |
| `trusted` | the author | never derived. `core`'s `LawStatus` carries it for slice 8's `keyed`/`reading` claims; a `law` has no spelling for it in v1 (owner question 3) |
| `open` | the compiler | no generator, past budget, or reach refused; licenses nothing |
A FALSE law is not a status: `law.false`, an error carrying the binding.
- STORED NOWHERE AS TRUTH. `law_status(decl)` is a query settled like a `const` and kept across builds like one (`compiler/kept_settle.av:1-17`), so a build's bytes stay a function of its source and deleting `.avra-cache` changes no licence. It is LAZY: only a licence, `avra laws` or `avra test` asks. `avra test` runs MORE cases under a printed seed (`--seed`), and never moves a status.
- THE RELEASE BUILD reads `licence(row, status, mode) -> { No, Yes, Marked }`, spec §10.1's rows as a `table` in `core/laws.av`; `--laws proven` (until `deploy` exists) turns `Marked` into `No`. Printing a `Marked` licence is its user's job (slice 18).
- PROJECTION: `avra laws [dir] [--json]`, one command file beside `commands/rules.av`: name, module, file:line, binders, status, n, seed, `exact`, and `form`.

## 5. PR ladder — each leaves main green
1. `grammar`: `TokenKind.Law`, `opens_law`, the rule, `mark_law`, formatter, fingerprint; program tests that parse and CALL a law. SYNTAX CHANGE: `cp build/avra build/avra.pre`, build twice. No seed refresh — the compiler's own source declares no law, and `law` stays a legal name (0 renames).
2. `typing`: `law.type`, binders written, `law.reach`; goldens.
3. `generation`: `@std/testing` leaves + their suite (same seed, same values, both engines); the implicit reach.
4. `runner`: the driver, `avra test` running laws, `law.false` with seed and shrink, `law.domain`.
5. `status`: `LawStatus`, the `law_status` query, the walked-whole rung, the licence table and its keeper against spec §10.1.
6. `projection`: `avra laws --json`, and `form` (associative / commutative / idempotent / absorbing over a named fn, matched on the claim's shape).
7. later, each alone: enums and `T?`; `List<T>`; records; the first law in the compiler's own source (THAT one rides a seed refresh).

## 6. Tests and risks
- Tests first, each failing for its real reason: `add` associative on ints holds; text `+` holds; a planted `sub` law fails with a replayable seed; the float law above fails; eval == native on the driver's answer; `fmt(x) == x` over a law file; two laws differing only in a binder's type fingerprint apart.
- RISKS: (a) a declared `component law` meets the soft word — refuse the component by name; (b) the settler running a synthesized driver is ESTIMATE, read not run; if it cannot, PR 5 falls back to a committed receipt (owner question 2); (c) 256 cases per asked law at a cold release build is unmeasured; (d) `form` matched on spelling misses `a + b` written as a method — slice 18 must say which spellings it needs; (e) implicit reach of `@std/testing` is new for a non-prelude package.
