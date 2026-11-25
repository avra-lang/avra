# avra-lane-switch-rehearsal — package sweep 2 (trunk 5e7ff03b)

Compiler: S4 = an old-path `make try` of trunk 5e7ff03b (one binary for both paths). C objects first:
`make libs build/sqlite3.o build/sqlite_sentinel.o build/width_witness.o`. Every package was run cold: every
`.avra-cache` under packages/ and tools/ui-board, plus the tree's, was emptied before each step. Steps per package:
1. old build: `./avra build <pkg>`
2. new build: `AVRA_PROGRAM=1 ./avra build <pkg>`
3. `S4 tapes <ABS pkg> --ran --left`
4. old tests: `./avra test <pkg>`

Exceptions:
- **std-task** ran under `--only` over the 6 prefixes that cover its 12 non-signal tests. `signals` and
  `signals_usr1` were SKIPPED.
- **std-http** ran ONE TEST AT A TIME (`--only src/tests/<t>/`, 300 s timeout each). Its whole-package `--ran` HANGS
  (defect 1 below); no test hit the timeout.

The new-path `ran` cells are tests / made / printing in the evaluator / natively / runs failing. The "new build (text)"
cell says whether the first thing each path said matches.

## Totals

**785 program tests / 651 made / 41 failing** (613 printing in the evaluator, 644 natively).
First sweep (31f3d60): 761 / 521 / 1 failing.

What the 41 failing runs are:
- 30: the evaluator refuses `sqlite3_open_v2`: "has a seat the frame cannot carry — the evaluator holds one as a handle,
  not a box". std-crud 7, std-db 6, std-sqlite 3, std-http cores_* 14. Owner: extern-seats.
- 8: four std-http tests give the wrong answer in BOTH engines: h2c_client, h2c_serve, http_server_decl,
  http_specificity. Trunk a0ef1a00 says extern-seats-2 fixed "std-http wrong answers (a template-written lambda is
  lifted by its node)". Re-check there.
- 2: std-db db_diff and migrate_all are native != expected. The binary traps:
  "`type_named` resolves a declaration at compile time — this program reached it at run time". You say package-sweep-2
  owns this (a const settled at compile time on the old path).
- 1: std-http cores_memory_per_core, native. This row is polluted by defect 1: forked copies of the compiler print
  their own results.

## Table

