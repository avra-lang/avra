# `law` declarations — design (avra-8sb5.34.53.26), revision 2

Probed with `build/avra` as seeded in `../avra-flow-law` at 0d261da (not verified to be built from it), scratch files outside the tree. Paths are under `packages/std-avrac/src/`. Revision 2 answers review 1 (`avra-channels-briefs/flow-law-review-1.md`); the lead ruled: a SOFT word, no `trusted` law in v1, status derived PLUS a committed counterexample file.

## 0. What this lane delivers
PRs 1–6 serve laws over `int`, `bool` and text: slices 10 and 18 (associativity, commutativity). Slice 8's absorption row compares records (`step(…) == step(…)`, spec §7.3) and WAITS on structural `==`, which is its own ticketed lane. No law is licensed from a claim that compares a projection of the state.

## 1. Grammar — PROBED
- TODAY REFUSES every spelling at the parser: one `for` per line is 3x F0100 "expected `in` while parsing `stmt`" + "expected BREAK"; `law n { for a: int, b: int …` and `law n(a: int) { … }` are "expected BREAK while parsing `stmt`".
- THE WORD IS SOFT. A grammar literal is a keyword (`std-grammar/src/ast.av:34`), refused as a field, parameter, binding (PROBED with `given`) and as an annotation (PROBED: `@const(1)` is "`const` is a keyword"), and `rule` carries `law:` and `@law("…")` (`features/rule.av:48`, `:64`). Count of `law` as a name: strip `"…"` and `//…` per line, match `\blaw\b`, over `packages/**/*.av` — 27 lines, 15 files, tests included. The lexer re-kinds `state` and `on` by position (`grammar/lexer.av:1476-1479`, `:1490`); `law NAME {` at `starts_statement` (`:1591`, covers `export`) becomes `TokenKind.Law`, term `LAW` (`grammar/bridge.av:43-45`). A declared `component law` is refused by name.
- THE RULE LIVES IN `features/fns/`, as `once fn` does (rule `mod.av:55`, builder `builders.av:72-97`) — gram and builder are one unit, and no feature imports a feature; `seats` and `aligned_param_types` are already `features/builder.av:577`, `:397`:
  `stmt = LAW n:NAME "{" ( BREAK | "for" ps:NAME ":" pt:type ( "," ps:NAME ":" pt:type )* ","? ( jn:"." )? )* ( s:stmt | BREAK )* "}" END @recover(sync_to: "END") -> law_decl(n, ps, pt, jn, s)`
  Trailing comma; ends at `END`; `LAW` anchors no other rule, so `@recover` is safe; merges before the `expr_stmt` floor. `where` is not in the first cut (PROBED: `let where = 3` is clean today).
- THE BODY IS A BLOCK, built by the one block law (`features/builder.av:263` `block_of`, as `features/block/builders.av:6`): statements, then the claim as the tail. So every FnDecl consumer sees the shape every fn body has, and a law may bind before it claims (`let once = step(s, x)`).
- A LEADING `.` JOINS THE BINDER ABOVE (review 5: the lexer drops that break). A type takes no `.` (`features/type_expr/mod.av:34-40`), so the rule captures one as `jn` and the builder refuses in its own words: "a line beginning with `.` continues the binder above it — parenthesise the claim".
- THE NODE IS A MARKED FN: `FnDecl(name, [], binders, bool, block)` plus `mark_law` (`core/store.av:13`), restamped with its own tag (`core/store.av:1207-1219`). No new `Stmt` or `DeclKind`. A law is a predicate: calling it and holding it as a value (`fn(int, int, int) -> bool`) are both legal and pinned by tests. EVERY reader of the `once` mark, and what the law mark does there:
  | reader | law |
  |---|---|
  | `features/fns/builders.av:97` | `mark_law` |
  | `core/rebuild.av:574` | copied |
  | `compiler/format/source_text.av:747` | its own print path: `law name {`, one `for` clause per written clause, the block's lines; comments kept on every line |
  | `compiler/typing/declare.av:471` | `law_laws`: every binder typed (PR 2) |
  | `compiler/typing/impls.av:457` | `law.place`: "a law lives at the top level" — an `impl` body takes any `stmt` (`features/impls/mod.av:53`) |
  | `compiler/lower/lower.av:966` | nothing: a law lowers as the fn it is |
  Also `features/fns/stmt.av:12` (`resolve.nested_fn`) speaks `law.place` for a law in a block. A name shared with a fn is the ordinary duplicate refusal. PR 2 adds a `law` fact to the decl row (`features/decls.av:303`) and its hash, so a dependency's law is not a plain exported fn.

## 2. Typing
- Binders are typed parameters, all written. The claim is ONE `bool`: `law.type`, replacing the fn voice "the body answers … but … declares" (`features/fns/check.av:663`) when the statement is a law.
- `==` today, PROBED: lists, maps, two-field records are `type.mismatch`; `int?`, text, floats compare. See §0.
- FLOATS run: `(x + 0.2) + 0.3 == x + (0.2 + 0.3)` at `x = 0.1` answers `false` (PROBED). The projection carries `exact` (no `float` under a binder) for `flow.float_law`. No `arb_float` in the first cut; when it lands, NaN is an edge value and `f == f` is false there.
- REACH is `Pure`, inferred; the settler's fence (`const.reach`, `compiler/lower/state.av:941`) with the voice `law.reach`.
- A law in `@std/prelude` is refused (`law.prelude`): it would give the floor a dependency (`compiler/packages.av:167`).

## 3. Generation
- STRUCTURAL, by the compiler: no trait (no type-qualified call; `impl … for List<T>` is F2031), no derive.
- LEAVES ARE AVRA in `@std/testing`: `arb_int(seed, at, size) -> int`, `arb_text`, `arb_bool` — stateless, pure. The package keeps NO dependency: `arb_text` declares the runtime's code-point row itself rather than importing `@std/text` (a law in `@std/text` would otherwise close a cycle). The compiler holds the leaves' signatures as rows and checks them when the package is admitted, as `features/crossing.av` holds `@std/meta`: a moved leaf is refused by name, never a lowering failure.
- EDGE ORDER, then a mix: case k < 5 draws every binder's k-th edge — int `0, 1, -1, MAX, MIN`; text `"", "a"`, a NUL-carrying text, a two-byte character, 64 characters; bool `false, true`. From case 5 on, each binder draws independently from edges and mixed values.
- ONE DRIVER PER LAW, `check(seed, n) -> int`, called natively by `avra test` (`compiler/suite_entry.av:10-12`) and run by the settler. First cut: `int`, `bool`, text, and payload-free enums (moved up, so `proven` is reachable). Later, one PR each: `T?`, `List<T>`, records.
- A TRAP IS A VERDICT, `law.trap`, apart from `law.false`. Case 0 of `(a / b) * b + a % b == a` traps (PROBED: `avra: division by zero`, exit 2). Natively the driver writes its case number to the in-flight marker (`compiler/suite_entry.av:16-22`); on a death the CLI re-runs the binary as a CHILD for that one law and case, which prints the binding and then dies — the machinery `.refuses` tests use. Shrinking a trap is one child per halving, at most 8 (ESTIMATE). In the settler a trap is caught as `const.trap` is.
- SHRINK IS BY SIZE: redraw at halved `size` while it still fails.