| package | old build | new build (text) | old tests | new tests/made/eval/native/failing | not-made reasons |
|---|---|---|---|---|---|
| std-path | 1 | 1 (DIFFERS) | 31/31, 1 proved (exit 0) | 1/1/1/1/0 |  |
| std-task | 1 | 1 (DIFFERS) | 11/11, 14 proved (exit 0) | 12/12/12/12/0 |  |
| cli | 0 | 0 (DIFFERS) | 420/438 (exit 1) | 0/0/0/0/0 |  |
| site | 0 | 1 (DIFFERS) | 18/18 (exit 0) | 0/0/0/0/0 |  |
| std-action | 1 | 1 (DIFFERS) | 127/127 (exit 0) | 0/0/0/0/0 |  |
| std-assets | 1 | 1 (DIFFERS) | 19/19 (exit 0) | 0/0/0/0/0 |  |
| std-cli | 1 | 1 (DIFFERS) | 43/43, 1 proved (exit 0) | 1/1/1/1/0 |  |
| std-compress | 1 | 1 (DIFFERS) | 33/33, 1 proved (exit 0) | 1/1/1/1/0 |  |
| std-convert | 1 | 1 (DIFFERS) | 3/3, 1 proved (exit 0) | 1/0/0/0/0 | a hole that isn't a number, a truth or text 1 |
| std-crud | 1 | 1 (DIFFERS) | 2/2, 7 proved (exit 0) | 7/7/0/7/7 |  |
| std-db | 1 | 1 (DIFFERS) | 187/187, 1 proved (exit 0) | 7/7/1/5/8 |  |
| std-derive | 1 | 1 (DIFFERS) | - (exit 0) | 0/0/0/0/0 |  |
| std-errors | 1 | 1 (DIFFERS) | 21/21 (exit 0) | 0/0/0/0/0 |  |
| std-grammar | 1 | 1 (DIFFERS) | 56/56 (exit 0) | 0/0/0/0/0 |  |
| std-hash | 1 | 1 (DIFFERS) | 14/14 (exit 0) | 0/0/0/0/0 |  |
| std-http-fuzz | 0 | 0 (same) | - (exit 0) | 0/0/0/0/0 |  |
| std-http-soak | 0 | 0 (same) | - (exit 0) | 0/0/0/0/0 |  |
| std-http | 1 | 1 (DIFFERS) | 1364/1365 (exit 1) | 56/55/37/50/23 | a call of the generic `declared` whose arguments don't lay out its type parameters 1 |
| std-http_compress | 1 | 1 (DIFFERS) | 78/78, 1 proved (exit 0) | 1/1/1/1/0 |  |
| std-http_message | 1 | 1 (DIFFERS) | 17/17 (exit 0) | 0/0/0/0/0 |  |
| std-http_session | 1 | 1 (DIFFERS) | 22/22, 1 proved (exit 0) | 1/1/1/1/0 |  |
| std-https | 1 | 1 (DIFFERS) | 19/19, 7 proved (exit 0) | 7/7/7/7/0 |  |
| std-io | 1 | 1 (DIFFERS) | 121/121, 5 proved (exit 0) | 5/5/5/5/0 |  |
| std-json | 1 | 1 (DIFFERS) | 183/183, 3 proved (exit 0) | 3/3/3/3/0 |  |
| std-mcp | 1 | 1 (DIFFERS) | 143/143 (exit 0) | 0/0/0/0/0 |  |
| std-meta | 1 | 1 (DIFFERS) | -, 1 proved (exit 0) | 1/1/1/1/0 |  |
| std-net | 1 | 1 (DIFFERS) | 84/90 (exit 1) | 19/19/18/19/0 |  |
| std-openapi | 1 | 1 (DIFFERS) | 12/12, 1 proved (exit 0) | 1/1/1/1/0 |  |
| std-prelude | 1 | 1 (DIFFERS) | -, 1 proved (exit 0) | 0/0/0/0/0 |  |
| std-process | 1 | 1 (DIFFERS) | 119/119, 4 proved (exit 0) | 4/4/4/4/0 |  |
| std-program | 1 | 1 (DIFFERS) | 401/402 (exit 1) | 0/0/0/0/0 |  |
| std-queue | 1 | 1 (DIFFERS) | 10/10, 10 proved (exit 0) | 10/0/0/0/0 | a default of the generic `queue<Job>` 9, `StructLit` 1 |
| std-relation | 1 | 1 (DIFFERS) | 312/312, 1 proved (exit 0) | 42/42/42/42/0 |  |
| std-sql | 1 | 1 (DIFFERS) | 96/96 (exit 0) | 0/0/0/0/0 |  |
| std-sqlite | 1 | 1 (DIFFERS) | 517/517, 3 proved (exit 0) | 3/3/0/3/3 |  |
| std-testing | 1 | 1 (DIFFERS) | 9/9 (exit 0) | 0/0/0/0/0 |  |
| std-text | 1 | 1 (DIFFERS) | 200/200, 4 proved (exit 0) | 4/3/3/3/0 | `float.round` 1 |
| std-time | 1 | 1 (DIFFERS) | 49/49, 11 proved (exit 0) | 11/11/10/11/0 |  |
| std-tls | 1 | 1 (DIFFERS) | 64/64, 5 proved (exit 0) | 5/5/5/5/0 |  |
| std-toml | 1 | 1 (DIFFERS) | 46/46 (exit 0) | 0/0/0/0/0 |  |
| std-ui | 1 | 1 (DIFFERS) | 975/975, 1 proved (exit 0) | 75/6/6/6/0 | a record literal leaving a field no declared default fills 53, a `dyn` box over a method the type doesn't write 6, `StructLit` 2, an untyped `Comp`, first under it an untyped `StructLit` 2, `MutLet` 2, the method `describe` of `tap` 1, a call of the generic `headless` whose arguments don't lay out its type parameters 1, the method `describe` of `panel` 1, `Lambda` 1 |
| std-ui_gallery | 1 | 1 (DIFFERS) | 38/38 (exit 0) | 0/0/0/0/0 |  |
| std-ui_http | 1 | 1 (DIFFERS) | 17/17 (exit 0) | 0/0/0/0/0 |  |
| std-url | 1 | 1 (DIFFERS) | 177/177, 1 proved (exit 0) | 1/1/1/1/0 |  |
| std-validate | 1 | 1 (DIFFERS) | 152/152, 6 proved (exit 0) | 6/6/6/6/0 |  |
| width-witness | 0 | 1 (DIFFERS) | - (exit 0) | 0/0/0/0/0 |  |
| ui-board | 1 | 1 (DIFFERS) | - (exit 0) | 0/0/0/0/0 |  |
| std-avrac | 1 | 1 (DIFFERS) | - (exit 2) | 500/448/446/448/0 | `MethodCall` 4, `StructLit` 3, a hole that isn't a number, a truth or text 3, `ConstDecl` 2, an untyped `Call` 2, a match whose patterns aren't each one variant or the rest 2, `Binary` 2, a write to a `let` 2, a walk over a walk it runs as one with 2, a catch whose arms take a union's members 2, a written receiver a lambda captures 2, an untyped call through a type 1, `Index` 1, an or-pattern bind |