## 4. Status
| status | set by | how |
|---|---|---|
| `proven` | the compiler | every binder finite and walked whole: `bool`, payload-free enums, products up to 4096 (ESTIMATE) |
| `checked (n)` | the compiler | the corpus, then n cases at a fixed seed, all hold (n = 256 — ESTIMATE) |
| `open (why)` | the compiler | no generator, or past budget |
`trusted` exists in `core`'s `LawStatus` for slice 8's effect claims; no law reaches it. FALSE and TRAPPED are errors, not statuses.
- DERIVED: `law_status(decl)` settles like a `const` and is kept like one (`compiler/kept_settle.av:1-17`).
- THE CORPUS: `laws.failed`, beside `avra.toml`, committed. First line `arb 1` (the leaves' version). Then one line per counterexample, sorted, unique: `module.law seed case size`. `avra test` WRITES a line when a law fails or traps (after shrinking) and prunes a line whose law is gone, saying so. The build's driver and `avra test` REPLAY a law's lines FIRST; a line that fails is `law.false` and the build is red, so a known-false law never holds a licence. The file is an input of `law_status`, kept by what it says now (the kept settlement's rule for a file a run read, `kept_settle.av:12-13`). A line that holds stays, as a regression case.
- BUDGET (review 3): laws take their own row, `[laws] steps`, never `[lifted]` (`features/worklist.av:45-46`: 600000 steps is 2343 a case at n = 256). Steps per case for int and text associativity are MEASURED before PR 5 and n is set from them. `open` is LOUD: `law.budget` (a warning naming the law, the case and the steps) prints in every build that asks the law's licence, and `avra laws` prints `open (budget)`.
- THE GATE is `avra test`: it settles every declared law and is red on `open`, false or trapped. `avra check` asks no status.
- LICENCES: `licence(row, status, mode) -> { No, Yes, Marked }`, spec §10.1's rows as a `table` in `core/laws.av`. `--laws proven` FIRST CUT, PLAINLY: every `int` or text law is `checked`, so under `--laws proven` they license NOTHING; only laws over `bool` and payload-free enums are `proven`. `avra laws` prints that line under any `checked` law.
- PROJECTION: `avra laws [dir] [--json]`: name, module, file:line, binders, status and why, n, seed, `exact`, `form`.

## 5. `form` — matched on the claim, keyed by declaration
The block's tail is ONE `==`, at the root (not under `&&`, `||`, `!`). Binders are DISTINCT and of ONE type per role. Either side order matches. A callee is its DeclId; `a |> f(b)` is `f(a, b)`; an operator is `(BinOp, type)`; a method is its declaration.
| form | claim | row of §10.1 |
|---|---|---|
| associative(f) | `f(f(a, b), c) == f(a, f(b, c))` | fold as reduce; lanes |
| commutative(f) | `f(a, b) == f(b, a)` | lanes; `.any` queue |
| absorbing(f) | `f(f(f(s, x), y), x) == f(f(s, x), y)` | no key |
| inverse(f, g) | `g(f(s, x), x) == s` | fold under removal |
| none | anything else | licenses nothing |
Each form gets a positive and a negative fixture per spelling (`f(f(a, a), a) == f(a, f(a, a))` is `none`), agreed with slice 18's owner before PR 6.

## 6. PR ladder — each leaves main green
1. grammar: soft word, rule and builder in `features/fns/`, mark and tag, formatter, `law.place`, the `.` join. `build/avra.pre`, build twice, `make bootstrap` + `seed-check`. No rename, no law in the compiler's source, so no seed refresh.
2. typing: `law.type`, binders written, `law.reach`, `law.prelude`, the decl-row fact.
3. leaves in `@std/testing`, their rows and crossing check.
4. runner: driver, `avra test`, `law.false`, `law.trap`, `law.domain`, `laws.failed`.
5. status: steps measured, `[laws] steps`, `law_status`, walked-whole rung, `law.budget`, the licence table.
6. `avra laws --json` and `form`.
7. later: `T?`, `List<T>`, records; the first law in the compiler's own source (rides a seed refresh).

## 7. Tests and risks
- First, failing for their real reason: a law parses and is called; `fmt(x) == x` with a comment on every line; two laws differing in a binder's type, or a law and the same-shaped fn, fingerprint apart; a law in an `impl` and in a block is `law.place`; a claim starting `.A` hears the join; `let law = 3` and `@law("…")` still check.
- ESTIMATE, read not run: the settler running a synthesized driver (else PR 5 keeps status in a committed receipt); the cost of n cases at a cold build; the two adjacent stars in the rule passing `grammar/first.av`.