std-avrac's full not-made list: `MethodCall` 4, `StructLit` 3, a hole that isn't a number, a truth or text 3, `ConstDecl` 2, an untyped `Call` 2, a match whose patterns aren't each one variant or the rest 2, `Binary` 2, a write to a `let` 2, a walk over a walk it runs as one with 2, a catch whose arms take a union's members 2, a written receiver a lambda captures 2, an untyped call through a type 1, `Index` 1, an or-pattern binding a payload a pattern of its own holds, or whose type isn't known 1, `int.float` 1, `float.round` 1, the method `draw` of `Html` 1, the method `grown` of `dyn Grows` 1, `int.checked_add` 1, the prelude's `filter_map`, whose arguments' layouts aren't known 1, a `contains` over elements that don't compare by value 1, `string.char_code` leaving a seat to its default 1, a map literal's spread 1, `Map.find` 1, `Map.drop` 1, `Map.fold` 1, `Map.take` 1, a method that may write its receiver: the method `all` of `box`, which no one impl gives 1, `MutLet` 1, a call of `seat` handing a generic unit a rest or a default its type parameters type, a `mut` seat a place no write reaches back from, or a spread record 1, an untyped `let` 1, `Catch` 1, `BytesLit` 1, a comprehension over a source that isn't a list, a map or a count 1, an untyped `Binary` 1, a method that may write its receiver 1, a const whose value doesn't cross as `Spanned` 1

Notes on the old-tests column:
- **cli 420/438**: 18 `commands/explain` tests fail. This is PRE-EXISTING debt: the same files fail at 31f3d605 with the
  3b610bc7 compiler, and at this clone's graft root 7538c80. The site text prints the whole body block,
  `direct { n + 1 }`, where the test expects `direct n + 1`.
- **std-net 84/90**: sandbox networking (IPv6 and loopback-family tests, a connect timeout).
- **std-http 1364/1365**: the admission redirect test (network).
- **std-program 401/402**: the read-only-directory test, which cannot hold as root.
- **std-avrac exit 2**: not a failure. After "226 rule examples proved" the run hits the pool limit: "this run needs
  more than the machine's whole memory pool: 9765 MB in use", on this 15 GB sandbox.

## What still blocks, ranked

1. **The evaluator cannot carry an extern seat held as a handle** (`sqlite3_open_v2`). 30 failing runs across std-crud,
   std-db, std-sqlite and std-http cores_*. Owner: extern-seats. Re-check on a0ef1a00+, which has extern-seats-2/-3.
2. **std-ui: 53 tests not made**, "a record literal leaving a field no declared default fills", plus 6 "a `dyn` box
   over a method the type doesn't write". The same two reasons make the **site** package's new build refuse: 11 traps
   that tools/program_traps.baseline does not accept; the old build is fine. Owner: ui-build (role fields, dyn box).
   Also in std-ui: 2 × `StructLit` / untyped `Comp`, 2 × `MutLet` (front-defects, fn-local state?), the methods
   `describe` of `tap` / `panel`, generic `headless` layout, one `Lambda`.
3. **std-queue: 9 of 10 not made**, "a default of the generic `queue<Job>`" (9), plus 1 `StructLit`. Owner:
   package-sweep-2 (generic defaults).
4. **std-http hangs under whole-package `--ran`.** An evaluated cores test (std-http server → `avra_cores_fork`)
   forks the multithreaded compiler. Each child goes on running the remaining tests and blocks forever in
   `avra_llvm_objects_unwritten` on `emit_idle`: it inherited `emit_workers > 0` but none of the threads (gdb). You
   say whole-program-3's eval leg in a child fixes it.
5. **New-path build failures (LLVM verifier)**:
   - width-witness: "Trunc only operates on integer: `%narrow = trunc ptr %slot to i32`" and "Call parameter type
     does not match function signature! … `call i32 @witness_out_i64(ptr %slot3)`" in `avra_main`. These are extern out-seats with
     widths, the extern-seats lane (a0ef1a00 says one mechanism landed). The old build is fine.
   - tools/ui-board: "PHI node operands are not the same type as the result! `%regval339 = phi i64 [ 2, … ], [ { i64
     -1, i64 0 }, … ]`" in `Show.read_from`, likely union/optional lowering (lowering-rows-b landed on db94aa87). The
     old build fails too, but at link: `undefined symbol: avra_ui_stood`, `avra_dom_frame`, `avra_ui_arm`.
6. **std-db native traps** (`type_named` at run time) on db_diff and migrate_all. Owner: package-sweep-2.
7. **Refusal text differs for every library package** (42 of them). Old: "avra: <pkg> declares no entry point". New:
   "avra: the program layer doesn't build this program yet — a file that runs no statement, at @std/<x>/src/main.av".
   Both exit 1. Owner: type-refusals / whole-program (refusal text).
8. **Warnings**: the cli old build prints its type warnings (first: "type.coalesce_never `??` never fires"), and the
   new build prints none. Owner: check-baseline / seat-laws, if warnings are meant to reach `build`.
9. **std-avrac's 52 not-made** (no failing runs): `MethodCall` 4, `StructLit` 3, holes 3, `ConstDecl` 2, an untyped `Call` 2,
   non-variant match patterns 2, `Binary` 2, a write to a `let` 2, a walk over a walk 2, catch over union members 2, a
   written receiver a lambda captures 2, then singles (`Map.find/drop/fold/take`, `int.float`, `float.round`,
   `int.checked_add`, `string.char_code` default seat, `dyn Grows.grown`, `Html.draw`, a method that may write its
   receiver ×2, `Catch`, `BytesLit`, …). Owners: lowering-gaps (multi-impl `all` of `box`, may-write-receiver), lowering-rows-b/-c
   and select-lowering (their rows), package-sweep-2 (`ConstDecl`, a const not crossing as `Spanned`).
   Smaller ones elsewhere: std-convert "a hole that isn't a number, a truth or text" 1; std-text `float.round` 1; std-http
   "a call of the generic `declared` whose arguments don't lay out its type parameters" 1 (lowering-gaps, generic
   layouts).

Not measured: tests the lead says `tapes --ran` skips (package-shaped tests). std-task's two signal tests. Every
trunk after 5e7ff03b: a0ef1a00 / db94aa87 / 3d35d216 landed fixes for items 1, 4, 5 and possibly 6, so a re-run
there should drop most of the 41.
